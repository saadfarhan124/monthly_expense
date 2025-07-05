import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/transaction_model.dart';
import '../domain/transaction_repository.dart';
import '../domain/transaction_service.dart';
import '../../accounts/domain/account_model.dart';
import '../../accounts/domain/account_repository.dart';
import '../../accounts/domain/account_service.dart';
import '../../categories/domain/category_model.dart';
import '../../categories/domain/category_repository.dart';
import '../../categories/domain/category_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final TransactionService _transactionService = TransactionService(TransactionRepository(), AccountRepository());
  final AccountService _accountService = AccountService(AccountRepository());
  final CategoryService _categoryService = CategoryService(CategoryRepository());
  
  bool _showAddForm = false;
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  TransactionType _selectedType = TransactionType.expense;
  String? _selectedAccountId;
  String? _selectedCategoryId;

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _toggleAddForm() {
    setState(() => _showAddForm = !_showAddForm);
  }

  Future<void> _addTransaction() async {
    if (!_formKey.currentState!.validate() || _selectedAccountId == null || _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields'), backgroundColor: AppColors.warning),
      );
      return;
    }
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    final transaction = TransactionModel(
      id: '',
      accountId: _selectedAccountId!,
      categoryId: _selectedCategoryId!,
      amount: double.tryParse(_amountController.text.trim()) ?? 0.0,
      description: _descController.text.trim(),
      type: _selectedType,
      userId: user.uid,
      date: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    try {
      await _transactionService.addTransaction(transaction);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction added!'), backgroundColor: AppColors.success),
        );
        _amountController.clear();
        _descController.clear();
        setState(() => _showAddForm = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteTransaction(String id) async {
    await _transactionService.deleteTransaction(id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction deleted!'), backgroundColor: AppColors.error),
      );
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
                        tooltip: _showAddForm ? 'Cancel' : 'Add Transaction',
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
                              // Amount Field
                              StreamBuilder<List<Account>>(
                                stream: _accountService.getAccounts(user.uid),
                                builder: (context, snapshot) {
                                  final accounts = snapshot.data ?? [];
                                  final selectedAccount = accounts.firstWhere(
                                    (acc) => acc.id == _selectedAccountId,
                                    orElse: () => accounts.isNotEmpty ? accounts.first : Account(
                                      id: '',
                                      name: '',
                                      type: AccountType.bank,
                                      currency: 'USD',
                                      balance: 0,
                                      userId: '',
                                      createdAt: DateTime.now(),
                                      updatedAt: DateTime.now(),
                                    ),
                                  );
                                  
                                  return TextFormField(
                                    controller: _amountController,
                                    decoration: InputDecoration(
                                      labelText: 'Amount',
                                      prefixText: '${selectedAccount.currency} ',
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (v) => v == null || v.isEmpty ? 'Enter amount' : null,
                                  );
                                },
                              ),
                              const SizedBox(height: AppSpacing.md),
                              
                              // Description Field
                              TextFormField(
                                controller: _descController,
                                decoration: const InputDecoration(labelText: 'Description (Optional)'),
                                maxLines: 2,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              
                              // Type and Account Row
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<TransactionType>(
                                      value: _selectedType,
                                      items: TransactionType.values
                                          .map((e) => DropdownMenuItem(
                                                value: e,
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      e == TransactionType.expense 
                                                          ? Icons.remove_circle_outline 
                                                          : Icons.add_circle_outline,
                                                      color: e == TransactionType.expense 
                                                          ? AppColors.error 
                                                          : AppColors.success,
                                                      size: 16,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(e.name.toUpperCase()),
                                                  ],
                                                ),
                                              ))
                                          .toList(),
                                      onChanged: (v) => setState(() => _selectedType = v ?? TransactionType.expense),
                                      decoration: const InputDecoration(labelText: 'Type'),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: StreamBuilder<List<Account>>(
                                      stream: _accountService.getAccounts(user.uid),
                                      builder: (context, snapshot) {
                                        final accounts = snapshot.data ?? [];
                                                                                 if (accounts.isEmpty) {
                                           return DropdownButtonFormField<String>(
                                             value: null,
                                             items: [],
                                             onChanged: (value) {},
                                             decoration: const InputDecoration(
                                               labelText: 'Account',
                                               helperText: 'Add an account first',
                                             ),
                                           );
                                         }
                                        
                                        if (_selectedAccountId == null && accounts.isNotEmpty) {
                                          _selectedAccountId = accounts.first.id;
                                        }
                                        
                                                                                 return DropdownButtonFormField<String>(
                                           value: _selectedAccountId,
                                           items: accounts
                                               .map((acc) => DropdownMenuItem(
                                                     value: acc.id,
                                                     child: Row(
                                                       mainAxisSize: MainAxisSize.min,
                                                       children: [
                                                         Text(acc.icon),
                                                         const SizedBox(width: 8),
                                                         Flexible(
                                                           child: Text(
                                                             acc.name,
                                                             overflow: TextOverflow.ellipsis,
                                                           ),
                                                         ),
                                                       ],
                                                     ),
                                                   ))
                                               .toList(),
                                           onChanged: (v) => setState(() => _selectedAccountId = v),
                                           decoration: const InputDecoration(labelText: 'Account'),
                                         );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),
                              
                                                            // Category Selection
                              StreamBuilder<List<Category>>(
                                stream: _categoryService.getCategories(user.uid),
                                builder: (context, snapshot) {
                                  final categories = snapshot.data ?? [];
                                  if (categories.isEmpty) {
                                    return DropdownButtonFormField<String>(
                                      value: null,
                                      items: [],
                                      onChanged: (value) {},
                                      decoration: const InputDecoration(
                                        labelText: 'Category',
                                        helperText: 'Add categories first',
                                      ),
                                    );
                                  }
                                  
                                  if (_selectedCategoryId == null && categories.isNotEmpty) {
                                    _selectedCategoryId = categories.first.id;
                                  }
                                  
                                  return DropdownButtonFormField<String>(
                                    value: _selectedCategoryId,
                                    items: categories
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
                                  );
                                },
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              ElevatedButton(
                                onPressed: _addTransaction,
                                child: const Text('Add Transaction'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  Expanded(
                    child: StreamBuilder<List<TransactionModel>>(
                      stream: _transactionService.getTransactions(user.uid),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        
                        final transactions = snapshot.data ?? [];
                                                 if (transactions.isEmpty) {
                           return Container(
                             width: double.infinity,
                             padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
                             child: Column(
                               mainAxisAlignment: MainAxisAlignment.center,
                               children: [
                                 Container(
                                   width: 80,
                                   height: 80,
                                   decoration: BoxDecoration(
                                     color: AppColors.surface,
                                     borderRadius: BorderRadius.circular(40),
                                     border: Border.all(
                                       color: AppColors.border,
                                       width: 1,
                                     ),
                                   ),
                                   child: Icon(
                                     Icons.receipt_long_outlined,
                                     size: 36,
                                     color: AppColors.onSurfaceVariant,
                                   ),
                                 ),
                                 const SizedBox(height: AppSpacing.lg),
                                 Text(
                                   'No transactions yet',
                                   style: AppTextStyles.titleLarge.copyWith(
                                     color: AppColors.onSurface,
                                     fontWeight: FontWeight.w600,
                                   ),
                                   textAlign: TextAlign.center,
                                 ),
                                 const SizedBox(height: AppSpacing.md),
                                 Text(
                                   'Start tracking your expenses and income\nby adding your first transaction',
                                   style: AppTextStyles.bodyMedium.copyWith(
                                     color: AppColors.onSurfaceVariant,
                                     height: 1.4,
                                   ),
                                   textAlign: TextAlign.center,
                                 ),
                                 const SizedBox(height: AppSpacing.xl),
                                 ElevatedButton.icon(
                                   onPressed: _toggleAddForm,
                                   icon: const Icon(Icons.add),
                                   label: const Text('Add Transaction'),
                                   style: ElevatedButton.styleFrom(
                                     backgroundColor: AppColors.primary,
                                     foregroundColor: AppColors.onPrimary,
                                     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                   ),
                                 ),
                               ],
                             ),
                           );
                         }
                        
                        return ListView.separated(
                          itemCount: transactions.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final transaction = transactions[index];
                            return _buildTransactionTile(transaction);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTransactionTile(TransactionModel transaction) {
    final isExpense = transaction.type == TransactionType.expense;
    final amountColor = isExpense ? AppColors.error : AppColors.success;
    final amountPrefix = isExpense ? '-' : '+';
    
    return FutureBuilder<Category?>(
      future: _getCategory(transaction.categoryId),
      builder: (context, snapshot) {
        final category = snapshot.data;
        
        return FutureBuilder<Account?>(
          future: _getAccount(transaction.accountId),
          builder: (context, accountSnapshot) {
            final account = accountSnapshot.data;
            final currency = account?.currency ?? 'USD';
            
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: category != null 
                    ? Color(int.parse(category.color.replaceAll('#', '0xFF'))).withOpacity(0.1)
                    : amountColor.withOpacity(0.1),
                child: Text(
                  category?.icon ?? (isExpense ? '📄' : '💰'),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              title: Text(
                transaction.description.isNotEmpty 
                    ? transaction.description 
                    : (category?.name ?? 'Transaction'),
                style: AppTextStyles.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category?.name ?? 'Unknown Category',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    _formatDate(transaction.date),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$amountPrefix$currency ${transaction.amount.toStringAsFixed(2)}',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: amountColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                    onPressed: () => _deleteTransaction(transaction.id),
                    tooltip: 'Delete',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<Category?> _getCategory(String categoryId) async {
    try {
      final categories = await _categoryService.getCategories(FirebaseAuth.instance.currentUser!.uid).first;
      return categories.firstWhere((cat) => cat.id == categoryId);
    } catch (e) {
      return null;
    }
  }

  Future<Account?> _getAccount(String accountId) async {
    try {
      final accounts = await _accountService.getAccounts(FirebaseAuth.instance.currentUser!.uid).first;
      return accounts.firstWhere((acc) => acc.id == accountId);
    } catch (e) {
      return null;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final transactionDate = DateTime(date.year, date.month, date.day);
    
    if (transactionDate == today) {
      return 'Today';
    } else if (transactionDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
} 