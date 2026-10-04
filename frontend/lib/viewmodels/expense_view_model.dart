import 'package:flutter/foundation.dart';
import '../data/models/expense_model.dart';
import '../data/models/user_model.dart';
import '../data/models/friend_request_model.dart';
import '../data/repositories/expense_repository.dart';

/// ExpenseViewModel managing expenses, balance calculations, group actions, and friendships.
class ExpenseViewModel extends ChangeNotifier {
  ExpenseRepository repository;

  List<ExpenseModel> _expenses = [];
  BalanceSummaryModel _summary = BalanceSummaryModel.empty();
  List<UserModel> _availableUsers = [];
  List<UserModel> _friends = [];
  List<FriendRequestModel> _incomingRequests = [];
  List<FriendRequestModel> _outgoingRequests = [];
  String _selectedCategory = 'all';

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _successMessage;

  ExpenseViewModel({required this.repository});

  void updateRepository(ExpenseRepository newRepo) {
    repository = newRepo;
  }

  List<ExpenseModel> get expenses => _expenses;
  BalanceSummaryModel get summary => _summary;
  List<UserModel> get availableUsers => _availableUsers;
  List<UserModel> get friends => _friends;
  List<FriendRequestModel> get incomingRequests => _incomingRequests;
  List<FriendRequestModel> get outgoingRequests => _outgoingRequests;
  String get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  Future<void> loadData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Concurrently load expenses, summary, members, friends, and requests
    final results = await Future.wait([
      repository.getExpenses(category: _selectedCategory),
      repository.getSummary(),
      repository.getUsers(),
      repository.getFriends(),
      repository.getFriendRequests(),
    ]);

    final expensesResult = results[0];
    final summaryResult = results[1];
    final usersResult = results[2];
    final friendsResult = results[3];
    final requestsResult = results[4];

    if (expensesResult.isSuccess) {
      _expenses = expensesResult.dataOrNull as List<ExpenseModel>;
    }
    if (summaryResult.isSuccess) {
      _summary = summaryResult.dataOrNull as BalanceSummaryModel;
    }
    if (usersResult.isSuccess) {
      _availableUsers = usersResult.dataOrNull as List<UserModel>;
    }
    if (friendsResult.isSuccess) {
      _friends = (friendsResult.dataOrNull as List<UserModel>?) ?? [];
    }
    if (requestsResult.isSuccess) {
      final reqMap = (requestsResult.dataOrNull as Map<String, List<FriendRequestModel>>?) ?? {};
      _incomingRequests = reqMap['incoming'] ?? [];
      _outgoingRequests = reqMap['outgoing'] ?? [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> filterByCategory(String category) async {
    _selectedCategory = category;
    _isLoading = true;
    notifyListeners();

    final result = await repository.getExpenses(category: category);
    if (result.isSuccess) {
      _expenses = result.dataOrNull ?? [];
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createExpense({
    required String title,
    required double amount,
    required String category,
    String notes = '',
    List<int>? participantIds,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    final result = await repository.createExpense(
      title: title,
      amount: amount,
      category: category,
      notes: notes,
      participantIds: participantIds,
    );

    _isSubmitting = false;

    if (result.isSuccess) {
      _successMessage = 'บันทึกบิล "${result.dataOrNull?.title}" สำเร็จ!';
      notifyListeners();
      await loadData();
      return true;
    } else {
      _errorMessage = result.errorOrNull?.toString().replaceAll('Exception: ', '') ?? 'ไม่สามารถบันทึกบิลได้';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateExpense({
    required int id,
    required String title,
    required double amount,
    required String category,
    String notes = '',
    List<int>? participantIds,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    final result = await repository.updateExpense(
      id: id,
      title: title,
      amount: amount,
      category: category,
      notes: notes,
      participantIds: participantIds,
    );

    _isSubmitting = false;

    if (result.isSuccess) {
      _successMessage = 'แก้ไขบิล "${result.dataOrNull?.title}" สำเร็จ!';
      notifyListeners();
      await loadData();
      return true;
    } else {
      _errorMessage = result.errorOrNull?.toString().replaceAll('Exception: ', '') ?? 'ไม่สามารถแก้ไขบิลได้';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteExpense(int id) async {
    _isLoading = true;
    notifyListeners();

    final result = await repository.deleteExpense(id);
    _isLoading = false;

    if (result.isSuccess) {
      _successMessage = 'ลบรายการบิลสำเร็จ';
      await loadData();
      return true;
    } else {
      _errorMessage = result.errorOrNull?.toString().replaceAll('Exception: ', '') ?? 'ไม่สามารถลบรายการได้';
      notifyListeners();
      return false;
    }
  }

  Future<UserModel?> addUser({required String username, String? displayName}) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    final result = await repository.addUser(username: username, displayName: displayName);
    _isSubmitting = false;

    if (result.isSuccess) {
      _successMessage = 'เพิ่มเพื่อนใหม่ "${result.dataOrNull?.displayName}" สำเร็จ!';
      await loadData();
      return result.dataOrNull;
    } else {
      _errorMessage = result.errorOrNull?.toString().replaceAll('Exception: ', '') ?? 'ไม่สามารถเพิ่มเพื่อนได้';
      notifyListeners();
      return null;
    }
  }

  Future<bool> settleDebt({required int creditorId, required double amount}) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    final result = await repository.settleDebt(creditorId: creditorId, amount: amount);
    _isSubmitting = false;

    if (result.isSuccess) {
      _successMessage = 'บันทึกการเคลียร์หนี้สำเร็จ';
      await loadData();
      return true;
    } else {
      _errorMessage = result.errorOrNull?.toString().replaceAll('Exception: ', '') ?? 'บันทึกการเคลียร์หนี้ไม่สำเร็จ';
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendFriendRequest(String username) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    final result = await repository.sendFriendRequest(username);
    _isSubmitting = false;

    if (result.isSuccess) {
      final msg = result.dataOrNull?['message'] as String? ?? 'ส่งคำขอเป็นเพื่อนเรียบร้อยแล้ว';
      _successMessage = msg;
      await loadData();
      return true;
    } else {
      _errorMessage = result.errorOrNull?.toString().replaceAll('Exception: ', '') ?? 'ไม่สามารถส่งคำขอเป็นเพื่อนได้';
      notifyListeners();
      return false;
    }
  }

  Future<bool> respondFriendRequest({required int requestId, required bool accept}) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    final result = await repository.respondFriendRequest(
      requestId: requestId,
      action: accept ? 'accept' : 'reject',
    );
    _isSubmitting = false;

    if (result.isSuccess) {
      final msg = result.dataOrNull?['message'] as String? ?? (accept ? 'ยอมรับคำขอเป็นเพื่อนแล้ว' : 'ปฏิเสธคำขอเป็นเพื่อนแล้ว');
      _successMessage = msg;
      await loadData();
      return true;
    } else {
      _errorMessage = result.errorOrNull?.toString().replaceAll('Exception: ', '') ?? 'ไม่สามารถดำเนินการได้';
      notifyListeners();
      return false;
    }
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}
