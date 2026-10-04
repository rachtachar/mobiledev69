from django.db import models
from django.contrib.auth.models import User

class ExpenseCategory(models.TextChoices):
    FOOD = 'food', 'อาหารและเครื่องดื่ม'
    TRANSPORT = 'transport', 'การเดินทาง'
    HOUSING = 'housing', 'ที่พักและโรงแรม'
    ENTERTAINMENT = 'entertainment', 'บันเทิงและกิจกรรม'
    SHOPPING = 'shopping', 'ซื้อของและของใช้'
    OTHER = 'other', 'อื่นๆ'

class Expense(models.Model):
    title = models.CharField(max_length=150)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    category = models.CharField(
        max_length=20,
        choices=ExpenseCategory.choices,
        default=ExpenseCategory.FOOD
    )
    payer = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='expenses_paid'
    )
    notes = models.TextField(blank=True, default='')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.title} ({self.amount} บาท) โดย {self.payer.username}"


class ExpenseSplit(models.Model):
    expense = models.ForeignKey(
        Expense,
        on_delete=models.CASCADE,
        related_name='splits'
    )
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='expense_splits'
    )
    amount_owed = models.DecimalField(max_digits=10, decimal_places=2)
    is_settled = models.BooleanField(default=False)
    settled_at = models.DateTimeField(null=True, blank=True)

    def __str__(self):
        status = "จ่ายแล้ว" if self.is_settled else "ยังไม่จ่าย"
        return f"{self.user.username} ค้าง {self.amount_owed} บาท ใน {self.expense.title} ({status})"


class Settlement(models.Model):
    debtor = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='settlements_made'
    )
    creditor = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='settlements_received'
    )
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    settled_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.debtor.username} ชำระเงิน {self.amount} บาท ให้ {self.creditor.username}"


class FriendRequest(models.Model):
    STATUS_CHOICES = (
        ('pending', 'Pending'),
        ('accepted', 'Accepted'),
        ('rejected', 'Rejected'),
    )
    from_user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='sent_friend_requests'
    )
    to_user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='received_friend_requests'
    )
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ('from_user', 'to_user')
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.from_user.username} -> {self.to_user.username} ({self.status})"

