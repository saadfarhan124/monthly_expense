import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/category_model.dart';
import '../domain/category_repository.dart';
import '../domain/category_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final CategoryService _categoryService = CategoryService(CategoryRepository());
  bool _showAddForm = false;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedIcon = '📁';
  String _selectedColor = '#6366F1';

  // Cache for categories
  List<Category> _cachedCategories = [];
  bool _isCategoriesLoaded = false;

  final List<String> _availableIcons = [
    '🚗', '🏠', '🏢', '🏥', '👨‍👩‍👧‍👦', '👤', '📱', '⛽', '📄', '📁',
    '🍔', '☕', '🎬', '🎵', '📚', '💻', '🎮', '🏃‍♂️', '🧘‍♀️', '✈️',
    '🛒', '💄', '👕', '👟', '💍', '💎', '🎁', '🎉', '🏖️', '🎨',
  ];

  final List<String> _availableColors = [
    '#EF4444', '#10B981', '#F59E0B', '#3B82F6', '#8B5CF6', '#6366F1',
    '#06B6D4', '#F97316', '#84CC16', '#6B7280', '#EC4899', '#8B5A2B',
    '#4F46E5', '#059669', '#D97706', '#DC2626', '#7C3AED', '#0891B2',
  ];

  @override
  void initState() {
    super.initState();
    _loadCachedData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }



  Future<void> _loadCachedData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Load categories once and cache them
    _categoryService.getCategories(user.uid).listen((categories) {
      if (mounted) {
        setState(() {
          _cachedCategories = categories;
          _isCategoriesLoaded = true;
        });
      }
    });
  }

  void _toggleAddForm() {
    setState(() => _showAddForm = !_showAddForm);
  }

  Future<void> _addCustomCategory() async {
    if (!_formKey.currentState!.validate()) return;
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _categoryService.addCustomCategory(
        _nameController.text.trim(),
        _selectedIcon,
        _selectedColor,
        user.uid,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category added!'), backgroundColor: AppColors.success),
        );
        _nameController.clear();
        setState(() => _showAddForm = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _deleteCategory(String id, bool isDefault) async {
    if (isDefault) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Default categories cannot be deleted'), backgroundColor: AppColors.warning),
      );
      return;
    }
    
    await _categoryService.deleteCategory(id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category deleted!'), backgroundColor: AppColors.error),
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
                        tooltip: _showAddForm ? 'Cancel' : 'Add Category',
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
                                decoration: const InputDecoration(labelText: 'Category Name'),
                                validator: (v) => v == null || v.isEmpty ? 'Enter a name' : null,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                'Select Icon',
                                style: AppTextStyles.labelMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Container(
                                height: 120,
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: GridView.builder(
                                  padding: const EdgeInsets.all(8),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 6,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                  ),
                                  itemCount: _availableIcons.length,
                                  itemBuilder: (context, index) {
                                    final icon = _availableIcons[index];
                                    final isSelected = icon == _selectedIcon;
                                    return GestureDetector(
                                      onTap: () => setState(() => _selectedIcon = icon),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Center(
                                          child: Text(
                                            icon,
                                            style: const TextStyle(fontSize: 20),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                'Select Color',
                                style: AppTextStyles.labelMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Container(
                                height: 60,
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: GridView.builder(
                                  padding: const EdgeInsets.all(8),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 6,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                  ),
                                  itemCount: _availableColors.length,
                                  itemBuilder: (context, index) {
                                    final color = _availableColors[index];
                                    final isSelected = color == _selectedColor;
                                    return GestureDetector(
                                      onTap: () => setState(() => _selectedColor = color),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Color(int.parse(color.replaceAll('#', '0xFF'))),
                                          borderRadius: BorderRadius.circular(8),
                                          border: isSelected 
                                              ? Border.all(color: AppColors.onSurface, width: 2)
                                              : null,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              ElevatedButton(
                                onPressed: _addCustomCategory,
                                child: const Text('Add Category'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  Expanded(
                    child: _isCategoriesLoaded
                        ? _buildCategoriesList()
                        : const Center(child: CircularProgressIndicator()),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCategoriesList() {
    if (_cachedCategories.isEmpty) {
      return const Center(child: Text('No categories yet.'));
    }
    
    return ListView.separated(
      itemCount: _cachedCategories.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final category = _cachedCategories[index];
        return _buildCategoryTile(category);
      },
    );
  }

  Widget _buildCategoryTile(Category category) {
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Color(int.parse(category.color.replaceAll('#', '0xFF'))),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            category.icon,
            style: const TextStyle(fontSize: 20),
          ),
        ),
      ),
      title: Text(
        category.name,
        style: AppTextStyles.titleMedium.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        category.isDefault ? 'Default Category' : 'Custom Category',
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, color: AppColors.error),
        onPressed: () => _deleteCategory(category.id, category.isDefault),
        tooltip: category.isDefault ? 'Cannot delete default category' : 'Delete',
      ),
    );
  }
} 