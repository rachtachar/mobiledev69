from decimal import Decimal
from django.db.models import Sum, Q
from django.contrib.auth.models import User
from django.contrib.auth import authenticate
from rest_framework import viewsets, permissions, status
from rest_framework.views import APIView
from rest_framework.response import Response
from oidc_provider.models import Client, Token
from oidc_provider.lib.utils.token import create_token
from .models import Expense, ExpenseSplit, Settlement
from .serializers import (
    ExpenseSerializer,
    ExpenseCreateSerializer,
    UserBasicSerializer,
    SettlementSerializer
)

class ExpenseViewSet(viewsets.ModelViewSet):
    """
    CRUD API for group expenses.
    Protected endpoint: requires valid OIDC Bearer token or session.
    """
    queryset = Expense.objects.all().select_related('payer').prefetch_related('splits__user')
    permission_classes = [permissions.IsAuthenticated]

    def get_serializer_class(self):
        if self.action == 'create':
            return ExpenseCreateSerializer
        return ExpenseSerializer

    def filter_queryset(self, queryset):
        category = self.request.query_params.get('category')
        if category and category != 'all':
            queryset = queryset.filter(category=category)
        return queryset


class UserListView(APIView):
    """
    Get active members in the organization/group for bill splitting.
    """
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        users = User.objects.filter(is_active=True).order_by('first_name', 'username')
        serializer = UserBasicSerializer(users, many=True)
        return Response(serializer.data)


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
