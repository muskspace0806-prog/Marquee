# 波浪渐变动画 Label

一个使用 UIKit 实现的带波浪渐变动画效果的自定义 Label 组件，支持跑马灯滚动效果和 Emoji 显示。

## 功能特点

- ✨ 流畅的波浪渐变动画效果
- 🎨 支持自定义渐变颜色
- 🧭 支持 8 种渐变方向（水平、垂直、对角线）
- ⚙️ 可调节动画速度和帧率
- 🎪 支持跑马灯滚动效果
- 😀 Emoji 保持原色显示（不受渐变影响）
- 📱 纯 UIKit 实现
- 🎯 支持 Frame 布局
- 🔄 多重兜底机制确保跑马灯正常工作
- 📐 支持自定义文字对齐方式

## 安装

使用 CocoaPods 安装：

```ruby
pod 'MarqueeLabel'
```

然后运行：
```bash
pod install
```

## 使用方法

### 基础用法

```swift
let label = WaveGradientLabelView(frame: CGRect(x: 20, y: 100, width: 300, height: 60))
label.text = "波浪渐变"
label.font = UIFont.systemFont(ofSize: 40, weight: .bold)
label.gradientColors = [.systemPink, .systemPurple, .systemBlue]
label.gradientDirection = .horizontalLeftToRight
label.animationDuration = 3.0
label.startAnimation()
view.addSubview(label)
```

### 启用跑马灯效果

```swift
let label = WaveGradientLabelView(frame: CGRect(x: 20, y: 100, width: 300, height: 60))
label.text = "这是一段很长的文字，会自动滚动显示😀"
label.font = UIFont.systemFont(ofSize: 40, weight: .bold)
label.gradientColors = [.systemPink, .systemPurple, .systemBlue]
label.gradientDirection = .horizontalLeftToRight
label.animationDuration = 3.0

// 启用跑马灯
label.enableMarquee = true
label.marqueeDirection = .rightToLeft  // 从右往左（默认）
label.marqueeSpeed = 20.0     // 滚动速度（像素/秒）
label.marqueeDelay = 1.0      // 延迟时间（秒）
label.marqueeGap = 40.0       // 两段文字之间的间距

label.startAnimation()
view.addSubview(label)
```

### RTL 语言支持（阿语等）

```swift
let label = WaveGradientLabelView(frame: CGRect(x: 20, y: 100, width: 300, height: 60))
label.text = "مرحبا بك في التطبيق 😀"  // 阿拉伯语
label.font = UIFont.systemFont(ofSize: 40, weight: .bold)
label.gradientColors = [.systemGreen, .systemTeal, .systemCyan]
label.gradientDirection = .horizontalLeftToRight
label.animationDuration = 3.0

// RTL 跑马灯（从左往右）
label.enableMarquee = true
label.marqueeDirection = .leftToRight  // 从左往右
label.marqueeSpeed = 20.0
label.marqueeDelay = 1.0

label.startAnimation()
view.addSubview(label)
```

### 使用 Emoji

```swift
let label = WaveGradientLabelView(frame: CGRect(x: 20, y: 100, width: 300, height: 60))
label.text = "Hello 😀🎉🔥"  // Emoji 会保持原色
label.gradientColors = [.systemPink, .systemPurple, .systemBlue]
label.startAnimation()
view.addSubview(label)
```

## 渐变方向

支持 8 种渐变方向：

```swift
// 水平方向
label.gradientDirection = .horizontalLeftToRight  // 左→右
label.gradientDirection = .horizontalRightToLeft  // 右→左

// 垂直方向
label.gradientDirection = .verticalTopToBottom    // 上→下
label.gradientDirection = .verticalBottomToTop    // 下→上

// 斜向（从上往下）
label.gradientDirection = .diagonalDownRight      // 左上→右下
label.gradientDirection = .diagonalDownLeft       // 右上→左下

// 斜向（从下往上）
label.gradientDirection = .diagonalUpRight        // 左下→右上
label.gradientDirection = .diagonalUpLeft         // 右下→左上
```

### 兼容旧版本

旧的方向名称仍然可用（会显示废弃警告）：

```swift
.horizontal              // 等同于 .horizontalLeftToRight
.vertical                // 等同于 .verticalTopToBottom
.topLeftToBottomRight    // 等同于 .diagonalDownRight
.topRightToBottomLeft    // 等同于 .diagonalDownLeft
```

## 属性说明

