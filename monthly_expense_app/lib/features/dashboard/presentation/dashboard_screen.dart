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
  final TransactionService _transactionService = TransactionService(TransactionRepository());

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
                  
                  // Accounts Grid
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
                      
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: AppSpacing.md,
                          mainAxisSpacing: AppSpacing.md,
                          childAspectRatio: 1.2, // Reduced aspect ratio to give more height
                        ),
                        itemCount: accounts.length,
                        itemBuilder: (context, index) {
                          final account = accounts[index];
                          return _buildAccountCard(account);
                        },
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
                  const SizedBox(height: AppSpacing.xl + 21), // Extra space to prevent overflow
                ],
              ),
            ),
    );
  }

  Widget _buildAccountCard(Account account) {
    return Card(
      color: AppColors.surfaceVariant,
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  account.icon,
                  style: const TextStyle(fontSize: 24),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
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
            const SizedBox(height: AppSpacing.sm),
            Text(
              account.name,
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${account.currency} ${account.balance.toStringAsFixed(2)}',
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
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