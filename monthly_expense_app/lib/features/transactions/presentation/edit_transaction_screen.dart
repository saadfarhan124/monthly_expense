import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/transaction_model.dart';
import '../domain/transaction_service.dart';
import '../domain/transaction_repository.dart';
import '../../accounts/domain/account_repository.dart';
import '../../accounts/domain/account_model.dart';
import '../../categories/domain/category_repository.dart';
import '../../categories/domain/category_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/animated_button.dart';

class EditTransactionScreen extends StatefulWidget {
  final TransactionModel transaction;

  const EditTransactionScreen({
    super.key,
    required this.transaction,
  });

  @override
  State<EditTransactionScreen> createState() => _EditTransactionScreenState();
}

class _EditTransactionScreenState extends State<EditTransactionScreen> {
  late final TransactionService _transactionService;
  late final AccountRepository _accountRepository;
  late final CategoryRepository _categoryRepository;
  
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  TransactionType _selectedType = TransactionType.expense;
  String? _selectedAccountId;
  String? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  
  List<Account> _accounts = [];
  List<Category> _categories = [];
  bool _isLoading = false;
  bool _isDataLoaded = false;

  @override
  void initState() {
    super.initState();
    _transactionService = TransactionService(TransactionRepository());
    _accountRepository = AccountRepository();
    _categoryRepository = CategoryRepository();
    
    // Initialize form with existing transaction data
    _amountController.text = widget.transaction.amount.toString();
    _descriptionController.text = widget.transaction.description;
    _selectedType = widget.transaction.type;
    _selectedAccountId = widget.transaction.accountId;
    _selectedCategoryId = widget.transaction.categoryId;
    _selectedDate = widget.transaction.date;
    
    _loadData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Load accounts and categories
    _accountRepository.getAccounts(user.uid).listen((accounts) {
      if (mounted) {
        setState(() {
          _accounts = accounts;
        });
      }
    });

    _categoryRepository.getCategories(user.uid).listen((categories) {
      if (mounted) {
        setState(() {
          _categories = categories;
          _isDataLoaded = true;
        });
      }
    });
  }

  Future<void> _updateTransaction() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedAccountId == null || _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both account and category'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final updatedTransaction = widget.transaction.copyWith(
        accountId: _selectedAccountId!,
        categoryId: _selectedCategoryId!,
        amount: double.parse(_amountController.text),
        description: _descriptionController.text,
        type: _selectedType,
        date: _selectedDate,
        updatedAt: DateTime.now(),
      );

      await _transactionService.updateTransaction(updatedTransaction);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Transaction'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteTransaction,
              tooltip: 'Delete Transaction',
            ),
        ],
      ),
      body: !_isDataLoaded
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: AppSpacing.paddingHorizontalLg,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.lg),
                    
                    // Amount Field
                    _buildAmountField(),
                    
                    const SizedBox(height: AppSpacing.md),
                    
                    // Description Field
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 2,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: AppSpacing.md),
                    
                    // Date Field
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: Text(
                        'Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        style: AppTextStyles.bodyMedium,
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: _selectDate,
                    ),
                    
                    const SizedBox(height: AppSpacing.md),
                    
                    // Type and Account Row
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<TransactionType>(
                            value: _selectedType,
                            items: TransactionType.values
                                .where((e) => e != TransactionType.transfer) // Exclude transfer from editing
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
                          child: _buildAccountDropdown(),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: AppSpacing.md),
                    
                    // Category Selection
                    _buildCategoryDropdown(),
                    
                    const SizedBox(height: AppSpacing.xl),
                    
                    // Update Button
                    AnimatedButton(
                      text: _isLoading ? 'Updating...' : 'Update Transaction',
                      icon: _isLoading ? Icons.hourglass_empty : Icons.save,
                      backgroundColor: AppColors.primary,
                      hapticType: HapticFeedbackType.medium,
                      onPressed: _isLoading ? null : _updateTransaction,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAccountDropdown() {
    if (_accounts.isEmpty) {
      return DropdownButtonFormField<String>(
        value: null,
        items: [],
        onChanged: null,
        decoration: const InputDecoration(
          labelText: 'Account',
          helperText: 'No accounts available',
        ),
      );
    }

    return DropdownButtonFormField<String>(
      value: _selectedAccountId,
      items: _accounts.map((acc) => DropdownMenuItem(
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
      )).toList(),
      onChanged: (v) => setState(() => _selectedAccountId = v),
      decoration: const InputDecoration(labelText: 'Account'),
      validator: (value) => value == null ? 'Please select an account' : null,
    );
  }

  Widget _buildAmountField() {
    if (_accounts.isEmpty) {
      return TextFormField(
        decoration: const InputDecoration(
          labelText: 'Amount',
          prefixText: 'USD ',
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        enabled: false,
      );
    }

    final selectedAccount = _accounts.firstWhere(
      (acc) => acc.id == _selectedAccountId,
      orElse: () => _accounts.isNotEmpty ? _accounts.first : Account(
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
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter an amount';
        }
        if (double.tryParse(value) == null) {
          return 'Please enter a valid number';
        }
        if (double.parse(value) <= 0) {
          return 'Amount must be greater than 0';
        }
        return null;
      },
    );
  }

  Widget _buildCategoryDropdown() {
    if (_categories.isEmpty) {
      return DropdownButtonFormField<String>(
        value: null,
        items: [],
        onChanged: null,
        decoration: const InputDecoration(
          labelText: 'Category',
          helperText: 'No categories available',
        ),
      );
    }

    return DropdownButtonFormField<String>(
      value: _selectedCategoryId,
      items: _categories.map((cat) => DropdownMenuItem(
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
      )).toList(),
      onChanged: (v) => setState(() => _selectedCategoryId = v),
      decoration: const InputDecoration(labelText: 'Category'),
      validator: (value) => value == null ? 'Please select a category' : null,
    );
  }

  Future<void> _deleteTransaction() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text('Are you sure you want to delete this transaction? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      
      try {
        await _transactionService.deleteTransaction(widget.transaction.id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transaction deleted successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }
} 