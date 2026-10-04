import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/result.dart';
import 'package:frontend/data/models/expense_model.dart';
import 'package:frontend/data/models/user_model.dart';
import 'package:frontend/data/repositories/auth_repository.dart';
import 'package:frontend/data/repositories/expense_repository.dart';
import 'package:frontend/viewmodels/auth_view_model.dart';
import 'package:frontend/viewmodels/expense_view_model.dart';

class FakeAuthRepository implements AuthRepository {
  UserModel? _user;
  String? _token;

  @override
  UserModel? get currentUser => _user;

  @override
  String? get accessToken => _token;

  @override
  bool get isAuthenticated => _token != null;

  @override
  Future<Result<UserModel>> login(String username, String password) async {
    if (username == 'alice' && password == 'alice123') {
      _user = const UserModel(
        id: 2,
        username: 'alice',
        firstName: 'Alice',
        lastName: 'Chen',
        email: 'alice@example.com',
        displayName: 'Alice Chen',
      );
      _token = 'fake_access_token_123';
      return Success(_user!);
    }
    return Failure(Exception('Invalid credentials'));
  }

  @override
  Future<Result<UserModel>> loginWithOidcCode({
    required String code,
    required String codeVerifier,
    required String redirectUri,
  }) async {
    return login('alice', 'alice123');
  }

  @override
  Future<bool> restoreSession() async {
    return isAuthenticated;
  }

  @override
  Future<void> logout() async {
    _user = null;
    _token = null;
  }
}

class FakeExpenseRepository implements ExpenseRepository {
  final List<ExpenseModel> _items = [];

  @override
  Future<Result<List<ExpenseModel>>> getExpenses({String? category}) async {
    if (category != null && category != 'all') {
      return Success(_items.where((e) => e.category == category).toList());
    }
    return Success(List.from(_items));
  }

  @override
  Future<Result<ExpenseModel>> createExpense({
    required String title,
    required double amount,
    required String category,
    String notes = '',
    List<int>? participantIds,
  }) async {
    final exp = ExpenseModel(
      id: _items.length + 1,
      title: title,
      amount: amount,
      category: category,
      categoryDisplay: category,
      payer: const UserModel(
        id: 2,
        username: 'alice',
        firstName: 'Alice',
        lastName: 'Chen',
        email: 'alice@example.com',
        displayName: 'Alice Chen',
      ),
      notes: notes,
      createdAt: DateTime.now(),
      splits: [],
    );
    _items.add(exp);
    return Success(exp);
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
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx != -1) {
      final old = _items[idx];
      final updated = ExpenseModel(
        id: old.id,
        title: title,
        amount: amount,
        category: category,
        categoryDisplay: category,
        payer: old.payer,
        notes: notes,
        createdAt: old.createdAt,
        splits: old.splits,
      );
      _items[idx] = updated;
      return Success(updated);
    }
    return Failure(Exception('Expense not found'));
  }

  @override
  Future<Result<void>> deleteExpense(int id) async {
    _items.removeWhere((e) => e.id == id);
    return const Success(null);
  }

  @override
  Future<Result<BalanceSummaryModel>> getSummary() async {
    return const Success(
      BalanceSummaryModel(
        totalOwedToYou: 500.0,
        totalYouOwe: 200.0,
        netBalance: 300.0,
        peopleBalances: [],
      ),
    );
  }

  @override
  Future<Result<List<UserModel>>> getUsers() async {
    return const Success([
      UserModel(id: 1, username: 'admin', firstName: '', lastName: '', email: '', displayName: 'Admin'),
      UserModel(id: 2, username: 'alice', firstName: '', lastName: '', email: '', displayName: 'Alice'),
    ]);
  }

  @override
  Future<Result<UserModel>> addUser({required String username, String? displayName}) async {
    final newUser = UserModel(
      id: 99,
      username: username,
      firstName: displayName ?? username,
      lastName: '',
      email: '$username@example.com',
      displayName: displayName ?? username,
    );
    return Success(newUser);
  }

  @override
  Future<Result<void>> settleDebt({required int creditorId, required double amount}) async {
    return const Success(null);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthViewModel Tests', () {
    test('Successful login updates currentUser and isAuthenticated', () async {
      final fakeRepo = FakeAuthRepository();
      final vm = AuthViewModel(authRepository: fakeRepo);

      expect(vm.isAuthenticated, isFalse);
      expect(vm.currentUser, isNull);

      final ok = await vm.login('alice', 'alice123');

      expect(ok, isTrue);
      expect(vm.isAuthenticated, isTrue);
      expect(vm.currentUser?.username, equals('alice'));
      expect(vm.errorMessage, isNull);
    });

    test('Failed login sets error message', () async {
      final fakeRepo = FakeAuthRepository();
      final vm = AuthViewModel(authRepository: fakeRepo);

      final ok = await vm.login('wrong', 'password');

      expect(ok, isFalse);
      expect(vm.isAuthenticated, isFalse);
      expect(vm.errorMessage, isNotNull);
    });

    test('Logout clears user and token', () async {
      final fakeRepo = FakeAuthRepository();
      final vm = AuthViewModel(authRepository: fakeRepo);
      await vm.login('alice', 'alice123');
      expect(vm.isAuthenticated, isTrue);

      await vm.logout();
      expect(vm.isAuthenticated, isFalse);
      expect(vm.currentUser, isNull);
    });
  });

  group('ExpenseViewModel Tests', () {
    test('loadData populates expenses and summary', () async {
      final fakeRepo = FakeExpenseRepository();
      final vm = ExpenseViewModel(repository: fakeRepo);

      await vm.loadData();

      expect(vm.summary.netBalance, equals(300.0));
      expect(vm.summary.totalOwedToYou, equals(500.0));
      expect(vm.availableUsers.length, equals(2));
    });

    test('createExpense and updateExpense workflow', () async {
      final fakeRepo = FakeExpenseRepository();
      final vm = ExpenseViewModel(repository: fakeRepo);

      final ok = await vm.createExpense(
        title: 'Dinner with team',
        amount: 800.0,
        category: 'food',
      );

      expect(ok, isTrue);
      expect(vm.expenses.length, equals(1));
      expect(vm.expenses.first.title, equals('Dinner with team'));

      // Test update
      final updateOk = await vm.updateExpense(
        id: vm.expenses.first.id,
        title: 'Dinner with team (Updated)',
        amount: 850.0,
        category: 'food',
      );

      expect(updateOk, isTrue);
      expect(vm.expenses.first.title, equals('Dinner with team (Updated)'));
      expect(vm.expenses.first.amount, equals(850.0));

      // Test delete
      final deleteOk = await vm.deleteExpense(vm.expenses.first.id);
      expect(deleteOk, isTrue);
      expect(vm.expenses.isEmpty, isTrue);
    });

    test('addUser successfully creates and adds user', () async {
      final fakeRepo = FakeExpenseRepository();
      final vm = ExpenseViewModel(repository: fakeRepo);

      final user = await vm.addUser(username: 'david', displayName: 'David Miller');
      expect(user, isNotNull);
      expect(user?.username, equals('david'));
      expect(user?.displayName, equals('David Miller'));
    });
  });
}
