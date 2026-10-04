import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../data/models/expense_model.dart';
import '../../data/models/user_model.dart';
import '../../viewmodels/auth_view_model.dart';
import '../../viewmodels/expense_view_model.dart';
import '../expenses/add_expense_screen.dart';
import '../expenses/expense_detail_screen.dart';
import '../profile/profile_screen.dart';
import '../profile/friends_screen.dart';
import '../../viewmodels/theme_view_model.dart';
import '../theme/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _creatorFilter = 'all'; // 'all', 'mine', 'others'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseViewModel>().loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final expenseVm = context.watch<ExpenseViewModel>();
    final summary = expenseVm.summary;
    final user = authVm.currentUser;

    final myExpensesCount = expenseVm.expenses.where((e) => user != null && (e.payer.id == user.id || e.payer.username == user.username)).length;
    final othersExpensesCount = expenseVm.expenses.where((e) => user == null || (e.payer.id != user.id && e.payer.username != user.username)).length;

    final displayedExpenses = expenseVm.expenses.where((e) {
      final isMine = user != null && (e.payer.id == user.id || e.payer.username == user.username);
      if (_creatorFilter == 'mine') return isMine;
      if (_creatorFilter == 'others') return !isMine;
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.group, color: AppTheme.primaryColor, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'SplitSquad',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ],
        ),
        actions: [
          // Friend Requests / Friends Management
          IconButton(
            tooltip: 'จัดการเพื่อนและคำขอเป็นเพื่อน',
            icon: Badge(
              isLabelVisible: expenseVm.incomingRequests.isNotEmpty,
              label: Text('${expenseVm.incomingRequests.length}'),
              child: const Icon(Icons.person_add_outlined),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FriendsScreen()),
              );
            },
          ),
          IconButton(
            tooltip: context.watch<ThemeViewModel>().isDarkMode ? 'เปลี่ยนเป็นธีมสว่าง' : 'เปลี่ยนเป็นธีมมืด 🌙',
            icon: Icon(
              context.watch<ThemeViewModel>().isDarkMode ? Icons.light_mode : Icons.dark_mode_outlined,
            ),
            onPressed: () => context.read<ThemeViewModel>().toggleTheme(),
          ),
          IconButton(
            tooltip: 'โปรไฟล์ & จัดการหนี้',
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryColor,
              child: Text(
                user != null && user.displayName.isNotEmpty
                    ? user.displayName[0].toUpperCase()
                    : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => expenseVm.loadData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Greeting
              Text(
                'สวัสดี, ${user?.displayName ?? "สมาชิก"} 👋',
                style: const TextStyle(
                  fontSize: 15,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),

              // Summary Cards
              _buildSummaryHeader(summary),
              const SizedBox(height: 20),

              // Category Filters
              _buildCategoryFilters(expenseVm),
              const SizedBox(height: 16),

              // Section Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'รายการบิลค่าใช้จ่าย',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  Text(
                    '${displayedExpenses.length} รายการ',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Creator Filter Tabs (ฉันสร้าง vs เพื่อนสร้าง)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCreatorTab(
                      label: 'ทั้งหมด',
                      count: expenseVm.expenses.length,
                      isSelected: _creatorFilter == 'all',
                      onTap: () => setState(() => _creatorFilter = 'all'),
                    ),
                    const SizedBox(width: 8),
                    _buildCreatorTab(
                      label: 'ฉันเป็นคนสร้าง 🙋‍♂️',
                      count: myExpensesCount,
                      isSelected: _creatorFilter == 'mine',
                      onTap: () => setState(() => _creatorFilter = 'mine'),
                      activeColor: AppTheme.accentGreen,
                    ),
                    const SizedBox(width: 8),
                    _buildCreatorTab(
                      label: 'เพื่อนเป็นคนสร้าง 👥',
                      count: othersExpensesCount,
                      isSelected: _creatorFilter == 'others',
                      onTap: () => setState(() => _creatorFilter = 'others'),
                      activeColor: Colors.orange.shade700,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Expenses List
              if (expenseVm.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (displayedExpenses.isEmpty)
                _buildEmptyState()
              else
                ...displayedExpenses.map((expense) => _buildExpenseCard(context, expense, user)),

              const SizedBox(height: 80), // Space for FAB
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'เพิ่มบิลใหม่',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
          );
        },
      ),
    );
  }

  Widget _buildCreatorTab({
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
    Color? activeColor,
  }) {
    final color = activeColor ?? AppTheme.primaryColor;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppTheme.textDark,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.25) : color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryHeader(BalanceSummaryModel summary) {
    final isPositive = summary.netBalance >= 0;

    return Column(
      children: [
        // Net Balance Card
        Card(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: isPositive
                    ? [const Color(0xFF0D9488), const Color(0xFF059669)]
                    : [const Color(0xFFE11D48), const Color(0xFFBE123C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ยอดคงเหลือสุทธิของคุณ (Net Balance)',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '${isPositive ? '+' : ''}${summary.netBalance.toStringAsFixed(2)} ฿',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  isPositive
                      ? 'คุณมีสิทธิ์ได้รับเงินคืนจากเพื่อนในกลุ่ม'
                      : 'คุณมียอดค้างจ่ายที่ต้องโอนคืนให้เพื่อน',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // 2 Column Mini-Cards
        Row(
          children: [
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.arrow_downward, size: 16, color: AppTheme.accentGreen),
                          const SizedBox(width: 4),
                          const Text(
                            'เพื่อนติดคุณ',
                            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${summary.totalOwedToYou.toStringAsFixed(2)} ฿',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.arrow_upward, size: 16, color: AppTheme.accentRed),
                          const SizedBox(width: 4),
                          const Text(
                            'คุณติดเพื่อน',
                            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${summary.totalYouOwe.toStringAsFixed(2)} ฿',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentRed,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryFilters(ExpenseViewModel vm) {
    final categories = [
      {'id': 'all', 'label': 'ทั้งหมด', 'icon': Icons.apps},
      {'id': 'food', 'label': 'อาหาร', 'icon': Icons.restaurant},
      {'id': 'transport', 'label': 'เดินทาง', 'icon': Icons.directions_car},
      {'id': 'housing', 'label': 'ที่พัก', 'icon': Icons.hotel},
      {'id': 'entertainment', 'label': 'บันเทิง', 'icon': Icons.sports_esports},
      {'id': 'shopping', 'label': 'ซื้อของ', 'icon': Icons.shopping_bag},
      {'id': 'other', 'label': 'อื่นๆ', 'icon': Icons.receipt_long},
    ];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = vm.selectedCategory == cat['id'];
          return ChoiceChip(
            selected: isSelected,
            avatar: Icon(
              cat['icon'] as IconData,
              size: 16,
              color: isSelected ? Colors.white : AppTheme.textMuted,
            ),
            label: Text(cat['label'] as String),
            selectedColor: AppTheme.primaryColor,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : AppTheme.textDark,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            onSelected: (_) => vm.filterByCategory(cat['id'] as String),
          );
        },
      ),
    );
  }

  Widget _buildExpenseCard(BuildContext context, ExpenseModel expense, UserModel? currentUser) {
    final catInfo = AppConstants.categories[expense.category] ??
        AppConstants.categories['other']!;
    final isMine = currentUser != null &&
        (expense.payer.id == currentUser.id || expense.payer.username == currentUser.username);

    // Find current user's split if any
    ExpenseSplitModel? mySplit;
    for (final s in expense.splits) {
      if (currentUser != null && (s.user.id == currentUser.id || s.user.username == currentUser.username)) {
        mySplit = s;
        break;
      }
    }

    String formattedDate;
    try {
      formattedDate = DateFormat('dd MMM, HH:mm', 'th_TH').format(expense.createdAt);
    } catch (_) {
      formattedDate = DateFormat('dd MMM, HH:mm').format(expense.createdAt);
    }

    final cardBorderColor = isMine
        ? AppTheme.accentGreen.withValues(alpha: 0.4)
        : Colors.orange.withValues(alpha: 0.4);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cardBorderColor, width: 1.2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ExpenseDetailScreen(expense: expense),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Creator Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isMine
                          ? AppTheme.accentGreen.withValues(alpha: 0.12)
                          : Colors.orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isMine
                            ? AppTheme.accentGreen.withValues(alpha: 0.3)
                            : Colors.orange.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isMine ? Icons.person : Icons.group,
                          size: 13,
                          color: isMine ? AppTheme.accentGreen : Colors.orange.shade800,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isMine ? '🙋‍♂️ คุณเป็นคนสร้างและจ่าย' : '👥 บิลของ ${expense.payer.displayName}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isMine ? AppTheme.accentGreen : Colors.orange.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    formattedDate,
                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: catInfo.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(catInfo.icon, color: catInfo.color, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          expense.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (isMine)
                          Text(
                            expense.splits.length > 1
                                ? 'คุณออกให้เพื่อน ${expense.splits.length - 1} คน'
                                : 'คุณออกเองทั้งหมด',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          )
                        else
                          Text(
                            'ส่วนที่คุณต้องแชร์: ฿ ${(mySplit?.amountOwed ?? 0).toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.accentRed,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '฿ ${expense.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${expense.splits.length} คนหาร',
                        style: const TextStyle(fontSize: 11, color: AppTheme.primaryColor),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 54, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text(
            'ยังไม่มีรายการบิลในหมวดนี้',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 4),
          const Text(
            'กดปุ่ม "เพิ่มบิลใหม่" ด้านล่างเพื่อเริ่มหารค่าใช้จ่าย',
            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}
