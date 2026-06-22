class CategoryModel {
  final String slug;
  final String displayName;
  final int sortOrder;

  const CategoryModel({
    required this.slug,
    required this.displayName,
    required this.sortOrder,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      slug: json['slug'] as String,
      displayName: json['display_name'] as String? ?? '',
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}
