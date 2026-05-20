import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_category_model.dart';

class CategoryProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  List<AppCategoryModel> _categories = [];
  bool _isLoading = false;

  List<AppCategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;

  String? get _userId => _supabase.auth.currentUser?.id;

  List<AppCategoryModel> byType(String type) {
    return _categories.where((e) => e.type == type && !e.isDeleted).toList();
  }

  Future<void> loadCategories() async {
    try {
      _isLoading = true;
      notifyListeners();

      final userId = _userId;
      if (userId == null) {
        _categories = [];
        return;
      }

      final response = await _supabase
          .from('categories')
          .select()
          .or('is_default.eq.true,user_id.eq.$userId')
          .eq('is_deleted', false)
          .order('is_default', ascending: false)
          .order('created_at', ascending: true);

      _categories =
          (response as List).map((e) => AppCategoryModel.fromMap(e)).toList();
    } catch (e) {
      debugPrint('loadCategories error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addCategory({
    required String name,
    required String emoji,
    required String type,
  }) async {
    final userId = _userId;
    if (userId == null) throw Exception('User not logged in');

    final trimmedName = name.trim();
    final trimmedEmoji = emoji.trim().isEmpty ? '📁' : emoji.trim();

    await _supabase.from('categories').insert({
      'user_id': userId,
      'name': trimmedName,
      'emoji': trimmedEmoji,
      'type': type,
      'is_default': false,
      'is_deleted': false,
    });

    await loadCategories();
  }

  Future<void> updateCategory({
    required String id,
    required String name,
    required String emoji,
    required String type,
  }) async {
    final trimmedName = name.trim();
    final trimmedEmoji = emoji.trim().isEmpty ? '📁' : emoji.trim();

    await _supabase.from('categories').update({
      'name': trimmedName,
      'emoji': trimmedEmoji,
      'type': type,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);

    await loadCategories();
  }

  Future<void> deleteCategory(String id) async {
    await _supabase.from('categories').update({
      'is_deleted': true,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);

    await loadCategories();
  }

  AppCategoryModel? getById(String id) {
    try {
      return _categories.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }
}
