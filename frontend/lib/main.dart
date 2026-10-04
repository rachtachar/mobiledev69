import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'core/api_client.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/expense_repository.dart';
import 'data/services/auth_service.dart';
import 'data/services/expense_api_service.dart';
import 'viewmodels/auth_view_model.dart';
import 'viewmodels/expense_view_model.dart';
import 'viewmodels/theme_view_model.dart';
import 'views/auth/login_screen.dart';
import 'views/dashboard/dashboard_screen.dart';
import 'views/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('th_TH', null);
  runApp(const RootApp());
}

/// RootApp configures the Dependency Injection (DI) tree according to
/// Week 15: Dependency Injection & System Assembly.
/// Chain: ApiClient -> Services -> Repositories -> ViewModels -> Views
class RootApp extends StatelessWidget {
  const RootApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 0. Theme ViewModel (Extra Feature: Dark Mode)
        ChangeNotifierProvider<ThemeViewModel>(
          create: (_) => ThemeViewModel(),
        ),

        // 1. Core Stateless Network Client
        Provider<ApiClient>(
          create: (_) => ApiClient(),
        ),

        // 2. Stateless API Services
        ProxyProvider<ApiClient, OidcAuthService>(
          update: (_, client, _) => OidcAuthService(apiClient: client),
        ),

        // 3. Auth Repository (Persistent Session Storage)
        ProxyProvider<OidcAuthService, AuthRepository>(
          update: (_, authService, _) =>
              AuthRepositoryRemote(authService: authService),
        ),

        // 4. Expense Repository (Authenticated with current token)
        ProxyProvider2<ApiClient, AuthRepository, ExpenseRepository>(
          update: (_, client, authRepo, _) {
            final authedClient = client.copyWithToken(authRepo.accessToken);
            return ExpenseRepositoryRemote(
              apiService: ExpenseApiService(apiClient: authedClient),
            );
          },
        ),

        // 5. MVVM ViewModels
        ChangeNotifierProxyProvider<AuthRepository, AuthViewModel>(
          create: (ctx) => AuthViewModel(authRepository: ctx.read<AuthRepository>()),
          update: (_, authRepo, vm) =>
              vm ?? AuthViewModel(authRepository: authRepo),
        ),

        ChangeNotifierProxyProvider<ExpenseRepository, ExpenseViewModel>(
          create: (ctx) =>
              ExpenseViewModel(repository: ctx.read<ExpenseRepository>()),
          update: (_, repo, vm) =>
              (vm ?? ExpenseViewModel(repository: repo))..updateRepository(repo),
        ),
      ],
      child: const SplitSquadApp(),
    );
  }
}

class SplitSquadApp extends StatelessWidget {
  const SplitSquadApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final themeVm = context.watch<ThemeViewModel>();

    return MaterialApp(
      title: 'SplitSquad - Group Expense & Bill Splitter',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeVm.themeMode,
      home: authVm.isRestoring
          ? const Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('กำลังโหลดข้อมูล...'),
                  ],
                ),
              ),
            )
          : (authVm.isAuthenticated
              ? const DashboardScreen()
              : const LoginScreen()),
    );
  }
}
