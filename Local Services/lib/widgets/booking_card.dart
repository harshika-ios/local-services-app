import 'package:flutter/material.dart';

enum BookingStatus { upcoming, completed, cancelled }

class BookingCard extends StatelessWidget {
  const BookingCard({
    required this.providerName,
    required this.serviceType,
    required this.scheduledFor,
    required this.status,
    this.onTap,
    super.key,
  });

  final String providerName;
  final String serviceType;
  final DateTime scheduledFor;
  final BookingStatus status;
  final VoidCallback? onTap;

  Color _statusAccentColor(BookingStatus s) => switch (s) {
    BookingStatus.upcoming => const Color(0xFF1E5BD9),
    BookingStatus.completed => const Color(0xFF1F7A3D),
    BookingStatus.cancelled => const Color(0xFFB42323),
  };

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                color: _statusAccentColor(status),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              serviceType,
                              style: TextStyle(
                                color: primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          _StatusPill(status: status),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        providerName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 14,
                            color: Colors.black54,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatDate(scheduledFor),
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.black54,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatTime(scheduledFor),
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    final hour12 = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'AM' : 'PM';
    return '$hour12:$minute $period';
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final BookingStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, fg, bg) = switch (status) {
      BookingStatus.upcoming => (
        'Upcoming',
        const Color(0xFF1E5BD9),
        const Color(0xFFE8F0FF),
      ),
      BookingStatus.completed => (
        'Completed',
        const Color(0xFF1F7A3D),
        const Color(0xFFE7F8EF),
      ),
      BookingStatus.cancelled => (
        'Cancelled',
        const Color(0xFFB42323),
        const Color(0xFFFCE8E8),
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
