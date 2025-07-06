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
import '../../../core/widgets/animated_button.dart';
import 'transfer_screen.dart';
import 'edit_transaction_screen.dart';

enum SortOrder { newest, oldest }
enum FilterType { all, expenses, income, transfers, lending, borrowing }

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final TransactionService _transactionService = TransactionService(TransactionRepository());
  final AccountService _accountService = AccountService(AccountRepository());
  final CategoryService _categoryService = CategoryService(CategoryRepository());
  
  bool _showAddForm = false;
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  TransactionType _selectedType = TransactionType.expense;
  String? _selectedAccountId;
  String? _selectedCategoryId;

  // Cache for accounts and categories
  List<Account> _cachedAccounts = [];
  List<Category> _cachedCategories = [];
  bool _isAccountsLoaded = false;
  bool _isCategoriesLoaded = false;

  // Filtering and sorting
  SortOrder _sortOrder = SortOrder.newest;
  FilterType _filterType = FilterType.all;
  String? _selectedCategoryFilter;
  String? _selectedAccountFilter;

  // Search
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCachedData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCachedData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Load accounts and categories once and cache them
    _accountService.getAccounts(user.uid).listen((accounts) {
      if (mounted) {
        setState(() {
          _cachedAccounts = accounts;
          _isAccountsLoaded = true;
        });
      }
    });

    _categoryService.getCategories(user.uid).listen((categories) {
      if (mounted) {
        setState(() {
          _cachedCategories = categories;
          _isCategoriesLoaded = true;
        });
      }
    });
  }

  Account? _getCachedAccount(String accountId) {
    try {
      return _cachedAccounts.firstWhere((acc) => acc.id == accountId);
    } catch (e) {
      return null;
    }
  }

  Category? _getCachedCategory(String categoryId) {
    try {
      return _cachedCategories.firstWhere((cat) => cat.id == categoryId);
    } catch (e) {
      return null;
    }
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

  void _editTransaction(TransactionModel transaction) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditTransactionScreen(transaction: transaction),
      ),
    );
  }

  List<TransactionModel> _filterAndSortTransactions(List<TransactionModel> transactions) {
    // Apply filters
    var filtered = transactions.where((t) {
      // Type filter
      if (_filterType == FilterType.expenses && t.type != TransactionType.expense) return false;
      if (_filterType == FilterType.income && t.type != TransactionType.income) return false;
      if (_filterType == FilterType.transfers && t.type != TransactionType.transfer) return false;
      if (_filterType == FilterType.lending && t.type != TransactionType.lend) return false;
      if (_filterType == FilterType.borrowing && t.type != TransactionType.borrow) return false;
      
      // Category filter
      if (_selectedCategoryFilter != null && t.categoryId != _selectedCategoryFilter) return false;
      
      // Account filter
      if (_selectedAccountFilter != null && t.accountId != _selectedAccountFilter) return false;
      
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final searchLower = _searchQuery.toLowerCase();
        final description = t.description.toLowerCase();
        final category = _getCachedCategory(t.categoryId)?.name.toLowerCase() ?? '';
        final account = _getCachedAccount(t.accountId)?.name.toLowerCase() ?? '';
        
        if (!description.contains(searchLower) && 
            !category.contains(searchLower) && 
            !account.contains(searchLower)) {
          return false;
        }
      }
      
      return true;
    }).toList();

    // Apply sorting
    switch (_sortOrder) {
      case SortOrder.newest:
        filtered.sort((a, b) => b.date.compareTo(a.date));
        break;
      case SortOrder.oldest:
        filtered.sort((a, b) => a.date.compareTo(b.date));
        break;
    }

    return filtered;
  }

  Map<String, List<TransactionModel>> _groupTransactionsByDate(List<TransactionModel> transactions) {
    final grouped = <String, List<TransactionModel>>{};
    
    for (final transaction in transactions) {
      final dateKey = _formatDateForGrouping(transaction.date);
      grouped.putIfAbsent(dateKey, () => []).add(transaction);
    }
    
    return grouped;
  }

  String _formatDateForGrouping(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final transactionDate = DateTime(date.year, date.month, date.day);
    
    if (transactionDate == today) {
      return 'Today';
    } else if (transactionDate == yesterday) {
      return 'Yesterday';
    } else if (transactionDate.isAfter(today.subtract(const Duration(days: 7)))) {
      return 'This Week';
    } else if (transactionDate.isAfter(today.subtract(const Duration(days: 30)))) {
      return 'This Month';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      body: user == null
          ? const Center(child: Text('Not signed in'))
          : Column(
              children: [
                // Header with search and filters
                _buildHeader(),
                
                // Add transaction form
                if (_showAddForm) _buildAddForm(),
                
                // Transactions list
                Expanded(
                  child: StreamBuilder<List<TransactionModel>>(
                    stream: _transactionService.getTransactions(user.uid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      final transactions = snapshot.data ?? [];
                      if (transactions.isEmpty) {
                        return _buildEmptyState();
                      }
                      
                      final filteredTransactions = _filterAndSortTransactions(transactions);
                      final groupedTransactions = _groupTransactionsByDate(filteredTransactions);
                      
                      if (groupedTransactions.isEmpty) {
                        return _buildNoResultsState();
                      }
                      
                      return _buildTransactionsList(groupedTransactions);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.border.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search transactions...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: AppColors.surfaceVariant,
            ),
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          // Filter and sort controls
          Row(
            children: [
              // Filter dropdown
              Expanded(
                flex: 2,
                child: _buildFilterDropdown(),
              ),
              const SizedBox(width: AppSpacing.xs),
              // Sort dropdown
              Expanded(
                flex: 2,
                child: _buildSortDropdown(),
              ),
              const SizedBox(width: AppSpacing.xs),
              // Transfer button
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TransferScreen()),
                  );
                },
                icon: const Icon(Icons.swap_horiz_outlined),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: AppColors.onPrimary,
                ),
                tooltip: 'Transfer Money',
              ),
              const SizedBox(width: AppSpacing.xs),
              // Add button
              IconButton(
                onPressed: _toggleAddForm,
                icon: Icon(_showAddForm ? Icons.close : Icons.add),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                ),
                tooltip: 'Add Transaction',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return DropdownButtonFormField<FilterType>(
      value: _filterType,
      decoration: InputDecoration(
        labelText: 'Filter',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        isDense: true,
      ),
      items: FilterType.values.map((type) => DropdownMenuItem(
        value: type,
        child: Text(
          _getFilterDisplayText(type),
          style: const TextStyle(fontSize: 12),
          overflow: TextOverflow.ellipsis,
        ),
      )).toList(),
      onChanged: (value) => setState(() => _filterType = value ?? FilterType.all),
    );
  }

  String _getFilterDisplayText(FilterType type) {
    switch (type) {
      case FilterType.all:
        return 'ALL';
      case FilterType.expenses:
        return 'EXP';
      case FilterType.income:
        return 'INC';
      case FilterType.transfers:
        return 'TRF';
      case FilterType.lending:
        return 'LND';
      case FilterType.borrowing:
        return 'BRW';
    }
  }

  String _getSortDisplayText(SortOrder order) {
    switch (order) {
      case SortOrder.newest:
        return 'NEW';
      case SortOrder.oldest:
        return 'OLD';
    }
  }

  Widget _buildSortDropdown() {
    return DropdownButtonFormField<SortOrder>(
      value: _sortOrder,
      decoration: InputDecoration(
        labelText: 'Sort',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        isDense: true,
      ),
      items: SortOrder.values.map((order) => DropdownMenuItem(
        value: order,
        child: Text(
          _getSortDisplayText(order),
          style: const TextStyle(fontSize: 12),
          overflow: TextOverflow.ellipsis,
        ),
      )).toList(),
      onChanged: (value) => setState(() => _sortOrder = value ?? SortOrder.newest),
    );
  }

  Widget _buildAddForm() {
    return Card(
      margin: AppSpacing.paddingLg,
      color: AppColors.surfaceVariant,
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Amount Field
              _buildAmountField(),
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
                          .where((e) => e != TransactionType.transfer && e != TransactionType.lend && e != TransactionType.borrow) // Exclude transfer, lend, borrow from regular transactions
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
              const SizedBox(height: AppSpacing.lg),
              AnimatedButton(
                text: 'Add Transaction',
                icon: Icons.add,
                backgroundColor: AppColors.primary,
                hapticType: HapticFeedbackType.medium,
                onPressed: _addTransaction,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountField() {
    if (!_isAccountsLoaded) {
      return TextFormField(
        decoration: const InputDecoration(
          labelText: 'Amount',
          prefixText: 'USD ',
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        enabled: false,
      );
    }

    final selectedAccount = _cachedAccounts.firstWhere(
      (acc) => acc.id == _selectedAccountId,
      orElse: () => _cachedAccounts.isNotEmpty ? _cachedAccounts.first : Account(
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
      validator: (v) => v == null || v.isEmpty ? 'Enter amount' : null,
    );
  }

  Widget _buildAccountDropdown() {
    if (!_isAccountsLoaded) {
      return DropdownButtonFormField<String>(
        value: null,
        items: [],
        onChanged: null,
        decoration: const InputDecoration(
          labelText: 'Account',
          helperText: 'Loading accounts...',
        ),
      );
    }

    if (_cachedAccounts.isEmpty) {
      return DropdownButtonFormField<String>(
        value: null,
        items: [],
        onChanged: null,
        decoration: const InputDecoration(
          labelText: 'Account',
          helperText: 'Add an account first',
        ),
      );
    }

    if (_selectedAccountId == null && _cachedAccounts.isNotEmpty) {
      _selectedAccountId = _cachedAccounts.first.id;
    }

    return DropdownButtonFormField<String>(
      value: _selectedAccountId,
      items: _cachedAccounts
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

    if (_selectedCategoryId == null && _cachedCategories.isNotEmpty) {
      _selectedCategoryId = _cachedCategories.first.id;
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
    );
  }

  Widget _buildTransactionsList(Map<String, List<TransactionModel>> groupedTransactions) {
    return ListView.builder(
      padding: AppSpacing.paddingLg,
      itemCount: groupedTransactions.length,
      itemBuilder: (context, index) {
        final dateKey = groupedTransactions.keys.elementAt(index);
        final transactions = groupedTransactions[dateKey]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Text(
                dateKey,
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            // Transactions for this date
            ...transactions.map((transaction) => _buildTransactionTile(transaction)),
            const SizedBox(height: AppSpacing.md),
          ],
        );
      },
    );
  }

  Widget _buildTransactionTile(TransactionModel transaction) {
    final isExpense = transaction.type == TransactionType.expense;
    final isLend = transaction.type == TransactionType.lend;
    final isBorrow = transaction.type == TransactionType.borrow;
    
    Color amountColor;
    String amountPrefix;
    
    if (isExpense) {
      amountColor = AppColors.error;
      amountPrefix = '-';
    } else if (isLend) {
      amountColor = AppColors.warning;
      amountPrefix = '-';
    } else if (isBorrow) {
      amountColor = AppColors.success;
      amountPrefix = '+';
    } else {
      amountColor = AppColors.success;
      amountPrefix = '+';
    }
    
    // Use cached data
    final account = _getCachedAccount(transaction.accountId);
    final category = _getCachedCategory(transaction.categoryId);
    final currency = account?.currency ?? 'USD';
    
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: category != null 
              ? Color(int.parse(category.color.replaceAll('#', '0xFF'))).withValues(alpha: 0.1)
              : amountColor.withValues(alpha: 0.1),
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
              account?.name ?? 'Unknown Account',
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
            if (transaction.type != TransactionType.transfer && transaction.type != TransactionType.lend && transaction.type != TransactionType.borrow) ...[
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 18),
                onPressed: () => _editTransaction(transaction),
                tooltip: 'Edit',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              const SizedBox(width: 4),
            ],
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 18),
              onPressed: () => _deleteTransaction(transaction.id),
              tooltip: 'Delete',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
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
          AnimatedButton(
            text: 'Add Transaction',
            icon: Icons.add,
            backgroundColor: AppColors.primary,
            hapticType: HapticFeedbackType.medium,
            onPressed: _toggleAddForm,
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_outlined,
            size: 64,
            color: AppColors.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'No transactions found',
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Try adjusting your filters or search terms',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
} 