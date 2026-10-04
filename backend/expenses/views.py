from decimal import Decimal
from django.db.models import Sum, Q
from django.contrib.auth.models import User
from django.contrib.auth import authenticate
from rest_framework import viewsets, permissions, status
from rest_framework.views import APIView
from rest_framework.response import Response
from oidc_provider.models import Client, Token
from oidc_provider.lib.utils.token import create_token
from .models import Expense, ExpenseSplit, Settlement, FriendRequest
from .serializers import (
    ExpenseSerializer,
    ExpenseCreateSerializer,
    UserBasicSerializer,
    SettlementSerializer,
    FriendRequestSerializer
)

def get_user_friends(user):
    """
    Returns QuerySet of User objects who have an accepted friendship with `user`.
    """
    sent = FriendRequest.objects.filter(from_user=user, status='accepted').values_list('to_user_id', flat=True)
    received = FriendRequest.objects.filter(to_user=user, status='accepted').values_list('from_user_id', flat=True)
    friend_ids = set(sent).union(set(received))
    return User.objects.filter(id__in=friend_ids, is_active=True).order_by('first_name', 'username')

class ExpenseViewSet(viewsets.ModelViewSet):
    """
    CRUD API for group expenses.
    Protected endpoint: requires valid OIDC Bearer token or session.
    Only returns expenses where the authenticated user is the payer or a split participant.
    """
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        queryset = Expense.objects.filter(
            Q(payer=user) | Q(splits__user=user)
        ).distinct().select_related('payer').prefetch_related('splits__user')

        category = self.request.query_params.get('category')
        if category and category != 'all':
            queryset = queryset.filter(category=category)
        return queryset

    def get_serializer_class(self):
        if self.action in ['create', 'update', 'partial_update']:
            return ExpenseCreateSerializer
        return ExpenseSerializer


class UserListView(APIView):
    """
    Get active members for bill splitting: current user + their accepted friends.
    Pass ?all=true to retrieve all active system users.
    """
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        if request.query_params.get('all') == 'true':
            users = User.objects.filter(is_active=True).order_by('first_name', 'username')
        else:
            friends = get_user_friends(request.user)
            user_ids = set(friends.values_list('id', flat=True)).union({request.user.id})
            users = User.objects.filter(id__in=user_ids, is_active=True).order_by('first_name', 'username')
        serializer = UserBasicSerializer(users, many=True)
        return Response(serializer.data)

    def post(self, request):
        username = request.data.get('username', '').strip().lower()
        display_name = request.data.get('display_name', '').strip()
        first_name = request.data.get('first_name', '').strip() or display_name
        email = request.data.get('email', '').strip()

        if not username:
            return Response({'error': 'กรุณาระบุชื่อผู้ใช้ (username)'}, status=status.HTTP_400_BAD_REQUEST)
        if User.objects.filter(username=username).exists():
            return Response({'error': f'มีชื่อผู้ใช้ "{username}" ในระบบแล้ว'}, status=status.HTTP_400_BAD_REQUEST)

        user = User.objects.create_user(
            username=username,
            first_name=first_name,
            email=email or f"{username}@splitsquad.app",
            password=f"{username}123"
        )
        return Response(UserBasicSerializer(user).data, status=status.HTTP_201_CREATED)


