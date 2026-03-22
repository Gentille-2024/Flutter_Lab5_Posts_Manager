import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/post.dart';
import 'edit_post_screen.dart';

class PostDetailScreen extends StatefulWidget {
  final Post post;
  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _db = DatabaseHelper();
  late Post _post;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
  }

  // ── Navigate to Edit, then reload fresh data from DB ─────────────
  Future<void> _navigateToEdit() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditPostScreen(post: _post),
      ),
    );
    if (!mounted) return;
    final updated = await _db.getPostById(_post.id!);
    if (updated != null && mounted) {
      setState(() => _post = updated);
    }
  }

  // ── Show confirmation dialog then delete ─────────────────────────
  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D27),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Colors.orange, size: 22),
            SizedBox(width: 8),
            Text(
              'Delete Post',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${_post.title}"?\n'
          'This action cannot be undone.',
          style: const TextStyle(color: Colors.white70, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      await _db.deletePost(_post.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${_post.title}" deleted successfully'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      Navigator.pop(context); // return to HomeScreen
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Delete failed: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── Category → colour mapping ─────────────────────────────────────
  Color _categoryColor(String category) {
    const map = {
      'News':    Colors.blue,
      'Tech':    Colors.purple,
      'Sports':  Colors.orange,
      'Health':  Colors.green,
      'General': Colors.teal,
    };
    return map[category] ?? Colors.grey;
  }

  // ── Build ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final categoryColor = _categoryColor(_post.category);

    return Scaffold(
      backgroundColor: const Color(0xFF0F1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1117),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Post Detail',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          // ── Edit button ───────────────────────────────────────────
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Post',
            onPressed: _navigateToEdit,
          ),
          // ── Delete button ─────────────────────────────────────────
          IconButton(
            icon: _isDeleting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.red,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.redAccent,
                  ),
            tooltip: 'Delete Post',
            onPressed: _isDeleting ? null : _confirmDelete,
          ),
          const SizedBox(width: 6),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Category chip ─────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: categoryColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: categoryColor.withOpacity(0.3),
                ),
              ),
              child: Text(
                _post.category,
                style: TextStyle(
                  color: categoryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            const SizedBox(height: 18),

            // ── Title ─────────────────────────────────────────────
            Text(
              _post.title,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.25,
              ),
            ),

            const SizedBox(height: 16),

            // ── Author + Date row ─────────────────────────────────
            Row(
              children: [
                const Icon(Icons.person_outline_rounded,
                    size: 15, color: Colors.white38),
                const SizedBox(width: 5),
                Text(
                  _post.author,
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 13),
                ),
                const Spacer(),
                const Icon(Icons.calendar_today_outlined,
                    size: 13, color: Colors.white38),
                const SizedBox(width: 5),
                Text(
                  _post.createdAt.length >= 10
                      ? _post.createdAt.substring(0, 10)
                      : _post.createdAt,
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 12),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Decorative divider ────────────────────────────────
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    categoryColor.withOpacity(0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Content body ──────────────────────────────────────
            Text(
              _post.content,
              style: const TextStyle(
                fontSize: 15.5,
                color: Colors.white70,
                height: 1.8,
              ),
            ),

            const SizedBox(height: 36),

            // ── Last edited notice (only if post was updated) ─────
            if (_post.updatedAt != _post.createdAt)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.edit_calendar_outlined,
                        size: 14, color: Colors.white30),
                    const SizedBox(width: 8),
                    Text(
                      'Last edited: ${_post.updatedAt.length >= 10 ? _post.updatedAt.substring(0, 10) : _post.updatedAt}',
                      style: const TextStyle(
                          color: Colors.white30, fontSize: 12),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 32),

            // ── Action buttons at bottom ──────────────────────────
            Row(
              children: [
                // Edit button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _navigateToEdit,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit Post'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF6C63FF),
                      side: const BorderSide(
                          color: Color(0xFF6C63FF), width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Delete button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isDeleting ? null : _confirmDelete,
                    icon: _isDeleting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.red),
                          )
                        : const Icon(Icons.delete_outline_rounded,
                            size: 18),
                    label: Text(_isDeleting ? 'Deleting…' : 'Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade400,
                      side: BorderSide(
                          color: Colors.red.shade400, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
}