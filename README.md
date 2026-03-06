# Light Meter - 智能光线感应工具

一款基于智能手机前置摄像头的专业级光线感应工具，将复杂的农业/园艺光学指标平民化，辅助用户精准控制植物生长环境。

## 功能特性

- ✅ 实时 Lux（勒克斯）监测
- ✅ 实时 CCT（相关色温）监测
- ✅ 摄像头实时预览
- ✅ 多帧数据平滑处理
- ✅ 简单校准（滑块调节）
- ✅ 参照校准（专业照度计对比）
- ✅ 本地历史记录存储
- ✅ 数据导出功能

## 技术栈

- **框架**: Flutter 3.x
- **语言**: Dart
- **数据库**: SQLite (sqflite)
- **状态管理**: Provider
- **摄像头**: camera 插件

## 项目结构

```
lib/
├── main.dart                 # 应用入口
├── app.dart                  # MaterialApp 配置
│
├── core/                     # 核心层
│   ├── constants/            # 常量定义
│   ├── theme/                # 主题配置
│   ├── database/             # 数据库
│   └── utils/                # 工具函数
│
├── features/                 # 功能模块
│   ├── camera/               # 摄像头模块
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── calibration/          # 校准模块
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── history/              # 历史记录模块
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   └── settings/             # 设置模块
│       └── presentation/
│
└── shared/                   # 共享组件
    ├── widgets/
    └── services/
```

## 开始使用

### 环境要求

- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0
- Android SDK (用于 Android 开发)

### 安装步骤

1. **克隆项目**
   ```bash
   git clone <repository-url>
   cd light
   ```

2. **安装依赖**
   ```bash
   flutter pub get
   ```

3. **运行应用**
   ```bash
   flutter run
   ```

### 构建 APK

```bash
flutter build apk --release
```

## 权限说明

本应用需要以下权限：

- **摄像头权限**: 用于捕获环境光信息进行光照强度计算

## 核心算法

### Lux 计算

使用 ITU-R BT.601 标准计算亮度：
```
Y = 0.299*R + 0.587*G + 0.114*B
```

### CCT 计算

使用 McCamy 近似公式计算相关色温：
```
n = (x - 0.3320) / (0.1858 - y)
CCT = 449 × n³ + 3525 × n² + 6823.3 × n + 5520.33
```

## 设计文档

- [设计文档](docs/plans/2026-03-05-light-meter-design.md)
- [PRD 文档](docs/PRD-light-meter.md)
- [UI 设计规范](docs/UI-design-spec.md)
- [UI 预览](docs/ui-preview.html)

## 版本历史

### v1.0.0 (2026-03-05)

- 初始版本
- 实现 Lux + CCT 实时监测
- 实现校准功能
- 实现历史记录功能

## 许可证

MIT License

## 联系方式

如有问题或建议，请发送邮件至：feedback@lightmeter.app