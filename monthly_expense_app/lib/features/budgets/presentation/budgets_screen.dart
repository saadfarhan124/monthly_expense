import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/budget_model.dart';
import '../domain/budget_repository.dart';
import '../domain/budget_service.dart';
import '../../categories/domain/category_repository.dart';
import '../../categories/domain/category_service.dart';
import '../../categories/domain/category_model.dart';
import '../../transactions/domain/transaction_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/animated_button.dart';


class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  late final CategoryRepository _categoryRepository;
  late final BudgetService _budgetService;
  late final CategoryService _categoryService;
  
  bool _showAddForm = false;
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  
  String? _selectedCategoryId;
  String _selectedCurrency = 'PKR';
  BudgetPeriod _selectedPeriod = BudgetPeriod.monthly;
  
  // Cache for categories - shared with budget service
  List<Category> _cachedCategories = [];
  bool _isCategoriesLoaded = false;
  
  // Cache the budget stream to prevent recreation
  Stream<List<BudgetWithSpending>>? _budgetStream;

  @override
  void initState() {
    super.initState();
    _categoryRepository = CategoryRepository();
    _budgetService = BudgetService(
      BudgetRepository(),
      TransactionRepository(),
      _categoryRepository,
    );
    _categoryService = CategoryService(_categoryRepository);
    _loadCachedData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadCachedData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Initialize the budget service cache which will also load categories
    await _budgetService.initializeCache(user.uid);
    
    // Create the budget stream once and cache it
    _budgetStream = _budgetService.getBudgetsWithSpending(user.uid);
    
    // Use the same category stream as the budget service
    _categoryRepository.getCategories(user.uid).listen((categories) {
      if (mounted) {
        setState(() {
          _cachedCategories = categories;
          _isCategoriesLoaded = true;
        });
      }
    });
  }

  void _toggleAddForm() {
    setState(() => _showAddForm = !_showAddForm);
  }

  Future<void> _addBudget() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category'), backgroundColor: AppColors.error),
      );
      return;
    }
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _budgetService.addBudget(
        userId: user.uid,
        categoryId: _selectedCategoryId!,
        amount: double.parse(_amountController.text),
        currency: _selectedCurrency,
        period: _selectedPeriod,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budget added!'), backgroundColor: AppColors.success),
        );
        _amountController.clear();
        setState(() {
          _showAddForm = false;
          _selectedCategoryId = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _deleteBudget(String budgetId) async {
    try {
      await _budgetService.deleteBudget(budgetId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budget deleted!'), backgroundColor: AppColors.error),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      body: user == null
          ? const Center(child: Text('Not signed in'))
          : Padding(
              padding: AppSpacing.paddingHorizontalLg,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('', style: TextStyle(fontSize: 1)), // Spacer
                      IconButton(
                        icon: Icon(_showAddForm ? Icons.close : Icons.add),
                        onPressed: _toggleAddForm,
                        tooltip: _showAddForm ? 'Cancel' : 'Add Budget',
                      ),
                    ],
                  ),
                  if (_showAddForm)
                    Card(
                      color: AppColors.surfaceVariant,
                      child: Padding(
                        padding: AppSpacing.paddingLg,
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildCategoryDropdown(),
                              const SizedBox(height: AppSpacing.md),
                              TextFormField(
                                controller: _amountController,
                                decoration: const InputDecoration(labelText: 'Budget Amount'),
                                keyboardType: TextInputType.number,
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Enter an amount';
                                  if (double.tryParse(v) == null) return 'Enter a valid number';
                                  if (double.parse(v) <= 0) return 'Amount must be greater than 0';
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _buildCurrencyDropdown(),
                              const SizedBox(height: AppSpacing.md),
                              _buildPeriodDropdown(),
                              const SizedBox(height: AppSpacing.lg),
                              AnimatedButton(
                                text: 'Add Budget',
                                icon: Icons.add_circle_outline,
                                backgroundColor: AppColors.primary,
                                hapticType: HapticFeedbackType.medium,
                                onPressed: _addBudget,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  Expanded(
                    child: _buildBudgetsList(user.uid),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCategoryDropdown() {
    if (!_isCategoriesLoaded) {
      return DropdownButtonFormField<String>(
        value: null,
        items: [],
        onChanged: null,
        decoration: const InputDecoration(
          labelText: 'Category',
          helperText: 'Loading categories...',
        ),
      );
    }

    if (_cachedCategories.isEmpty) {
      return DropdownButtonFormField<String>(
        value: null,
        items: [],
        onChanged: null,
        decoration: const InputDecoration(
          labelText: 'Category',
          helperText: 'Add categories first',
        ),
      );
    }

    return DropdownButtonFormField<String>(
      value: _selectedCategoryId,
      items: _cachedCategories
          .map((cat) => DropdownMenuItem(
                value: cat.id,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Color(int.parse(cat.color.replaceAll('#', '0xFF'))),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Center(
                        child: Text(
                          cat.icon,
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        cat.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
      onChanged: (v) => setState(() => _selectedCategoryId = v),
      decoration: const InputDecoration(labelText: 'Category'),
      validator: (value) => value == null ? 'Please select a category' : null,
    );
  }

  Widget _buildCurrencyDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCurrency,
      items: ['PKR', 'USD', 'EUR']
          .map((currency) => DropdownMenuItem(
                value: currency,
                child: Text(currency),
              ))
          .toList(),
      onChanged: (v) => setState(() => _selectedCurrency = v!),
      decoration: const InputDecoration(labelText: 'Currency'),
    );
  }

  Widget _buildPeriodDropdown() {
    return DropdownButtonFormField<BudgetPeriod>(
      value: _selectedPeriod,
      items: BudgetPeriod.values
          .map((period) => DropdownMenuItem(
                value: period,
                child: Text(period.name.toUpperCase()),
              ))
          .toList(),
      onChanged: (v) => setState(() => _selectedPeriod = v!),
      decoration: const InputDecoration(labelText: 'Period'),
    );
  }

  Widget _buildBudgetsList(String userId) {
    print('DEBUG: _buildBudgetsList called, stream: $_budgetStream');
    return StreamBuilder<List<BudgetWithSpending>>(
      stream: _budgetStream,
      builder: (context, snapshot) {
        print('DEBUG: StreamBuilder state: ${snapshot.connectionState}, data: ${snapshot.data?.length ?? 0}');
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final budgets = snapshot.data ?? [];
        print('DEBUG: Final budgets count: ${budgets.length}');
        
        if (budgets.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 64,
                  color: AppColors.onSurfaceVariant,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'No budgets yet',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Create your first budget to start tracking your spending',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        
        return ListView.separated(
          itemCount: budgets.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final budgetWithSpending = budgets[index];
            return _buildBudgetTile(budgetWithSpending);
          },
        );
      },
    );
  }

  Widget _buildBudgetTile(BudgetWithSpending budgetWithSpending) {
    final budget = budgetWithSpending.budget;
    final spentAmount = budgetWithSpending.spentAmount;
    final remainingBudget = budgetWithSpending.remainingBudget;
    final usagePercentage = budgetWithSpending.usagePercentage;
    final statusColor = budgetWithSpending.statusColor;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Color(int.parse(budget.categoryColor.replaceAll('#', '0xFF'))),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      budget.categoryIcon,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        budget.categoryName,
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${budget.period.name.toUpperCase()} • ${budget.currency}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                  onPressed: () => _deleteBudget(budget.id),
                  tooltip: 'Delete',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Budget',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '${budget.currency} ${budget.amount.toStringAsFixed(2)}',
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Spent',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '${budget.currency} ${spentAmount.toStringAsFixed(2)}',
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Remaining',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '${budget.currency} ${remainingBudget.toStringAsFixed(2)}',
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: remainingBudget >= 0 ? AppColors.success : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '${usagePercentage.toStringAsFixed(1)}%',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: (usagePercentage / 100).clamp(0.0, 1.0),
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color(int.parse(statusColor.replaceAll('#', '0xFF'))),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 