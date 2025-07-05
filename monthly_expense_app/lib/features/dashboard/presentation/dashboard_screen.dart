import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../accounts/domain/account_model.dart';
import '../../accounts/domain/account_repository.dart';
import '../../accounts/domain/account_service.dart';
import '../../transactions/domain/transaction_model.dart';
import '../../transactions/domain/transaction_repository.dart';
import '../../transactions/domain/transaction_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AccountService _accountService = AccountService(AccountRepository());
  final TransactionService _transactionService = TransactionService(TransactionRepository(), AccountRepository());

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      body: user == null
          ? const Center(child: Text('Not signed in'))
          : SingleChildScrollView(
              padding: AppSpacing.paddingHorizontalLg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Dashboard',
                    style: AppTextStyles.headlineLarge.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Welcome back! Here\'s your financial overview.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  
                  // Stats Cards
                  _buildStatsSection(user.uid),
                  const SizedBox(height: AppSpacing.xl),
                  
                  // Accounts Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Your Accounts',
                        style: AppTextStyles.titleLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () {
                          // TODO: Navigate to add account
                        },
                        tooltip: 'Add Account',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  // Accounts List
                  StreamBuilder<List<Account>>(
                    stream: _accountService.getAccounts(user.uid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      final accounts = snapshot.data ?? [];
                      if (accounts.isEmpty) {
                        return Card(
                          color: AppColors.surfaceVariant,
                          child: Padding(
                            padding: AppSpacing.paddingLg,
                            child: Column(
                              children: [
                                Icon(
                                  Icons.account_balance_wallet_outlined,
                                  size: 48,
                                  color: AppColors.onSurfaceVariant,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  'No accounts yet',
                                  style: AppTextStyles.titleMedium.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  'Add your first account to get started',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    // TODO: Navigate to add account
                                  },
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add Account'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      
                      return Column(
                        children: accounts.map((account) => _buildAccountCard(account)).toList(),
                      );
                    },
                  ),
                  
                  const SizedBox(height: AppSpacing.xl),
                  
                  // Recent Transactions Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Transactions',
                        style: AppTextStyles.titleLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          // TODO: Navigate to all transactions
                        },
                        icon: const Icon(Icons.arrow_forward_ios, size: 16),
                        label: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  // Recent Transactions List
                  StreamBuilder<List<TransactionModel>>(
                    stream: _transactionService.getTransactions(user.uid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      final transactions = snapshot.data ?? [];
                      if (transactions.isEmpty) {
                        return Card(
                          color: AppColors.surfaceVariant,
                          child: Padding(
                            padding: AppSpacing.paddingLg,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.receipt_long_outlined,
                                  size: 48,
                                  color: AppColors.onSurfaceVariant,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  'No transactions yet',
                                  style: AppTextStyles.titleMedium.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  'Your recent transactions will appear here',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      
                      // Show only recent transactions (last 5)
                      final recentTransactions = transactions.take(5).toList();
                      
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (int i = 0; i < recentTransactions.length; i++) ...[
                            _buildTransactionTile(recentTransactions[i]),
                            if (i < recentTransactions.length - 1) const Divider(height: 1),
                          ],
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl + 45), // Extra space to prevent overflow
                ],
              ),
            ),
    );
  }

  Widget _buildStatsSection(String userId) {
    return StreamBuilder<List<Account>>(
      stream: _accountService.getAccounts(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final accounts = snapshot.data ?? [];
        final currencyTotals = <String, double>{};
        
        for (final account in accounts) {
          currencyTotals[account.currency] = (currencyTotals[account.currency] ?? 0) + account.balance;
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Balance',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: currencyTotals.entries.map((entry) => 
                _buildCurrencyCard(entry.key, entry.value)
              ).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildSpendingStats(userId),
          ],
        );
      },
    );
  }

  Widget _buildCurrencyCard(String currency, double total) {
    return Card(
      color: AppColors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currency,
                             style: AppTextStyles.labelMedium.copyWith(
                 color: AppColors.onPrimary,
                 fontWeight: FontWeight.w600,
               ),
            ),
            const SizedBox(height: 4),
            Text(
              '${total.toStringAsFixed(2)}',
                             style: AppTextStyles.headlineSmall.copyWith(
                 color: AppColors.onPrimary,
                 fontWeight: FontWeight.bold,
               ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpendingStats(String userId) {
    return StreamBuilder<List<TransactionModel>>(
      stream: _transactionService.getTransactions(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        
        final transactions = snapshot.data ?? [];
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final weekStart = today.subtract(Duration(days: today.weekday - 1));
        final monthStart = DateTime(now.year, now.month, 1);
        
        double todaySpending = 0;
        double weekSpending = 0;
        double monthSpending = 0;
        
        for (final transaction in transactions) {
          if (transaction.type == TransactionType.expense) {
            final transactionDate = DateTime(transaction.date.year, transaction.date.month, transaction.date.day);
            
            if (transactionDate == today) {
              todaySpending += transaction.amount;
            }
            if (transactionDate.isAfter(weekStart.subtract(const Duration(days: 1)))) {
              weekSpending += transaction.amount;
            }
            if (transactionDate.isAfter(monthStart.subtract(const Duration(days: 1)))) {
              monthSpending += transaction.amount;
            }
          }
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Spending Analytics',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _buildSpendingCard('Today', todaySpending, Icons.today),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildSpendingCard('This Week', weekSpending, Icons.calendar_view_week),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildSpendingCard('This Month', monthSpending, Icons.calendar_month),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildSpendingCard(String title, double amount, IconData icon) {
    return Card(
      color: AppColors.surfaceVariant,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: AppColors.onSurfaceVariant, size: 20),
            const SizedBox(height: 4),
            Text(
              title,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '\$${amount.toStringAsFixed(2)}',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCard(Account account) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      color: AppColors.surfaceVariant,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                account.icon,
                style: const TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.name,
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${account.currency} • ${account.type.name.toUpperCase()}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${account.currency} ${account.balance.toStringAsFixed(2)}',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    account.type.name.toUpperCase(),
                                         style: AppTextStyles.labelSmall.copyWith(
                       color: AppColors.onPrimary,
                       fontWeight: FontWeight.w600,
                     ),
                  ),
                ),
              ],
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
    
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: amountColor.withOpacity(0.1),
        child: Icon(
          isExpense ? Icons.remove : Icons.add,
          color: amountColor,
          size: 20,
        ),
      ),
      title: Text(
        transaction.description.isNotEmpty 
            ? transaction.description 
            : 'Transaction',
        style: AppTextStyles.titleMedium,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        transaction.date.toString().split(' ')[0], // Just the date part
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
      ),
      trailing: Text(
        '$amountPrefix\$${transaction.amount.toStringAsFixed(2)}',
        style: AppTextStyles.titleMedium.copyWith(
          color: amountColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
} 