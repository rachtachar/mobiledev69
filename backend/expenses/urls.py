from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    ExpenseViewSet,
    UserListView,
    BalanceSummaryView,
    SettleDebtView,
    LoginTokenView,
    LogoutTokenView,
    FriendListView,
    FriendRequestListView,
    FriendRequestRespondView,
    RemoveFriendView,
    FriendRequestDeleteView,
    MarkSplitPaidView,
    VerifySplitPaymentView,
)

router = DefaultRouter()
router.register(r'expenses', ExpenseViewSet, basename='expense')

urlpatterns = [
    path('', include(router.urls)),
    path('auth/token/', LoginTokenView.as_view(), name='auth-token'),
    path('auth/logout/', LogoutTokenView.as_view(), name='auth-logout'),
    path('users/', UserListView.as_view(), name='user-list'),
    path('summary/', BalanceSummaryView.as_view(), name='balance-summary'),
    path('settle/', SettleDebtView.as_view(), name='settle-debt'),
    path('friends/', FriendListView.as_view(), name='friend-list'),
    path('friends/<int:pk>/', RemoveFriendView.as_view(), name='friend-remove'),
    path('friends/requests/', FriendRequestListView.as_view(), name='friend-requests'),
    path('friends/requests/<int:pk>/', FriendRequestDeleteView.as_view(), name='friend-request-delete'),
    path('friends/requests/<int:pk>/respond/', FriendRequestRespondView.as_view(), name='friend-respond'),
    path('splits/<int:pk>/mark-paid/', MarkSplitPaidView.as_view(), name='split-mark-paid'),
    path('splits/<int:pk>/verify/', VerifySplitPaymentView.as_view(), name='split-verify'),
]
