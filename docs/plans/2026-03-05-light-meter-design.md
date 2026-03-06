# Light Meter - 智能光线感应工具设计文档

## 项目概览

| 项目名称 | Light Meter - 智能光线感应工具 |
|---------|------------------------------|
| 目标平台 | Android (Flutter) |
| 核心功能 | Lux + CCT 实时监测 + 本地历史记录 |
| 目标用户 | 农业/园艺从业者、植物爱好者 |

---

## 需求边界

| 维度 | 决策 |
|------|------|
| 核心指标 | Lux + CCT（不含 PAR/PPFD） |
| 平台 | Flutter Android 原生 App |
| 校准方式 | 混合模式（系数调节 + 参照设备校准） |
| 数据记录 | 本地 SQLite 存储 |

---

## 技术栈

| 类别 | 技术选型 |
|------|---------|
| 框架 | Flutter 3.x + Dart |
| 摄像头 | camera 插件 |
| 数据库 | sqflite |
| 权限管理 | permission_handler |
| 状态管理 | Provider / Riverpod |

---

## 项目架构

```
light/
├── lib/
│   ├── main.dart                 # 应用入口
│   ├── app.dart                  # MaterialApp 配置
│   │
│   ├── core/                     # 核心层
│   │   ├── constants/            # 常量定义
│   │   ├── theme/                # 主题配置
│   │   └── utils/                # 工具函数
│   │
│   ├── features/                 # 功能模块
│   │   ├── camera/               # 摄像头模块
│   │   │   ├── data/             # 数据层
│   │   │   ├── domain/           # 业务逻辑
│   │   │   └── presentation/     # UI 层
│   │   │
│   │   ├── calibration/          # 校准模块
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   │
│   │   └── history/              # 历史记录模块
│   │       ├── data/
│   │       ├── domain/
│   │       └── presentation/
│   │
│   └── shared/                   # 共享组件
│       ├── widgets/              # 通用 UI 组件
│       └── services/             # 共享服务
│
├── pubspec.yaml                  # 依赖配置
└── README.md
```

---

## 核心算法设计

### Lux 计算算法

```
输入：摄像头帧 → RGB 像素数据
处理流程：
  1. 获取帧平均亮度 Y = 0.299*R + 0.587*G + 0.114*B
  2. 应用曝光补偿系数
  3. 映射到 Lux 范围（经验公式）

公式：
  Lux = (Y × 校准系数) × 设备补偿因子

校准系数：
  - 简单模式：用户滑块调节 0.5x - 2.0x
  - 参照模式：用户输入专业照度计读数，反推系数
```

### CCT（相关色温）计算算法

```
输入：RGB 数据
处理流程：
  1. RGB → XYZ 色彩空间转换
  2. XYZ → CIE 1931 xy 色度坐标
  3. McCamy 近似公式计算 CCT

公式：
  n = (x - 0.3320) / (0.1858 - y)
  CCT = 449 × n³ + 3525 × n² + 6823.3 × n + 5520.33

输出范围：2000K（暖光）- 10000K（冷光）
```

### 数据平滑处理

```
问题：摄像头帧数据抖动大
解决方案：
  - 滑动窗口平均（最近 5 帧）
  - 异常值过滤（偏离均值 > 2σ 则丢弃）
  - 渐进式更新 UI（避免数值跳变）
```

---

## UI/UX 设计

### 主界面布局

```
┌─────────────────────────────────────┐
│  Light Meter              ⚙️ 设置   │
├─────────────────────────────────────┤
│                                     │
│     ┌─────────────────────────┐     │
│     │                         │     │
│     │   摄像头实时预览画面     │     │
│     │                         │     │
│     │   (全屏或 4:3 比例)     │     │
│     │                         │     │
│     └─────────────────────────┘     │
│                                     │
├─────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐   │
│  │  🌞 亮度    │  │  🌡️ 色温   │   │
│  │  1,234 Lux │  │  5,600 K   │   │
│  │  [理想]    │  │  [日光]    │   │
│  └─────────────┘  └─────────────┘   │
│                                     │
│     📊 校准系数: 1.05x              │
│     📅 历史记录 (3)                 │
└─────────────────────────────────────┘
```

### 核心交互

