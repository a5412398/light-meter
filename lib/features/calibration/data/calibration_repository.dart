import '../domain/models/calibration_config.dart';
import '../../../core/database/database_helper.dart';

/// 校准配置仓库
class CalibrationRepository {
  /// 获取默认校准配置
  Future<CalibrationConfig?> getDefault() async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      'calibration_configs',
      where: 'is_default = ?',
      whereArgs: [1],
    );

    if (maps.isEmpty) return null;
    return CalibrationConfig.fromMap(maps.first);
  }

  /// 获取所有校准配置
  Future<List<CalibrationConfig>> getAll() async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      'calibration_configs',
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => CalibrationConfig.fromMap(map)).toList();
  }

  /// 保存校准配置
  Future<int> save(CalibrationConfig config) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert('calibration_configs', config.toMap());
  }

  /// 更新校准配置
  Future<int> update(CalibrationConfig config) async {
    if (config.id == null) return 0;

    final db = await DatabaseHelper.instance.database;
    return await db.update(
      'calibration_configs',
      config.toMap(),
      where: 'id = ?',
      whereArgs: [config.id],
    );
  }

  /// 设置默认配置
  Future<void> setDefault(int id) async {
    final db = await DatabaseHelper.instance.database;

    // 先清除所有默认
    await db.update(
      'calibration_configs',
      {'is_default': 0},
    );

    // 设置指定配置为默认
    await db.update(
      'calibration_configs',
      {'is_default': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 删除校准配置
  Future<int> delete(int id) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete(
      'calibration_configs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}