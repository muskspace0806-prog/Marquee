# View 复用问题排查指南

## 问题现象

当多个 `GMWaveGradientLabelView` 实例被复用时（例如在 UITableViewCell 或继承自同一基类的多个 View 中），可能会出现以下问题：

1. **文字内容不匹配**
   - `debugMarqueeStatus()` 显示 `TEXT MISMATCH!`
   - `text` 属性和 `maskLabel.text` 不一致

2. **跑马灯状态混乱**
   - 设置了 `enableMarquee = true` 但跑马灯没有启动
   - 文字明明超出容器宽度，但没有滚动
   - 跑马灯回调触发异常

3. **渐变动画异常**
   - 渐变动画速度不对
   - 动画突然停止或重启

## 根本原因

View 复用时，旧的状态没有被清理，导致：
- 旧的文字内容残留
- 旧的动画状态残留
- 旧的回调闭包残留
- 旧的 frame 和 layer 状态残留

## 解决方案

### 方案 1：使用 resetAllStates()（推荐）

在重新配置 View 之前，先调用 `resetAllStates()` 清理所有状态：

```swift
class VIPCell: UITableViewCell {
    let nameLabel = GMWaveGradientLabelView()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        // ✅ 重置所有状态
        nameLabel.resetAllStates()
    }
    
    func configure(name: String, level: Int) {
        // ✅ 重新设置回调
        nameLabel.marqueeStatusChanged = { [weak self] isScrolling in
            print("状态改变: \(isScrolling)")
        }
        
        // 配置新内容
        nameLabel.text = name
        nameLabel.font = UIFont.systemFont(ofSize: 16)
        nameLabel.gradientColors = getColors(level: level)
        nameLabel.enableMarquee = true
        nameLabel.startAnimation()
    }
}
```

### 方案 2：在自定义基类中处理

如果你有多个 View 继承自同一基类：

```swift
class BaseVIPView: UIView {
    let nameLabel = GMWaveGradientLabelView()
    
    func resetForReuse() {
        // ✅ 重置 label 状态
        nameLabel.resetAllStates()
    }
    
    func configure(name: String, level: Int) {
        // ✅ 先重置
        resetForReuse()
        
        // ✅ 重新设置回调
        nameLabel.marqueeStatusChanged = { [weak self] isScrolling in
            self?.handleMarqueeStatusChanged(isScrolling)
        }
        
        // 配置新内容
        nameLabel.text = name
        configUI(level: level)
    }
    
    func handleMarqueeStatusChanged(_ isScrolling: Bool) {
        // 子类可以重写此方法
    }
}

class VIPView1: BaseVIPView {
    // 使用 configure 方法
}

class VIPView2: BaseVIPView {
    // 使用 configure 方法
}

class VIPView3: BaseVIPView {
    // 使用 configure 方法
}
```

## resetAllStates() 做了什么？

```swift
func resetAllStates() {
    // 1. 停止所有动画
    stopAnimation()
    stopMarquee()
    
    // 2. 重置属性
    text = ""
    enableMarquee = false
    marqueeStatusChanged = nil
    
    // 3. 重置 label 状态
    maskLabel.text = nil
    maskLabel.attributedText = nil
    maskLabel2.text = nil
    maskLabel2.attributedText = nil
    emojiLabel.text = nil
    emojiLabel.attributedText = nil
    emojiLabel2.text = nil
    emojiLabel2.attributedText = nil
    
    // 4. 隐藏第二份内容
    maskLabel2.isHidden = true
    emojiLabel2.isHidden = true
    
    // 5. 重置 frame
    maskLabel.frame = bounds
    maskLabel2.frame = bounds
    emojiLabel.frame = bounds
    emojiLabel2.frame = bounds
}
```

## 调试步骤

### 步骤 1：检查文字是否匹配

```swift
nameLabel.debugMarqueeStatus()
```

查看输出：
```
🔍 [Marquee Debug]
   - text (property): "新文字"
   - text (maskLabel): "旧文字"
   - text match: ❌ MISMATCH!
   🚨 TEXT MISMATCH DETECTED!
```

如果看到 `TEXT MISMATCH`，说明状态没有正确重置。

### 步骤 2：检查跑马灯状态

```swift
nameLabel.debugMarqueeStatus()
```

查看输出：
```
🔍 [Marquee Debug]
   - enableMarquee: true
   - textWidth: 250px
   - containerWidth: 200px
   - needsScroll: ✅
   - marqueeDisplayLink: ❌ not running
   ⚠️ WARNING: Marquee should be running but it's not!
   💡 Try calling: label.restartMarqueeIfNeeded()
```

如果看到 `WARNING: Marquee should be running but it's not!`，说明跑马灯没有正确启动。

### 步骤 3：强制重启跑马灯

```swift
// 如果跑马灯没有启动，可以强制重启
nameLabel.restartMarqueeIfNeeded()
```

### 步骤 4：检查回调是否触发

```swift
nameLabel.marqueeStatusChanged = { isScrolling in
    print("🎬 回调触发: \(isScrolling)")
}
```

如果回调没有触发，检查：
1. 是否调用了 `resetAllStates()` 后忘记重新设置回调
2. 是否文字太短，不需要滚动

## 完整示例

### UITableViewCell 中使用

