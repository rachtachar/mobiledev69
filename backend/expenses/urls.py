from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import ExpenseViewSet, UserListView, BalanceSummaryView, SettleDebtView, LoginTokenView

router = DefaultRouter()
router.register(r'expenses', ExpenseViewSet, basename='expense')

urlpatterns = [
    path('', include(router.urls)),
    path('auth/token/', LoginTokenView.as_view(), name='auth-token'),
    path('users/', UserListView.as_view(), name='user-list'),
    path('summary/', BalanceSummaryView.as_view(), name='balance-summary'),
    path('settle/', SettleDebtView.as_view(), name='settle-debt'),
]
