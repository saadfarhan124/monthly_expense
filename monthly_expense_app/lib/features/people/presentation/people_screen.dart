import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/person_service.dart';
import '../domain/person_model.dart';
import '../domain/person_repository.dart';
import '../../accounts/domain/account_repository.dart';
import '../../accounts/domain/account_model.dart';
import '../../transactions/domain/transaction_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/animated_button.dart';

class PeopleScreen extends StatefulWidget {
  const PeopleScreen({super.key});

  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  late final PersonService _personService;
  late final AccountRepository _accountRepository;
  
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String? _selectedPersonId;
  String? _selectedAccountId;
  List<Person> _people = [];
  List<Account> _accounts = [];
  bool _isLoading = false;
  bool _showAddForm = false;
  bool _showLendForm = false;
  bool _showBorrowForm = false;

  @override
  void initState() {
    super.initState();
    _personService = PersonService(
      PersonRepository(),
      TransactionRepository(),
      AccountRepository(),
    );
    _accountRepository = AccountRepository();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _personService.getPeople(user.uid).listen((people) {
      if (mounted) {
        setState(() {
          _people = people;
        });
      }
    });

    _accountRepository.getAccounts(user.uid).listen((accounts) {
      if (mounted) {
        setState(() {
          _accounts = accounts;
        });
      }
    });
  }

  void _toggleAddForm() {
    setState(() {
      _showAddForm = !_showAddForm;
      if (!_showAddForm) {
        _nameController.clear();
      }
    });
  }

  void _toggleLendForm() {
    setState(() {
      _showLendForm = !_showLendForm;
      if (!_showLendForm) {
        _amountController.clear();
        _descriptionController.clear();
        _selectedPersonId = null;
        _selectedAccountId = null;
      }
    });
  }

  void _toggleBorrowForm() {
    setState(() {
      _showBorrowForm = !_showBorrowForm;
      if (!_showBorrowForm) {
        _amountController.clear();
        _descriptionController.clear();
        _selectedPersonId = null;
        _selectedAccountId = null;
      }
    });
  }

