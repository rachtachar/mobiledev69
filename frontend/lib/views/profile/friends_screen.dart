import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/expense_view_model.dart';
import '../theme/app_theme.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final _usernameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  void _sendFriendRequest() async {
    if (!_formKey.currentState!.validate()) return;

    final vm = context.read<ExpenseViewModel>();
    final username = _usernameController.text.trim();
    final messenger = ScaffoldMessenger.of(context);

    final success = await vm.sendFriendRequest(username);
    if (!mounted) return;

    if (success) {
      _usernameController.clear();
      messenger.showSnackBar(
        SnackBar(
          content: Text(vm.successMessage ?? 'ส่งคำขอเป็นเพื่อนเรียบร้อยแล้ว'),
          backgroundColor: AppTheme.accentGreen,
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(vm.errorMessage ?? 'ไม่สามารถส่งคำขอเป็นเพื่อนได้'),
          backgroundColor: AppTheme.accentRed,
        ),
      );
    }
  }

  void _confirmRemoveFriend(dynamic friend) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.person_remove, color: AppTheme.accentRed),
            const SizedBox(width: 8),
            Text('ลบเพื่อน (${friend.displayName})'),
          ],
        ),
        content: Text(
          'คุณแน่ใจหรือไม่ว่าต้องการลบ @${friend.username} ออกจากรายชื่อเพื่อน?\n\n'
          'เมื่อลบแล้ว จะไม่สามารถเลือกเพื่อนคนนี้ในบิลใหม่ได้ จนกว่าจะส่งคำขอเป็นเพื่อนกันใหม่อีกครั้ง',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final vm = context.read<ExpenseViewModel>();
              final messenger = ScaffoldMessenger.of(context);
              final ok = await vm.removeFriend(friend.id as int);
              if (!mounted) return;
              if (ok) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('ลบ @${friend.username} ออกจากเพื่อนเรียบร้อยแล้ว'),
                    backgroundColor: AppTheme.accentGreen,
                  ),
                );
              } else {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(vm.errorMessage ?? 'ไม่สามารถลบเพื่อนได้'),
                    backgroundColor: AppTheme.accentRed,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentRed),
            child: const Text('ลบเพื่อน'),
          ),
        ],
      ),
    );
  }

  void _confirmCancelRequest(dynamic req) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยกเลิกคำขอเป็นเพื่อน'),
        content: Text('ต้องการยกเลิกคำขอเป็นเพื่อนที่ส่งไปยัง @${req.toUser.username} หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('ปิด'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final vm = context.read<ExpenseViewModel>();
              final messenger = ScaffoldMessenger.of(context);
              final ok = await vm.cancelFriendRequest(req.id as int);
              if (!mounted) return;
              if (ok) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('ยกเลิกคำขอเรียบร้อยแล้ว'),
                    backgroundColor: AppTheme.accentGreen,
                  ),
                );
              } else {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(vm.errorMessage ?? 'ไม่สามารถยกเลิกคำขอได้'),
                    backgroundColor: AppTheme.accentRed,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentRed),
            child: const Text('ยกเลิกคำขอ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ExpenseViewModel>();
    final incoming = vm.incomingRequests;
    final outgoing = vm.outgoingRequests;
    final friends = vm.friends;

    return Scaffold(
      appBar: AppBar(
        title: const Text('จัดการเพื่อน (Friends)'),
      ),
      body: RefreshIndicator(
        onRefresh: () => vm.loadData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Add Friend Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.person_add, color: AppTheme.primaryColor, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'เพิ่มเพื่อนด้วย Username',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'กรอกชื่อผู้ใช้ (Username) ของเพื่อนเพื่อส่งคำขอเพิ่มเพื่อน',
                          style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _usernameController,
                                decoration: const InputDecoration(
                                  hintText: 'เช่น bob, alice, somchai',
                                  prefixIcon: Icon(Icons.alternate_email, size: 20),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'กรุณาระบุ Username';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton.icon(
                              onPressed: vm.isSubmitting ? null : _sendFriendRequest,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                              icon: vm.isSubmitting
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.send, size: 16),
                              label: const Text('ส่งคำขอ'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 2. Incoming Requests
              Row(
                children: [
                  const Text(
                    '📬 คำขอเป็นเพื่อนที่รอตอบรับ',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  ),
                  const SizedBox(width: 8),
                  if (incoming.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.accentRed,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${incoming.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              if (incoming.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'ไม่มีคำขอเป็นเพื่อนในขณะนี้',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                      ),
                    ),
                  ),
                )
              else
                ...incoming.map((req) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                            child: Text(
                              req.fromUser.displayName.isNotEmpty
                                  ? req.fromUser.displayName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  req.fromUser.displayName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Text(
                                  '@${req.fromUser.username}',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                ),
                              ],
                            ),
                          ),
                          // Accept button
                          IconButton.filled(
                            style: IconButton.styleFrom(
                              backgroundColor: AppTheme.accentGreen,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.check, size: 18),
                            tooltip: 'ตอบรับคำขอ',
                            onPressed: vm.isSubmitting
                                ? null
                                : () async {
                                    final messenger = ScaffoldMessenger.of(context);
                                    final ok = await vm.respondFriendRequest(requestId: req.id, accept: true);
                                    if (ok) {
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text('คุณและ ${req.fromUser.displayName} เป็นเพื่อนกันแล้ว'),
                                          backgroundColor: AppTheme.accentGreen,
                                        ),
                                      );
                                    }
                                  },
                          ),
                          const SizedBox(width: 6),
                          // Reject button
                          IconButton.outlined(
                            style: IconButton.styleFrom(
                              foregroundColor: AppTheme.accentRed,
                              side: const BorderSide(color: AppTheme.accentRed),
                            ),
                            icon: const Icon(Icons.close, size: 18),
                            tooltip: 'ปฏิเสธคำขอ',
                            onPressed: vm.isSubmitting
                                ? null
                                : () async {
                                    final messenger = ScaffoldMessenger.of(context);
                                    final ok = await vm.respondFriendRequest(requestId: req.id, accept: false);
                                    if (ok) {
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text('ปฏิเสธคำขอเรียบร้อยแล้ว'),
                                        ),
                                      );
                                    }
                                  },
                          ),
                        ],
                      ),
                    ),
                  );
                }),

              // 3. Outgoing Requests (if any)
              if (outgoing.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  '⏳ คำขอที่คุณส่งไปแล้ว (รอการตอบรับ)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                ),
                const SizedBox(height: 8),
                ...outgoing.map((req) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey.shade200,
                        child: Text(
                          req.toUser.displayName.isNotEmpty ? req.toUser.displayName[0].toUpperCase() : '?',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                        ),
                      ),
                      title: Text(req.toUser.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('@${req.toUser.username}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'รอตอบรับ',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange),
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                            tooltip: 'ยกเลิกคำขอ',
                            onPressed: () => _confirmCancelRequest(req),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],

              const SizedBox(height: 20),

              // 4. Friends List
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '👥 เพื่อนของฉัน (Friends)',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  ),
                  Text(
                    '${friends.length} คน',
                    style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (friends.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.people_outline, size: 40, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          const Text(
                            'ยังไม่มีเพื่อนในระบบ',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'ส่งคำขอเพิ่มเพื่อนด้วย Username ด้านบนเพื่อเริ่มหารบิลร่วมกัน',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                ...friends.map((friend) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryColor,
                        child: Text(
                          friend.displayName.isNotEmpty ? friend.displayName[0].toUpperCase() : '?',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      title: Text(
                        friend.displayName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('@${friend.username} • ${friend.email}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle, color: AppTheme.accentGreen, size: 18),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.person_remove_outlined, color: AppTheme.accentRed, size: 20),
                            tooltip: 'ลบเพื่อน',
                            onPressed: () => _confirmRemoveFriend(friend),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
