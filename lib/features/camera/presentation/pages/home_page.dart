import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/light_calculator.dart';
import '../../../calibration/data/calibration_repository.dart';
import '../../../history/data/measurement_repository.dart';
import '../../domain/models/measurement.dart';
import '../widgets/param_card.dart';
import '../widgets/camera_preview_widget.dart';
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
  List<double> _luxHistory = [];
  List<double> _cctHistory = [];

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

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _showError('未找到摄像头');
        return;
      }

      // 使用前置摄像头
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
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
      // 处理摄像头帧数据
      _processImage(image);
    });
  }

  void _processImage(CameraImage image) {
    try {
      // 将 YUV 转换为 RGBA (简化处理)
      final bytes = _convertYUVToRGBA(image);

      // 计算 Lux
      final newLux = LightCalculator.calculateLux(
        bytes,
        _calibrationFactor,
        1.0,
      );

      // 计算 CCT
      final newCct = LightCalculator.calculateCCT(bytes);

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
      // 忽略处理错误
    }
  }

  Uint8List? _convertYUVToRGBA(CameraImage image) {
    // 简化的 YUV 到 RGBA 转换
    // 实际应用中需要更精确的转换
    try {
      final int width = image.width;
      final int height = image.height;
      final int uvRowStride = image.planes[1].bytesPerRow;
      final int uvPixelStride = image.planes[1].bytesPerPixel ?? 1;

      final rgba = Uint8List(width * height * 4);

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final int uvIndex = uvPixelStride * (x ~/ 2) + uvRowStride * (y ~/ 2);
          final int index = y * width + x;

          final yp = image.planes[0].bytes[index];
          final up = image.planes[1].bytes[uvIndex];
          final vp = image.planes[2].bytes[uvIndex];

          int r = (yp + vp * 1.370705).round().clamp(0, 255);
          int g = (yp - up * 0.337633 - vp * 0.698001).round().clamp(0, 255);
          int b = (yp + up * 1.732446).round().clamp(0, 255);

          rgba[index * 4] = r;
          rgba[index * 4 + 1] = g;
          rgba[index * 4 + 2] = b;
          rgba[index * 4 + 3] = 255;
        }
      }

      return rgba;
    } catch (e) {
      return null;
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
    );
  }

  Widget _buildCameraPreview() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 320,
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
                ],
              )
            : Container(
                color: Colors.grey[300],
                child: const Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryGreen),
                ),
              ),
      ),
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
            _buildOverlayItem('🌞', _lux.toStringAsFixed(0), 'Lux', '理想'),
            Container(width: 1, height: 40, color: Colors.grey[300]),
            _buildOverlayItem('🌡️', _cct.toStringAsFixed(0), 'K', '日光'),
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
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.ideal,
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
        return '理想范围';
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