class BalanceSummaryView(APIView):
    """
    Computes debt balance summary for the authenticated user:
    - total_owed_to_you: money others owe you
    - total_you_owe: money you owe others
    - net_balance: net position
    - people_balances: individual breakdowns per member
    """
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        current_user = request.user

        # 1. Money others owe current user
        unsettled_owed_to_me = ExpenseSplit.objects.filter(
            expense__payer=current_user,
            is_settled=False
        ).exclude(user=current_user)

        total_owed_to_you = unsettled_owed_to_me.aggregate(
            total=Sum('amount_owed')
        )['total'] or Decimal('0.00')

        # 2. Money current user owes others
        unsettled_i_owe = ExpenseSplit.objects.filter(
            user=current_user,
            is_settled=False
        ).exclude(expense__payer=current_user)

        total_you_owe = unsettled_i_owe.aggregate(
            total=Sum('amount_owed')
        )['total'] or Decimal('0.00')

        # 3. Individual balance calculations with each other user
        other_users = User.objects.filter(is_active=True).exclude(pk=current_user.pk)
        people_balances = []

        for other in other_users:
            they_owe_me = ExpenseSplit.objects.filter(
                expense__payer=current_user,
                user=other,
                is_settled=False
            ).aggregate(total=Sum('amount_owed'))['total'] or Decimal('0.00')

            i_owe_them = ExpenseSplit.objects.filter(
                expense__payer=other,
                user=current_user,
                is_settled=False
            ).aggregate(total=Sum('amount_owed'))['total'] or Decimal('0.00')

            net = they_owe_me - i_owe_them
            if net != 0:
                people_balances.append({
                    'user': UserBasicSerializer(other).data,
                    'they_owe_you': float(they_owe_me),
                    'you_owe_them': float(i_owe_them),
                    'net_amount': float(net),  # positive: they owe you, negative: you owe them
                })

        return Response({
            'total_owed_to_you': float(total_owed_to_you),
            'total_you_owe': float(total_you_owe),
            'net_balance': float(total_owed_to_you - total_you_owe),
            'people_balances': people_balances,
        })


