import '../../core/result.dart';
import '../models/expense_model.dart';
import '../models/user_model.dart';
import '../models/friend_request_model.dart';
import '../services/expense_api_service.dart';

abstract class ExpenseRepository {
  Future<Result<List<ExpenseModel>>> getExpenses({String? category});
  Future<Result<ExpenseModel>> createExpense({
    required String title,
    required double amount,
    required String category,
    String notes = '',
    List<int>? participantIds,
  });
  Future<Result<ExpenseModel>> updateExpense({
    required int id,
    required String title,
    required double amount,
    required String category,
    String notes = '',
    List<int>? participantIds,
  });
  Future<Result<void>> deleteExpense(int id);
  Future<Result<BalanceSummaryModel>> getSummary();
  Future<Result<List<UserModel>>> getUsers();
  Future<Result<UserModel>> addUser({required String username, String? displayName});
  Future<Result<void>> settleDebt({required int creditorId, required double amount});
  Future<Result<List<UserModel>>> getFriends();
  Future<Result<Map<String, List<FriendRequestModel>>>> getFriendRequests();
  Future<Result<Map<String, dynamic>>> sendFriendRequest(String username);
  Future<Result<Map<String, dynamic>>> respondFriendRequest({required int requestId, required String action});
}

class ExpenseRepositoryRemote implements ExpenseRepository {
  final ExpenseApiService apiService;

  ExpenseRepositoryRemote({required this.apiService});

  @override
  Future<Result<List<ExpenseModel>>> getExpenses({String? category}) async {
    try {
      final list = await apiService.getExpenses(category: category);
      return Success(list);
    } on Exception catch (e, st) {
      return Failure(e, st);
    } catch (e, st) {
      return Failure(Exception(e.toString()), st);
    }
  }

  @override
  Future<Result<ExpenseModel>> createExpense({
    required String title,
    required double amount,
    required String category,
    String notes = '',
    List<int>? participantIds,
  }) async {
    try {
      final expense = await apiService.createExpense(
        title: title,
        amount: amount,
        category: category,
        notes: notes,
        participantIds: participantIds,
      );
      return Success(expense);
    } on Exception catch (e, st) {
      return Failure(e, st);
    } catch (e, st) {
      return Failure(Exception(e.toString()), st);
    }
  }

  @override
  Future<Result<ExpenseModel>> updateExpense({
    required int id,
    required String title,
    required double amount,
    required String category,
    String notes = '',
    List<int>? participantIds,
  }) async {
    try {
      final expense = await apiService.updateExpense(
        id: id,
        title: title,
        amount: amount,
        category: category,
        notes: notes,
        participantIds: participantIds,
      );
      return Success(expense);
    } on Exception catch (e, st) {
      return Failure(e, st);
    } catch (e, st) {
      return Failure(Exception(e.toString()), st);
    }
  }

  @override
  Future<Result<void>> deleteExpense(int id) async {
    try {
      await apiService.deleteExpense(id);
      return const Success(null);
    } on Exception catch (e, st) {
      return Failure(e, st);
    } catch (e, st) {
      return Failure(Exception(e.toString()), st);
    }
  }

  @override
  Future<Result<BalanceSummaryModel>> getSummary() async {
    try {
      final summary = await apiService.getSummary();
      return Success(summary);
    } on Exception catch (e, st) {
      return Failure(e, st);
    } catch (e, st) {
      return Failure(Exception(e.toString()), st);
    }
  }

  @override
  Future<Result<List<UserModel>>> getUsers() async {
    try {
      final users = await apiService.getUsers();
      return Success(users);
    } on Exception catch (e, st) {
      return Failure(e, st);
    } catch (e, st) {
      return Failure(Exception(e.toString()), st);
    }
  }

  @override
  Future<Result<UserModel>> addUser({required String username, String? displayName}) async {
    try {
      final user = await apiService.addUser(username: username, displayName: displayName);
      return Success(user);
    } on Exception catch (e, st) {
      return Failure(e, st);
    } catch (e, st) {
      return Failure(Exception(e.toString()), st);
    }
  }

  @override
  Future<Result<void>> settleDebt({required int creditorId, required double amount}) async {
    try {
      await apiService.settleDebt(creditorId: creditorId, amount: amount);
      return const Success(null);
    } on Exception catch (e, st) {
      return Failure(e, st);
    } catch (e, st) {
      return Failure(Exception(e.toString()), st);
    }
  }

  @override
  Future<Result<List<UserModel>>> getFriends() async {
    try {
      final friends = await apiService.getFriends();
      return Success(friends);
    } on Exception catch (e, st) {
      return Failure(e, st);
    } catch (e, st) {
      return Failure(Exception(e.toString()), st);
    }
  }

  @override
  Future<Result<Map<String, List<FriendRequestModel>>>> getFriendRequests() async {
    try {
      final requests = await apiService.getFriendRequests();
      return Success(requests);
    } on Exception catch (e, st) {
      return Failure(e, st);
    } catch (e, st) {
      return Failure(Exception(e.toString()), st);
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> sendFriendRequest(String username) async {
    try {
      final res = await apiService.sendFriendRequest(username);
      return Success(res);
    } on Exception catch (e, st) {
      return Failure(e, st);
    } catch (e, st) {
      return Failure(Exception(e.toString()), st);
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> respondFriendRequest({
    required int requestId,
    required String action,
  }) async {
    try {
      final res = await apiService.respondFriendRequest(
        requestId: requestId,
        action: action,
      );
      return Success(res);
    } on Exception catch (e, st) {
      return Failure(e, st);
    } catch (e, st) {
      return Failure(Exception(e.toString()), st);
    }
  }
}

