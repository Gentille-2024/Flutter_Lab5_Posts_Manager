import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/post.dart';

class EditPostScreen extends StatefulWidget {
  final Post post;
  const EditPostScreen({super.key, required this.post});

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _contentCtrl;
  late TextEditingController _authorCtrl;
  late String _category;
  bool _isSaving = false;
  bool _hasChanges = false;

  final List<String> _categories = [
    'General',
    'News',
    'Tech',
    'Sports',
    'Health',
  ];

  @override
  void initState() {
    super.initState();
    // Pre-fill all fields with existing post data
    _titleCtrl   = TextEditingController(text: widget.post.title);
    _contentCtrl = TextEditingController(text: widget.post.content);
    _authorCtrl  = TextEditingController(text: widget.post.author);
    _category    = widget.post.category;

    // Track changes so we can warn before discarding
    _titleCtrl.addListener(_onChanged);
    _contentCtrl.addListener(_onChanged);
    _authorCtrl.addListener(_onChanged);
  }

  void _onChanged() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _authorCtrl.dispose();
    super.dispose();
  }

  // ── Save updated post to SQLite ───────────────────────────────────
  Future<void> _savePost() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final updatedPost = widget.post.copyWith(
        title:     _titleCtrl.text.trim(),
        content:   _contentCtrl.text.trim(),
        author:    _authorCtrl.text.trim(),
        category:  _category,
        updatedAt: DateTime.now().toIso8601String(),
      );

      final rowsAffected = await DatabaseHelper().updatePost(updatedPost);

      if (!mounted) return;

      if (rowsAffected > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle_outline,
                  color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Post updated successfully'),
            ]),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.pop(context); // return to PostDetailScreen
      } else {
        // rowsAffected == 0 means the ID wasn't found in the DB
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No post found with that ID.'),
            backgroundColor: Colors.orange.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Update failed: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  // ── Warn user if they try to leave with unsaved changes ───────────
  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D27),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Discard changes?',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        content: const Text(
          'You have unsaved changes. If you leave now they will be lost.',
          style: TextStyle(color: Colors.white70, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep editing',
                style: TextStyle(color: Color(0xFF6C63FF))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Discard',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    return leave ?? false;
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

  // ── Reusable labelled text field ──────────────────────────────────
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
            errorStyle: TextStyle(color: Colors.red.shade300),
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

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F1117),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F1117),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'Edit Post',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            // Quick save button in AppBar
            if (_hasChanges)
              TextButton.icon(
                onPressed: _isSaving ? null : _savePost,
                icon: const Icon(Icons.save_outlined,
                    size: 18, color: Color(0xFF6C63FF)),
                label: const Text('Save',
                    style: TextStyle(color: Color(0xFF6C63FF))),
              ),
            const SizedBox(width: 6),
          ],
        ),

        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
            children: [

              // ── Editing banner ──────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF6C63FF).withOpacity(0.25),
                  ),
                ),
                child: Row(children: [
                  const Icon(Icons.edit_note_rounded,
                      size: 16, color: Color(0xFF6C63FF)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Editing: "${widget.post.title}"',
                      style: const TextStyle(
                        color: Color(0xFF6C63FF),
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]),
              ),

              const SizedBox(height: 24),

              // ── Title field ─────────────────────────────────────
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

              // ── Author field ────────────────────────────────────
              _buildField(
                label: 'Author',
                controller: _authorCtrl,
                hint: 'Enter author name',
                icon: Icons.person_outline_rounded,
              ),

              const SizedBox(height: 20),

              // ── Category dropdown ───────────────────────────────
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
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1D27),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _category,
                      dropdownColor: const Color(0xFF1A1D27),
                      style: const TextStyle(
                          color: Colors.white, fontSize: 15),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded,
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
                      onChanged: (v) {
                        setState(() {
                          _category = v!;
                          _hasChanges = true;
                        });
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Content field ───────────────────────────────────
              _buildField(
                label: 'Content',
                controller: _contentCtrl,
                hint: 'Write your post content here...',
                icon: Icons.article_outlined,
                maxLines: 10,
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

              const SizedBox(height: 16),

              // ── Character counter ───────────────────────────────
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${_contentCtrl.text.length} characters',
                  style: const TextStyle(
                      color: Colors.white24, fontSize: 11),
                ),
              ),
            ],
          ),
        ),

        // ── Floating Save button ──────────────────────────────────
        floatingActionButton: AnimatedOpacity(
          opacity: _hasChanges ? 1.0 : 0.4,
          duration: const Duration(milliseconds: 300),
          child: SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: FilledButton.icon(
                onPressed: _isSaving ? null : _savePost,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save_rounded, size: 20),
                label: Text(
                  _isSaving ? 'Saving...' : 'Save Changes',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: _hasChanges
                      ? const Color(0xFF6C63FF)
                      : Colors.grey.shade700,
                  disabledBackgroundColor: Colors.grey.shade800,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
        ),
        floatingActionButtonLocation:
            FloatingActionButtonLocation.centerFloat,
      ),
    );
  }
}