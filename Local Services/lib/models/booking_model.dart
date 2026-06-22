import '../widgets/booking_card.dart';
import 'provider_model.dart';

class BookingModel {
  final String id;
  final ProviderModel? provider;
  final DateTime scheduledFor;
  final BookingStatus status;
  final String? notes;
  final String? customerName;

  const BookingModel({
    required this.id,
    required this.provider,
    required this.scheduledFor,
    required this.status,
    this.notes,
    this.customerName,
  });

  // User-side: joins providers(*)
  factory BookingModel.fromJson(Map<String, dynamic> json) {
    final providerJson = json['providers'] as Map<String, dynamic>?;
    return BookingModel(
      id: json['id'] as String,
      provider:
          providerJson != null ? ProviderModel.fromJson(providerJson) : null,
      scheduledFor: DateTime.parse(json['scheduled_for'] as String),
      status: _statusFromString(json['status'] as String?),
      notes: json['notes'] as String?,
      customerName: json['customer_name'] as String?,
    );
  }

  // Provider-side: no provider join, has customer_name
  factory BookingModel.fromProviderJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] as String,
      provider: null,
      scheduledFor: DateTime.parse(json['scheduled_for'] as String),
      status: _statusFromString(json['status'] as String?),
      notes: json['notes'] as String?,
      customerName: json['customer_name'] as String?,
    );
  }

  static BookingStatus _statusFromString(String? s) {
    switch (s) {
      case 'completed':
        return BookingStatus.completed;
      case 'cancelled':
        return BookingStatus.cancelled;
      case 'upcoming':
      default:
        return BookingStatus.upcoming;
    }
  }
}
