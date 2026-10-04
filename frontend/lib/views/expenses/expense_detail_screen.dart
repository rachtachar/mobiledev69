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
                          ? '🙋‍♂️ คุณเป็นคนสร้างและจ่ายบิลนี้ (มีสิทธิ์ตรวจสอบการชำระเงิน แก้ไข และลบ)'
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

            // All Members Settled Banner
            if (currentExpense.splits.isNotEmpty && currentExpense.splits.every((s) => s.isSettled))
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.teal.shade700, width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade700,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🎉 บิลนี้สมาชิกทุกคนชำระเงินครบหมดแล้ว!',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              color: Colors.teal.shade900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'ยอดเงินถูกเคลียร์เรียบร้อย 100% ปิดยอดสมบูรณ์ ไม่มีใครติดค้างในบิลนี้แล้ว',
                            style: TextStyle(fontSize: 11, color: AppTheme.textDark),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Pending Verification Alert Banner for Owner
            if (isMine && currentExpense.splits.any((s) => s.pendingVerification))
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade700, width: 1.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active, color: Colors.orange, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '🔔 มีเพื่อนแจ้งโอนเงินเข้ามา!',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'ตรวจสอบเงินเข้าในบัญชีของคุณ แล้วกดปุ่ม ✔️ (ยืนยัน) หรือ ❌ (ปฏิเสธ) ที่ชื่อเพื่อนด้านล่างได้เลยครับ',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade800),
                          ),
                        ],
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

              // Subtitle & color based on status
              String statusText;
              Color statusColor;
              if (split.isSettled) {
                statusText = 'ชำระเรียบร้อยแล้ว ✔️';
                statusColor = AppTheme.accentGreen;
              } else if (split.pendingVerification) {
                if (isMine) {
                  statusText = 'แจ้งโอนแล้ว (รอคุณตรวจสอบ ⏳)';
                } else if (isMe) {
                  statusText = 'แจ้งโอนแล้ว (รอเจ้าของบิลตรวจสอบ ⏳)';
                } else {
                  statusText = 'แจ้งโอนแล้ว (รอตรวจสอบ ⏳)';
                }
                statusColor = Colors.orange.shade800;
              } else {
                statusText = isMe ? 'คุณยังค้างชำระ' : 'ยังค้างชำระ';
                statusColor = AppTheme.accentRed;
              }

              final cardBorderColor = split.isSettled
                  ? AppTheme.accentGreen.withValues(alpha: 0.3)
                  : (split.pendingVerification ? Colors.orange.shade400 : AppTheme.accentRed.withValues(alpha: 0.35));

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: cardBorderColor, width: 1.2),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isPayer
                        ? AppTheme.primaryColor
                        : (split.pendingVerification ? Colors.orange : AppTheme.secondaryColor),
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
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: statusColor.withValues(alpha: 0.35)),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 11,
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
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
                      // Case 1: Owner sees pending verification -> buttons to confirm or reject
                      if (isMine && !isPayer && split.pendingVerification) ...[
                        const SizedBox(width: 6),
                        IconButton(
                          icon: const Icon(Icons.check_circle, color: AppTheme.accentGreen, size: 26),
                          tooltip: 'ยืนยันได้รับเงินแล้ว',
                          onPressed: () => _confirmVerifyPayment(context, split, true),
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel, color: AppTheme.accentRed, size: 26),
                          tooltip: 'ปฏิเสธ (ยังไม่ได้รับ)',
                          onPressed: () => _confirmVerifyPayment(context, split, false),
                        ),
                      ]
                      // Case 2: Debtor sees unpaid split -> button to notify paid
                      else if (!isMine && isMe && !split.isSettled && !split.pendingVerification) ...[
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.payment, size: 14),
                          label: const Text('แจ้งว่าโอนแล้ว', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          onPressed: () => _confirmNotifyPaid(context, split, currentExpense.payer.displayName),
                        ),
                      ]
                      // Case 3: Debtor waiting for verification -> pending badge
                      else if (!isMine && isMe && split.pendingVerification) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.hourglass_top, color: Colors.orange, size: 12),
                              SizedBox(width: 4),
                              Text(
                                'รอตรวจ',
                                style: TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ]
                      // Case 4: Owner can directly mark received if friend pays directly in cash / transfer
                      else if (isMine && !isPayer && !split.isSettled && !split.pendingVerification) ...[
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade50,
                            foregroundColor: Colors.teal.shade800,
                            side: BorderSide(color: Colors.teal.shade300),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.check_circle_outline, size: 14),
                          label: const Text('บันทึกว่าได้รับเงินแล้ว', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          onPressed: () => _confirmDirectReceived(context, split),
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

  void _confirmNotifyPaid(BuildContext context, ExpenseSplitModel split, String payerName) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.payment, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text('แจ้งว่าโอนเงินแล้ว', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('คุณได้โอนเงิน ฿${split.amountOwed.toStringAsFixed(2)} ให้กับ "$payerName" เรียบร้อยแล้วใช่หรือไม่?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'เมื่อกดยืนยัน ระบบจะส่งการแจ้งเตือนให้เจ้าของบิลตรวจสอบยอดเงิน และกดยืนยันรับเงินให้คุณครับ',
                      style: TextStyle(fontSize: 11, color: Colors.blueGrey),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              final vm = context.read<ExpenseViewModel>();
              final ok = await vm.markSplitPaid(split.id);
              if (context.mounted && ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('แจ้ง $payerName ว่าโอนเงินแล้วเรียบร้อย รอเจ้าของบิลตรวจสอบยอด'),
                    backgroundColor: AppTheme.accentGreen,
                  ),
                );
              }
            },
            child: const Text('ยืนยันแจ้งโอน'),
          ),
        ],
      ),
    );
  }

  void _confirmVerifyPayment(BuildContext context, ExpenseSplitModel split, bool confirm) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              confirm ? Icons.check_circle_outline : Icons.cancel_outlined,
              color: confirm ? AppTheme.accentGreen : AppTheme.accentRed,
            ),
            const SizedBox(width: 8),
            Text(
              confirm ? 'ยืนยันการรับเงิน' : 'ปฏิเสธการแจ้งโอน',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          confirm
              ? 'คุณตรวจสอบยอดเงินและยืนยันว่าได้รับ ฿${split.amountOwed.toStringAsFixed(2)} จาก "${split.user.displayName}" แล้วใช่หรือไม่? ระบบจะตัดยอดหนี้ให้ทันที'
              : 'คุณยังไม่ได้รับเงินจาก "${split.user.displayName}" ใช่หรือไม่? ระบบจะเปลี่ยนสถานะกลับเป็น "ยังค้างชำระ"',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: confirm ? AppTheme.accentGreen : AppTheme.accentRed,
            ),
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              final vm = context.read<ExpenseViewModel>();
              final ok = await vm.verifySplitPayment(splitId: split.id, confirm: confirm);
              if (context.mounted && ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      confirm
                          ? 'ยืนยันการรับเงินจาก ${split.user.displayName} เรียบร้อยแล้ว'
                          : 'ปฏิเสธการแจ้งโอนของ ${split.user.displayName} แล้ว',
                    ),
                    backgroundColor: confirm ? AppTheme.accentGreen : Colors.orange.shade800,
                  ),
                );
              }
            },
            child: Text(confirm ? 'ยืนยันรับเงิน' : 'ปฏิเสธ'),
          ),
        ],
      ),
    );
  }

  void _confirmDirectReceived(BuildContext context, ExpenseSplitModel split) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: AppTheme.accentGreen),
            SizedBox(width: 8),
            Text(
              'บันทึกว่าได้รับเงินแล้ว',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'คุณได้รับเงินคืนจำนวน ฿${split.amountOwed.toStringAsFixed(2)} จาก "${split.user.displayName}" สำหรับบิลนี้เรียบร้อยแล้วใช่หรือไม่?\n\n'
          'ระบบจะเปลี่ยนสถานะของ ${split.user.displayName} เป็น "ชำระเรียบร้อยแล้ว ✔️" ทันที',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentGreen,
            ),
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              final vm = context.read<ExpenseViewModel>();
              final ok = await vm.verifySplitPayment(splitId: split.id, confirm: true);
              if (context.mounted && ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('บันทึกว่า ${split.user.displayName} ชำระเงินเรียบร้อยแล้ว ✔️'),
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
