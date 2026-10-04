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

from django.contrib.auth import login as auth_login
from django.contrib.auth.models import User
from django.shortcuts import render, redirect

def register_view(request):
    """
    User registration for OpenID Connect server.
    """
    next_url = request.GET.get('next', request.POST.get('next', '/'))
    error = None
    if request.method == 'POST':
        username = request.POST.get('username', '').strip().lower()
        display_name = request.POST.get('display_name', '').strip()
        email = request.POST.get('email', '').strip()
        password = request.POST.get('password', '')

        if not username or not password:
            error = "กรุณากรอก Username และ Password ให้ครบถ้วน"
        elif User.objects.filter(username=username).exists():
            error = f'ชื่อผู้ใช้ "{username}" มีอยู่ในระบบแล้ว กรุณาใช้ชื่ออื่น'
        elif len(password) < 4:
            error = "รหัสผ่านต้องมีอย่างน้อย 4 ตัวอักษร"
        else:
            user = User.objects.create_user(
                username=username,
                first_name=display_name or username,
                email=email or f"{username}@splitsquad.app",
                password=password
            )
            auth_login(request, user)
            return redirect(next_url or '/')

    return render(request, 'registration/register.html', {'next': next_url, 'error': error})

urlpatterns = [
    path('admin/', admin.site.urls),

    # Authentication views
    path('accounts/login/', auth_views.LoginView.as_view(template_name='registration/login.html'), name='login'),
    path('accounts/register/', register_view, name='register'),
    path('accounts/logout/', auth_views.LogoutView.as_view(next_page='/accounts/login/'), name='logout'),

    # OpenID Connect Provider endpoints
    path('openid/', include('oidc_provider.urls', namespace='oidc_provider')),

    # REST API endpoints for SplitSquad
    path('api/', include('expenses.urls')),

    # Root welcome / API overview
    path('', index_view, name='index'),
]
