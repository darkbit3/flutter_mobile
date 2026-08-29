import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'notification_model.dart';

/// Notification Service — manages low stock notifications
class NotificationService extends StateNotifier<List<AppNotification>> {
  NotificationService() : super([]);

  /// Add a low stock notification
  void addLowStockNotification({
    required String materialId,
    required String materialName,
    required double remainingPercentage,
  }) {
    final notification = AppNotification.lowStock(
      materialId: materialId,
      materialName: materialName,
      remainingPercentage: remainingPercentage,
    );
    
    // Avoid duplicates within 5 seconds
    final isDuplicate = state.any((n) =>
        n.materialId == materialId &&
        n.timestamp != null &&
        DateTime.now().difference(n.timestamp!).inSeconds < 5);
    
    if (!isDuplicate) {
      state = [...state, notification];
      
      // Auto-remove after 7 seconds
      Future.delayed(const Duration(seconds: 7), () {
        state = state.where((n) => n.id != notification.id).toList();
      });
    }
  }

  /// Remove a notification by ID
  void removeNotification(String id) {
    state = state.where((n) => n.id != id).toList();
  }

  /// Clear all notifications
  void clearAll() {
    state = [];
  }
}

final notificationServiceProvider =
    StateNotifierProvider<NotificationService, List<AppNotification>>((ref) {
  return NotificationService();
});
