import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../providers/app_providers.dart';
import '../../dashboard/presentation/widgets/recent_transactions_list.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final _searchController = TextEditingController();
  String _selectedCategory = '';
  String _selectedType = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final transactionsAsync = ref.watch(transactionsProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            floating: true,
            snap: true,
            title: const Text('Transactions'),
            actions: [
              IconButton(
                icon: const Icon(Icons.tune_rounded),
                onPressed: _showFilterSheet,
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => _applyFilter(search: v),
                decoration: InputDecoration(
                  hintText: 'Search transactions...',
                  hintStyle: const TextStyle(fontFamily: 'Inter', fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _applyFilter(search: '');
                          },
                        )
                      : null,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _buildFilterChips(),
          ),
        ],
        body: transactionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (transactions) {
            if (transactions.isEmpty) {
              return _buildEmpty(context);
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TransactionTile(transaction: transactions[index]),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppConstants.routeAddTransaction),
        backgroundColor: AppColors.seedColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterChips() {
    final categories = ['', ...AppConstants.defaultCategories];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          _FilterChip(
            label: 'All',
            selected: _selectedType.isEmpty && _selectedCategory.isEmpty,
            onTap: () {
              setState(() { _selectedType = ''; _selectedCategory = ''; });
              ref.read(transactionFilterProvider.notifier).state = const TransactionFilter();
            },
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Expenses',
            selected: _selectedType == 'expense',
            color: AppColors.expense,
            onTap: () {
              setState(() => _selectedType = _selectedType == 'expense' ? '' : 'expense');
              _applyFilter();
            },
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Income',
            selected: _selectedType == 'income',
            color: AppColors.income,
            onTap: () {
              setState(() => _selectedType = _selectedType == 'income' ? '' : 'income');
              _applyFilter();
            },
          ),
          const SizedBox(width: 8),
          ...AppConstants.defaultCategories.map((cat) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _FilterChip(
                  label: cat,
                  selected: _selectedCategory == cat,
                  color: AppColors.getCategoryColor(cat),
                  onTap: () {
                    setState(() => _selectedCategory = _selectedCategory == cat ? '' : cat);
                    _applyFilter();
                  },
                ),
              )),
        ],
      ),
    );
  }

  void _applyFilter({String? search}) {
    ref.read(transactionFilterProvider.notifier).state = TransactionFilter(
      category: _selectedCategory.isEmpty ? null : _selectedCategory,
      type: _selectedType.isEmpty ? null : _selectedType,
      search: search ?? _searchController.text,
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FilterSheet(
        selectedType: _selectedType,
        onApply: (type, category) {
          setState(() {
            _selectedType = type;
            _selectedCategory = category;
          });
          _applyFilter();
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No transactions found',
              style: TextStyle(fontSize: 16, fontFamily: 'Inter', fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty
                ? 'Try a different search term'
                : 'Transactions from SMS will appear here',
            style: const TextStyle(color: Colors.grey, fontFamily: 'Inter'),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.seedColor;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? chipColor : chipColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : chipColor,
          ),
        ),
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final String selectedType;
  final Function(String type, String category) onApply;

  const _FilterSheet({required this.selectedType, required this.onApply});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String _type;
  String _category = '';

  @override
  void initState() {
    super.initState();
    _type = widget.selectedType;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Filter Transactions',
              style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          const Text('Type', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              _typeButton('All', ''),
              const SizedBox(width: 8),
              _typeButton('Expense', 'expense'),
              const SizedBox(width: 8),
              _typeButton('Income', 'income'),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => widget.onApply(_type, _category),
              child: const Text('Apply Filter'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _typeButton(String label, String value) {
    final selected = _type == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _type = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.seedColor : AppColors.seedColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.seedColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
