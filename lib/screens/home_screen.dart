import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/post.dart';
import 'post_detail_screen.dart'; // ← create this file first
import 'add_post_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _db = DatabaseHelper();
  List<Post> _posts = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    try {
      setState(() => _isLoading = true);
      final posts = _searchQuery.isEmpty
          ? await _db.getAllPosts()
          : await _db.searchPosts(_searchQuery);
      setState(() { _posts = posts; _isLoading = false; });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load posts: $e');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Posts Manager',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded),
              onPressed: _loadPosts),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              onChanged: (v) {
                setState(() => _searchQuery = v);
                _loadPosts();
              },
              decoration: const InputDecoration(
                hintText: 'Search posts...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _posts.isEmpty
              ? _buildEmpty()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _posts.length,
                  itemBuilder: (ctx, i) => _buildPostCard(_posts[i]),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AddPostScreen()));
          _loadPosts(); // Refresh after adding
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Post'),
        backgroundColor: const Color(0xFF6C63FF),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.article_outlined, size: 72, color: Colors.white24),
        const SizedBox(height: 16),
        Text('No posts yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white54)),
        const SizedBox(height: 8),
        const Text('Tap + to create your first post',
            style: TextStyle(color: Colors.white38)),
      ],
    ));
  }

  Widget _buildPostCard(Post post) {
    final colors = [Colors.purple, Colors.teal, Colors.orange, Colors.blue];
    final color = colors[post.id! % colors.length];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await Navigator.push(context, MaterialPageRoute(
              builder: (_) => PostDetailScreen(post: post)));
          _loadPosts();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              width: 4, height: 60,
              decoration: BoxDecoration(
                color: color.shade400,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(post.category,
                        style: TextStyle(fontSize: 11, color: color.shade300)),
                  ),
                  const Spacer(),
                  Text(post.createdAt.substring(0, 10),
                      style: const TextStyle(fontSize: 11, color: Colors.white38)),
                ]),
                const SizedBox(height: 8),
                Text(post.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(post.content,
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            )),
            const Icon(Icons.chevron_right_rounded, color: Colors.white24),
          ]),
        ),
      ),
    );
  }
}