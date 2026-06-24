import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../providers/app_providers.dart';
import '../../../../data/database/app_database.dart';
import '../../../../data/database/tables/tables.dart';

class AddBudgetScreen extends ConsumerStatefulWidget {
  final int? editId;
  const AddBudgetScreen({super.key, this.editId});

  @override
  ConsumerState<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends ConsumerState<AddBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  
  int _month = DateTime.now().month;
  int _year = DateTime.now().year;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.editId != null) {
      _loadBudget();
    } else {
      _nameController.text = 'Monthly Budget';
    }
  }

  Future<void> _loadBudget() async {
    final db = ref.read(databaseProvider);
    final budget = await db.budgetDao.getBudgetById(widget.editId!);
    if (budget != null && mounted) {
      setState(() {
        _nameController.text = budget.name;
        _amountController.text = budget.amount.toString();
        _month = budget.month;
        _year = budget.year;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editId == null ? 'Create Budget' : 'Edit Budget'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: const Text('Save', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Month / Year Selector
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _month,
                    decoration: const InputDecoration(labelText: 'Month'),
                    items: List.generate(12, (i) => DropdownMenuItem(
                      value: i + 1,
                      child: Text(_getMonthName(i + 1), style: const TextStyle(fontFamily: 'Inter')),
                    )),
                    onChanged: (v) => setState(() => _month = v!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _year,
                    decoration: const InputDecoration(labelText: 'Year'),
                    items: List.generate(5, (i) => DropdownMenuItem(
                      value: DateTime.now().year + i,
                      child: Text('${DateTime.now().year + i}', style: const TextStyle(fontFamily: 'Inter')),
                    )),
                    onChanged: (v) => setState(() => _year = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Budget Name'),
              style: const TextStyle(fontFamily: 'Inter'),
              validator: (v) => (v == null || v.isEmpty) ? 'Enter a name' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Total Amount',
                prefixText: 'MK ',
                prefixStyle: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600),
              ),
              style: const TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w700),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter an amount';
                if (double.tryParse(v.replaceAll(',', '')) == null) return 'Invalid amount';
                if (double.parse(v.replaceAll(',', '')) <= 0) return 'Amount must be greater than 0';
                return null;
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save Budget'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final amount = double.parse(_amountController.text.replaceAll(',', ''));
    final name = _nameController.text.trim();

    final notifier = ref.read(budgetNotifierProvider.notifier);
    
    if (widget.editId != null) {
      await notifier.updateBudget(
        BudgetsCompanion(
          id: Value(widget.editId!),
          name: Value(name),
          amount: Value(amount),
          month: Value(_month),
          year: Value(_year),
        ),
      );
    } else {
      await notifier.createBudget(
        name: name,
        amount: amount,
        month: _month,
        year: _year,
      );
    }

    if (mounted) Navigator.pop(context);
  }
}
