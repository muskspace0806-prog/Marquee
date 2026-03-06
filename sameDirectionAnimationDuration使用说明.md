# sameDirectionAnimationDuration 使用说明

## 功能说明

`sameDirectionAnimationDuration` 是一个可选属性，用于在渐变和跑马灯方向一致时，使用不同的渐变速度，以减少视觉冲突。

## 问题背景

当渐变动画和跑马灯方向一致时（例如都向左移动），会出现视觉上的参照系问题：
- 用户的眼睛会跟随移动的文字
- 渐变相对于文字看起来在反向移动
- 造成视觉上的不协调

## 解决方案

通过设置 `sameDirectionAnimationDuration`，在方向一致时使用更快的渐变速度，使渐变看起来与文字同向移动。

## 使用方法

```swift
class GMGradientNameView: WaveGradientLabelView {
    func configUI(font: UIFont, level: Int, defaultColors: [UIColor]) {
        // 1. 设置渐变方向（根据语言）
        self.gradientDirection = GMLanguageChange.shared.isMiddleEast 
            ? .horizontalLeftToRight   // 中东：向右
            : .horizontalRightToLeft   // 其他：向左
        
        // 2. 设置跑马灯方向（根据语言）
        self.marqueeDirection = GMLanguageChange.shared.isMiddleEast 
            ? .leftToRight   // 中东：向右
            : .rightToLeft   // 其他：向左
        
        // 3. 设置正常速度
        self.animationDuration = 4.5
        
        // 4. ✅ 设置方向一致时的速度
        self.sameDirectionAnimationDuration = 0.7
        
        // 5. 设置跑马灯参数
        self.marqueeSpeed = 45
        self.marqueeDelay = 1.0
        self.marqueeGap = 10
        
        // 6. 启动动画和跑马灯
        self.startAnimation()
        self.enableMarquee = true
    }
}
```

## 效果

### 非中东地区（LTR）
- 渐变方向：`.horizontalRightToLeft`（向左 ←）
- 跑马灯方向：`.rightToLeft`（向左 ←）
- 方向一致：✅
- 跑马灯未启动：使用 `animationDuration = 4.5` 秒
- 跑马灯启动后：使用 `sameDirectionAnimationDuration = 0.7` 秒
- 跑马灯停止后：恢复 `animationDuration = 4.5` 秒

### 中东地区（RTL）
- 渐变方向：`.horizontalLeftToRight`（向右 →）
- 跑马灯方向：`.leftToRight`（向右 →）
- 方向一致：✅
- 跑马灯未启动：使用 `animationDuration = 4.5` 秒
- 跑马灯启动后：使用 `sameDirectionAnimationDuration = 0.7` 秒
- 跑马灯停止后：恢复 `animationDuration = 4.5` 秒

## 速度建议

根据 `marqueeSpeed` 选择合适的 `sameDirectionAnimationDuration`：

| marqueeSpeed | animationDuration | sameDirectionAnimationDuration | 说明 |
|--------------|-------------------|--------------------------------|------|
| 40-50 | 4.5 | 0.5-0.7 | 快速滚动，推荐 0.7 |
| 30-40 | 3.5 | 0.7-1.0 | 中速滚动，推荐 0.8 |
| 20-30 | 3.0 | 1.0-1.5 | 慢速滚动，推荐 1.0 |

## 方向检测逻辑

组件会自动检测渐变和跑马灯方向是否一致：

```swift
private func isGradientAndMarqueeDirectionSame() -> Bool {
    switch (gradientDirection, marqueeDirection) {
    case (.horizontalLeftToRight, .leftToRight):
        return true  // 都向右 → → 一致
    case (.horizontalRightToLeft, .rightToLeft):
        return true  // 都向左 ← ← 一致
    default:
        return false // 方向不一致
    }
}
```

## 调试

如果需要调试，可以查看控制台输出（Debug 模式）：

```
🎬 [Marquee] startMarquee called
   🎨 Gradient speed updated for marquee
   ✅ Marquee started, delay: 1.0s
   🎨 Current animation duration: 0.7s
```

## 注意事项

1. **可选属性**：默认为 `nil`，不影响现有代码
2. **自动切换**：跑马灯启动/停止时自动切换速度
3. **只影响水平方向**：垂直和斜向渐变不受影响
4. **方向必须一致**：只有当渐变和跑马灯方向一致时才生效
5. **建议值范围**：0.5 - 1.5 秒

## 完整示例

```swift
// 在 ViewController 中使用
let nameLabel = GMGradientNameView()
nameLabel.text = "VIP用户名 🎉"
nameLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)

// 配置样式
nameLabel.configUI(
    font: UIFont.systemFont(ofSize: 20, weight: .semibold),
    level: 1,
    defaultColors: [.white]
)

// 添加到视图
view.addSubview(nameLabel)
```

## 常见问题

### Q1: 设置了 sameDirectionAnimationDuration 但没效果？

检查：
1. 渐变和跑马灯方向是否一致？
2. 跑马灯是否真的启动了？（文字是否足够长？）
3. 查看控制台调试输出

### Q2: 速度太快或太慢？

调整 `sameDirectionAnimationDuration` 的值：
- 太快：增加值（例如从 0.5 改为 0.8）
- 太慢：减少值（例如从 1.0 改为 0.7）

### Q3: 不想使用这个功能？

不设置 `sameDirectionAnimationDuration`，或设置为 `nil`：
```swift
label.sameDirectionAnimationDuration = nil  // 禁用
```

## 相关文件

- `WaveGradientLabel.swift`：主要实现
- `跑马灯渐变同步修复说明.md`：详细技术说明
- `实际项目使用指南.md`：项目集成指南
