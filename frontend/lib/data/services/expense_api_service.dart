import '../../core/api_client.dart';
import '../models/expense_model.dart';
import '../models/user_model.dart';

class ExpenseApiService {
  final ApiClient apiClient;

  ExpenseApiService({required this.apiClient});

  Future<List<ExpenseModel>> getExpenses({String? category}) async {
    final queryParams = <String, dynamic>{};
    if (category != null && category != 'all') {
      queryParams['category'] = category;
    }
    final response = await apiClient.get(
      '/api/expenses/',
      queryParameters: queryParams,
    );
    final list = response.data as List<dynamic>;
    return list.map((json) => ExpenseModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<ExpenseModel> createExpense({
    required String title,
    required double amount,
    required String category,
    String notes = '',
    List<int>? participantIds,
  }) async {
    final response = await apiClient.post(
      '/api/expenses/',
      data: {
        'title': title,
        'amount': amount,
        'category': category,
        'notes': notes,
        if (participantIds != null && participantIds.isNotEmpty)
          'participant_ids': participantIds,
      },
    );
    return ExpenseModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ExpenseModel> updateExpense({
    required int id,
    required String title,
    required double amount,
    required String category,
    String notes = '',
    List<int>? participantIds,
  }) async {
    final response = await apiClient.put(
      '/api/expenses/$id/',
      data: {
        'title': title,
        'amount': amount,
        'category': category,
        'notes': notes,
        if (participantIds != null && participantIds.isNotEmpty)
          'participant_ids': participantIds,
      },
    );
    return ExpenseModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteExpense(int id) async {
    await apiClient.delete('/api/expenses/$id/');
  }

  Future<BalanceSummaryModel> getSummary() async {
    final response = await apiClient.get('/api/summary/');
    return BalanceSummaryModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<UserModel>> getUsers() async {
    final response = await apiClient.get('/api/users/');
    final list = response.data as List<dynamic>;
    return list.map((json) => UserModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<UserModel> addUser({required String username, String? displayName}) async {
    final response = await apiClient.post(
      '/api/users/',
      data: {
        'username': username,
        if (displayName != null && displayName.isNotEmpty)
          'display_name': displayName,
      },
    );
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> settleDebt({required int creditorId, required double amount}) async {
    await apiClient.post(
      '/api/settle/',
      data: {
        'creditor_id': creditorId,
        'amount': amount,
      },
    );
  }
}
