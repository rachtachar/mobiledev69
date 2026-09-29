# Backend (Django + django-oidc-provider)

This backend serves as an **OpenID Connect (OIDC) Identity Provider & Authorization Server** built with Django and `django-oidc-provider`. It is configured to authenticate users and issue tokens to mobile (Flutter) and web applications.

---

## Features

- **OIDC Provider**: Full OpenID Connect implementation supporting Authorization Code flow with PKCE and Implicit flow.
- **Discovery Endpoint**: Automatically exposes configuration at `.well-known/openid-configuration`.
- **Key Management**: Built-in RSA key generation and JWKS endpoint for token verification.
- **Custom Claims**: Configured in `authentication/claims.py` (`name`, `given_name`, `family_name`, `preferred_username`, `email`, `email_verified`).
- **CORS Support**: `django-cors-headers` enabled for cross-origin requests from Flutter web or emulators.
- **Modern Styled UI**: Templates for Sign In, Consent Screen, and Error Handling.

---

## Quick Start (with `uv`)

### 1. Run Migrations & Signing Keys
```bash
cd backend
uv run manage.py migrate
uv run manage.py creatersakey
```

### 2. Seed Development Users & Data
```bash
uv run manage.py seed_splitsquad_data
```

### 3. Run the Server
```bash
uv run manage.py runserver 0.0.0.0:8000
```

---

## OpenID Connect Endpoints

| Endpoint | URL | Description |
| :--- | :--- | :--- |
| **Discovery** | `/openid/.well-known/openid-configuration` | OpenID provider configuration metadata |
| **JWKS** | `/openid/jwks/` | Public RSA keys for verifying ID tokens |
| **Authorize** | `/openid/authorize/` | User authentication & consent authorization |
| **Token** | `/openid/token/` | Exchange authorization code for tokens |
| **Userinfo** | `/openid/userinfo/` | User profile claims |
| **End Session** | `/openid/end-session/` | Logout / RP-initiated session termination |

---

## Connecting from Flutter / Mobile App

When configuring an OIDC client package in Flutter (e.g. `openid_client` or `flutter_appauth`):

- **Issuer**: `http://10.0.2.2:8000/openid` (Android Emulator) or `http://localhost:8000/openid` (iOS Simulator / Web)
- **Client ID**: `flutter-mobile-client`
- **Redirect URI**: `com.example.frontend:/oauth2redirect` or `http://localhost:3000/callback`
- **Scopes**: `openid profile email`
- **Response Type**: `code`
