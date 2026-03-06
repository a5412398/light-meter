class AppConstants {
  // 应用信息
  static const String appName = 'Light Meter';
  static const String appVersion = '1.0.0';

  // 测量范围
  static const double minLux = 10;
  static const double maxLux = 100000;
  static const double minCCT = 2000;
  static const double maxCCT = 10000;

  // 校准系数范围
  static const double minCalibrationFactor = 0.5;
  static const double maxCalibrationFactor = 2.0;
  static const double defaultCalibrationFactor = 1.0;

  // 数据保留
  static const int defaultRetentionDays = 30;

  // 采样间隔（毫秒）
  static const int defaultSamplingInterval = 500;

  // 平滑处理
  static const int smoothingWindowSize = 5;
}

/// 光照状态枚举
enum LightStatus {
  ideal,    // 理想
  low,      // 偏低
  high,     // 偏高
  unknown,  // 未知
}

/// 色温类型枚举
enum ColorTemperatureType {
  warmLight,    // 暖光 (< 3500K)
  neutralLight, // 中性光 (3500K - 5000K)
  daylight,     // 日光 (5000K - 6500K)
  coolLight,    // 冷光 (> 6500K)
}