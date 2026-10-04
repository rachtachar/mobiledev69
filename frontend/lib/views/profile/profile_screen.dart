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
                        ? ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.check, size: 14),
                            label: const Text('ได้รับเงินแล้ว', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            onPressed: () => _confirmSettleReceive(
                              context,
                              person.user.id,
                              person.user.displayName,
                              person.netAmount.abs(),
                            ),
                          )
                        : OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.accentRed,
                              side: const BorderSide(color: AppTheme.accentRed),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                            icon: const Icon(Icons.payment, size: 14),
                            label: const Text('โอนคืนแล้ว', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            onPressed: () => _confirmSettlePay(
                              context,
                              person.user.id,
                              person.user.displayName,
                              person.netAmount.abs(),
                            ),
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

  void _confirmSettlePay(BuildContext context, int creditorId, String name, double totalAmount) {
    final amountController = TextEditingController(text: totalAmount.toStringAsFixed(2));
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.payment, color: AppTheme.accentRed),
            SizedBox(width: 8),
            Text('โอนเงินคืนเพื่อน', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ระบุยอดเงินที่คุณโอนคืนให้ "$name" (ยอดหนี้รวม ฿${totalAmount.toStringAsFixed(2)})',
                style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'จำนวนเงินที่โอนคืน (฿)',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (val) {
                  final v = double.tryParse(val ?? '');
                  if (v == null || v <= 0) return 'กรุณาระบุจำนวนเงินที่ถูกต้อง';
                  if (v > totalAmount + 0.01) return 'ยอดเงินเกินยอดหนี้ทั้งหมด (฿${totalAmount.toStringAsFixed(2)})';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              const Text(
                '💡 หากโอนคืนบางส่วน ระบบจะนำไปตัดบิลเก่าก่อนตามลำดับ (FIFO)',
                style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final enteredAmount = double.parse(amountController.text.trim());
              Navigator.of(dialogCtx).pop();
              final vm = context.read<ExpenseViewModel>();
              await vm.settleDebt(creditorId: creditorId, amount: enteredAmount);
            },
            child: const Text('ยืนยันโอนเงิน'),
          ),
        ],
      ),
    );
  }

  void _confirmSettleReceive(BuildContext context, int debtorId, String name, double totalAmount) {
    final amountController = TextEditingController(text: totalAmount.toStringAsFixed(2));
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: AppTheme.accentGreen),
            SizedBox(width: 8),
            Text('ได้รับเงินคืนแล้ว', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ระบุยอดเงินที่ได้รับคืนจาก "$name" (ยอดหนี้รวม ฿${totalAmount.toStringAsFixed(2)})',
                style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'จำนวนเงินที่ได้รับ (฿)',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (val) {
                  final v = double.tryParse(val ?? '');
                  if (v == null || v <= 0) return 'กรุณาระบุจำนวนเงินที่ถูกต้อง';
                  if (v > totalAmount + 0.01) return 'ยอดเงินเกินยอดหนี้ทั้งหมด (฿${totalAmount.toStringAsFixed(2)})';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              const Text(
                '💡 หากเพื่อนคืนเพียงบางส่วน ระบบจะนำไปตัดบิลเก่าก่อนตามลำดับ (FIFO)',
                style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentGreen),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final enteredAmount = double.parse(amountController.text.trim());
              Navigator.of(dialogCtx).pop();
              final vm = context.read<ExpenseViewModel>();
              await vm.settleDebt(debtorId: debtorId, amount: enteredAmount);
            },
            child: const Text('ยืนยันได้รับเงิน'),
          ),
        ],
      ),
    );
  }
}