  Future<void> _addPerson() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final person = Person(
        id: '',
        name: _nameController.text.trim(),
        icon: '👤',
        color: '#6366F1',
        userId: user.uid,
        balance: 0.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _personService.addPerson(person);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Person added successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        _nameController.clear();
        setState(() => _showAddForm = false);
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

  Future<void> _lendMoney() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedPersonId == null || _selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both person and account'),
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

      await _personService.lendMoney(
        userId: user.uid,
        accountId: _selectedAccountId!,
        personId: _selectedPersonId!,
        amount: amount,
        description: description,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Money lent successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        _amountController.clear();
        _descriptionController.clear();
        setState(() {
          _selectedPersonId = null;
          _selectedAccountId = null;
          _showLendForm = false;
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

  Future<void> _borrowMoney() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedPersonId == null || _selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both person and account'),
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

      await _personService.borrowMoney(
        userId: user.uid,
        accountId: _selectedAccountId!,
        personId: _selectedPersonId!,
        amount: amount,
        description: description,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Money borrowed successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        _amountController.clear();
        _descriptionController.clear();
        setState(() {
          _selectedPersonId = null;
          _selectedAccountId = null;
          _showBorrowForm = false;
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
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
        actions: [
          IconButton(
            onPressed: _toggleAddForm,
            icon: Icon(_showAddForm ? Icons.close : Icons.add),
            tooltip: 'Add Person',
          ),
        ],
      ),
      body: Column(
        children: [
          // Action buttons
          if (!_showAddForm && !_showLendForm && !_showBorrowForm)
            Container(
              padding: AppSpacing.paddingLg,
              child: Row(
                children: [
                  Expanded(
                    child: AnimatedButton(
                      text: 'Lend Money',
                      icon: Icons.arrow_upward,
                      backgroundColor: AppColors.success,
                      hapticType: HapticFeedbackType.medium,
                      onPressed: _toggleLendForm,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AnimatedButton(
                      text: 'Borrow Money',
                      icon: Icons.arrow_downward,
                      backgroundColor: AppColors.warning,
                      hapticType: HapticFeedbackType.medium,
                      onPressed: _toggleBorrowForm,
                    ),
                  ),
                ],
              ),
            ),
          
          // Add person form
          if (_showAddForm) _buildAddPersonForm(),
          
          // Lend money form
          if (_showLendForm) _buildLendForm(),
          
          // Borrow money form
          if (_showBorrowForm) _buildBorrowForm(),
          
          // People list
          Expanded(
            child: _people.isEmpty
                ? _buildEmptyState()
                : _buildPeopleList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAddPersonForm() {
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
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Person Name',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              AnimatedButton(
                text: _isLoading ? 'Adding...' : 'Add Person',
                icon: _isLoading ? Icons.hourglass_empty : Icons.add,
                backgroundColor: AppColors.primary,
                hapticType: HapticFeedbackType.medium,
                onPressed: _isLoading ? null : _addPerson,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLendForm() {
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
              _buildPersonDropdown('Select Person'),
              const SizedBox(height: AppSpacing.md),
              _buildAccountDropdown('Select Account'),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixIcon: Icon(Icons.attach_money),
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
              ),
              const SizedBox(height: AppSpacing.md),
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
              const SizedBox(height: AppSpacing.lg),
              AnimatedButton(
                text: _isLoading ? 'Processing...' : 'Lend Money',
                icon: _isLoading ? Icons.hourglass_empty : Icons.arrow_upward,
                backgroundColor: AppColors.success,
                hapticType: HapticFeedbackType.medium,
                onPressed: _isLoading ? null : _lendMoney,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBorrowForm() {
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
              _buildPersonDropdown('Select Person'),
              const SizedBox(height: AppSpacing.md),
              _buildAccountDropdown('Select Account'),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixIcon: Icon(Icons.attach_money),
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
              ),
              const SizedBox(height: AppSpacing.md),
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
              const SizedBox(height: AppSpacing.lg),
              AnimatedButton(
                text: _isLoading ? 'Processing...' : 'Borrow Money',
                icon: _isLoading ? Icons.hourglass_empty : Icons.arrow_downward,
                backgroundColor: AppColors.warning,
                hapticType: HapticFeedbackType.medium,
                onPressed: _isLoading ? null : _borrowMoney,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonDropdown(String label) {
    return DropdownButtonFormField<String>(
      value: _selectedPersonId,
      items: _people.map((person) {
        return DropdownMenuItem(
          value: person.id,
          child: Text('${person.icon} ${person.name}'),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedPersonId = value),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) => value == null ? 'Please select a person' : null,
    );
  }

  Widget _buildAccountDropdown(String label) {
    return DropdownButtonFormField<String>(
      value: _selectedAccountId,
      items: _accounts.map((account) {
        return DropdownMenuItem(
          value: account.id,
          child: Text('${account.icon} ${account.name} (${account.currency} ${account.balance.toStringAsFixed(2)})'),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedAccountId = value),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) => value == null ? 'Please select an account' : null,
    );
  }

  Widget _buildPeopleList() {
    return ListView.builder(
      padding: AppSpacing.paddingLg,
      itemCount: _people.length,
      itemBuilder: (context, index) {
        final person = _people[index];
        return Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Color(int.parse(person.color.replaceAll('#', '0xFF'))).withValues(alpha: 0.1),
              child: Text(
                person.icon,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            title: Text(
              person.name,
              style: AppTextStyles.titleMedium,
            ),
            subtitle: Text(
              person.balanceDisplayText,
              style: AppTextStyles.bodySmall.copyWith(
                color: Color(int.parse(person.balanceColor.replaceAll('#', '0xFF'))),
              ),
            ),
            trailing: Text(
              '${person.balance >= 0 ? '+' : ''}${person.balance.toStringAsFixed(2)}',
              style: AppTextStyles.titleMedium.copyWith(
                color: Color(int.parse(person.balanceColor.replaceAll('#', '0xFF'))),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
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
              Icons.people_outline,
              size: 36,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'No people yet',
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Add people to track money you lend or borrow',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.onSurfaceVariant,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          AnimatedButton(
            text: 'Add Person',
            icon: Icons.add,
            backgroundColor: AppColors.primary,
            hapticType: HapticFeedbackType.medium,
            onPressed: _toggleAddForm,
          ),
        ],
      ),
    );
  }
} 