import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'core/database/database_helper.dart';
import 'features/calibration/data/calibration_repository.dart';
import 'features/history/data/measurement_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化数据库
  await DatabaseHelper.instance.database;
  
  runApp(const LightMeterApp());
}

class LightMeterApp extends StatelessWidget {
  const LightMeterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<MeasurementRepository>(
          create: (_) => MeasurementRepository(),
        ),
        Provider<CalibrationRepository>(
          create: (_) => CalibrationRepository(),
        ),
      ],
      child: const App(),
    );
  }
}