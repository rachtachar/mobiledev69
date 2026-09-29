from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model

User = get_user_model()

class Command(BaseCommand):
    help = "Creates a default superuser for development if one does not already exist."

    def add_arguments(self, parser):
        parser.add_argument('--username', default='admin', help='Superuser username')
        parser.add_argument('--password', default='admin123', help='Superuser password')
        parser.add_argument('--email', default='admin@example.com', help='Superuser email')

    def handle(self, *args, **options):
        username = options['username']
        password = options['password']
        email = options['email']

        if User.objects.filter(username=username).exists():
            self.stdout.write(self.style.WARNING(f"User '{username}' already exists."))
            user = User.objects.get(username=username)
            user.set_password(password)
            user.is_superuser = True
            user.is_staff = True
            user.save()
            self.stdout.write(self.style.SUCCESS(f"Updated password for '{username}'."))
        else:
            User.objects.create_superuser(
                username=username,
                email=email,
                password=password,
                first_name='Dev',
                last_name='Admin'
            )
            self.stdout.write(self.style.SUCCESS(f"Created superuser '{username}' with password '{password}'."))
