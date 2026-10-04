import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_view_model.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authVm = context.read<AuthViewModel>();
    final success = await authVm.login(
      _usernameController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (!success && authVm.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authVm.errorMessage!),
          backgroundColor: AppTheme.accentRed,
        ),
      );
    }
  }

  void _fillUsername(String username) {
    _usernameController.text = username;
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Branding
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet,
                      size: 38,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'SplitSquad',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'ระบบหารค่าใช้จ่ายกลุ่มและจัดการหนี้อัจฉริยะ\nเชื่อมต่อมาตรฐาน OpenID Connect',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textMuted,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Form Container
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'เข้าสู่ระบบ (Sign In)',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // OpenID Connect Web Flow (PKCE)
                            ElevatedButton.icon(
                              onPressed: authVm.isLoading ? null : () => authVm.startOidcWebLogin(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4F46E5), // Indigo
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                              ),
                              icon: const Icon(Icons.security, size: 20),
                              label: const Text(
                                'เข้าสู่ระบบด้วย Django OIDC (PKCE)',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                            const SizedBox(height: 16),

                            Row(
                              children: const [
                                Expanded(child: Divider()),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(
                                    'หรือกรอกรหัสผ่าน / บัญชีด่วน',
                                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                  ),
                                ),
                                Expanded(child: Divider()),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Username Field
                            TextFormField(
                              controller: _usernameController,
                              focusNode: _usernameFocusNode,
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) {
                                FocusScope.of(context).requestFocus(_passwordFocusNode);
                              },
                              decoration: const InputDecoration(
                                labelText: 'ชื่อผู้ใช้ (Username)',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'กรุณากรอกชื่อผู้ใช้';
                                }
                                if (value.trim().length < 3) {
                                  return 'ชื่อผู้ใช้ต้องมีอย่างน้อย 3 ตัวอักษร';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Password Field
                            TextFormField(
                              controller: _passwordController,
                              focusNode: _passwordFocusNode,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                              decoration: InputDecoration(
                                labelText: 'รหัสผ่าน (Password)',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'กรุณากรอกรหัสผ่าน';
                                }
                                if (value.length < 4) {
                                  return 'รหัสผ่านต้องมีอย่างน้อย 4 ตัวอักษร';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),

                            // Submit Button
                            ElevatedButton(
                              onPressed: authVm.isLoading ? null : _submit,
                              child: authVm.isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('เข้าสู่ระบบ'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Dev usernames hint
                  const Text(
                    '⚡ รายชื่อบัญชีทดสอบในระบบ (ไม่ Hard-code รหัสผ่าน):',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      ActionChip(
                        label: const Text('alice'),
                        avatar: const CircleAvatar(
                          backgroundColor: Colors.pinkAccent,
                          child: Text('A', style: TextStyle(color: Colors.white, fontSize: 11)),
                        ),
                        onPressed: () => _fillUsername('alice'),
                      ),
                      ActionChip(
                        label: const Text('bob'),
                        avatar: const CircleAvatar(
                          backgroundColor: Colors.blueAccent,
                          child: Text('B', style: TextStyle(color: Colors.white, fontSize: 11)),
                        ),
                        onPressed: () => _fillUsername('bob'),
                      ),
                      ActionChip(
                        label: const Text('somchai'),
                        avatar: const CircleAvatar(
                          backgroundColor: Colors.orangeAccent,
                          child: Text('S', style: TextStyle(color: Colors.white, fontSize: 11)),
                        ),
                        onPressed: () => _fillUsername('somchai'),
                      ),
                      ActionChip(
                        label: const Text('admin'),
                        avatar: const CircleAvatar(
                          backgroundColor: Colors.teal,
                          child: Text('M', style: TextStyle(color: Colors.white, fontSize: 11)),
                        ),
                        onPressed: () => _fillUsername('admin'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
