from decimal import Decimal
from django.core.management.base import BaseCommand
from django.contrib.auth.models import User
from django.core.management import call_command
from oidc_provider.models import Client, ResponseType, RSAKey
from expenses.models import Expense, ExpenseSplit, ExpenseCategory, FriendRequest

class Command(BaseCommand):
    help = "Seeds initial development users, OIDC client, and sample group expenses."

    def handle(self, *args, **options):
        # 1. Ensure RSA Key for OIDC exists
        if not RSAKey.objects.exists():
            self.stdout.write("Generating RSA Key for OIDC...")
            call_command('creatersakey')

        # 2. Setup standard OIDC Client for Flutter App
        client_id = "flutter-mobile-client"
        redirect_uris = [
            'http://localhost:50000/callback',
            'http://127.0.0.1:50000/callback',
            'http://localhost:50000',
            'http://127.0.0.1:50000',
            'com.example.frontend:/oauth2redirect',
            'http://localhost:3000/callback',
            'http://127.0.0.1:8000/callback',
            'http://localhost:8000/callback',
        ]
        client, created = Client.objects.get_or_create(
            client_id=client_id,
            defaults={
                'name': 'SplitSquad Flutter App',
                'client_type': 'public',
                'jwt_alg': 'RS256',
                'require_consent': False,
                'reuse_consent': True,
                'redirect_uris': redirect_uris,
            }
        )
        client.redirect_uris = redirect_uris
        client.client_type = 'public'
        client.require_consent = False
        client.reuse_consent = True
        client.save()

        code_rt = ResponseType.objects.filter(value='code').first()
        id_token_rt = ResponseType.objects.filter(value='id_token token').first()
        if code_rt:
            client.response_types.add(code_rt)
        if id_token_rt:
            client.response_types.add(id_token_rt)

        self.stdout.write(self.style.SUCCESS(f"OIDC Client ready: {client.client_id}"))

        # 3. Create Sample Users
        users_data = [
            {'username': 'admin', 'pass': 'admin123', 'first': 'System', 'last': 'Admin', 'email': 'admin@splitsquad.app', 'is_staff': True, 'is_super': True},
            {'username': 'alice', 'pass': 'alice123', 'first': 'Alice', 'last': 'Chen', 'email': 'alice@example.com', 'is_staff': False, 'is_super': False},
            {'username': 'bob', 'pass': 'bob123', 'first': 'Bob', 'last': 'Smith', 'email': 'bob@example.com', 'is_staff': False, 'is_super': False},
            {'username': 'somchai', 'pass': 'somchai123', 'first': 'Somchai', 'last': 'Jaidee', 'email': 'somchai@example.com', 'is_staff': False, 'is_super': False},
        ]

        users_dict = {}
        for u_info in users_data:
            user, u_created = User.objects.get_or_create(
                username=u_info['username'],
                defaults={
                    'first_name': u_info['first'],
                    'last_name': u_info['last'],
                    'email': u_info['email'],
                    'is_staff': u_info['is_staff'],
                    'is_superuser': u_info['is_super'],
                }
            )
            user.set_password(u_info['pass'])
            user.save()
            users_dict[u_info['username']] = user
            status_str = "Created" if u_created else "Updated"
            self.stdout.write(f"{status_str} user: {user.username} (pw: {u_info['pass']})")

        # 3.1 Establish mutual friendships among demo users
        demo_pairs = [
            ('admin', 'alice'),
            ('admin', 'bob'),
            ('admin', 'somchai'),
            ('alice', 'bob'),
            ('alice', 'somchai'),
            ('bob', 'somchai'),
        ]
        for u1, u2 in demo_pairs:
            user_a = users_dict[u1]
            user_b = users_dict[u2]
            FriendRequest.objects.get_or_create(
                from_user=user_a,
                to_user=user_b,
                defaults={'status': 'accepted'}
            )
        self.stdout.write(self.style.SUCCESS("Demo friendships established!"))

        # 4. Create Sample Expenses if empty
        if not Expense.objects.exists():
            sample_bills = [
                {
                    'title': 'บุฟเฟต์ชาบู ชาบูชิ เซ็นทรัล',
                    'amount': Decimal('1596.00'),
                    'category': ExpenseCategory.FOOD,
                    'payer': users_dict['alice'],
                    'notes': 'กินหลังสอบเสร็จ 4 คน หารเท่ากัน',
                    'participants': [users_dict['admin'], users_dict['alice'], users_dict['bob'], users_dict['somchai']],
                },
                {
                    'title': 'ค่า Grab เดินทางไปสถานีรถไฟ',
                    'amount': Decimal('450.00'),
                    'category': ExpenseCategory.TRANSPORT,
                    'payer': users_dict['bob'],
                    'notes': 'Grab Van 7 ที่นั่ง',
                    'participants': [users_dict['admin'], users_dict['alice'], users_dict['bob']],
                },
                {
                    'title': 'ค่าห้องพักพูลวิลล่า หัวหิน (2 คืน)',
                    'amount': Decimal('4800.00'),
                    'category': ExpenseCategory.HOUSING,
                    'payer': users_dict['admin'],
                    'notes': 'จองผ่าน Agoda',
                    'participants': [users_dict['admin'], users_dict['alice'], users_dict['bob'], users_dict['somchai']],
                },
                {
                    'title': 'ตั๋วบัตรคอนเสิร์ตดนตรีในสวน',
                    'amount': Decimal('1200.00'),
                    'category': ExpenseCategory.ENTERTAINMENT,
                    'payer': users_dict['somchai'],
                    'notes': 'บัตร Early Bird 2 ใบ',
                    'participants': [users_dict['admin'], users_dict['somchai']],
                },
            ]

            for bill in sample_bills:
                exp = Expense.objects.create(
                    title=bill['title'],
                    amount=bill['amount'],
                    category=bill['category'],
                    payer=bill['payer'],
                    notes=bill['notes'],
                )
                split_val = (bill['amount'] / Decimal(len(bill['participants']))).quantize(Decimal('0.01'))
                for p in bill['participants']:
                    ExpenseSplit.objects.create(
                        expense=exp,
                        user=p,
                        amount_owed=split_val,
                        is_settled=(p.id == bill['payer'].id)
                    )
                self.stdout.write(f"Created sample bill: {exp.title} ({exp.amount} THB)")

        self.stdout.write(self.style.SUCCESS("All seed data created successfully!"))
