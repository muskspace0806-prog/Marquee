# JXSegmentedView 复用场景使用指南

## 问题描述

在 JXSegmentedView、UITableView、UICollectionView 等使用 View 复用的场景中，`GMWaveGradientLabelView` 可能会出现：
- 文字显示正确，但跑马灯没有启动
- 文字宽度使用了旧的缓存值
- 跑马灯判断错误（应该滚动但没有滚动）

## 根本原因

View 复用时的执行顺序问题：
1. View 被复用，还保留着旧的 frame 和 bounds
2. 设置新的 `text` 属性
3. `text` 的 `didSet` 触发，调用 `rebuildAttributedTextAndLayout()`
4. `updateTextSize()` 使用当前的 `bounds` 计算文字宽度
5. **问题**：此时 `bounds` 还是旧的，导致文字宽度计算错误
6. 后续 Auto Layout 更新了 `bounds`，但文字宽度已经缓存了错误的值

## 解决方案

### 方案 1：使用 resetAllStates() + forceRefreshLayout()（推荐）

```swift
class CustomTitleView: UIView {
    let nameLabel = GMWaveGradientLabelView()
    
    func configure(title: String, level: Int) {
        // ✅ 步骤 1：重置所有状态
        nameLabel.resetAllStates()
        
        // ✅ 步骤 2：配置属性
        nameLabel.text = title
        nameLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        nameLabel.gradientColors = getColors(level: level)
        nameLabel.enableMarquee = true
        nameLabel.marqueeSpeed = 45
        nameLabel.startAnimation()
        
        // ✅ 步骤 3：强制刷新布局（在 layoutSubviews 之后调用）
        DispatchQueue.main.async { [weak self] in
            self?.nameLabel.forceRefreshLayout()
        }
    }
}
```

### 方案 2：在 layoutSubviews 中刷新

```swift
class CustomTitleView: UIView {
    let nameLabel = GMWaveGradientLabelView()
    private var needsRefresh = false
    
    func configure(title: String, level: Int) {
        nameLabel.resetAllStates()
        
        nameLabel.text = title
        nameLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        nameLabel.gradientColors = getColors(level: level)
        nameLabel.enableMarquee = true
        nameLabel.marqueeSpeed = 45
        nameLabel.startAnimation()
        
        // 标记需要刷新
        needsRefresh = true
        setNeedsLayout()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // ✅ 在布局完成后刷新
        if needsRefresh {
            needsRefresh = false
            nameLabel.forceRefreshLayout()
        }
    }
}
```

### 方案 3：使用回调监听布局完成

```swift
class CustomTitleView: UIView {
    let nameLabel = GMWaveGradientLabelView()
    
    func configure(title: String, level: Int) {
        nameLabel.resetAllStates()
        
        nameLabel.text = title
        nameLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        nameLabel.gradientColors = getColors(level: level)
        nameLabel.enableMarquee = true
        nameLabel.marqueeSpeed = 45
        nameLabel.startAnimation()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // ✅ 每次布局后都刷新（简单但可能有性能影响）
        nameLabel.forceRefreshLayout()
    }
}
```

## JXSegmentedView 完整示例

### 自定义 TitleView

```swift
class GradientTitleView: UIView, JXSegmentedViewItemContentView {
    let nameLabel = GMWaveGradientLabelView()
    private var needsRefresh = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        addSubview(nameLabel)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            nameLabel.topAnchor.constraint(equalTo: topAnchor),
            nameLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    func reloadData(itemModel: JXSegmentedBaseItemModel, selectedType: JXSegmentedViewItemSelectedType) {
        guard let model = itemModel as? CustomItemModel else { return }
        
        // ✅ 重置状态
        nameLabel.resetAllStates()
        
        // ✅ 配置属性
        nameLabel.text = model.title
        nameLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        nameLabel.gradientColors = model.gradientColors
        nameLabel.gradientDirection = .horizontalRightToLeft
        nameLabel.animationDuration = 4.5
        nameLabel.enableMarquee = true
        nameLabel.marqueeSpeed = 45
        nameLabel.marqueeDelay = 1.0
        nameLabel.startAnimation()
        
        // ✅ 标记需要刷新
        needsRefresh = true
        setNeedsLayout()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // ✅ 在布局完成后刷新
        if needsRefresh {
            needsRefresh = false
            nameLabel.forceRefreshLayout()
        }
    }
}
```

### 自定义 ItemModel

```swift
class CustomItemModel: JXSegmentedBaseItemModel {
    var gradientColors: [UIColor] = []
    
    init(title: String, gradientColors: [UIColor]) {
        super.init()
        self.title = title
        self.gradientColors = gradientColors
    }
}
```

### 使用示例

