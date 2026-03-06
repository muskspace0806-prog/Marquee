# 测试 pauseGradientDuringMarquee 功能

## 测试步骤

### 1. 运行项目
```bash
# 在 Xcode 中运行项目
```

### 2. 观察示例 11（最下面的 label）

文字：`"跑马灯运行时暂停渐变动画 🎬 这是一段很长的文字"`

配置：
- `gradientDirection = .horizontalLeftToRight`（渐变从左往右）
- `marqueeDirection = .rightToLeft`（跑马灯从右往左）
- `pauseGradientDuringMarquee = true`（启用暂停）

### 3. 预期行为

#### 初始状态（延迟 1 秒）
- ✅ 渐变动画正常运行（从左往右波浪移动）
- ❌ 跑马灯未启动（延迟 1 秒）

#### 跑马灯启动后
- ❌ 渐变动画应该暂停（不再移动）
- ✅ 跑马灯正常滚动（从右往左）
- ✅ 渐变颜色仍然显示，但不移动

#### 如果文字变短（不需要滚动）
- ✅ 跑马灯停止
- ✅ 渐变动画恢复运行

### 4. 调试输出

在控制台查看调试信息：

```
🎬 [Marquee] startMarquee called
   - Text: "跑马灯运行时暂停渐变动画 🎬 这是一段很长的文字"
   - textWidth: XXXpx
   - containerWidth: XXXpx
   - threshold: 1.0 (XXXpx)
   - needsScroll: ✅
   - window: ✅
   - pauseGradientDuringMarquee: true
   ✅ Marquee started, delay: 1.0s
🎨 [Gradient] Paused due to marquee running
```

### 5. 对比测试

#### 示例 9（pauseGradientDuringMarquee = false，默认）
- 跑马灯运行时，渐变继续移动
- 会出现视觉冲突（渐变看起来反了）

#### 示例 11（pauseGradientDuringMarquee = true）
- 跑马灯运行时，渐变暂停
- 没有视觉冲突

## 测试代码

```swift
// 测试 1：基本功能
let label1 = WaveGradientLabelView(frame: CGRect(x: 20, y: 100, width: 300, height: 50))
label1.text = "测试文字很长需要滚动显示"
label1.gradientDirection = .horizontalLeftToRight
label1.marqueeDirection = .rightToLeft
label1.pauseGradientDuringMarquee = true  // 启用暂停
label1.enableMarquee = true
label1.startAnimation()

// 预期：跑马灯启动后，渐变暂停

// 测试 2：动态切换
let label2 = WaveGradientLabelView(frame: CGRect(x: 20, y: 200, width: 300, height: 50))
label2.text = "测试文字很长需要滚动显示"
label2.gradientDirection = .horizontalLeftToRight
label2.marqueeDirection = .rightToLeft
label2.enableMarquee = true
label2.startAnimation()

// 3 秒后启用暂停
DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
    label2.pauseGradientDuringMarquee = true
    // 预期：渐变立即暂停
}

// 6 秒后禁用暂停
DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
    label2.pauseGradientDuringMarquee = false
    // 预期：渐变立即恢复
}

// 测试 3：文字不需要滚动
let label3 = WaveGradientLabelView(frame: CGRect(x: 20, y: 300, width: 300, height: 50))
label3.text = "短文字"
label3.gradientDirection = .horizontalLeftToRight
label3.pauseGradientDuringMarquee = true
label3.enableMarquee = true
label3.startAnimation()

// 预期：跑马灯不启动，渐变正常运行
```

## 常见问题

### Q1: 设置了 pauseGradientDuringMarquee = true，但渐变还在动？

检查：
1. 跑马灯是否真的启动了？（文字是否足够长？）
2. 设置顺序是否正确？（先设置 pauseGradientDuringMarquee，再设置 enableMarquee）
3. 查看控制台调试输出

### Q2: 渐变暂停了，但颜色消失了？

这是 bug，渐变应该保持显示，只是不移动。检查：
- `stopAnimation()` 是否正确保留了渐变层
- `gradientLayer.transform` 是否被重置

### Q3: 动态切换 pauseGradientDuringMarquee 不生效？

检查 `didSet` 是否正确调用了 `updateGradientAnimationState()`：

```swift
var pauseGradientDuringMarquee: Bool = false {
    didSet {
        if enableMarquee {
            updateGradientAnimationState()
        }
    }
}
```

## 实现检查清单

- [x] `pauseGradientDuringMarquee` 属性声明
- [x] `updateGradientAnimationState()` 方法实现
- [x] 在 `startMarquee()` 中调用（在 marqueeDisplayLink 创建之后）
- [x] 在 `stopMarquee()` 中调用
- [x] 在 `pauseGradientDuringMarquee.didSet` 中调用
- [x] 在 `ensureGradientAnimatingIfNeeded()` 中检查
- [x] 添加调试输出
- [x] 文档更新

## 预期效果

当 `pauseGradientDuringMarquee = true` 且跑马灯运行时：
- 渐变颜色保持显示
- 渐变不再移动（波浪效果暂停）
- 跑马灯正常滚动
- 没有视觉冲突

当跑马灯停止时：
- 渐变动画自动恢复
- 波浪效果继续移动
