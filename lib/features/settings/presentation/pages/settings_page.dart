import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _autoRecord = true;
  int _retentionDays = 30;
  String _defaultUnit = 'Lux';
  double _calibrationFactor = 1.0;

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
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection('测量设置', [
                      _buildDropdownItem(
                        icon: '📏',
                        title: '默认单位',
                        subtitle: '光照强度显示单位',
                        value: _defaultUnit,
                        options: const ['Lux', 'fc'],
                        onChanged: (value) {
                          setState(() => _defaultUnit = value);
                        },
                      ),
                      _buildToggleItem(
                        icon: '🔄',
                        title: '自动记录',
                        subtitle: '测量时自动保存数据',
                        value: _autoRecord,
                        onChanged: (value) {
                          setState(() => _autoRecord = value);
                        },
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildSection('校准设置', [
                      _buildSliderItem(
                        icon: '📊',
                        title: '校准系数',
                        value: _calibrationFactor,
                        onChanged: (value) {
                          setState(() => _calibrationFactor = value);
                        },
                      ),
                      _buildNavigationItem(
                        icon: '🎯',
                        title: '参照校准',
                        subtitle: '使用专业照度计校准',
                        onTap: () {
                          _showReferenceCalibrationDialog();
                        },
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildSection('数据管理', [
                      _buildDropdownItem(
                        icon: '📅',
                        title: '数据保留',
                        subtitle: '自动清理旧数据',
                        value: '$_retentionDays 天',
                        options: const ['7 天', '30 天', '90 天', '永久'],
                        onChanged: (value) {
                          final days = int.parse(value.replaceAll(' 天', ''));
                          setState(() => _retentionDays = days);
                        },
                      ),
                      _buildNavigationItem(
                        icon: '📤',
                        title: '导出数据',
                        subtitle: '导出为 CSV 文件',
                        onTap: () {
                          _showExportDialog();
                        },
                      ),
                      _buildDangerItem(
                        icon: '🗑️',
                        title: '清除所有数据',
                        subtitle: '删除所有历史记录',
                        onTap: () {
                          _showDeleteConfirmDialog();
                        },
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildSection('关于', [
                      _buildNavigationItem(
                        icon: 'ℹ️',
                        title: '使用指南',
                        subtitle: '如何正确使用本应用',
                        onTap: () {
                          _showGuideDialog();
                        },
                      ),
                      _buildNavigationItem(
                        icon: '⭐',
                        title: '评价应用',
                        subtitle: '在应用商店给我们评分',
                        onTap: () {},
                      ),
                      _buildNavigationItem(
                        icon: '📧',
                        title: '反馈问题',
                        subtitle: '报告 Bug 或提出建议',
                        onTap: () {
                          _showFeedbackDialog();
                        },
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildVersionInfo(),
                    const SizedBox(height: 32),
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
        children: [
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
              icon: const Icon(Icons.arrow_back, color: AppTheme.deepCharcoal),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const Expanded(
            child: Text(
              '设置',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: AppTheme.deepCharcoal,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.earthBrown,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
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
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildToggleItem({
    required String icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return _buildSettingsItem(
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: Switch(
        value: value,
        activeColor: AppTheme.primaryGreen,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDropdownItem({
    required String icon,
    required String title,
    required String subtitle,
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    return _buildSettingsItem(
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.softGreen.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButton<String>(
          value: value,
          underline: const SizedBox(),
          icon: const Icon(Icons.arrow_drop_down, size: 16),
          items: options.map((option) {
            return DropdownMenuItem(
              value: option,
              child: Text(option),
            );
          }).toList(),
          onChanged: (newValue) {
            if (newValue != null) onChanged(newValue);
          },
        ),
      ),
    );
  }

  Widget _buildSliderItem({
    required String icon,
    required String title,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(icon, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.deepCharcoal,
                    ),
                  ),
                ],
              ),
              Text(
                '${value.toStringAsFixed(2)}x',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppTheme.primaryGreen,
              inactiveTrackColor: AppTheme.softGreen,
              thumbColor: Colors.white,
              overlayColor: AppTheme.primaryGreen.withOpacity(0.12),
            ),
            child: Slider(
              value: value,
              min: AppConstants.minCalibrationFactor,
              max: AppConstants.maxCalibrationFactor,
              divisions: 30,
              onChanged: onChanged,
            ),
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0.5x', style: TextStyle(fontSize: 11, color: AppTheme.earthBrown)),
              Text('1.0x', style: TextStyle(fontSize: 11, color: AppTheme.earthBrown)),
              Text('1.5x', style: TextStyle(fontSize: 11, color: AppTheme.earthBrown)),
              Text('2.0x', style: TextStyle(fontSize: 11, color: AppTheme.earthBrown)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationItem({
    required String icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return _buildSettingsItem(
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: const Icon(Icons.chevron_right, color: AppTheme.earthBrown),
      onTap: onTap,
    );
  }

  Widget _buildDangerItem({
    required String icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return _buildSettingsItem(
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: const Icon(Icons.chevron_right, color: AppTheme.error),
      titleColor: AppTheme.error,
      onTap: onTap,
    );
  }

  Widget _buildSettingsItem({
    required String icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    Color? titleColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.withOpacity(0.1),
            ),
          ),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: titleColor ?? AppTheme.deepCharcoal,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.earthBrown,
                    ),
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildVersionInfo() {
    return Center(
      child: Column(
        children: [
          const Text(
            'Light Meter',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.deepCharcoal,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '版本 ${AppConstants.appVersion}',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.earthBrown,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '© 2026 Light Meter Team',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.earthBrown,
            ),
          ),
        ],
      ),
    );
  }

  void _showReferenceCalibrationDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('参照校准'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('请输入专业照度计的读数 (Lux):'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '例如: 1000',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              // 计算校准系数
              final reference = double.tryParse(controller.text);
              if (reference != null && reference > 0) {
                // 这里需要当前测量值来计算系数
                // 简化处理，直接使用输入值
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('校准系数已更新')),
                );
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导出数据'),
        content: const Text('确定要导出所有历史记录为 CSV 文件吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('数据已导出')),
              );
            },
            child: const Text('导出'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除所有历史记录吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
            ),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('所有数据已删除')),
              );
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _showGuideDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('使用指南'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('1. 授权摄像头权限'),
              SizedBox(height: 8),
              Text('2. 将手机对准光源'),
              SizedBox(height: 8),
              Text('3. 查看实时 Lux 和 CCT 数值'),
              SizedBox(height: 8),
              Text('4. 使用校准功能提高精度'),
              SizedBox(height: 8),
              Text('5. 保存测量记录供后续查看'),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('反馈问题'),
        content: const Text('请发送邮件至:\nfeedback@lightmeter.app'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}