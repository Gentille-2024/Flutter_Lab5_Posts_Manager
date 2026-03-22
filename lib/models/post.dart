class Post {
  final int? id;
  final String title;
  final String content;
  final String author;
  final String category;
  final String createdAt;
  final String updatedAt;

  const Post({
    this.id,
    required this.title,
    required this.content,
    required this.author,
    this.category = 'General',
    required this.createdAt,
    required this.updatedAt,
  });

  // ── Convert Post → Map (for storage) ─────────────────────────────
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title':     title,
      'content':   content,
      'author':    author,
      'category':  category,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // ── Convert Map → Post (from storage) ────────────────────────────
  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      id:        map['id'] != null ? (map['id'] as num).toInt() : null,
      title:     map['title']     as String,
      content:   map['content']   as String,
      author:    map['author']    as String,
      category:  map['category']  as String,
      createdAt: map['createdAt'] as String,
      updatedAt: map['updatedAt'] as String,
    );
  }

  // ── Immutable update helper ───────────────────────────────────────
  Post copyWith({
    int?    id,
    String? title,
    String? content,
    String? author,
    String? category,
    String? updatedAt,
  }) {
    return Post(
      id:        id        ?? this.id,
      title:     title     ?? this.title,
      content:   content   ?? this.content,
      author:    author    ?? this.author,
      category:  category  ?? this.category,
      createdAt: createdAt,          // never changes
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}