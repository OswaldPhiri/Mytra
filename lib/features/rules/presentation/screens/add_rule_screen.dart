import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../providers/app_providers.dart';
import '../../../../data/database/app_database.dart';
import '../../../../data/database/tables/tables.dart';

class AddRuleScreen extends ConsumerStatefulWidget {
  final int? editId;
  const AddRuleScreen({super.key, this.editId});

  @override
  ConsumerState<AddRuleScreen> createState() => _AddRuleScreenState();
}

class _AddRuleScreenState extends ConsumerState<AddRuleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _valueController = TextEditingController();
  
  String _field = 'sender';
  String _operator = 'contains';
  String _category = 'Food';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.editId != null) {
      _loadRule();
    }
  }

  Future<void> _loadRule() async {
    final db = ref.read(databaseProvider);
    final rule = await db.ruleDao.getRuleById(widget.editId!);
    if (rule != null && mounted) {
      setState(() {
        _nameController.text = rule.name;
        _valueController.text = rule.conditionValue;
        _field = rule.conditionField;
        _operator = rule.conditionOperator;
        _category = rule.actionCategory;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editId == null ? 'Create Rule' : 'Edit Rule'),
        actions: [
          if (widget.editId != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.expense),
              onPressed: _deleteRule,
            ),
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
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Rule Name (e.g. Shoprite Groceries)'),
              style: const TextStyle(fontFamily: 'Inter'),
              validator: (v) => (v == null || v.isEmpty) ? 'Enter a name' : null,
            ),
            const SizedBox(height: 24),
            const Text('Condition', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: _field,
                    decoration: const InputDecoration(labelText: 'Field'),
                    items: const [
                      DropdownMenuItem(value: 'sender', child: Text('Sender', style: TextStyle(fontFamily: 'Inter'))),
                      DropdownMenuItem(value: 'description', child: Text('Description', style: TextStyle(fontFamily: 'Inter'))),
                      DropdownMenuItem(value: 'amount', child: Text('Amount', style: TextStyle(fontFamily: 'Inter'))),
                    ],
                    onChanged: (v) => setState(() {
                      _field = v!;
                      if (_field == 'amount') _operator = 'gt';
                      else _operator = 'contains';
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: _operator,
                    decoration: const InputDecoration(labelText: 'Operator'),
                    items: _field == 'amount'
                        ? const [
                            DropdownMenuItem(value: 'equals', child: Text('Equals', style: TextStyle(fontFamily: 'Inter'))),
                            DropdownMenuItem(value: 'gt', child: Text('Greater than', style: TextStyle(fontFamily: 'Inter'))),
                            DropdownMenuItem(value: 'lt', child: Text('Less than', style: TextStyle(fontFamily: 'Inter'))),
                          ]
                        : const [
                            DropdownMenuItem(value: 'contains', child: Text('Contains', style: TextStyle(fontFamily: 'Inter'))),
                            DropdownMenuItem(value: 'equals', child: Text('Equals exactly', style: TextStyle(fontFamily: 'Inter'))),
                            DropdownMenuItem(value: 'starts_with', child: Text('Starts with', style: TextStyle(fontFamily: 'Inter'))),
                          ],
                    onChanged: (v) => setState(() => _operator = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _valueController,
              keyboardType: _field == 'amount' ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
              decoration: InputDecoration(
                labelText: 'Value',
                hintText: _field == 'amount' ? '5000' : 'Airtel Money',
              ),
              style: const TextStyle(fontFamily: 'Inter'),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter a value';
                if (_field == 'amount' && double.tryParse(v) == null) return 'Must be a valid number';
                return null;
              },
            ),
            const SizedBox(height: 24),
            const Text('Action', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            const Text('Assign to category:', style: TextStyle(fontFamily: 'Inter', fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppConstants.defaultCategories.map((cat) {
                final selected = cat == _category;
                final color = AppColors.getCategoryColor(cat);
                return GestureDetector(
                  onTap: () => setState(() => _category = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? color : color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : color,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final db = ref.read(databaseProvider);
    
    if (widget.editId != null) {
      await db.ruleDao.updateRule(
        RulesCompanion(
          id: Value(widget.editId!),
          name: Value(_nameController.text.trim()),
          conditionField: Value(_field),
          conditionOperator: Value(_operator),
          conditionValue: Value(_valueController.text.trim()),
          actionCategory: Value(_category),
        ),
      );
    } else {
      await db.ruleDao.insertRule(
        RulesCompanion.insert(
          name: _nameController.text.trim(),
          conditionField: _field,
          conditionOperator: _operator,
          conditionValue: _valueController.text.trim(),
          actionCategory: _category,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    }

    if (mounted) Navigator.pop(context);
  }

  Future<void> _deleteRule() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Rule', style: TextStyle(fontFamily: 'Inter')),
        content: const Text('Are you sure?', style: TextStyle(fontFamily: 'Inter')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.expense)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(databaseProvider).ruleDao.deleteRule(widget.editId!);
      if (mounted) Navigator.pop(context);
    }
  }
}
