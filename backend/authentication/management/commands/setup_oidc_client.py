import uuid
from django.core.management.base import BaseCommand
from django.core.management import call_command
from oidc_provider.models import Client, ResponseType, RSAKey

class Command(BaseCommand):
    help = "Creates or updates an OpenID Connect Client and ensures RSA signing keys exist."

    def add_arguments(self, parser):
        parser.add_argument(
            '--name',
            default='Mobile App Client',
            help='Name of the OIDC client application',
        )
        parser.add_argument(
            '--client-id',
            default=None,
            help='Client ID (default: auto-generated)',
        )
        parser.add_argument(
            '--client-secret',
            default=None,
            help='Client secret (default: auto-generated)',
        )
        parser.add_argument(
            '--client-type',
            default='public',
            choices=['public', 'confidential'],
            help='Client type (default: public for mobile apps)',
        )
        parser.add_argument(
            '--redirect-uris',
            nargs='+',
            default=[
                'http://localhost:3000/callback',
                'com.example.frontend:/oauth2redirect',
                'http://127.0.0.1:8000/callback',
            ],
            help='Allowed redirect URIs',
        )
        parser.add_argument(
            '--skip-consent',
            action='store_true',
            help='Automatically skip consent screen for this client',
        )

    def handle(self, *args, **options):
        # 1. Ensure at least one RSAKey exists
        if not RSAKey.objects.exists():
            self.stdout.write("Generating new RSA key for token signing...")
            call_command('creatersakey')
        else:
            self.stdout.write(self.style.SUCCESS("Existing RSAKey found."))

        # 2. Get or create Client
        name = options['name']
        client_id = options['client_id'] or str(uuid.uuid4().hex[:16])
        client_secret = options['client_secret'] or str(uuid.uuid4().hex[:32])
        client_type = options['client_type']
        redirect_uris = options['redirect_uris']
        require_consent = not options['skip_consent']

        client, created = Client.objects.get_or_create(
            name=name,
            defaults={
                'client_id': client_id,
                'client_secret': client_secret,
                'client_type': client_type,
                'jwt_alg': 'RS256',
                'require_consent': require_consent,
                'reuse_consent': True,
            }
        )

        # Update attributes
        client.redirect_uris = redirect_uris
        client.client_type = client_type
        client.jwt_alg = 'RS256'
        client.require_consent = require_consent
        client.reuse_consent = True
        client.save()

        # Associate response types (code and id_token token)
        code_rt = ResponseType.objects.filter(value='code').first()
        id_token_rt = ResponseType.objects.filter(value='id_token token').first()
        if code_rt:
            client.response_types.add(code_rt)
        if id_token_rt:
            client.response_types.add(id_token_rt)

        action = "Created" if created else "Updated"
        self.stdout.write(self.style.SUCCESS(f"\n{action} OIDC Client successfully!"))
        self.stdout.write("--------------------------------------------------")
        self.stdout.write(f"Client Name:       {client.name}")
        self.stdout.write(f"Client ID:         {client.client_id}")
        self.stdout.write(f"Client Secret:     {client.client_secret}")
        self.stdout.write(f"Client Type:       {client.client_type}")
        self.stdout.write(f"JWT Alg:           {client.jwt_alg}")
        self.stdout.write(f"Require Consent:   {client.require_consent}")
        self.stdout.write("Redirect URIs:")
        for uri in client.redirect_uris:
            self.stdout.write(f"  - {uri}")
        self.stdout.write("--------------------------------------------------")