class SettleDebtView(APIView):
    """
    Settle outstanding balances with another user.
    """
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = SettlementSerializer(data=request.data, context={'request': request})
        if serializer.is_valid():
            settlement = serializer.save()
            return Response(SettlementSerializer(settlement).data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class LoginTokenView(APIView):
    """
    Authenticate username/password and issue an OpenID Connect Token
    for mobile and client applications.
    """
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        username = request.data.get('username')
        password = request.data.get('password')
        client_id = request.data.get('client_id', 'flutter-mobile-client')

        if not username or not password:
            return Response(
                {'error': 'กรุณาระบุ username และ password'},
                status=status.HTTP_400_BAD_REQUEST
            )

        user = authenticate(request, username=username, password=password)
        if not user:
            return Response(
                {'error': 'ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง'},
                status=status.HTTP_401_UNAUTHORIZED
            )

        client = Client.objects.filter(client_id=client_id).first()
        if not client:
            client = Client.objects.first()

        scope = ['openid', 'profile', 'email']
        id_token_dic = {'sub': str(user.pk)}
        token = create_token(user, client, scope, id_token_dic=id_token_dic)
        token.save()

        return Response({
            'access_token': token.access_token,
            'token_type': 'Bearer',
            'expires_in': 3600,
            'id_token': token.id_token,
            'user': UserBasicSerializer(user).data
        })


class LogoutTokenView(APIView):
    """
    Terminates user session on OIDC/Django backend.
    """
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        from django.contrib.auth import logout
        logout(request)
        return Response({'message': 'Logged out successfully'})


class FriendListView(APIView):
    """
    List accepted friends of the current user.
    """
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        friends = get_user_friends(request.user)
        return Response(UserBasicSerializer(friends, many=True).data)


class FriendRequestListView(APIView):
    """
    List pending incoming/outgoing friend requests and send a new request by username.
    """
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        incoming = FriendRequest.objects.filter(to_user=request.user, status='pending')
        outgoing = FriendRequest.objects.filter(from_user=request.user, status='pending')
        return Response({
            'incoming': FriendRequestSerializer(incoming, many=True).data,
            'outgoing': FriendRequestSerializer(outgoing, many=True).data,
        })

    def post(self, request):
        username = request.data.get('username', '').strip()
        if not username:
            return Response({'error': 'กรุณาระบุ Username ของผู้ใช้ที่ต้องการเพิ่มเป็นเพื่อน'}, status=status.HTTP_400_BAD_REQUEST)

        if username.lower() == request.user.username.lower():
            return Response({'error': 'ไม่สามารถส่งคำขอเป็นเพื่อนให้ตนเองได้'}, status=status.HTTP_400_BAD_REQUEST)

        target_user = User.objects.filter(username__iexact=username, is_active=True).first()
        if not target_user:
            return Response({'error': f'ไม่พบบัญชีผู้ใช้ "{username}" ในระบบ'}, status=status.HTTP_404_NOT_FOUND)

        # Check if already accepted friends
        already_friends = FriendRequest.objects.filter(
            (Q(from_user=request.user, to_user=target_user) | Q(from_user=target_user, to_user=request.user)) &
            Q(status='accepted')
        ).exists()
        if already_friends:
            return Response({'error': f'คุณและ {target_user.username} เป็นเพื่อนกันอยู่แล้ว'}, status=status.HTTP_400_BAD_REQUEST)

        # Check if target already sent a pending request to current user -> auto accept!
        incoming_req = FriendRequest.objects.filter(from_user=target_user, to_user=request.user, status='pending').first()
        if incoming_req:
            incoming_req.status = 'accepted'
            incoming_req.save()
            return Response({
                'message': f'ยอมรับคำขอเป็นเพื่อนจาก {target_user.username} เรียบร้อยแล้ว',
                'request': FriendRequestSerializer(incoming_req).data,
                'is_friend': True
            }, status=status.HTTP_200_OK)

        # Check if current user already has pending request to target
        outgoing_req = FriendRequest.objects.filter(from_user=request.user, to_user=target_user, status='pending').first()
        if outgoing_req:
            return Response({'error': f'คุณได้ส่งคำขอเป็นเพื่อนไปยัง {target_user.username} แล้ว รอการตอบรับ'}, status=status.HTTP_400_BAD_REQUEST)

        # If previous request was rejected or exists in another direction, reuse or create
        existing = FriendRequest.objects.filter(
            Q(from_user=request.user, to_user=target_user) | Q(from_user=target_user, to_user=request.user)
        ).first()

        if existing:
            existing.from_user = request.user
            existing.to_user = target_user
            existing.status = 'pending'
            existing.save()
            req_obj = existing
        else:
            req_obj = FriendRequest.objects.create(
                from_user=request.user,
                to_user=target_user,
                status='pending'
            )

        return Response({
            'message': f'ส่งคำขอเป็นเพื่อนไปยัง {target_user.username} เรียบร้อยแล้ว',
            'request': FriendRequestSerializer(req_obj).data,
            'is_friend': False
        }, status=status.HTTP_201_CREATED)


class FriendRequestRespondView(APIView):
    """
    Accept or reject an incoming friend request.
    Endpoint: POST /api/friends/requests/<int:pk>/respond/
    Payload: {"action": "accept"} or {"action": "reject"}
    """
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk):
        action = request.data.get('action', '').strip().lower()
        if action not in ['accept', 'reject']:
            return Response({'error': 'การกระทำไม่ถูกต้อง (ต้องเป็น "accept" หรือ "reject")'}, status=status.HTTP_400_BAD_REQUEST)

        friend_req = FriendRequest.objects.filter(pk=pk, to_user=request.user, status='pending').first()
        if not friend_req:
            return Response({'error': 'ไม่พบคำขอเป็นเพื่อนที่รอการตอบรับนี้'}, status=status.HTTP_404_NOT_FOUND)

        if action == 'accept':
            friend_req.status = 'accepted'
            friend_req.save()
            return Response({
                'message': f'ยอมรับคำขอเป็นเพื่อนจาก {friend_req.from_user.username} สำเร็จ',
                'request': FriendRequestSerializer(friend_req).data
            })
        else:
            friend_req.status = 'rejected'
            friend_req.save()
            return Response({
                'message': f'ปฏิเสธคำขอเป็นเพื่อนจาก {friend_req.from_user.username} แล้ว',
                'request': FriendRequestSerializer(friend_req).data
            })
