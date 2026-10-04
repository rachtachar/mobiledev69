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
    final currentUser = authVm.currentUser;
    final isMine = currentUser != null &&
        (expense.payer.id == currentUser.id || expense.payer.username == currentUser.username);

    final catInfo = AppConstants.categories[expense.category] ??
        AppConstants.categories['other']!;
    String formattedDate;
    try {
      formattedDate = DateFormat('dd MMM yyyy, HH:mm น.', 'th_TH').format(expense.createdAt);
    } catch (_) {
      formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(expense.createdAt);
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
                    builder: (_) => AddExpenseScreen(expenseToEdit: expense),
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
              onPressed: () => _confirmDelete(context),
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
                          : '👥 บิลนี้สร้างโดย ${expense.payer.displayName} (คุณร่วมหาร)',
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
                      expense.title,
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
                      '฿ ${expense.amount.toStringAsFixed(2)}',
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
                          'จ่ายโดย: ${expense.payer.displayName}',
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
                    if (expense.notes.isNotEmpty) ...[
                      const Divider(height: 24),
                      Text(
                        '📝 ${expense.notes}',
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

            ...expense.splits.map((split) {
              final isPayer = split.user.id == expense.payer.id;
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
                    split.user.displayName + (isPayer ? ' (คนจ่าย)' : ''),
                    style: TextStyle(
                      fontWeight: isPayer ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    split.isSettled ? 'ชำระเรียบร้อยแล้ว' : 'ยังค้างชำระ',
                    style: TextStyle(
                      fontSize: 12,
                      color: split.isSettled ? AppTheme.accentGreen : AppTheme.accentRed,
                    ),
                  ),
                  trailing: Text(
                    '฿ ${split.amountOwed.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: split.isSettled ? AppTheme.textMuted : AppTheme.textDark,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('ยืนยันการลบบิล'),
        content: Text('คุณต้องการลบ "${expense.title}" ใช่หรือไม่? การกระทำนี้ไม่สามารถย้อนกลับได้'),
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
              final success = await vm.deleteExpense(expense.id);
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
