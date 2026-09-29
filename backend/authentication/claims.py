"""
Custom claims provider for django-oidc-provider.
"""

def userinfo(claims, user):
    """
    Populate OpenID Connect userinfo claims based on Django User model.
    """
    claims['sub'] = str(user.pk)
    claims['name'] = f"{user.first_name} {user.last_name}".strip() or user.username
    claims['given_name'] = user.first_name or user.username
    claims['family_name'] = user.last_name or ""
    claims['preferred_username'] = user.username
    claims['nickname'] = user.username
    claims['email'] = user.email or ""
    claims['email_verified'] = bool(user.email)
    return claims
