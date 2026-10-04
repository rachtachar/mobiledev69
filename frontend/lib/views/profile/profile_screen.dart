import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_view_model.dart';
import '../../viewmodels/expense_view_model.dart';
import '../../viewmodels/theme_view_model.dart';
import '../theme/app_theme.dart';
import 'friends_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final expenseVm = context.watch<ExpenseViewModel>();
    final themeVm = context.watch<ThemeViewModel>();
    final user = authVm.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('โปรไฟล์ & สถานะหนี้ส่วนบุคคล'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppTheme.primaryColor,
                      child: Text(
                        user != null && user.displayName.isNotEmpty
                            ? user.displayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 28,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user?.displayName ?? 'ผู้ใช้งาน',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@${user?.username ?? ''} • ${user?.email ?? ''}',
                      style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_user, size: 14, color: AppTheme.primaryColor),
                          SizedBox(width: 6),
                          Text(
                            'OpenID Connect Verified',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Settings: Dark Mode Toggle
            Card(
              child: SwitchListTile(
                secondary: Icon(
                  themeVm.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  color: AppTheme.primaryColor,
                ),
                title: const Text(
                  'โหมดกลางคืน (Dark Mode 🌙)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(themeVm.isDarkMode ? 'เปิดใช้งานธีมมืด' : 'เปิดใช้งานธีมสว่าง'),
                value: themeVm.isDarkMode,
                onChanged: (_) => themeVm.toggleTheme(),
              ),
            ),

            const SizedBox(height: 12),

            // Friends Management Tile
            Card(
              child: ListTile(
                leading: const Icon(Icons.people_outline, color: AppTheme.primaryColor),
                title: const Text(
                  'จัดการเพื่อนและคำขอเป็นเพื่อน',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  expenseVm.incomingRequests.isNotEmpty
                      ? 'มี ${expenseVm.incomingRequests.length} คำขอรอการตอบรับ'
                      : 'เพื่อนในกลุ่ม ${expenseVm.friends.length} คน',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (expenseVm.incomingRequests.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.accentRed,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${expenseVm.incomingRequests.length}',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, color: AppTheme.textMuted),
                  ],
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const FriendsScreen()),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Friends balance & Settle actions
            const Text(
              '🤝 ยอดคงค้างแยกรายบุคคล:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),

            if (expenseVm.summary.peopleBalances.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      '🎉 ยอดหนี้ทั้งหมดเคลียร์หมดแล้ว!',
                      style: TextStyle(color: AppTheme.accentGreen, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              )
            else
              ...expenseVm.summary.peopleBalances.map((person) {
                final theyOweYou = person.netAmount > 0;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theyOweYou ? AppTheme.accentGreen : AppTheme.accentRed,
                      child: Icon(
                        theyOweYou ? Icons.arrow_downward : Icons.arrow_upward,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    title: Text(
                      person.user.displayName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      theyOweYou
                          ? 'ติดคุณอยู่ ${person.netAmount.abs().toStringAsFixed(2)} ฿'
                          : 'คุณติดเขาอยู่ ${person.netAmount.abs().toStringAsFixed(2)} ฿',
                      style: TextStyle(
                        fontSize: 12,
                        color: theyOweYou ? AppTheme.accentGreen : AppTheme.accentRed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: theyOweYou
                        ? null
                        : TextButton(
                            onPressed: () => _confirmSettle(context, person.user.id, person.user.displayName, person.netAmount.abs()),
                            child: const Text('บันทึกคืนเงิน'),
                          ),
                  ),
                );
              }),

            const SizedBox(height: 32),

            // Logout Button
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.accentRed,
                side: const BorderSide(color: AppTheme.accentRed),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                authVm.logout();
              },
              icon: const Icon(Icons.logout),
              label: const Text('ออกจากระบบ (Logout)'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmSettle(BuildContext context, int creditorId, String name, double amount) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('บันทึกการคืนเงิน (Settle Debt)'),
        content: Text('คุณต้องการบันทึกว่าได้คืนเงิน $amount บาท ให้กับ "$name" เรียบร้อยแล้วใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              final vm = context.read<ExpenseViewModel>();
              await vm.settleDebt(creditorId: creditorId, amount: amount);
            },
            child: const Text('ยืนยันการคืนเงิน'),
          ),
        ],
      ),
    );
  }
}
