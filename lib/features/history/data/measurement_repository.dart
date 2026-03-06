import 'package:sqflite/sqflite.dart';
import '../../camera/domain/models/measurement.dart';
import '../../../core/database/database_helper.dart';

/// 测量记录仓库
class MeasurementRepository {
  /// 插入测量记录
  Future<int> insert(Measurement measurement) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert('measurements', measurement.toMap());
  }

  /// 获取所有记录
  Future<List<Measurement>> getAll() async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      'measurements',
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => Measurement.fromMap(map)).toList();
  }

  /// 按日期范围获取记录
  Future<List<Measurement>> getByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      'measurements',
      where: 'created_at >= ? AND created_at <= ?',
      whereArgs: [
        start.millisecondsSinceEpoch,
        end.millisecondsSinceEpoch,
      ],
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => Measurement.fromMap(map)).toList();
  }

  /// 获取最近的记录
  Future<List<Measurement>> getRecent({int limit = 10}) async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      'measurements',
      orderBy: 'created_at DESC',
      limit: limit,
    );

    return maps.map((map) => Measurement.fromMap(map)).toList();
  }

  /// 删除记录
  Future<int> delete(int id) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete(
      'measurements',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 清除所有记录
  Future<int> deleteAll() async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete('measurements');
  }

  /// 清除过期记录
  Future<int> deleteOlderThan(int days) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    final db = await DatabaseHelper.instance.database;
    return await db.delete(
      'measurements',
      where: 'created_at < ?',
      whereArgs: [cutoffDate.millisecondsSinceEpoch],
    );
  }

  /// 获取记录数量
  Future<int> getCount() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM measurements');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}