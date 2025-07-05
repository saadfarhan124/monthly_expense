import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/account_model.dart';
import '../domain/account_repository.dart';
import '../domain/account_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  final AccountService _accountService = AccountService(AccountRepository());
  bool _showAddForm = false;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  String _selectedCurrency = 'USD';
  AccountType _selectedType = AccountType.cash;

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  void _toggleAddForm() {
    setState(() => _showAddForm = !_showAddForm);
  }

  Future<void> _addAccount() async {
    if (!_formKey.currentState!.validate()) {
      print('Form validation failed');
      return;
    }
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('No user found');
      return;
    }
    
    try {
      final account = Account(
        id: '',
        name: _nameController.text.trim(),
        currency: _selectedCurrency,
        balance: double.tryParse(_balanceController.text.trim()) ?? 0.0,
        type: _selectedType,
        userId: user.uid,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      print('Adding account: ${account.name} with balance: ${account.balance}');
      await _accountService.addAccount(account);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account added!'), backgroundColor: AppColors.success),
        );
        _nameController.clear();
        _balanceController.clear();
        setState(() => _showAddForm = false);
      }
    } catch (e) {
      print('Error adding account: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding account: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteAccount(String id) async {
    await _accountService.deleteAccount(id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account deleted!'), backgroundColor: AppColors.error),
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
                        tooltip: _showAddForm ? 'Cancel' : 'Add Account',
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
                              TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(labelText: 'Account Name'),
                                validator: (v) => v == null || v.isEmpty ? 'Enter a name' : null,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              TextFormField(
                                controller: _balanceController,
                                decoration: const InputDecoration(labelText: 'Initial Balance'),
                                keyboardType: TextInputType.number,
                                validator: (v) => v == null || v.isEmpty ? 'Enter an initial balance' : null,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: _selectedCurrency,
                                      items: const [
                                        DropdownMenuItem(value: 'USD', child: Text('USD')),
                                        DropdownMenuItem(value: 'PKR', child: Text('PKR')),
                                        DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                                      ],
                                      onChanged: (v) => setState(() => _selectedCurrency = v ?? 'USD'),
                                      decoration: const InputDecoration(labelText: 'Currency'),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: DropdownButtonFormField<AccountType>(
                                      value: _selectedType,
                                      items: AccountType.values
                                          .map((e) => DropdownMenuItem(
                                                value: e,
                                                child: Text(e.name.toUpperCase()),
                                              ))
                                          .toList(),
                                      onChanged: (v) => setState(() => _selectedType = v ?? AccountType.cash),
                                      decoration: const InputDecoration(labelText: 'Type'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              ElevatedButton(
                                onPressed: () {
                                  print('Add account button pressed');
                                  _addAccount();
                                },
                                child: const Text('Add Account'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  Expanded(
                    child: StreamBuilder<List<Account>>(
                      stream: _accountService.getAccounts(user.uid),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final accounts = snapshot.data ?? [];
                        if (accounts.isEmpty) {
                          return const Center(child: Text('No accounts yet.'));
                        }
                        return ListView.separated(
                          itemCount: accounts.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, i) {
                            final acc = accounts[i];
                            return ListTile(
                              leading: Text(acc.icon, style: const TextStyle(fontSize: 24)),
                              title: Text(acc.name, style: AppTextStyles.titleMedium),
                              subtitle: Text('${acc.currency} • ${acc.type.name.toUpperCase()}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                                onPressed: () => _deleteAccount(acc.id),
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