import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/post.dart';

/// StorageHelper replaces SQLite with SharedPreferences.
/// Works identically on Web, Android, iOS, and Desktop.
/// Same public API — no changes needed in any screen.
class DatabaseHelper {
  // ── Singleton ─────────────────────────────────────────────────────
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static const _postsKey = 'offline_posts';

  // ── Read all posts from storage ───────────────────────────────────
  Future<List<Post>> _readAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_postsKey) ?? [];
    return raw
        .map((s) => Post.fromMap(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  // ── Write full list back to storage ──────────────────────────────
  Future<void> _writeAll(List<Post> posts) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = posts.map((p) => jsonEncode(p.toMap())).toList();
    await prefs.setStringList(_postsKey, raw);
  }

  // ── CREATE ────────────────────────────────────────────────────────
  Future<int> insertPost(Post post) async {
    try {
      final posts = await _readAll();
      // Generate a new unique ID
      final newId = posts.isEmpty
          ? 1
          : posts.map((p) => p.id ?? 0).reduce((a, b) => a > b ? a : b) + 1;
      final newPost = post.copyWith(id: newId);
      posts.insert(0, newPost); // newest first
      await _writeAll(posts);
      return newId;
    } catch (e) {
      throw Exception('Insert failed: $e');
    }
  }

  // ── READ ALL ──────────────────────────────────────────────────────
  Future<List<Post>> getAllPosts() async {
    try {
      return await _readAll();
    } catch (e) {
      throw Exception('Fetch failed: $e');
    }
  }

  // ── READ ONE ──────────────────────────────────────────────────────
  Future<Post?> getPostById(int id) async {
    try {
      final posts = await _readAll();
      final matches = posts.where((p) => p.id == id);
      return matches.isEmpty ? null : matches.first;
    } catch (e) {
      throw Exception('Fetch by ID failed: $e');
    }
  }

  // ── UPDATE ────────────────────────────────────────────────────────
  Future<int> updatePost(Post post) async {
    try {
      final posts = await _readAll();
      final index = posts.indexWhere((p) => p.id == post.id);
      if (index == -1) return 0; // not found
      posts[index] = post;
      await _writeAll(posts);
      return 1; // 1 row affected
    } catch (e) {
      throw Exception('Update failed: $e');
    }
  }

  // ── DELETE ────────────────────────────────────────────────────────
  Future<int> deletePost(int id) async {
    try {
      final posts = await _readAll();
      final before = posts.length;
      posts.removeWhere((p) => p.id == id);
      await _writeAll(posts);
      return before - posts.length; // rows deleted
    } catch (e) {
      throw Exception('Delete failed: $e');
    }
  }

  // ── SEARCH ────────────────────────────────────────────────────────
  Future<List<Post>> searchPosts(String query) async {
    try {
      final posts = await _readAll();
      final q = query.toLowerCase();
      return posts
          .where((p) =>
              p.title.toLowerCase().contains(q) ||
              p.content.toLowerCase().contains(q))
          .toList();
    } catch (e) {
      throw Exception('Search failed: $e');
    }
  }

  // ── CLEAR ALL (utility for testing) ──────────────────────────────
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_postsKey);
  }
}