### 基础属性

| 属性 | 类型 | 说明 | 默认值 |
|------|------|------|--------|
| `text` | String | 文字内容 | "" |
| `font` | UIFont | 字体 | systemFont(40, bold) |
| `textColor` | UIColor | 文字颜色（非渐变状态） | .white |
| `gradientColors` | [UIColor] | 渐变颜色数组 | [pink, purple, blue, teal] |
| `gradientDirection` | WaveGradientDirection | 渐变方向 | .horizontalLeftToRight |
| `animationDuration` | TimeInterval | 动画时长（秒） | 3.0 |
| `autoStartAnimation` | Bool | 是否自动开始动画 | true |
| `enableAnimation` | Bool | 是否启用动画 | true |
| `preferredFramesPerSecond` | Int | 动画帧率 | 60 |
| `textAlignment` | NSTextAlignment | 文字对齐方式 | .center |

### 跑马灯属性

| 属性 | 类型 | 说明 | 默认值 |
|------|------|------|--------|
| `enableMarquee` | Bool | 是否启用跑马灯 | false |
| `marqueeSpeed` | CGFloat | 滚动速度（像素/秒） | 50.0 |
| `marqueeDelay` | TimeInterval | 延迟时间（秒） | 2.0 |
| `marqueeGap` | CGFloat | 两段文字之间的间距 | 40.0 |
| `marqueeDirection` | MarqueeDirection | 跑马灯方向 | .rightToLeft |
| `marqueeThreshold` | CGFloat | 启动跑马灯的阈值（0-1） | 1.0 |

## 方法说明

### 渐变动画

```swift
// 开始渐变动画
label.startAnimation()

// 停止渐变动画
label.stopAnimation()
```

### 跑马灯控制

```swift
// 重启跑马灯（兜底方法）
label.restartMarqueeIfNeeded()

// 调试跑马灯状态
label.debugMarqueeStatus()
```

## 实现原理

1. 使用 `CAGradientLayer` 创建渐变效果
2. 使用 `CADisplayLink` 实现流畅的动画循环
3. 通过 `CATransform3D` 平移渐变层实现无缝循环
4. 渐变层设置为 2 倍大小，locations 均匀分布，实现完美循环
5. 使用 layer mask 技术让渐变只在文字区域显示
6. Emoji 通过独立的 label 层显示，保持原色
7. 跑马灯使用 CADisplayLink 实现自定义滚动逻辑
8. 多重兜底机制（didMoveToWindow、layoutSubviews）确保跑马灯正常启动

## 性能优化

- 使用 `CADisplayLink` 替代 `CABasicAnimation`，避免动画循环时的卡顿
- 支持调整帧率（`preferredFramesPerSecond`），可设置为 30fps 降低 CPU 消耗
- 使用 `CATransaction.setDisableActions(true)` 避免隐式动画
- 在 `deinit` 中正确释放 DisplayLink，避免内存泄漏

## 常见问题

### 跑马灯不工作？

1. 确保文字宽度超过容器宽度
2. 确保 `enableMarquee = true`
3. 在 `viewDidAppear` 中调用 `restartMarqueeIfNeeded()`
4. 使用 `debugMarqueeStatus()` 查看详细状态

详见：[跑马灯问题排查指南.md](跑马灯问题排查指南.md)

### 文字显示省略号？

确保设置了正确的 `lineBreakMode`：

```swift
label.lineBreakMode = .byClipping  // 不显示省略号
```

详见：[文字被截断问题诊断.md](文字被截断问题诊断.md)

### 文字闪烁？

这是由于 frame 变化导致的，已在最新版本中修复。

详见：[文字闪烁问题修复说明.md](文字闪烁问题修复说明.md)

## 文档

- [渐变方向说明.md](渐变方向说明.md) - 8 种渐变方向详解
- [跑马灯兜底机制说明.md](跑马灯兜底机制说明.md) - 跑马灯兜底机制
- [跑马灯方向说明.md](跑马灯方向说明.md) - 跑马灯方向配置（LTR/RTL）
- [文字对齐方式配置说明.md](文字对齐方式配置说明.md) - 文字对齐配置
- [实际项目使用指南.md](实际项目使用指南.md) - 实际项目集成指南
- [性能说明.md](性能说明.md) - 性能分析和优化建议

## 系统要求

- iOS 13.0+
- Swift 5.0+
- Xcode 12.0+

## License

MIT License
