import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:streetbite/models/stall.dart';

/// Represents an in-app alert triggered when a stall launches a special offer.
class DiscountAlertItem {
  const DiscountAlertItem({
    required this.id,
    required this.stallId,
    required this.stallName,
    required this.offer,
    required this.receivedAt,
    this.isRead = false,
  });

  final String id;
  final String stallId;
  final String stallName;
  final StallOffer offer;
  final DateTime receivedAt;
  final bool isRead;

  DiscountAlertItem copyWith({bool? isRead}) {
    return DiscountAlertItem(
      id: id,
      stallId: stallId,
      stallName: stallName,
      offer: offer,
      receivedAt: receivedAt,
      isRead: isRead ?? this.isRead,
    );
  }
}

/// Bridges Flutter to native Android status-bar notifications for stall flash discounts.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const MethodChannel _channel =
      MethodChannel('com.streetbite.app/notifications');

  Future<void> requestPermission() async {
    try {
      await _channel.invokeMethod<bool>('requestPermission');
    } catch (e) {
      debugPrint('Notification permission request skipped: $e');
    }
  }

  Future<void> showDiscountNotification({
    required Stall stall,
    required StallOffer offer,
  }) async {
    final title = '🔥 ${offer.discountBadge} at ${stall.name}';
    final body =
        '${offer.title} (${offer.durationType.label} • ${offer.remainingTimeLabel})';

    try {
      await _channel.invokeMethod<bool>(
        'showOfferNotification',
        <String, dynamic>{
          'id': stall.id.hashCode.abs(),
          'title': title,
          'body': body,
        },
      );
    } catch (e) {
      debugPrint('Local notification channel skipped: $e');
    }
  }
}
