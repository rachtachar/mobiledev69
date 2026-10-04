import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../data/models/expense_model.dart';
import '../../viewmodels/expense_view_model.dart';
import '../theme/app_theme.dart';

class AddExpenseScreen extends StatefulWidget {
  final ExpenseModel? expenseToEdit;

  const AddExpenseScreen({super.key, this.expenseToEdit});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  final _titleFocusNode = FocusNode();
  final _amountFocusNode = FocusNode();
  final _notesFocusNode = FocusNode();

  String _selectedCategory = 'food';
  final Set<int> _selectedMemberIds = {};

  @override
  void initState() {
    super.initState();
    if (widget.expenseToEdit != null) {
      final e = widget.expenseToEdit!;
      _titleController.text = e.title;
      _amountController.text = e.amount.toStringAsFixed(2);
      _notesController.text = e.notes;
      _selectedCategory = e.category;
      for (final s in e.splits) {
        _selectedMemberIds.add(s.user.id);
      }
    } else {
      final vm = context.read<ExpenseViewModel>();
      // Default all available members selected
      for (final u in vm.availableUsers) {
        _selectedMemberIds.add(u.id);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    _titleFocusNode.dispose();
    _amountFocusNode.dispose();
    _notesFocusNode.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedMemberIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาเลือกผู้ร่วมหารอย่างน้อย 1 คน'),
          backgroundColor: AppTheme.accentRed,
        ),
      );
      return;
    }

    final vm = context.read<ExpenseViewModel>();
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;

    final success = widget.expenseToEdit != null
        ? await vm.updateExpense(
            id: widget.expenseToEdit!.id,
            title: _titleController.text.trim(),
            amount: amount,
            category: _selectedCategory,
            notes: _notesController.text.trim(),
            participantIds: _selectedMemberIds.toList(),
          )
        : await vm.createExpense(
            title: _titleController.text.trim(),
            amount: amount,
            category: _selectedCategory,
            notes: _notesController.text.trim(),
            participantIds: _selectedMemberIds.toList(),
          );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.successMessage ?? (widget.expenseToEdit != null ? 'แก้ไขบิลสำเร็จ!' : 'บันทึกบิลสำเร็จ!')),
          backgroundColor: AppTheme.accentGreen,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.errorMessage ?? 'เกิดข้อผิดพลาดในการบันทึกบิล'),
          backgroundColor: AppTheme.accentRed,
        ),
      );
    }
  }

  double get _estimatedPerPerson {
    final amt = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amt <= 0 || _selectedMemberIds.isEmpty) return 0.0;
    return amt / _selectedMemberIds.length;
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ExpenseViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.expenseToEdit != null ? 'แก้ไขบิลค่าใช้จ่าย' : 'เพิ่มบิลค่าใช้จ่ายใหม่'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Bill Title
                TextFormField(
                  controller: _titleController,
                  focusNode: _titleFocusNode,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) {
                    FocusScope.of(context).requestFocus(_amountFocusNode);
                  },
                  decoration: const InputDecoration(
                    labelText: 'ชื่อรายการบิล (Title) *',
                    hintText: 'เช่น ค่าอาหารเย็น, ค่า Grab, ตั๋วรถไฟ',
                    prefixIcon: Icon(Icons.receipt),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'กรุณากรอกชื่อรายการบิล';
                    }
                    if (value.trim().length < 3) {
                      return 'ชื่อรายการต้องมีความยาวอย่างน้อย 3 ตัวอักษร';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 2. Amount Field
                TextFormField(
                  controller: _amountController,
                  focusNode: _amountFocusNode,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() {}),
                  onFieldSubmitted: (_) {
                    FocusScope.of(context).requestFocus(_notesFocusNode);
                  },
                  decoration: const InputDecoration(
                    labelText: 'จำนวนเงินรวม (Amount) *',
                    hintText: '0.00',
                    prefixText: '฿ ',
                    prefixStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.primaryColor,
                    ),
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'กรุณาระบุจำนวนเงิน';
                    }
                    final regExp = RegExp(r'^\d+(\.\d{1,2})?$');
                    if (!regExp.hasMatch(value.trim())) {
                      return 'กรุณาระบุเป็นตัวเลขทศนิยมไม่เกิน 2 ตำแหน่ง (เช่น 350 หรือ 350.50)';
                    }
                    final val = double.tryParse(value.trim());
                    if (val == null || val <= 0) {
                      return 'จำนวนเงินต้องมากกว่า 0 บาท';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 3. Category Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'หมวดหมู่ค่าใช้จ่าย *',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: AppConstants.categories.entries.map((entry) {
                    return DropdownMenuItem<String>(
                      value: entry.key,
                      child: Row(
                        children: [
                          Icon(entry.value.icon, size: 20, color: entry.value.color),
                          const SizedBox(width: 10),
                          Text(entry.value.label),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedCategory = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 20),

                // 4. Split participants selection
                const Text(
                  '👥 เลือกผู้ร่วมหารในกลุ่ม:',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 8),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: vm.availableUsers.map((user) {
                    final isSelected = _selectedMemberIds.contains(user.id);
                    return FilterChip(
                      selected: isSelected,
                      label: Text(user.displayName),
                      avatar: CircleAvatar(
                        backgroundColor: isSelected ? Colors.white : AppTheme.primaryColor,
                        child: Text(
                          user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
                          style: TextStyle(
                            color: isSelected ? AppTheme.primaryColor : Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      selectedColor: AppTheme.primaryColor,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.textDark,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedMemberIds.add(user.id);
                          } else {
                            _selectedMemberIds.remove(user.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),

                // Live split preview banner
                if (_estimatedPerPerson > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.secondaryColor.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'หาร ${_selectedMemberIds.length} คน เท่าๆ กัน:',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.secondaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'คนละ ${_estimatedPerPerson.toStringAsFixed(2)} ฿',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.secondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // 5. Notes Field
                TextFormField(
                  controller: _notesController,
                  focusNode: _notesFocusNode,
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'บันทึกเพิ่มเติม (Notes)',
                    hintText: 'เช่น หารเฉพาะค่าข้าว ไม่รวมค่าน้ำ',
                    prefixIcon: Icon(Icons.notes_outlined),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 28),

                // Submit Button
                ElevatedButton.icon(
                  onPressed: vm.isSubmitting ? null : _submit,
                  icon: vm.isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(vm.isSubmitting
                      ? 'กำลังบันทึก...'
                      : (widget.expenseToEdit != null ? 'บันทึกการแก้ไข' : 'บันทึกบิลนี้')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