```swift
class ViewController: UIViewController {
    let segmentedView = JXSegmentedView()
    let dataSource = JXSegmentedViewDataSource<GradientTitleView>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 配置数据源
        dataSource.itemModels = [
            CustomItemModel(title: "短标题", gradientColors: [.systemPink, .systemPurple]),
            CustomItemModel(title: "这是一个很长的标题需要滚动", gradientColors: [.systemBlue, .systemTeal]),
            CustomItemModel(title: "VIP用户名", gradientColors: [.systemOrange, .systemRed])
        ]
        
        segmentedView.dataSource = dataSource
        view.addSubview(segmentedView)
    }
}
```

## UITableViewCell 示例

```swift
class VIPCell: UITableViewCell {
    let nameLabel = GMWaveGradientLabelView()
    private var needsRefresh = false
    
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
        // ✅ 重置状态
        nameLabel.resetAllStates()
    }
    
    func configure(user: User) {
        // ✅ 配置属性
        nameLabel.text = user.name
        nameLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        nameLabel.gradientColors = user.level > 0 ? 
            [.systemPink, .systemPurple, .systemBlue] : [.white]
        
        if user.level > 0 {
            nameLabel.animationDuration = 4.5
            nameLabel.marqueeSpeed = 45
            nameLabel.marqueeDelay = 1.0
            nameLabel.enableMarquee = true
            nameLabel.startAnimation()
        }
        
        // ✅ 标记需要刷新
        needsRefresh = true
        setNeedsLayout()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // ✅ 在布局完成后刷新
        if needsRefresh {
            needsRefresh = false
            nameLabel.forceRefreshLayout()
        }
    }
}
```

## 关键方法说明

### resetAllStates()

清理所有状态，包括：
- 停止所有动画
- 重置文字内容
- 清空回调
- 重置 frame（清理文字宽度缓存）

**调用时机**：在重新配置 View 之前

### forceRefreshLayout()

强制刷新布局和跑马灯状态，包括：
- 强制重新布局
- 重新计算文字大小（使用最新的 bounds）
- 重新启动跑马灯（重新判断是否需要滚动）

**调用时机**：在布局完成后（layoutSubviews 或 async）

## 调试技巧

### 1. 使用调试输出

```swift
nameLabel.forceRefreshLayout()
// 会自动打印：
// 🔄 [forceRefreshLayout] Forcing layout refresh
//    - text: "用户名"
//    - bounds: (0.0, 0.0, 200.0, 40.0)
//    - enableMarquee: true
//    ✅ Layout refreshed
// 🔍 [Marquee Debug] ...
```

### 2. 手动调试

```swift
nameLabel.debugMarqueeStatus()
```

检查输出：
- `textWidth` vs `containerWidth` - 文字宽度是否正确
- `needsScroll` - 是否应该滚动
- `marqueeDisplayLink` - 跑马灯是否在运行

### 3. 检查文字不匹配

如果看到 `TEXT MISMATCH`，说明状态没有正确重置：
```
🚨 TEXT MISMATCH DETECTED!
   - Property 'text': "新文字"
   - maskLabel.text: "旧文字"
```

解决方案：确保调用了 `resetAllStates()`

## 常见问题

### Q1：为什么需要 async 调用 forceRefreshLayout()？

A：因为 Auto Layout 的约束更新是异步的，在设置完属性后，bounds 可能还没有更新。使用 `DispatchQueue.main.async` 确保在下一个 runloop 时 bounds 已经是最新的。

### Q2：可以在 configure 方法中直接调用 forceRefreshLayout() 吗？

A：不推荐。此时 bounds 可能还没有更新，建议在 `layoutSubviews` 中调用，或使用 async。

### Q3：每次 layoutSubviews 都调用 forceRefreshLayout() 会有性能问题吗？

A：可能会。建议使用 `needsRefresh` 标志，只在需要时刷新。

### Q4：为什么跑马灯有时候不启动？

A：可能的原因：
1. 没有调用 `resetAllStates()` 清理旧状态
2. 没有调用 `forceRefreshLayout()` 刷新布局
3. bounds 还是旧的，文字宽度计算错误
4. 文字实际上不需要滚动（宽度小于容器）

## 最佳实践

1. ✅ 总是在重新配置前调用 `resetAllStates()`
2. ✅ 在布局完成后调用 `forceRefreshLayout()`
3. ✅ 使用 `needsRefresh` 标志避免重复刷新
4. ✅ 使用 `debugMarqueeStatus()` 调试问题
5. ✅ 在 `prepareForReuse()` 中重置状态

## 相关文件

- `WaveGradientLabel.swift` - 主要实现
- `View复用问题排查指南.md` - 复用问题排查
- `跑马灯问题排查指南.md` - 跑马灯问题排查
