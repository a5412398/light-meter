import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/measurement_repository.dart';
import '../../../camera/domain/models/measurement.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Measurement> _measurements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMeasurements();
  }

  Future<void> _loadMeasurements() async {
    final repo = context.read<MeasurementRepository>();
    final measurements = await repo.getAll();
    if (mounted) {
      setState(() {
        _measurements = measurements;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteMeasurement(int id) async {
    final repo = context.read<MeasurementRepository>();
    await repo.delete(id);
    _loadMeasurements();
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
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.primaryGreen),
                    )
                  : _measurements.isEmpty
                      ? _buildEmptyState()
                      : _buildMeasurementList(),
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
              '历史记录',
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '暂无历史记录',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '开始测量后，记录将显示在这里',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementList() {
    return RefreshIndicator(
      color: AppTheme.primaryGreen,
      onRefresh: _loadMeasurements,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _measurements.length,
        itemBuilder: (context, index) {
          final measurement = _measurements[index];
          return _buildMeasurementCard(measurement);
        },
      ),
    );
  }

  Widget _buildMeasurementCard(Measurement measurement) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Dismissible(
        key: Key(measurement.id.toString()),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: AppTheme.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.delete,
            color: AppTheme.error,
          ),
        ),
        onDismissed: (_) {
          if (measurement.id != null) {
            _deleteMeasurement(measurement.id!);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _getStatusColor(measurement.lux),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        dateFormat.format(measurement.createdAt),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.deepCharcoal,
                        ),
                      ),
                    ],
                  ),
                  if (measurement.calibrationFactor != null)
                    Text(
                      '校准: ${measurement.calibrationFactor!.toStringAsFixed(2)}x',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.earthBrown,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildValueChip(
                    '🌞',
                    '${measurement.lux.toStringAsFixed(0)} Lux',
                  ),
                  const SizedBox(width: 12),
                  _buildValueChip(
                    '🌡️',
                    '${measurement.cct.toStringAsFixed(0)} K',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildValueChip(String icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.softGreen.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.deepCharcoal,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(double lux) {
    if (lux < 500 || lux > 5000) {
      return AppTheme.warning;
    }
    return AppTheme.ideal;
  }
}