import 'user_model.dart';

class ExpenseSplitModel {
  final int id;
  final UserModel user;
  final double amountOwed;
  final bool isSettled;
  final DateTime? settledAt;
  final bool pendingVerification;
  final DateTime? paidMarkedAt;

  const ExpenseSplitModel({
    required this.id,
    required this.user,
    required this.amountOwed,
    required this.isSettled,
    this.settledAt,
    this.pendingVerification = false,
    this.paidMarkedAt,
  });

  factory ExpenseSplitModel.fromJson(Map<String, dynamic> json) {
    return ExpenseSplitModel(
      id: json['id'] ?? 0,
      user: UserModel.fromJson(json['user'] ?? {}),
      amountOwed: double.tryParse(json['amount_owed']?.toString() ?? '0') ?? 0.0,
      isSettled: json['is_settled'] ?? false,
      settledAt: json['settled_at'] != null ? DateTime.tryParse(json['settled_at'].toString()) : null,
      pendingVerification: json['pending_verification'] ?? false,
      paidMarkedAt: json['paid_marked_at'] != null ? DateTime.tryParse(json['paid_marked_at'].toString()) : null,
    );
  }
}

class ExpenseModel {
  final int id;
  final String title;
  final double amount;
  final String category;
  final String categoryDisplay;
  final UserModel payer;
  final String notes;
  final DateTime createdAt;
  final List<ExpenseSplitModel> splits;

  const ExpenseModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.categoryDisplay,
    required this.payer,
    required this.notes,
    required this.createdAt,
    required this.splits,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      category: json['category'] ?? 'other',
      categoryDisplay: json['category_display'] ?? '',
      payer: UserModel.fromJson(json['payer'] ?? {}),
      notes: json['notes'] ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      splits: (json['splits'] as List<dynamic>? ?? [])
          .map((s) => ExpenseSplitModel.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PersonBalanceModel {
  final UserModel user;
  final double theyOweYou;
  final double youOweThem;
  final double netAmount; // Positive means they owe you, negative means you owe them

  const PersonBalanceModel({
    required this.user,
    required this.theyOweYou,
    required this.youOweThem,
    required this.netAmount,
  });

  factory PersonBalanceModel.fromJson(Map<String, dynamic> json) {
    return PersonBalanceModel(
      user: UserModel.fromJson(json['user'] ?? {}),
      theyOweYou: double.tryParse(json['they_owe_you']?.toString() ?? '0') ?? 0.0,
      youOweThem: double.tryParse(json['you_owe_them']?.toString() ?? '0') ?? 0.0,
      netAmount: double.tryParse(json['net_amount']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class BalanceSummaryModel {
  final double totalOwedToYou;
  final double totalYouOwe;
  final double netBalance;
  final List<PersonBalanceModel> peopleBalances;

  const BalanceSummaryModel({
    required this.totalOwedToYou,
    required this.totalYouOwe,
    required this.netBalance,
    required this.peopleBalances,
  });

  factory BalanceSummaryModel.fromJson(Map<String, dynamic> json) {
    return BalanceSummaryModel(
      totalOwedToYou: double.tryParse(json['total_owed_to_you']?.toString() ?? '0') ?? 0.0,
      totalYouOwe: double.tryParse(json['total_you_owe']?.toString() ?? '0') ?? 0.0,
      netBalance: double.tryParse(json['net_balance']?.toString() ?? '0') ?? 0.0,
      peopleBalances: (json['people_balances'] as List<dynamic>? ?? [])
          .map((p) => PersonBalanceModel.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }

  factory BalanceSummaryModel.empty() {
    return const BalanceSummaryModel(
      totalOwedToYou: 0.0,
      totalYouOwe: 0.0,
      netBalance: 0.0,
      peopleBalances: [],
    );
  }
}
