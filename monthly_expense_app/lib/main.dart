import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'features/auth/presentation/auth_screen.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/accounts/presentation/accounts_screen.dart';
import 'features/transactions/presentation/transactions_screen.dart';
import 'features/transactions/presentation/transfer_screen.dart';
import 'features/categories/presentation/categories_screen.dart';
import 'features/budgets/presentation/budgets_screen.dart';
import 'features/people/presentation/people_screen.dart';
import 'features/categories/domain/category_service.dart';
import 'features/categories/domain/category_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MonthlyExpenseApp());
}

class MonthlyExpenseApp extends StatelessWidget {
  const MonthlyExpenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Monthly Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          return const MainNavScreen();
        }
        return const AuthScreen();
      },
    );
  }
}

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _selectedIndex = 0;
  bool _isInitialized = false;
  
  void _navigateToScreen(int screenIndex) {
    setState(() {
      _selectedIndex = screenIndex;
    });
  }
  
  @override
  void initState() {
    super.initState();
    _initializeForNewUser();
  }
  
  Future<void> _initializeForNewUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !_isInitialized) {
      final categoryService = CategoryService(CategoryRepository());
      await categoryService.initializeDefaultCategories(user.uid);
      _isInitialized = true;
    }
  }
  
  List<Widget> get _screens => [
    DashboardScreen(onNavigateToScreen: _navigateToScreen),
    const AccountsScreen(),
    const TransactionsScreen(),
    const CategoriesScreen(),
    const BudgetsScreen(),
    const PeopleScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? 'Dashboard' : _selectedIndex == 1 ? 'Accounts' : _selectedIndex == 2 ? 'Transactions' : _selectedIndex == 3 ? 'Categories' : _selectedIndex == 4 ? 'Budgets' : 'People'),
        backgroundColor: AppColors.surface,
      ),
      drawer: Drawer(
        backgroundColor: AppColors.surface,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: AppColors.primary,
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Expense Tracker',
                    style: TextStyle(
                      color: AppColors.onPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Manage your finances',
                    style: TextStyle(
                      color: AppColors.onPrimary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: const Text('Dashboard'),
              selected: _selectedIndex == 0,
              onTap: () {
                setState(() => _selectedIndex = 0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined),
              title: const Text('Accounts'),
              selected: _selectedIndex == 1,
              onTap: () {
                setState(() => _selectedIndex = 1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('Transactions'),
              selected: _selectedIndex == 2,
              onTap: () {
                setState(() => _selectedIndex = 2);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz_outlined),
              title: const Text('Transfer Money'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TransferScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.category_outlined),
              title: const Text('Categories'),
              selected: _selectedIndex == 3,
              onTap: () {
                setState(() => _selectedIndex = 3);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_money_outlined),
              title: const Text('Budgets'),
              selected: _selectedIndex == 4,
              onTap: () {
                setState(() => _selectedIndex = 4);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.people_outline),
              title: const Text('People'),
              selected: _selectedIndex == 5,
              onTap: () {
                setState(() => _selectedIndex = 5);
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign Out'),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: _screens[_selectedIndex],
    );
  }
}
