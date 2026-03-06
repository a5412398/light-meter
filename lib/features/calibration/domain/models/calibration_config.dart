/// 校准配置模型
class CalibrationConfig {
  final int? id;
  final String name;
  final double factor;
  final double? referenceLux;
  final bool isDefault;
  final DateTime createdAt;

  CalibrationConfig({
    this.id,
    required this.name,
    required this.factor,
    this.referenceLux,
    this.isDefault = false,
    required this.createdAt,
  });

  /// 从数据库 Map 创建
  factory CalibrationConfig.fromMap(Map<String, dynamic> map) {
    return CalibrationConfig(
      id: map['id'] as int?,
      name: map['name'] as String,
      factor: map['factor'] as double,
      referenceLux: map['reference_lux'] as double?,
      isDefault: map['is_default'] == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  /// 转换为数据库 Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'factor': factor,
      'reference_lux': referenceLux,
      'is_default': isDefault ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  /// 复制并修改
  CalibrationConfig copyWith({
    int? id,
    String? name,
    double? factor,
    double? referenceLux,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return CalibrationConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      factor: factor ?? this.factor,
      referenceLux: referenceLux ?? this.referenceLux,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}