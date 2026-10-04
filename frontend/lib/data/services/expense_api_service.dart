import '../../core/api_client.dart';
import '../models/expense_model.dart';
import '../models/user_model.dart';
import '../models/friend_request_model.dart';

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

  Future<void> settleDebt({int? creditorId, int? debtorId, required double amount}) async {
    final payload = <String, dynamic>{'amount': amount};
    if (creditorId != null) payload['creditor_id'] = creditorId;
    if (debtorId != null) payload['debtor_id'] = debtorId;
    await apiClient.post(
      '/api/settle/',
      data: payload,
    );
  }

  Future<List<UserModel>> getFriends() async {
    final response = await apiClient.get('/api/friends/');
    final list = response.data as List<dynamic>;
    return list.map((json) => UserModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<Map<String, List<FriendRequestModel>>> getFriendRequests() async {
    final response = await apiClient.get('/api/friends/requests/');
    final data = response.data as Map<String, dynamic>;
    final incomingList = (data['incoming'] as List<dynamic>? ?? [])
        .map((j) => FriendRequestModel.fromJson(j as Map<String, dynamic>))
        .toList();
    final outgoingList = (data['outgoing'] as List<dynamic>? ?? [])
        .map((j) => FriendRequestModel.fromJson(j as Map<String, dynamic>))
        .toList();

    return {
      'incoming': incomingList,
      'outgoing': outgoingList,
    };
  }

  Future<Map<String, dynamic>> sendFriendRequest(String username) async {
    final response = await apiClient.post(
      '/api/friends/requests/',
      data: {'username': username},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> respondFriendRequest({
    required int requestId,
    required String action,
  }) async {
    final response = await apiClient.post(
      '/api/friends/requests/$requestId/respond/',
      data: {'action': action},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<void> removeFriend(int userId) async {
    await apiClient.delete('/api/friends/$userId/');
  }

  Future<void> cancelFriendRequest(int requestId) async {
    await apiClient.delete('/api/friends/requests/$requestId/');
  }

  Future<void> markSplitPaid(int splitId) async {
    await apiClient.post('/api/splits/$splitId/mark-paid/');
  }

  Future<void> verifySplitPayment({required int splitId, required String action}) async {
    await apiClient.post(
      '/api/splits/$splitId/verify/',
      data: {'action': action},
    );
  }
}