```swift
class VIPCell: UITableViewCell {
    let nameLabel = GMWaveGradientLabelView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        contentView.addSubview(nameLabel)
        nameLabel.frame = CGRect(x: 20, y: 10, width: 200, height: 40)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        // ✅ 关键：重置所有状态
        nameLabel.resetAllStates()
    }
    
    func configure(user: User) {
        // ✅ 重新设置回调
        nameLabel.marqueeStatusChanged = { [weak self] isScrolling in
            print("Cell \(user.name) 跑马灯状态: \(isScrolling)")
        }
        
        // 配置内容
        nameLabel.text = user.name
        nameLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        nameLabel.gradientColors = user.level > 0 ? 
            [.systemPink, .systemPurple, .systemBlue] : [.white]
        
        if user.level > 0 {
            nameLabel.animationDuration = 4.5
            nameLabel.sameDirectionAnimationDuration = 0.7
            nameLabel.marqueeSpeed = 45
            nameLabel.marqueeDelay = 1.0
            nameLabel.enableMarquee = true
            nameLabel.startAnimation()
        }
    }
}
```

### 自定义 View 中使用

```swift
class GMGradientNameView: GMWaveGradientLabelView {
    
    var onMarqueeStatusChanged: ((Bool) -> Void)?
    
    func configUI(font: UIFont, level: Int, defaultColors: [UIColor]) {
        // ✅ 先重置（如果是复用场景）
        // resetAllStates()  // 如果需要
        
        // 配置样式
        self.gradientDirection = .horizontalRightToLeft
        self.font = font
        self.gradientColors = getColors(level: level, defaultColors: defaultColors)
        
        if level > 0 {
            self.animationDuration = 4.5
            self.sameDirectionAnimationDuration = 0.7
            self.marqueeSpeed = 45
            self.marqueeDelay = 1.0
            
            // ✅ 设置回调
            self.marqueeStatusChanged = { [weak self] isScrolling in
                self?.onMarqueeStatusChanged?(isScrolling)
            }
            
            self.enableMarquee = true
            self.startAnimation()
        }
    }
    
    private func getColors(level: Int, defaultColors: [UIColor]) -> [UIColor] {
        // 根据等级返回不同的颜色
        switch level {
        case 1: return [.systemPink, .systemPurple]
        case 2: return [.systemPink, .systemPurple, .systemBlue]
        case 3: return [.systemPink, .systemPurple, .systemBlue, .systemTeal]
        default: return defaultColors
        }
    }
}
```

## 常见错误

### ❌ 错误 1：忘记调用 resetAllStates()

```swift
func configure(name: String) {
    // ❌ 直接设置，旧状态残留
    nameLabel.text = name
    nameLabel.enableMarquee = true
}
```

### ✅ 正确做法

```swift
func configure(name: String) {
    // ✅ 先重置
    nameLabel.resetAllStates()
    
    // ✅ 重新设置回调
    nameLabel.marqueeStatusChanged = { isScrolling in
        print("状态: \(isScrolling)")
    }
    
    // ✅ 再配置
    nameLabel.text = name
    nameLabel.enableMarquee = true
}
```

### ❌ 错误 2：在 resetAllStates() 之前设置回调

```swift
func configure(name: String) {
    // ❌ 先设置回调
    nameLabel.marqueeStatusChanged = { isScrolling in
        print("状态: \(isScrolling)")
    }
    
    // ❌ 后重置（回调被清空了）
    nameLabel.resetAllStates()
    
    nameLabel.text = name
}
```

### ✅ 正确做法

```swift
func configure(name: String) {
    // ✅ 先重置
    nameLabel.resetAllStates()
    
    // ✅ 再设置回调
    nameLabel.marqueeStatusChanged = { isScrolling in
        print("状态: \(isScrolling)")
    }
    
    nameLabel.text = name
}
```

### ❌ 错误 3：多个 View 共享同一个回调闭包

```swift
// ❌ 三个 View 共享同一个闭包，可能导致混乱
let sharedCallback: (Bool) -> Void = { isScrolling in
    print("状态: \(isScrolling)")
}

view1.marqueeStatusChanged = sharedCallback
view2.marqueeStatusChanged = sharedCallback
view3.marqueeStatusChanged = sharedCallback
```

### ✅ 正确做法

```swift
// ✅ 每个 View 使用独立的闭包
view1.marqueeStatusChanged = { isScrolling in
    print("View1 状态: \(isScrolling)")
}

view2.marqueeStatusChanged = { isScrolling in
    print("View2 状态: \(isScrolling)")
}

view3.marqueeStatusChanged = { isScrolling in
    print("View3 状态: \(isScrolling)")
}
```

## 性能建议

1. **只在需要时重置**：如果 View 不会被复用，不需要调用 `resetAllStates()`
2. **避免频繁重置**：不要在每次更新文字时都调用 `resetAllStates()`，只在复用时调用
3. **使用弱引用**：在回调闭包中使用 `[weak self]` 避免循环引用

## 相关文件

- `WaveGradientLabel.swift`：主要实现
- `跑马灯状态回调说明.md`：回调使用说明
- `跑马灯问题排查指南.md`：跑马灯问题排查
- `实际项目使用指南.md`：项目集成指南
