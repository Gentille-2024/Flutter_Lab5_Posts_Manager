import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/post.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _titleCtrl   = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _authorCtrl  = TextEditingController();
  String _category   = 'General';
  bool _isSaving     = false;

  final List<String> _categories = [
    'General',
    'News',
    'Tech',
    'Sports',
    'Health',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _authorCtrl.dispose();
    super.dispose();
  }

  // ── Save new post to SQLite ───────────────────────────────────────
  Future<void> _savePost() async {
    // 1. Validate form fields first
    if (!_formKey.currentState!.validate()) return;

    // 2. Show loading state
    setState(() => _isSaving = true);

    try {
      final now  = DateTime.now().toIso8601String();
      final post = Post(
        title:     _titleCtrl.text.trim(),
        content:   _contentCtrl.text.trim(),
        author:    _authorCtrl.text.trim(),
        category:  _category,
        createdAt: now,
        updatedAt: now,
      );

      // 3. Insert into DB
      final id = await DatabaseHelper().insertPost(post);

      // 4. Guard against widget being disposed during await
      if (!mounted) return;

      if (id > 0) {
        // Success — show snackbar and go back
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle_outline,
                  color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Post created successfully!'),
            ]),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.pop(context); // returns to HomeScreen
      } else {
        // Insert returned 0 — unexpected but handle gracefully
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to save post. Please try again.'),
            backgroundColor: Colors.orange.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // 5. ALWAYS reset _isSaving on error so button works again
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving post: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  // ── Category colour helper ────────────────────────────────────────
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

  // ── Reusable field builder ────────────────────────────────────────
  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24),
            prefixIcon: Icon(icon, color: Colors.white38, size: 20),
            filled: true,
            fillColor: const Color(0xFF1A1D27),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: Color(0xFF6C63FF), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: Colors.red.shade400, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: Colors.red.shade400, width: 2),
            ),
          ),
          validator: validator ??
              (v) => (v == null || v.trim().isEmpty)
                  ? '$label is required'
                  : null,
        ),
      ],
    );
  }

  // ── Build ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final accentColor = _categoryColor(_category);

    return Scaffold(
      backgroundColor: const Color(0xFF0F1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1117),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'New Post',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          children: [

            // ── Title ───────────────────────────────────────────────
            _buildField(
              label: 'Title',
              controller: _titleCtrl,
              hint: 'Enter post title',
              icon: Icons.title_rounded,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Title is required';
                }
                if (v.trim().length < 3) {
                  return 'Title must be at least 3 characters';
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            // ── Author ──────────────────────────────────────────────
            _buildField(
              label: 'Author',
              controller: _authorCtrl,
              hint: 'Enter author name',
              icon: Icons.person_outline_rounded,
            ),

            const SizedBox(height: 20),

            // ── Category dropdown ───────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Category',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _category,
                  dropdownColor: const Color(0xFF1A1D27),
                  style: const TextStyle(
                      color: Colors.white, fontSize: 15),
                  icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.white38),
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.label_outline_rounded,
                      color: accentColor.withOpacity(0.7),
                      size: 20,
                    ),
                    filled: true,
                    fillColor: const Color(0xFF1A1D27),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: Color(0xFF6C63FF), width: 2),
                    ),
                  ),
                  items: _categories
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Row(children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _categoryColor(c),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(c),
                            ]),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _category = v!),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Content ─────────────────────────────────────────────
            _buildField(
              label: 'Content',
              controller: _contentCtrl,
              hint: 'Write your post content here...',
              icon: Icons.article_outlined,
              maxLines: 8,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Content is required';
                }
                if (v.trim().length < 10) {
                  return 'Content must be at least 10 characters';
                }
                return null;
              },
            ),
          ],
        ),
      ),

      // ── Floating Save button ──────────────────────────────────────
      floatingActionButton: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: FilledButton.icon(
            onPressed: _isSaving ? null : _savePost,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Icon(Icons.save_rounded, size: 20),
            label: Text(
              _isSaving ? 'Saving...' : 'Save Post',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              disabledBackgroundColor: Colors.grey.shade800,
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerFloat,
    );
  }
}