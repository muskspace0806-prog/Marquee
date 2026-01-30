# 波浪渐变动画 Label

一个使用 UIKit 实现的带波浪渐变动画效果的自定义 Label 组件，支持跑马灯滚动效果。

## 功能特点

- ✨ 流畅的波浪渐变动画效果
- 🎨 支持自定义渐变颜色
- 🧭 支持4种渐变方向（水平、垂直、对角线）
- ⚙️ 可调节动画速度
- 🎪 支持跑马灯滚动效果（基于 MarqueeLabel）
- 📱 纯 UIKit 实现
- 🎯 支持 Frame 布局

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
let label = WaveGradientLabel(frame: CGRect(x: 20, y: 100, width: 300, height: 60))
label.text = "波浪渐变"
label.font = UIFont.systemFont(ofSize: 40, weight: .bold)
label.gradientColors = [.systemPink, .systemPurple, .systemBlue]
label.gradientDirection = .horizontal
label.animationDuration = 3.0
label.startAnimation()
view.addSubview(label)
```

### 启用跑马灯效果

```swift
let label = WaveGradientLabel(frame: CGRect(x: 20, y: 100, width: 300, height: 60))
label.text = "这是一段很长的文字，会自动滚动显示"
label.font = UIFont.systemFont(ofSize: 40, weight: .bold)
label.gradientColors = [.systemPink, .systemPurple, .systemBlue]
label.gradientDirection = .horizontal
label.animationDuration = 3.0

// 启用跑马灯
label.enableMarquee = true
label.marqueeSpeed = 8.0      // 滚动一次的时间（秒）
label.marqueeDelay = 2.0      // 延迟时间（秒）
label.marqueeTrailingBuffer = 30.0  // 尾部缓冲距离

label.startAnimation()
view.addSubview(label)
```

## 渐变方向

支持4种渐变方向：

```swift
// 水平方向（左到右）
label.gradientDirection = .horizontal

// 垂直方向（上到下）
label.gradientDirection = .vertical

// 左上到右下
label.gradientDirection = .topLeftToBottomRight

// 右上到左下
label.gradientDirection = .topRightToBottomLeft
```

## 属性说明

### 基础属性

| 属性 | 类型 | 说明 | 默认值 |
|------|------|------|--------|
| `text` | String | 文字内容 | "" |
| `font` | UIFont | 字体 | systemFont(40, bold) |
| `textColor` | UIColor | 文字颜色（非渐变状态） | .white |
| `gradientColors` | [UIColor] | 渐变颜色数组 | [pink, purple, blue, teal] |
| `gradientDirection` | WaveGradientDirection | 渐变方向 | .horizontal |
| `animationDuration` | TimeInterval | 动画时长（秒） | 3.0 |

### 跑马灯属性

| 属性 | 类型 | 说明 | 默认值 |
|------|------|------|--------|
| `enableMarquee` | Bool | 是否启用跑马灯 | false |
| `marqueeSpeed` | TimeInterval | 滚动一次的时间（秒） | 8.0 |
| `marqueeDelay` | TimeInterval | 延迟时间（秒） | 2.0 |
| `marqueeTrailingBuffer` | CGFloat | 尾部缓冲距离 | 30.0 |

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
// 重启跑马灯（文字改变后调用）
label.restartMarquee()

// 暂停跑马灯
label.pauseMarquee()

// 继续跑马灯
label.unpauseMarquee()
```

## 实现原理

1. 使用 `CAGradientLayer` 创建渐变效果
2. 使用 `MarqueeLabel` 实现跑马灯滚动
3. 通过 `CABasicAnimation` 动画改变渐变的 `locations` 属性实现波浪移动效果
4. 渐变颜色数组重复排列，创造无限循环的波浪效果
5. 使用 layer mask 技术让渐变只在文字区域显示

## 依赖

- [MarqueeLabel](https://github.com/cbpowell/MarqueeLabel) - 跑马灯效果

## 系统要求

- iOS 13.0+
- Swift 5.0+
- Xcode 12.0+
