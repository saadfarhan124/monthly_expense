import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/transaction_model.dart';
import '../domain/transaction_repository.dart';
import '../domain/transaction_service.dart';
import '../../accounts/domain/account_model.dart';
import '../../accounts/domain/account_repository.dart';
import '../../accounts/domain/account_service.dart';
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
  bool _showAddForm = false;
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  TransactionType _selectedType = TransactionType.expense;
  String? _selectedAccountId;
  String _selectedCategoryId = 'category1'; // Placeholder

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
    if (!_formKey.currentState!.validate() || _selectedAccountId == null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final transaction = TransactionModel(
      id: '',
      accountId: _selectedAccountId!,
      categoryId: _selectedCategoryId,
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
                    StreamBuilder<List<Account>>(
                      stream: _accountService.getAccounts(user.uid),
                      builder: (context, snapshot) {
                        final accounts = snapshot.data ?? [];
                        if (accounts.isEmpty) {
                          return const Text('Add an account first.');
                        }
                        // Set default selected account if not set
                        if (_selectedAccountId == null && accounts.isNotEmpty) {
                          _selectedAccountId = accounts.first.id;
                        }
                        return Card(
                          color: AppColors.surfaceVariant,
                          child: Padding(
                            padding: AppSpacing.paddingLg,
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  TextFormField(
                                    controller: _amountController,
                                    decoration: const InputDecoration(labelText: 'Amount'),
                                    keyboardType: TextInputType.number,
                                    validator: (v) => v == null || v.isEmpty ? 'Enter amount' : null,
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  TextFormField(
                                    controller: _descController,
                                    decoration: const InputDecoration(labelText: 'Description'),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: DropdownButtonFormField<TransactionType>(
                                          value: _selectedType,
                                          items: TransactionType.values
                                              .map((e) => DropdownMenuItem(
                                                    value: e,
                                                    child: Text(e.name.toUpperCase()),
                                                  ))
                                              .toList(),
                                          onChanged: (v) => setState(() => _selectedType = v ?? TransactionType.expense),
                                          decoration: const InputDecoration(labelText: 'Type'),
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.md),
                                      Expanded(
                                        child: DropdownButtonFormField<String>(
                                          value: _selectedAccountId,
                                          items: accounts
                                              .map((acc) => DropdownMenuItem(
                                                    value: acc.id,
                                                    child: Text(acc.displayName),
                                                  ))
                                              .toList(),
                                          onChanged: (v) => setState(() => _selectedAccountId = v),
                                          decoration: const InputDecoration(labelText: 'Account'),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  DropdownButtonFormField<String>(
                                    value: _selectedCategoryId,
                                    items: const [
                                      DropdownMenuItem(value: 'category1', child: Text('Category 1')),
                                    ],
                                    onChanged: (v) => setState(() => _selectedCategoryId = v ?? 'category1'),
                                    decoration: const InputDecoration(labelText: 'Category'),
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
                        );
                      },
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  Expanded(
                    child: StreamBuilder<List<TransactionModel>>(
                      stream: _transactionService.getTransactions(user.uid),
                      builder: (context, snapshot) {
                        print('StreamBuilder state: ${snapshot.connectionState}');
                        print('StreamBuilder data length: ${snapshot.data?.length ?? 0}');
                        print('User ID: ${user.uid}');
                        
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final txs = snapshot.data ?? [];
                        if (txs.isEmpty) {
                          return const Center(child: Text('No transactions yet.'));
                        }
                        return ListView.separated(
                          itemCount: txs.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, i) {
                            final tx = txs[i];
                            return ListTile(
                              leading: Icon(
                                tx.type == TransactionType.expense ? Icons.remove_circle : Icons.add_circle,
                                color: tx.type == TransactionType.expense ? AppColors.error : AppColors.success,
                              ),
                              title: Text('${tx.amount}', style: AppTextStyles.titleMedium),
                              subtitle: Text('${tx.description} • ${tx.type.name.toUpperCase()}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                                onPressed: () => _deleteTransaction(tx.id),
                                tooltip: 'Delete',
                              ),
                            );
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
} 