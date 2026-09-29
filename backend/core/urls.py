"""
URL configuration for core project.
"""

from django.contrib import admin
from django.urls import path, include
from django.contrib.auth import views as auth_views
from django.http import JsonResponse
from django.shortcuts import render

def index_view(request):
    """
    Root status and endpoint overview.
    """
    context = {
        'user': request.user,
        'discovery_url': request.build_absolute_uri('/openid/.well-known/openid-configuration'),
        'jwks_url': request.build_absolute_uri('/openid/jwks/'),
        'authorize_url': request.build_absolute_uri('/openid/authorize/'),
        'token_url': request.build_absolute_uri('/openid/token/'),
        'userinfo_url': request.build_absolute_uri('/openid/userinfo/'),
    }
    if request.headers.get('Accept') == 'application/json':
        return JsonResponse({
            'status': 'ok',
            'service': 'Django OpenID Connect Provider',
            'endpoints': context,
        })
    return render(request, 'index.html', context)

urlpatterns = [
    path('admin/', admin.site.urls),

    # Authentication views
    path('accounts/login/', auth_views.LoginView.as_view(template_name='registration/login.html'), name='login'),
    path('accounts/logout/', auth_views.LogoutView.as_view(next_page='/accounts/login/'), name='logout'),

    # OpenID Connect Provider endpoints
    path('openid/', include('oidc_provider.urls', namespace='oidc_provider')),

    # REST API endpoints for SplitSquad
    path('api/', include('expenses.urls')),

    # Root welcome / API overview
    path('', index_view, name='index'),
]
