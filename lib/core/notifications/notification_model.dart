enum NotificationType { lowStock, success, error, info }

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.timestamp,
    this.materialId,
    this.materialName,
    this.remainingPercentage,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime? timestamp;
  final String? materialId; // For low stock notifications
  final String? materialName;
  final double? remainingPercentage;

  factory AppNotification.lowStock({
    required String materialId,
    required String materialName,
    required double remainingPercentage,
  }) {
    return AppNotification(
      id: '${materialId}_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.lowStock,
      title: '⚠️  Low Stock Alert',
      message: '$materialName is running low ($remainingPercentage% remaining)',
      timestamp: DateTime.now(),
      materialId: materialId,
      materialName: materialName,
      remainingPercentage: remainingPercentage,
    );
  }
}
