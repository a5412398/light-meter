import 'dart:math';
import 'dart:typed_data';

/// 光照计算器
class LightCalculator {
  /// 计算亮度 (Lux)
  /// 从 RGB 数据计算亮度值
  static double calculateLux(
    Uint8List? imageData,
    double calibrationFactor,
    double exposureCompensation,
  ) {
    if (imageData == null || imageData.isEmpty) {
      return 0;
    }

    // 计算平均亮度 (ITU-R BT.601 标准)
    double totalLuminance = 0;
    int pixelCount = 0;

    // 假设 imageData 是 RGBA 格式
    for (int i = 0; i < imageData.length - 3; i += 4) {
      final r = imageData[i];
      final g = imageData[i + 1];
      final b = imageData[i + 2];

      // Y = 0.299*R + 0.587*G + 0.114*B
      totalLuminance += 0.299 * r + 0.587 * g + 0.114 * b;
      pixelCount++;
    }

    if (pixelCount == 0) return 0;

    final avgLuminance = totalLuminance / pixelCount;

    // 将亮度值映射到 Lux 范围 (经验公式)
    // 这里使用简化的映射，实际应用需要根据设备校准
    double lux = _mapLuminanceToLux(avgLuminance);

    // 应用校准系数和曝光补偿
    lux *= calibrationFactor * exposureCompensation;

    // 限制在有效范围内
    return lux.clamp(0, 100000);
  }

  /// 将亮度值映射到 Lux
  static double _mapLuminanceToLux(double luminance) {
    // 简化的映射公式
    // 实际应用需要根据摄像头特性进行校准
    // 这里使用对数映射来扩展动态范围
    if (luminance <= 0) return 0;

    // 使用对数映射扩展动态范围
    final normalizedLuminance = luminance / 255;
    final logValue = log(normalizedLuminance * 100 + 1);
    final lux = logValue * 2000;

    return lux;
  }

  /// 计算相关色温 (CCT)
  /// 使用 McCamy 近似公式
  static double calculateCCT(Uint8List? imageData) {
    if (imageData == null || imageData.isEmpty) {
      return 6500; // 默认日光色温
    }

    // 计算平均 RGB 值
    double totalR = 0, totalG = 0, totalB = 0;
    int pixelCount = 0;

    for (int i = 0; i < imageData.length - 3; i += 4) {
      totalR += imageData[i];
      totalG += imageData[i + 1];
      totalB += imageData[i + 2];
      pixelCount++;
    }

    if (pixelCount == 0) return 6500;

    final avgR = totalR / pixelCount;
    final avgG = totalG / pixelCount;
    final avgB = totalB / pixelCount;

    // RGB -> XYZ 转换 (sRGB D65)
    final x = 0.4124564 * avgR + 0.3575761 * avgG + 0.1804375 * avgB;
    final y = 0.2126729 * avgR + 0.7151522 * avgG + 0.0721750 * avgB;
    final z = 0.0193339 * avgR + 0.1191920 * avgG + 0.9503041 * avgB;

    // XYZ -> CIE 1931 xy 色度坐标
    final sum = x + y + z;
    if (sum == 0) return 6500;

    final xChromaticity = x / sum;
    final yChromaticity = y / sum;

    // McCamy 近似公式计算 CCT
    final n = (xChromaticity - 0.3320) / (0.1858 - yChromaticity);
    final cct = 449 * pow(n, 3) + 3525 * pow(n, 2) + 6823.3 * n + 5520.33;

    // 限制在有效范围内
    return cct.clamp(2000, 10000);
  }

  /// 平滑处理 - 滑动窗口平均
  static List<double> smoothValues(List<double> values, int windowSize) {
    if (values.length < windowSize) return values;

    final smoothed = <double>[];
    for (int i = 0; i < values.length; i++) {
      final start = i - windowSize ~/ 2;
      final end = i + windowSize ~/ 2 + 1;
      final window = values.sublist(
        start.clamp(0, values.length - 1),
        end.clamp(0, values.length),
      );
      final avg = window.reduce((a, b) => a + b) / window.length;
      smoothed.add(avg);
    }

    return smoothed;
  }

  /// 异常值过滤
  static double filterOutlier(List<double> values, double newValue) {
    if (values.length < 3) return newValue;

    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) / values.length;
    final stdDev = sqrt(variance);

    // 如果新值偏离均值超过 2 个标准差，则视为异常值
    if ((newValue - mean).abs() > 2 * stdDev) {
      return mean; // 返回均值代替异常值
    }

    return newValue;
  }
}