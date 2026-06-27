enum MovementType { inward, outward }

class StockMovement {
  final int? id;
  final int productId;
  final String productName; // Denormalized for easier display
  final MovementType type;
  final int quantity;
  final DateTime date;
  final String? reason;
  final String userId; // "admin" or "employee" username

  StockMovement({
    this.id,
    required this.productId,
    required this.productName,
    required this.type,
    required this.quantity,
    required this.date,
    this.reason,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'type': type == MovementType.inward ? 'IN' : 'OUT',
      'quantity': quantity,
      'date': date.toIso8601String(),
      'reason': reason,
      'userId': userId,
    };
  }

  factory StockMovement.fromMap(Map<String, dynamic> map) {
    return StockMovement(
      id: map['id'],
      productId: map['productId'],
      productName: map['productName'],
      type: map['type'] == 'IN' ? MovementType.inward : MovementType.outward,
      quantity: map['quantity'],
      date: DateTime.parse(map['date']),
      reason: map['reason'],
      userId: map['userId'],
    );
  }
}