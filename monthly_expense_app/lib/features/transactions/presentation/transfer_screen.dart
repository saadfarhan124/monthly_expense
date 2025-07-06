import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/transfer_service.dart';
import '../domain/transaction_repository.dart';
import '../../accounts/domain/account_repository.dart';
import '../../accounts/domain/account_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/animated_button.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  late final TransferService _transferService;
  late final AccountRepository _accountRepository;
  
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _exchangeRateController = TextEditingController();
  final _transferFeeController = TextEditingController();
  
  String? _selectedFromAccountId;
  String? _selectedToAccountId;
  List<Account> _accounts = [];
  bool _isLoading = false;
  bool _showExchangeRate = false;
  bool _showTransferFee = false;

  @override
  void initState() {
    super.initState();
    _transferService = TransferService(
      TransactionRepository(),
      AccountRepository(),
    );
    _accountRepository = AccountRepository();
    _loadAccounts();
    
    // Add listeners to update summary in real-time
    _amountController.addListener(() {
      if (mounted) setState(() {});
    });
    _exchangeRateController.addListener(() {
      if (mounted) setState(() {});
    });
    _transferFeeController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _exchangeRateController.dispose();
    _transferFeeController.dispose();
    super.dispose();
  }

  Future<void> _loadAccounts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _accountRepository.getAccounts(user.uid).listen((accounts) {
      if (mounted) {
        setState(() {
          _accounts = accounts;
        });
      }
    });
  }

  void _onFromAccountChanged(String? accountId) {
    setState(() {
      _selectedFromAccountId = accountId;
      _checkIfCrossCurrency();
    });
  }

  void _onToAccountChanged(String? accountId) {
    setState(() {
      _selectedToAccountId = accountId;
      _checkIfCrossCurrency();
    });
  }

  void _checkIfCrossCurrency() {
    if (_selectedFromAccountId != null && _selectedToAccountId != null) {
      final fromAccount = _accounts.firstWhere(
        (a) => a.id == _selectedFromAccountId,
        orElse: () => Account(
          id: '',
          name: '',
          currency: '',
          balance: 0,
          type: AccountType.cash,
          userId: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      
      final toAccount = _accounts.firstWhere(
        (a) => a.id == _selectedToAccountId,
        orElse: () => Account(
          id: '',
          name: '',
          currency: '',
          balance: 0,
          type: AccountType.cash,
          userId: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      setState(() {
        _showExchangeRate = fromAccount.currency != toAccount.currency;
        if (!_showExchangeRate) {
          _exchangeRateController.clear();
        }
      });
    }
  }

  Future<void> _createTransfer() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedFromAccountId == null || _selectedToAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both accounts'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedFromAccountId == _selectedToAccountId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot transfer to the same account'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final amount = double.parse(_amountController.text);
      final description = _descriptionController.text;
      final exchangeRate = _showExchangeRate && _exchangeRateController.text.isNotEmpty
          ? double.parse(_exchangeRateController.text)
          : null;
      final transferFee = _showTransferFee && _transferFeeController.text.isNotEmpty
          ? double.parse(_transferFeeController.text)
          : null;

      await _transferService.createTransfer(
        userId: user.uid,
        fromAccountId: _selectedFromAccountId!,
        toAccountId: _selectedToAccountId!,
        amount: amount,
        description: description,
        exchangeRate: exchangeRate,
        transferFee: transferFee,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transfer completed successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        
        // Clear form
        _amountController.clear();
        _descriptionController.clear();
        _exchangeRateController.clear();
        _transferFeeController.clear();
        setState(() {
          _selectedFromAccountId = null;
          _selectedToAccountId = null;
          _showExchangeRate = false;
          _showTransferFee = false;
        });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer Money'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
      ),
      body: Padding(
        padding: AppSpacing.paddingHorizontalLg,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.lg),
              
              // From Account
              _buildAccountDropdown(
                label: 'From Account',
                value: _selectedFromAccountId,
                onChanged: _onFromAccountChanged,
                accounts: _accounts,
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              // To Account
              _buildAccountDropdown(
                label: 'To Account',
                value: _selectedToAccountId,
                onChanged: _onToAccountChanged,
                accounts: _accounts,
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              // Amount
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
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
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.description),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              // Exchange Rate (for cross-currency transfers)
              if (_showExchangeRate) ...[
                TextFormField(
                  controller: _exchangeRateController,
                  decoration: const InputDecoration(
                    labelText: 'Exchange Rate',
                    prefixIcon: Icon(Icons.currency_exchange),
                    helperText: 'How much of the destination currency equals 1 unit of source currency',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Exchange rate is required for cross-currency transfers';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    if (double.parse(value) <= 0) {
                      return 'Exchange rate must be greater than 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              
              // Transfer Fee (optional)
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _transferFeeController,
                                             decoration: const InputDecoration(
                         labelText: 'Transfer Fee (Optional)',
                         prefixIcon: Icon(Icons.payment),
                       ),
                      keyboardType: TextInputType.number,
                      enabled: _showTransferFee,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          if (double.parse(value) < 0) {
                            return 'Fee cannot be negative';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Switch(
                    value: _showTransferFee,
                    onChanged: (value) {
                      setState(() {
                        _showTransferFee = value;
                        if (!value) {
                          _transferFeeController.clear();
                        }
                      });
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: AppSpacing.xl),
              
              // Transfer Button
              AnimatedButton(
                text: _isLoading ? 'Processing...' : 'Transfer Money',
                icon: _isLoading ? Icons.hourglass_empty : Icons.send,
                backgroundColor: AppColors.primary,
                hapticType: HapticFeedbackType.medium,
                onPressed: _isLoading ? null : _createTransfer,
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              // Transfer Summary
              if (_selectedFromAccountId != null && _selectedToAccountId != null) ...[
                _buildTransferSummary(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountDropdown({
    required String label,
    required String? value,
    required Function(String?) onChanged,
    required List<Account> accounts,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: accounts.map((account) {
        return DropdownMenuItem(
          value: account.id,
          child: Text('${account.icon} ${account.name} (${account.currency} ${account.balance.toStringAsFixed(2)})'),
        );
      }).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) => value == null ? 'Please select an account' : null,
    );
  }

  Widget _buildTransferSummary() {
    final fromAccount = _accounts.firstWhere(
      (a) => a.id == _selectedFromAccountId,
      orElse: () => Account(
        id: '',
        name: '',
        currency: '',
        balance: 0,
        type: AccountType.cash,
        userId: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    
    final toAccount = _accounts.firstWhere(
      (a) => a.id == _selectedToAccountId,
      orElse: () => Account(
        id: '',
        name: '',
        currency: '',
        balance: 0,
        type: AccountType.cash,
        userId: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final exchangeRate = double.tryParse(_exchangeRateController.text);
    final transferFee = double.tryParse(_transferFeeController.text) ?? 0.0;
    
    final isCrossCurrency = fromAccount.currency != toAccount.currency;
    final destinationAmount = isCrossCurrency && exchangeRate != null
        ? amount * exchangeRate
        : amount;
    final totalDeducted = amount + transferFee;

    return Card(
      color: AppColors.surfaceVariant,
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transfer Summary',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildSummaryRow('From', '${fromAccount.currency} $totalDeducted'),
            _buildSummaryRow('To', '${toAccount.currency} ${destinationAmount.toStringAsFixed(2)}'),
            if (transferFee > 0) _buildSummaryRow('Fee', '${fromAccount.currency} $transferFee'),
            if (isCrossCurrency && exchangeRate != null)
              _buildSummaryRow('Exchange Rate', '1 ${fromAccount.currency} = ${exchangeRate.toStringAsFixed(4)} ${toAccount.currency}'),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
} 