| 交互 | 操作 | 反馈 |
|------|------|------|
| 查看详情 | 点击 Lux/CCT 卡片 | 展开显示范围说明 |
| 调整校准 | 点击系数值 | 弹出滑块/参照校准面板 |
| 查看历史 | 点击历史记录 | 跳转历史列表页 |
| 切换单位 | 长按数值 | 切换显示单位（如 Lux ↔ fc） |

### 色彩方案

```
主题色：自然绿色系（呼应植物/农业场景）
  - Primary: #4CAF50 (Material Green)
  - Secondary: #81C784 (Light Green)
  - Background: #F5F5F5 (Light Grey)

状态色：
  - 理想范围：绿色
  - 偏低/偏高：橙色
  - 异常值：红色
```

---

## 数据存储设计

### 数据库结构

```sql
-- 测量记录表
CREATE TABLE measurements (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  lux REAL NOT NULL,              -- 勒克斯值
  cct REAL NOT NULL,              -- 色温值
  calibration_factor REAL,        -- 当时使用的校准系数
  device_model TEXT,              -- 设备型号
  created_at INTEGER NOT NULL,    -- 时间戳
  note TEXT                       -- 用户备注
);

-- 校准配置表
CREATE TABLE calibration_configs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,             -- 配置名称
  factor REAL NOT NULL,           -- 校准系数
  reference_lux REAL,             -- 参照照度计读数
  is_default INTEGER DEFAULT 0,   -- 是否默认配置
  created_at INTEGER NOT NULL
);
```

### 数据访问层

```
MeasurementRepository
  ├── Future<void> insert(Measurement m)
  ├── Future<List<Measurement>> getAll()
  ├── Future<List<Measurement>> getByDateRange(DateTime start, end)
  └── Future<void> delete(int id)

CalibrationRepository
  ├── Future<CalibrationConfig> getDefault()
  ├── Future<void> setDefault(int id)
  └── Future<void> save(CalibrationConfig c)
```

### 数据保留策略

| 策略 | 配置 |
|------|------|
| 默认保留 | 最近 30 天数据 |
| 自动清理 | 每次启动检查并删除过期数据 |
| 用户控制 | 设置中可调整保留天数或关闭自动清理 |

---

## 功能清单

| 功能模块 | 优先级 | 描述 |
|---------|--------|------|
| 实时预览 | P0 | 摄像头画面 + 叠加参数显示 |
| Lux 计算 | P0 | RGB → 亮度转换 + 校准 |
| CCT 计算 | P0 | RGB → 色温转换 |
| 简单校准 | P0 | 滑块调节 0.5x-2.0x |
| 参照校准 | P1 | 输入专业照度计读数对比 |
| 历史记录 | P1 | 本地存储 + 列表查看 |
| 数据导出 | P2 | CSV/JSON 导出（二期） |

---

## 验收标准

| 验收项 | 标准 |
|--------|------|
| 响应速度 | 参数更新延迟 < 500ms |
| 精度范围 | Lux: 10-100,000 lx ±15% |
| 精度范围 | CCT: 2000-10000K ±200K |
| 稳定性 | 连续运行 30 分钟无崩溃 |
| 权限处理 | 拒绝权限时显示友好提示 |

---

## 风险与对策

| 风险 | 影响 | 对策 |
|------|------|------|
| 摄像头硬件差异 | 精度不一致 | 提供校准功能 + 设备指纹库（二期） |
| 低光环境噪点多 | 读数波动大 | 多帧平滑 + 异常值过滤 |
| 后台运行限制 | 无法持续监测 | 提示用户保持前台运行 |

---

## 决策记录

| 日期 | 决策项 | 选择 | 理由 |
|------|--------|------|------|
| 2026-03-05 | 核心指标 | Lux + CCT | MVP 快速验证，PAR/PPFD 二期迭代 |
| 2026-03-05 | 平台 | Flutter Android | 性能与开发体验平衡 |
| 2026-03-05 | 校准方式 | 混合模式 | 兼顾易用与专业 |
| 2026-03-05 | 数据记录 | 本地 SQLite | 平衡功能与复杂度 |
| 2026-03-05 | 技术方案 | MVP 方案 | 快速验证核心价值 |