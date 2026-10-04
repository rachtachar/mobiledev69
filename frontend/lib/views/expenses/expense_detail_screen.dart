import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../data/models/expense_model.dart';
import '../../viewmodels/auth_view_model.dart';
import '../../viewmodels/expense_view_model.dart';
import '../theme/app_theme.dart';
import 'add_expense_screen.dart';

class ExpenseDetailScreen extends StatelessWidget {
  final ExpenseModel expense;

  const ExpenseDetailScreen({super.key, required this.expense});

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final expenseVm = context.watch<ExpenseViewModel>();
    final currentExpense = expenseVm.expenses.firstWhere(
      (e) => e.id == expense.id,
      orElse: () => expense,
    );

    final currentUser = authVm.currentUser;
    final isMine = currentUser != null &&
        (currentExpense.payer.id == currentUser.id || currentExpense.payer.username == currentUser.username);

    final catInfo = AppConstants.categories[currentExpense.category] ??
        AppConstants.categories['other']!;
    String formattedDate;
    try {
      formattedDate = DateFormat('dd MMM yyyy, HH:mm น.', 'th_TH').format(currentExpense.createdAt);
    } catch (_) {
      formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(currentExpense.createdAt);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('รายละเอียดบิล'),
        actions: [
          if (isMine) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryColor),
              tooltip: 'แก้ไขบิล',
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AddExpenseScreen(expenseToEdit: currentExpense),
                  ),
                );
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppTheme.accentRed),
              tooltip: 'ลบบิลนี้',
              onPressed: () => _confirmDelete(context, currentExpense.id, currentExpense.title),
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Ownership Banner (สร้างเอง vs คนอื่นสร้าง)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMine
                    ? AppTheme.accentGreen.withValues(alpha: 0.12)
                    : Colors.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isMine
                      ? AppTheme.accentGreen.withValues(alpha: 0.3)
                      : Colors.orange.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isMine ? Icons.verified : Icons.group,
                    color: isMine ? AppTheme.accentGreen : Colors.orange.shade800,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isMine
                          ? '🙋‍♂️ คุณเป็นคนสร้างและจ่ายบิลนี้ (มีสิทธิ์แก้ไขและลบ)'
                          : '👥 บิลนี้สร้างโดย ${currentExpense.payer.displayName} (คุณร่วมหาร)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isMine ? AppTheme.accentGreen : Colors.orange.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Header Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: catInfo.color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(catInfo.icon, size: 36, color: catInfo.color),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      currentExpense.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Chip(
                      label: Text(catInfo.label),
                      backgroundColor: catInfo.color.withValues(alpha: 0.1),
                      side: BorderSide.none,
                      labelStyle: TextStyle(color: catInfo.color, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '฿ ${currentExpense.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.person, size: 16, color: AppTheme.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          'จ่ายโดย: ${currentExpense.payer.displayName}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedDate,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                    if (currentExpense.notes.isNotEmpty) ...[
                      const Divider(height: 24),
                      Text(
                        '📝 ${currentExpense.notes}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textMuted,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Splits Breakdown
            const Text(
              '📊 รายละเอียดผู้ร่วมหาร (Splits):',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),

            ...currentExpense.splits.map((split) {
              final isPayer = split.user.id == currentExpense.payer.id;
              final isMe = currentUser != null &&
                  (split.user.id == currentUser.id || split.user.username == currentUser.username);
              final canMarkReceived = isMine && !isPayer && !split.isSettled;
              final canMarkPaid = !isMine && isMe && !split.isSettled;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isPayer ? AppTheme.primaryColor : AppTheme.secondaryColor,
                    child: Text(
                      split.user.displayName.isNotEmpty
                          ? split.user.displayName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    split.user.displayName + (isPayer ? ' (คนจ่าย)' : (isMe ? ' (คุณ)' : '')),
                    style: TextStyle(
                      fontWeight: (isPayer || isMe) ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    split.isSettled ? 'ชำระเรียบร้อยแล้ว ✔️' : 'ยังค้างชำระ',
                    style: TextStyle(
                      fontSize: 12,
                      color: split.isSettled ? AppTheme.accentGreen : AppTheme.accentRed,
                      fontWeight: split.isSettled ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '฿ ${split.amountOwed.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: split.isSettled ? AppTheme.textMuted : AppTheme.textDark,
                        ),
                      ),
                      if (canMarkReceived) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.check_circle, color: AppTheme.accentGreen),
                          tooltip: 'ทำเครื่องหมายว่าได้รับเงินคืนจาก ${split.user.displayName} แล้ว',
                          onPressed: () => _confirmSettleSplit(
                            context,
                            debtorId: split.user.id,
                            name: split.user.displayName,
                            amount: split.amountOwed,
                            isReceive: true,
                          ),
                        ),
                      ] else if (canMarkPaid) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.payment, color: AppTheme.accentRed),
                          tooltip: 'บันทึกว่าโอนคืนบิลนี้แล้ว',
                          onPressed: () => _confirmSettleSplit(
                            context,
                            creditorId: currentExpense.payer.id,
                            name: currentExpense.payer.displayName,
                            amount: split.amountOwed,
                            isReceive: false,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _confirmSettleSplit(
    BuildContext context, {
    int? debtorId,
    int? creditorId,
    required String name,
    required double amount,
    required bool isReceive,
  }) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isReceive ? Icons.check_circle_outline : Icons.payment,
              color: isReceive ? AppTheme.accentGreen : AppTheme.accentRed,
            ),
            const SizedBox(width: 8),
            Text(
              isReceive ? 'ได้รับเงินแล้ว' : 'โอนเงินคืนแล้ว',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          isReceive
              ? 'คุณได้รับเงินคืนจำนวน ฿${amount.toStringAsFixed(2)} จาก "$name" สำหรับบิลนี้เรียบร้อยแล้วใช่หรือไม่?'
              : 'คุณได้โอนเงินคืนจำนวน ฿${amount.toStringAsFixed(2)} ให้กับ "$name" สำหรับบิลนี้เรียบร้อยแล้วใช่หรือไม่?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isReceive ? AppTheme.accentGreen : AppTheme.primaryColor,
            ),
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              final vm = context.read<ExpenseViewModel>();
              await vm.settleDebt(
                debtorId: debtorId,
                creditorId: creditorId,
                amount: amount,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isReceive
                          ? 'บันทึกว่าได้รับเงินคืนจาก $name เรียบร้อยแล้ว'
                          : 'บันทึกการโอนเงินคืน $name เรียบร้อยแล้ว',
                    ),
                    backgroundColor: AppTheme.accentGreen,
                  ),
                );
              }
            },
            child: const Text('ยืนยัน'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, int expenseId, String expenseTitle) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('ยืนยันการลบบิล'),
        content: Text('คุณต้องการลบ "$expenseTitle" ใช่หรือไม่? การกระทำนี้ไม่สามารถย้อนกลับได้'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentRed),
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              final vm = context.read<ExpenseViewModel>();
              final success = await vm.deleteExpense(expenseId);
              if (context.mounted && success) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('ลบรายการ'),
          ),
        ],
      ),
    );
  }
}
