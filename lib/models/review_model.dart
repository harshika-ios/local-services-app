class ReviewModel {
  final String id;
  final String providerId;
  final String userId;
  final String reviewerName;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  const ReviewModel({
    required this.id,
    required this.providerId,
    required this.userId,
    required this.reviewerName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] as String,
      providerId: json['provider_id'] as String,
      userId: json['user_id'] as String,
      reviewerName: (json['reviewer_name'] as String?) ?? 'Anonymous',
      rating: (json['rating'] as num).toInt(),
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
