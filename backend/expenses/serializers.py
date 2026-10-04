from decimal import Decimal
from rest_framework import serializers
from django.contrib.auth.models import User
from .models import Expense, ExpenseSplit, Settlement, ExpenseCategory, FriendRequest

class UserBasicSerializer(serializers.ModelSerializer):
    display_name = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = ['id', 'username', 'first_name', 'last_name', 'email', 'display_name']

    def get_display_name(self, obj):
        full = f"{obj.first_name} {obj.last_name}".strip()
        return full if full else obj.username


class ExpenseSplitSerializer(serializers.ModelSerializer):
    user = UserBasicSerializer(read_only=True)

    class Meta:
        model = ExpenseSplit
        fields = ['id', 'user', 'amount_owed', 'is_settled', 'settled_at']


class ExpenseSerializer(serializers.ModelSerializer):
    payer = UserBasicSerializer(read_only=True)
    splits = ExpenseSplitSerializer(many=True, read_only=True)
    category_display = serializers.CharField(source='get_category_display', read_only=True)

    class Meta:
        model = Expense
        fields = [
            'id',
            'title',
            'amount',
            'category',
            'category_display',
            'payer',
            'notes',
            'created_at',
            'splits',
        ]


class ExpenseCreateSerializer(serializers.ModelSerializer):
    participant_ids = serializers.ListField(
        child=serializers.IntegerField(),
        write_only=True,
        required=False,
        help_text="List of User IDs who participate in splitting this bill"
    )

    class Meta:
        model = Expense
        fields = ['id', 'title', 'amount', 'category', 'notes', 'participant_ids']

    def create(self, validated_data):
        participant_ids = validated_data.pop('participant_ids', [])
        payer = self.context['request'].user
        validated_data['payer'] = payer

        expense = Expense.objects.create(**validated_data)

        # Participants: if empty, default to payer
        if not participant_ids:
            participant_ids = [payer.id]

        users = list(User.objects.filter(id__in=participant_ids))
        if users:
            split_amount = (expense.amount / Decimal(len(users))).quantize(Decimal('0.01'))
            for u in users:
                is_settled = (u.id == payer.id) # Payer has already paid their own share
                ExpenseSplit.objects.create(
                    expense=expense,
                    user=u,
                    amount_owed=split_amount,
                    is_settled=is_settled
                )

        return expense

    def update(self, instance, validated_data):
        participant_ids = validated_data.pop('participant_ids', None)
        for attr, val in validated_data.items():
            setattr(instance, attr, val)
        instance.save()

        if participant_ids is not None:
            instance.splits.all().delete()
            users = list(User.objects.filter(id__in=participant_ids))
            if users:
                split_amount = (instance.amount / Decimal(len(users))).quantize(Decimal('0.01'))
                for u in users:
                    is_settled = (u.id == instance.payer.id)
                    ExpenseSplit.objects.create(
                        expense=instance,
                        user=u,
                        amount_owed=split_amount,
                        is_settled=is_settled
                    )
        return instance

    def to_representation(self, instance):
        return ExpenseSerializer(instance, context=self.context).data


class SettlementSerializer(serializers.ModelSerializer):
    debtor = UserBasicSerializer(read_only=True)
    creditor = UserBasicSerializer(read_only=True)
    creditor_id = serializers.IntegerField(write_only=True)

    class Meta:
        model = Settlement
        fields = ['id', 'debtor', 'creditor', 'creditor_id', 'amount', 'settled_at']

    def create(self, validated_data):
        debtor = self.context['request'].user
        creditor_id = validated_data.pop('creditor_id')
        creditor = User.objects.get(pk=creditor_id)

        settlement = Settlement.objects.create(
            debtor=debtor,
            creditor=creditor,
            **validated_data
        )

        # Mark matching unsettled splits where debtor owes creditor as settled up to this amount
        unsettled_splits = ExpenseSplit.objects.filter(
            user=debtor,
            expense__payer=creditor,
            is_settled=False
        )
        remaining = settlement.amount
        for split in unsettled_splits:
            if remaining <= 0:
                break
            if split.amount_owed <= remaining:
                split.is_settled = True
                split.save()
                remaining -= split.amount_owed

        return settlement


class FriendRequestSerializer(serializers.ModelSerializer):
    from_user = UserBasicSerializer(read_only=True)
    to_user = UserBasicSerializer(read_only=True)

    class Meta:
        model = FriendRequest
        fields = ['id', 'from_user', 'to_user', 'status', 'created_at', 'updated_at']
