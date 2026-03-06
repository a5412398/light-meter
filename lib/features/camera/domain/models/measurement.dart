/// 测量数据模型
class Measurement {
  final int? id;
  final double lux;
  final double cct;
  final double? calibrationFactor;
  final String? deviceModel;
  final DateTime createdAt;
  final String? note;

  Measurement({
    this.id,
    required this.lux,
    required this.cct,
    this.calibrationFactor,
    this.deviceModel,
    required this.createdAt,
    this.note,
  });

  /// 从数据库 Map 创建
  factory Measurement.fromMap(Map<String, dynamic> map) {
    return Measurement(
      id: map['id'] as int?,
      lux: map['lux'] as double,
      cct: map['cct'] as double,
      calibrationFactor: map['calibration_factor'] as double?,
      deviceModel: map['device_model'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      note: map['note'] as String?,
    );
  }

  /// 转换为数据库 Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'lux': lux,
      'cct': cct,
      'calibration_factor': calibrationFactor,
      'device_model': deviceModel,
      'created_at': createdAt.millisecondsSinceEpoch,
      'note': note,
    };
  }

  /// 复制并修改
  Measurement copyWith({
    int? id,
    double? lux,
    double? cct,
    double? calibrationFactor,
    String? deviceModel,
    DateTime? createdAt,
    String? note,
  }) {
    return Measurement(
      id: id ?? this.id,
      lux: lux ?? this.lux,
      cct: cct ?? this.cct,
      calibrationFactor: calibrationFactor ?? this.calibrationFactor,
      deviceModel: deviceModel ?? this.deviceModel,
      createdAt: createdAt ?? this.createdAt,
      note: note ?? this.note,
    );
  }
}