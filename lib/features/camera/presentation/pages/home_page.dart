import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../calibration/data/calibration_repository.dart';
import '../../../history/data/measurement_repository.dart';
import '../../domain/models/measurement.dart';
import '../widgets/param_card.dart';
import '../../../settings/presentation/pages/settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  CameraController? _cameraController;
  bool _isInitialized = false;
  double _lux = 0;
  double _cct = 6500;
  double _calibrationFactor = 1.0;
  bool _autoRecord = true;
  final List<double> _luxHistory = [];
  final List<double> _cctHistory = [];
  
  // 摄像头选择
  bool _useFrontCamera = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
    _loadCalibration();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  /// 切换摄像头
  Future<void> _toggleCamera() async {
    setState(() {
      _isInitialized = false;
      _useFrontCamera = !_useFrontCamera;
    });
    
    await _cameraController?.dispose();
    await _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _showError('未找到摄像头');
        return;
      }

      // 根据选择使用前置或后置摄像头
      final targetCamera = _useFrontCamera
          ? cameras.firstWhere(
              (camera) => camera.lensDirection == CameraLensDirection.front,
              orElse: () => cameras.first,
            )
          : cameras.firstWhere(
              (camera) => camera.lensDirection == CameraLensDirection.back,
              orElse: () => cameras.first,
            );

      _cameraController = CameraController(
        targetCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() => _isInitialized = true);
        _startImageStream();
      }
    } catch (e) {
      _showError('摄像头初始化失败: $e');
    }
  }

  void _startImageStream() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    _cameraController!.startImageStream((image) {
      _processImage(image);
    });
  }

  void _processImage(CameraImage image) {
    try {
      // 直接从 Y 平面计算亮度（YUV420 格式，Y 平面是第一个）
      final yPlane = image.planes[0];
      final yBytes = yPlane.bytes;
      
      // 计算平均亮度
      int totalY = 0;
      final int length = yBytes.length;
      
      // 采样计算（每隔 4 个像素）
      int sampleCount = 0;
      for (int i = 0; i < length; i += 4) {
        totalY += yBytes[i] & 0xFF;
        sampleCount++;
      }
      
      if (sampleCount == 0) return;
      
      final avgY = totalY / sampleCount;
      
      // 计算 Lux
      double newLux = _mapYToLux(avgY);
      newLux *= _calibrationFactor;
      
      // 计算 CCT
      double newCct = _calculateCCT(image);
      
      // 平滑处理
      _luxHistory.add(newLux);
      _cctHistory.add(newCct);
      
      if (_luxHistory.length > AppConstants.smoothingWindowSize) {
        _luxHistory.removeAt(0);
        _cctHistory.removeAt(0);
      }
      
      final smoothedLux = _luxHistory.reduce((a, b) => a + b) / _luxHistory.length;
      final smoothedCct = _cctHistory.reduce((a, b) => a + b) / _cctHistory.length;
      
      if (mounted) {
        setState(() {
          _lux = smoothedLux;
          _cct = smoothedCct;
        });
      }
    } catch (e) {
      debugPrint('图像处理错误: $e');
    }
  }

  /// 将 Y 值映射到 Lux
  double _mapYToLux(double y) {
    if (y <= 0) return 0;
    
    // Y 值范围: 0-255 (黑色到白色)
    // 使用非线性映射扩展动态范围
    
    final normalizedY = y / 255.0;
    
    // 使用幂函数映射
    // 低光区域更敏感，高光区域压缩
    double lux;
    if (normalizedY < 0.05) {
      // 非常暗：0-50 Lux
      lux = normalizedY * 1000;
    } else if (normalizedY < 0.2) {
      // 暗：50-500 Lux
      lux = 50 + (normalizedY - 0.05) * 3000;
    } else if (normalizedY < 0.6) {
      // 中等：500-3000 Lux
      lux = 500 + (normalizedY - 0.2) * 6250;
    } else {
      // 亮：3000-100000 Lux
      lux = 3000 + math.pow((normalizedY - 0.6) * 2.5, 2) * 11200;
    }
    
    return lux.clamp(0, 100000);
  }

  /// 从 YUV 数据计算 CCT
  double _calculateCCT(CameraImage image) {
    try {
      // YUV420 格式：U 和 V 平面是交错的
      final uPlane = image.planes[1];
      final vPlane = image.planes[2];
      
      final uBytes = uPlane.bytes;
      final vBytes = vPlane.bytes;
      
      // 计算平均 UV
      int totalU = 0;
      int totalV = 0;
      int sampleCount = 0;
      
      final int minLength = math.min(uBytes.length, vBytes.length);
      
      for (int i = 0; i < minLength; i += 8) {
        totalU += uBytes[i] & 0xFF;
        totalV += vBytes[i] & 0xFF;
        sampleCount++;
      }
      
      if (sampleCount == 0) return 6500;
      
      // UV 值中心是 128
      final avgU = (totalU / sampleCount) - 128;
      final avgV = (totalV / sampleCount) - 128;
      
      // 根据色度估算色温
      // V 偏高 -> 偏红（低色温，暖光）
      // U 偏高 -> 偏蓝（高色温，冷光）
      
      final colorRatio = avgV - avgU * 0.5;
      
      double cct;
      if (colorRatio > 30) {
        cct = 2700; // 暖光（白炽灯）
      } else if (colorRatio > 10) {
        cct = 3500; // 暖白光
      } else if (colorRatio > -10) {
        cct = 5000; // 中性光
      } else if (colorRatio > -30) {
        cct = 6000; // 日光
      } else {
        cct = 7500; // 冷光
      }
      
      return cct.clamp(2000, 10000);
    } catch (e) {
      return 6500;
    }
  }

  Future<void> _loadCalibration() async {
    final repo = context.read<CalibrationRepository>();
    final config = await repo.getDefault();
    if (config != null && mounted) {
      setState(() => _calibrationFactor = config.factor);
    }
  }

  void _saveMeasurement() async {
    if (!_autoRecord) return;

    final repo = context.read<MeasurementRepository>();
    await repo.insert(Measurement(
      lux: _lux,
      cct: _cct,
      calibrationFactor: _calibrationFactor,
      createdAt: DateTime.now(),
    ));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已保存测量记录'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.softWhite,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildCameraPreview(),
                    const SizedBox(height: 20),
                    _buildParamCards(),
                    const SizedBox(height: 20),
                    _buildBottomSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Light Meter',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: AppTheme.deepCharcoal,
            ),
          ),
          Row(
            children: [
              // 摄像头切换按钮
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    _useFrontCamera ? Icons.camera_front : Icons.camera_rear,
                    color: AppTheme.deepCharcoal,
                  ),
                  onPressed: _toggleCamera,
                  tooltip: _useFrontCamera ? '切换到后置摄像头' : '切换到前置摄像头',
                ),
              ),
              const SizedBox(width: 8),
              // 设置按钮
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.settings_outlined, color: AppTheme.deepCharcoal),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsPage()),
                    );
                    _loadCalibration();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          height: 280,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryGreen.withOpacity(0.12),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: _isInitialized && _cameraController != null
                ? Stack(
                    children: [
                      CameraPreview(_cameraController!),
                      _buildOverlayParams(),
                      // 测量提示
                      Positioned(
                        top: 16,
                        left: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _useFrontCamera ? Icons.phone_android : Icons.camera_alt,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _useFrontCamera 
                                      ? '前置摄像头 • 避免屏幕反光'
                                      : '后置摄像头 • 更准确测量',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: CircularProgressIndicator(color: AppTheme.primaryGreen),
                    ),
                  ),
          ),
        ),
        // 测量提示
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.softGreen.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, color: AppTheme.primaryGreen, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _useFrontCamera
                        ? '提示：将手机屏幕朝下，让摄像头对准光源，减少屏幕反光干扰'
                        : '提示：使用后置摄像头测量更准确，对准光源即可',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.darkGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOverlayParams() {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildOverlayItem('🌞', _lux.toStringAsFixed(0), 'Lux', _getLuxStatusText()),
            Container(width: 1, height: 40, color: Colors.grey[300]),
            _buildOverlayItem('🌡️', _cct.toStringAsFixed(0), 'K', _getCCTStatusText()),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlayItem(String icon, String value, String unit, String status) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppTheme.deepCharcoal,
          ),
        ),
        Text(
          unit,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.earthBrown,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '● $status',
          style: TextStyle(
            fontSize: 12,
            color: _getLuxStatus() == LightStatus.ideal ? AppTheme.ideal : AppTheme.warning,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildParamCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: ParamCard(
              icon: '🌞',
              title: '亮度',
              value: _lux.toStringAsFixed(0),
              unit: 'Lux',
              status: _getLuxStatus(),
              statusText: _getLuxStatusText(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ParamCard(
              icon: '🌡️',
              title: '色温',
              value: _cct.toStringAsFixed(0),
              unit: 'K',
              status: _getCCTStatus(),
              statusText: _getCCTStatusText(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildInfoRow(
            '📊',
            '校准系数',
            '${_calibrationFactor.toStringAsFixed(2)}x',
            onTap: _showCalibrationDialog,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            '📅',
            '历史记录',
            '查看',
            onTap: () {
              // TODO: Navigate to history page
            },
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _saveMeasurement,
            icon: const Icon(Icons.save),
            label: const Text('保存记录'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String icon, String label, String value, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryGreen.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.deepCharcoal,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppTheme.earthBrown, size: 20),
          ],
        ),
      ),
    );
  }

  LightStatus _getLuxStatus() {
    if (_lux < 500) return LightStatus.low;
    if (_lux > 5000) return LightStatus.high;
    return LightStatus.ideal;
  }

  String _getLuxStatusText() {
    switch (_getLuxStatus()) {
      case LightStatus.ideal:
        return '理想';
      case LightStatus.low:
        return '偏低';
      case LightStatus.high:
        return '偏高';
      default:
        return '未知';
    }
  }

  LightStatus _getCCTStatus() {
    if (_cct >= 5000 && _cct <= 6500) return LightStatus.ideal;
    return LightStatus.low;
  }

  String _getCCTStatusText() {
    if (_cct < 3500) return '暖光';
    if (_cct < 5000) return '中性光';
    if (_cct <= 6500) return '日光';
    return '冷光';
  }

  void _showCalibrationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('校准系数'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('当前: ${_calibrationFactor.toStringAsFixed(2)}x'),
            const SizedBox(height: 16),
            Slider(
              value: _calibrationFactor,
              min: AppConstants.minCalibrationFactor,
              max: AppConstants.maxCalibrationFactor,
              divisions: 30,
              label: _calibrationFactor.toStringAsFixed(2),
              onChanged: (value) {
                setState(() => _calibrationFactor = value);
              },
            ),
            const Text('0.5x                    2.0x'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _calibrationFactor = 1.0);
              Navigator.pop(context);
            },
            child: const Text('重置'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}