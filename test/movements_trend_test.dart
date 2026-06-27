import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:stock_master/models/stock_movement.dart';

void main() {
  group('Movements Trend Logic', () {
    test('Should correctly group movements by date', () {
      final now = DateTime.now();
      final movements = [
        StockMovement(
            productId: 1,
            productName: 'A',
            type: MovementType.inward,
            quantity: 10,
            date: now,
            userId: 'u1'),
        StockMovement(
            productId: 1,
            productName: 'A',
            type: MovementType.outward,
            quantity: 5,
            date: now,
            userId: 'u1'),
        StockMovement(
            productId: 2,
            productName: 'B',
            type: MovementType.inward,
            quantity: 20,
            date: now.subtract(const Duration(days: 1)),
            userId: 'u1'),
      ];

      Map<String, int> dailyCounts = {};
      int selectedDays = 7;
      
      // Initialize map
      for (int i = 0; i < selectedDays; i++) {
        final date = now.subtract(Duration(days: i));
        final dateStr = DateFormat('yyyy-MM-dd').format(date);
        dailyCounts[dateStr] = 0;
      }

      // Populate map
      for (var m in movements) {
        final dateStr = DateFormat('yyyy-MM-dd').format(m.date);
        if (dailyCounts.containsKey(dateStr)) {
          dailyCounts[dateStr] = dailyCounts[dateStr]! + m.quantity;
        }
      }

      final todayStr = DateFormat('yyyy-MM-dd').format(now);
      final yesterdayStr = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 1)));

      expect(dailyCounts[todayStr], 15); // 10 IN + 5 OUT
      expect(dailyCounts[yesterdayStr], 20);
    });

    test('Should separate IN and OUT quantities', () {
       final now = DateTime.now();
      final movements = [
        StockMovement(
            productId: 1,
            productName: 'A',
            type: MovementType.inward,
            quantity: 10,
            date: now,
            userId: 'u1'),
        StockMovement(
            productId: 1,
            productName: 'A',
            type: MovementType.outward,
            quantity: 5,
            date: now,
            userId: 'u1'),
      ];

      Map<String, Map<String, int>> dailyStats = {};
      // key: date, value: { 'IN': 0, 'OUT': 0 }

       final todayStr = DateFormat('yyyy-MM-dd').format(now);
       dailyStats[todayStr] = {'IN': 0, 'OUT': 0};

       for (var m in movements) {
        final dateStr = DateFormat('yyyy-MM-dd').format(m.date);
        if (dailyStats.containsKey(dateStr)) {
          final typeKey = m.type == MovementType.inward ? 'IN' : 'OUT';
          dailyStats[dateStr]![typeKey] = (dailyStats[dateStr]![typeKey] ?? 0) + m.quantity;
        }
      }

      expect(dailyStats[todayStr]!['IN'], 10);
      expect(dailyStats[todayStr]!['OUT'], 5);
    });
  });
}