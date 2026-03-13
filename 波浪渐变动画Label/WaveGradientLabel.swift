//  这个就阿语跑马灯滚动方向不对,其他没问题
//  WaveGradientLabel.swift
//  波浪渐变动画Label
//
//  Created by hule on 2026/1/16.
//

import UIKit

// MARK: - 渐变方向枚举
enum GMWaveGradientDirection {
    case horizontalLeftToRight  // 水平：左到右
    case horizontalRightToLeft  // 水平：右到左
    case verticalTopToBottom    // 垂直：上到下
    case verticalBottomToTop    // 垂直：下到上
    case diagonalDownRight      // 斜向：左上到右下（从上往下）
    case diagonalDownLeft       // 斜向：右上到左下（从上往下）
    case diagonalUpRight        // 斜向：左下到右上（从下往上）
    case diagonalUpLeft         // 斜向：右下到左上（从下往上）

    var points: (start: CGPoint, end: CGPoint) {
        switch self {
        case .horizontalLeftToRight, .horizontalRightToLeft:
            // 水平方向：保持相同的 points，通过动画方向控制波浪流向
            return (CGPoint(x: 0, y: 0.5), CGPoint(x: 1, y: 0.5))
            
        case .verticalTopToBottom, .verticalBottomToTop:
            // 垂直方向：保持相同的 points，通过动画方向控制波浪流向
            return (CGPoint(x: 0.5, y: 0), CGPoint(x: 0.5, y: 1))
            
        case .diagonalDownRight, .diagonalUpRight:
            // 左上到右下 / 左下到右上：保持相同的 points
            return (CGPoint(x: 0, y: 0), CGPoint(x: 1, y: 1))
            
        case .diagonalDownLeft, .diagonalUpLeft:
            // 右上到左下 / 右下到左上：保持相同的 points
            return (CGPoint(x: 1, y: 0), CGPoint(x: 0, y: 1))
        }
    }
    
    // ✅ 兼容旧名称（避免破坏现有代码）
    @available(*, deprecated, renamed: "horizontalLeftToRight")
    static var horizontal: GMWaveGradientDirection { .horizontalLeftToRight }
    
    @available(*, deprecated, renamed: "verticalTopToBottom")
    static var vertical: GMWaveGradientDirection { .verticalTopToBottom }
    
    @available(*, deprecated, renamed: "diagonalDownRight")
    static var topLeftToBottomRight: GMWaveGradientDirection { .diagonalDownRight }
    
    @available(*, deprecated, renamed: "diagonalDownLeft")
    static var topRightToBottomLeft: GMWaveGradientDirection { .diagonalDownLeft }
}

// MARK: - 跑马灯方向枚举
enum MarqueeDirection {
    case rightToLeft  // 从右往左（默认，LTR 语言）
    case leftToRight  // 从左往右（RTL 语言，如阿语）
}

// MARK: - WaveGradientLabelView
class GMWaveGradientLabelView: UIView {

    // MARK: - Layers
    private let gradientContainerLayer = CALayer()
    private let gradientLayer = CAGradientLayer()

    private let maskLabel = UILabel()
    private let maskLabel2 = UILabel()
    private let maskContainerLayer = CALayer()

    private let emojiLabel = UILabel()
    private let emojiLabel2 = UILabel()

    // MARK: - State
    private var isAnimating = false
    private var marqueeDisplayLink: CADisplayLink?
    private var marqueeStartTime: CFTimeInterval = 0

    private var gradientDisplayLink: CADisplayLink?
    private var gradientStartTime: CFTimeInterval = 0
    
    /// 是否已应用手动截断
    private var hasAppliedManualTruncation = false

    var autoStartAnimation: Bool = true {
        didSet {
            if autoStartAnimation {
                ensureGradientAnimatingIfNeeded()
            } else {
                stopAnimation()
            }
        }
    }
    
    /// 是否启用动画（false 时显示静态渐变）
    var enableAnimation: Bool = true {
        didSet {
            if enableAnimation {
                if autoStartAnimation {
                    ensureGradientAnimatingIfNeeded()
                }
            } else {
                stopAnimation()
                // 重置到初始状态，显示静态渐变
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                gradientLayer.transform = CATransform3DIdentity
                CATransaction.commit()
            }
        }
    }

    // MARK: - Public Properties
    var text: String = "" {
        didSet {
            // ✅ 文字改变：重置手动截断标志
            hasAppliedManualTruncation = false
            
            rebuildAttributedTextAndLayout()
            ensureGradientAnimatingIfNeeded()
        }
    }

    var font: UIFont = UIFont.systemFont(ofSize: 40, weight: .bold) {
        didSet {
            maskLabel.font = font
            maskLabel2.font = font
            emojiLabel.font = font
            emojiLabel2.font = font
            rebuildAttributedTextAndLayout()
            ensureGradientAnimatingIfNeeded()
        }
    }

    var textColor: UIColor = .white {
        didSet { rebuildAttributedTextAndLayout() }
    }

    var gradientColors: [UIColor] = [.systemPink, .systemPurple, .systemBlue, .systemTeal] {
        didSet { updateGradientColors() }
    }

    var gradientDirection: GMWaveGradientDirection = .horizontal {
        didSet {
            updateGradientDirection()
            setNeedsLayout()
            layoutIfNeeded()

            if isAnimating {
                gradientStartTime = CACurrentMediaTime()
            } else {
                ensureGradientAnimatingIfNeeded()
            }
        }
    }

    var animationDuration: TimeInterval = 3.0 {
        didSet {
            if isAnimating {
                gradientStartTime = CACurrentMediaTime()
            }
        }
    }
    
    /// 当渐变和跑马灯方向一致且跑马灯运行时，使用的动画时长（可选）
    /// - 如果设置了此值，当方向一致且跑马灯运行时，会使用此时长替代 animationDuration
    /// - 如果为 nil（默认），则始终使用 animationDuration
    /// - 建议设置为比 animationDuration 更小的值，以减少视觉冲突
    /// - 例如：animationDuration = 4.5, sameDirectionAnimationDuration = 0.5
    var sameDirectionAnimationDuration: TimeInterval? = nil {
        didSet {
            // 速度改变会在下一帧自动生效，不需要重置 gradientStartTime
            // 这样可以保持动画的平滑过渡
        }
    }
    
    /// 获取当前应该使用的动画时长
    private func getCurrentAnimationDuration() -> TimeInterval {
        let isMarqueeRunning = enableMarquee && marqueeDisplayLink != nil
        
        // 如果跑马灯运行 && 方向一致 && 设置了 sameDirectionAnimationDuration
        if isMarqueeRunning && isGradientAndMarqueeDirectionSame(),
           let sameDirDuration = sameDirectionAnimationDuration {
            return sameDirDuration
        }
        
        // 其他情况使用 animationDuration
        return animationDuration
    }
    
    /// 检测渐变和跑马灯方向是否一致（会产生视觉冲突）
    private func isGradientAndMarqueeDirectionSame() -> Bool {
        // 关键理解：
        // - 渐变方向是相对于容器的绝对方向
        // - 跑马灯方向是文字移动的方向
        // - 当两者方向一致时，用户眼睛跟随文字移动，渐变看起来反了
        
        switch (gradientDirection, marqueeDirection) {
        case (.horizontalLeftToRight, .leftToRight):
            // 渐变向右 →，文字向右 → → 方向一致，有冲突 ✅
            return true
            
        case (.horizontalRightToLeft, .rightToLeft):
            // 渐变向左 ←，文字向左 ← → 方向一致，有冲突 ✅
            return true
            
        case (.horizontalLeftToRight, .rightToLeft):
            // 渐变向右 →，文字向左 ← → 方向相反，无冲突
            return false
            
        case (.horizontalRightToLeft, .leftToRight):
            // 渐变向左 ←，文字向右 → → 方向相反，无冲突
            return false
            
        default:
            return false
        }
    }
    
    /// 动画帧率（默认 60fps，可设置为 30fps 降低消耗）
    var preferredFramesPerSecond: Int = 60 {
        didSet {
            gradientDisplayLink?.preferredFramesPerSecond = preferredFramesPerSecond
        }
    }

    var enableMarquee: Bool = false {
        didSet {
            // ✅ 根据跑马灯状态设置 lineBreakMode
            updateLineBreakMode()
            
            if enableMarquee {
                // ✅ 启用跑马灯：如果之前应用了手动截断，恢复原始文字
                if hasAppliedManualTruncation {
                    hasAppliedManualTruncation = false
                    rebuildAttributedTextAndLayout()
                }
                startMarquee()
            } else {
                stopMarquee()
            }
        }
    }
    
    /// 更新文字截断模式
    private func updateLineBreakMode() {
        // ✅ 静态模式下使用 .byClipping（因为我们手动添加省略号）
        // ✅ 跑马灯模式下也使用 .byClipping（文字会滚动）
        let maskMode: NSLineBreakMode = .byClipping
        maskLabel.lineBreakMode = maskMode
        maskLabel2.lineBreakMode = maskMode
        
        // ✅ emojiLabel：始终使用 .byClipping
        emojiLabel.lineBreakMode = .byClipping
        emojiLabel2.lineBreakMode = .byClipping
        
        // ✅ 静态模式：确保 emojiLabel 可见
        if !enableMarquee {
            updateEmojiLabelVisibility()
        }
    }
    
    /// 更新 emojiLabel 的可见性
    private func updateEmojiLabelVisibility() {
        // ✅ 现在使用手动截断+省略号的方案，emojiLabel 可以始终可见
        // 表情符号会正常显示（彩色），省略号也会正常显示（应用渐变）
        emojiLabel.isHidden = false
        emojiLabel2.isHidden = false
        emojiLabel.lineBreakMode = .byClipping
        emojiLabel2.lineBreakMode = .byClipping
    }
    
    /// 强制重新启动跑马灯（用于兜底）
    func restartMarqueeIfNeeded() {
        guard enableMarquee else { return }
        guard window != nil else { return }
        guard bounds.width > 0, bounds.height > 0 else { return }
        
        // ✅ 关键修复：先停止，再重新启动
        // 这样可以重新计算文字宽度和判断是否需要滚动
        stopMarquee()
        
        // 强制重新计算文字大小
        updateTextSize()
        
        // 重新启动
        startMarquee()
    }
    
    /// 调试：打印表情检测结果
    func debugEmojiDetection() {
        print("🎨 [Emoji Debug] Text: \"\(text)\"")
        for (index, ch) in text.enumerated() {
            let isEmoji = characterContainsEmoji(ch)
            print("   [\(index)] '\(ch)' -> \(isEmoji ? "✅ Emoji" : "❌ Text")")
            
            // 打印 Unicode 信息
            for scalar in ch.unicodeScalars {
                print("      U+\(String(format: "%04X", scalar.value)): isEmoji=\(scalar.properties.isEmoji), isEmojiPresentation=\(scalar.properties.isEmojiPresentation)")
            }
        }
        
        // 检查 emojiLabel 的属性
        if let attr = emojiLabel.attributedText {
            print("🎨 [Emoji Label] attributedText length: \(attr.length)")
            attr.enumerateAttributes(in: NSRange(location: 0, length: attr.length)) { attributes, range, _ in
                let substring = (attr.string as NSString).substring(with: range)
                print("   Range \(range): '\(substring)'")
                print("      Attributes: \(attributes)")
            }
        }
        
        print("🎨 [Emoji Label] textColor: \(emojiLabel.textColor?.description ?? "nil")")
        print("🎨 [Emoji Label] font: \(emojiLabel.font?.description ?? "nil")")
    }
    
    /// 调试：打印跑马灯状态
    func debugMarqueeStatus() {
        let textWidth = maskLabel.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: bounds.height)).width
        let containerWidth = bounds.width
        let thresholdWidth = containerWidth * marqueeThreshold
        
        print("🔍 [Marquee Debug]")
        print("   - enableMarquee: \(enableMarquee)")
        print("   - text (property): \"\(text)\"")
        print("   - text (maskLabel): \"\(maskLabel.text ?? "nil")\"")
        print("   - text (attributedText): \"\(maskLabel.attributedText?.string ?? "nil")\"")
        print("   - text match: \(text == (maskLabel.text ?? "") ? "✅" : "❌ MISMATCH!")")
        print("   - font: \(font)")
        print("   - frame: \(frame)")
        print("   - bounds: \(bounds)")
        print("   - superview.bounds: \(superview?.bounds ?? .zero)")
        print("   - window: \(window != nil ? "✅ attached" : "❌ not attached")")
        print("   - textWidth: \(textWidth)px")
        print("   - containerWidth: \(containerWidth)px")
        print("   - threshold: \(marqueeThreshold) (\(thresholdWidth)px)")
        print("   - needsScroll: \(textWidth > thresholdWidth) (\(textWidth > thresholdWidth ? "✅" : "❌"))")
        print("   - maskLabel.frame: \(maskLabel.frame)")
        print("   - emojiLabel.frame: \(emojiLabel.frame)")
        print("   - marqueeDisplayLink: \(marqueeDisplayLink != nil ? "✅ running" : "❌ not running")")
        print("   - clipsToBounds: \(clipsToBounds)")
        
        // ✅ 关键：检查是否有 Auto Layout 约束
        if translatesAutoresizingMaskIntoConstraints == false {
            print("   ⚠️ Using Auto Layout - constraints may not be applied yet")
        }
        
        if enableMarquee && marqueeDisplayLink == nil && textWidth > thresholdWidth {
            print("   ⚠️ WARNING: Marquee should be running but it's not!")
            print("   💡 Try calling: label.restartMarqueeIfNeeded()")
        } else if enableMarquee && textWidth <= thresholdWidth {
            print("   💡 Text is too short. Current situation:")
            print("      - Text needs: \(textWidth)px")
            print("      - Container has: \(containerWidth)px")
            print("      - Threshold requires: >\(thresholdWidth)px")
            if textWidth > containerWidth {
                print("   ⚠️ CRITICAL: Text is wider than container but threshold blocks it!")
                print("      Solution: Set marqueeThreshold = 1.0 (default)")
            }
        }
        
        // ✅ 检查文本不一致的情况
        if text != (maskLabel.text ?? "") {
            print("   🚨 TEXT MISMATCH DETECTED!")
            print("      - Property 'text': \"\(text)\"")
            print("      - maskLabel.text: \"\(maskLabel.text ?? "nil")\"")
            print("      - This may cause marquee issues!")
            print("      💡 Solution: Call rebuildAttributedTextAndLayout() or set text again")
        }
    }

    var marqueeSpeed: CGFloat = 50.0
    var marqueeDelay: TimeInterval = 2.0
    var marqueeGap: CGFloat = 40.0
    
    /// 跑马灯方向（默认从右往左）
    var marqueeDirection: MarqueeDirection = .rightToLeft {
        didSet {
            if enableMarquee {
                // 方向改变时，重新启动跑马灯
                stopMarquee()
                startMarquee()
            }
        }
    }
    
    /// 跑马灯最小宽度阈值（文字宽度超过容器宽度的百分比才启动跑马灯，默认 1.0 即 100%）
    /// 设置为 0.8 表示文字宽度达到容器的 80% 就启动跑马灯
    var marqueeThreshold: CGFloat = 1.0
    
    /// 文字对齐方式（默认居中）
    var textAlignment: NSTextAlignment = .center {
        didSet {
            updateTextAlignment()
        }
    }

    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }

    deinit {
        marqueeDisplayLink?.invalidate()
        gradientDisplayLink?.invalidate()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            ensureGradientAnimatingIfNeeded()
            // ✅ 兜底：如果启用了跑马灯但没有启动，重新启动
            if enableMarquee && marqueeDisplayLink == nil {
                // 延迟一点确保 bounds 已经正确
                DispatchQueue.main.async { [weak self] in
                    self?.startMarquee()
                }
            }
        } else {
            stopAnimation()
        }
    }

    // MARK: - Setup
    private func setupLayers() {
        clipsToBounds = true

        layer.addSublayer(gradientContainerLayer)
        gradientContainerLayer.addSublayer(gradientLayer)
        gradientContainerLayer.mask = maskContainerLayer

        updateGradientDirection()
        updateGradientColors()

        maskLabel.textAlignment = textAlignment
        maskLabel.font = font
        maskLabel.numberOfLines = 1
        maskLabel.lineBreakMode = .byTruncatingTail  // ✅ 默认显示省略号
        maskLabel.backgroundColor = .clear

        maskLabel2.textAlignment = textAlignment
        maskLabel2.font = font
        maskLabel2.numberOfLines = 1
        maskLabel2.lineBreakMode = .byTruncatingTail  // ✅ 默认显示省略号
        maskLabel2.backgroundColor = .clear

        maskContainerLayer.addSublayer(maskLabel.layer)
        maskContainerLayer.addSublayer(maskLabel2.layer)

        emojiLabel.textAlignment = textAlignment
        emojiLabel.font = font
        emojiLabel.numberOfLines = 1
        emojiLabel.lineBreakMode = .byClipping  // ✅ 不显示省略号
        emojiLabel.backgroundColor = .clear
        emojiLabel.isUserInteractionEnabled = false
        addSubview(emojiLabel)

        emojiLabel2.textAlignment = textAlignment
        emojiLabel2.font = font
        emojiLabel2.numberOfLines = 1
        emojiLabel2.lineBreakMode = .byClipping  // ✅ 不显示省略号
        emojiLabel2.backgroundColor = .clear
        emojiLabel2.isUserInteractionEnabled = false
        addSubview(emojiLabel2)

        rebuildAttributedTextAndLayout()
        ensureGradientAnimatingIfNeeded()
    }
    
    private func updateTextAlignment() {
        maskLabel.textAlignment = textAlignment
        maskLabel2.textAlignment = textAlignment
        emojiLabel.textAlignment = textAlignment
        emojiLabel2.textAlignment = textAlignment
    }

    private func updateGradientDirection() {
        let points = gradientDirection.points
        gradientLayer.startPoint = points.start
        gradientLayer.endPoint = points.end
    }

    private func updateGradientColors() {
        let colors = gradientColors.map { $0.cgColor }
        
        // ✅ 关键：创建无缝循环的渐变
        // 策略：[a,b,c,d,a] 重复两次，让 d→a 的过渡平滑
        let count = gradientColors.count
        
        if count > 1 {
            // 添加第一个颜色到末尾，形成循环：[a,b,c,d,a]
            let cyclicColors = colors + [colors[0]]
            gradientLayer.colors = cyclicColors + cyclicColors
            
            var locations: [NSNumber] = []
            let totalSteps = count  // a,b,c,d 之间有 count 个间隔
            let step = 0.5 / Double(totalSteps)
            
            // 第一组：0 到 0.5
            for i in 0...count {
                let location = Double(i) * step
                locations.append(NSNumber(value: location))
            }
            
            // 第二组：0.5 到 1.0
            for i in 0...count {
                let location = 0.5 + Double(i) * step
                locations.append(NSNumber(value: location))
            }
            
            gradientLayer.locations = locations
        } else {
            // 只有一个颜色
            gradientLayer.colors = [colors[0], colors[0]]
            gradientLayer.locations = [0, 1.0]
        }
        
        #if DEBUG
        print("🎨 [updateGradientColors] input colors: \(count)")
        print("   gradient colors: \(gradientLayer.colors?.count ?? 0)")
        print("   locations: \(gradientLayer.locations ?? [])")
        #endif
    }

    // MARK: - Emoji handling
    private func isEmojiScalar(_ scalar: UnicodeScalar) -> Bool {
        // 1. 检查是否是表情展示形式（彩色表情）
        if scalar.properties.isEmojiPresentation { return true }
        
        // 2. 检查是否是标准表情符号范围（通常是彩色的）
        if scalar.value >= 0x1F000 && scalar.value <= 0x1FFFF {
            // 排除单独的区域指示符号（国旗字母）
            if scalar.value >= 0x1F1E6 && scalar.value <= 0x1F1FF {
                return false
            }
            
            // 排除带圆圈/方框的字母和数字（装饰性字符）
            // 这些字符应该跟文字一起渲染
            if scalar.value >= 0x1F170 && scalar.value <= 0x1F189 {
                return false  // 🅰-🆉 等方框字母
            }
            if scalar.value >= 0x1F100 && scalar.value <= 0x1F10C {
                return false  // 🄀-🄌 等带圆圈数字
            }
            
            return true
        }
        
        // 3. 其他符号（如 ★ ❤ 等）不作为表情处理
        return false
    }

    private func characterContainsEmoji(_ ch: Character) -> Bool {
        // ✅ 如果字符包含文本变体选择器 U+FE0E，不作为表情处理
        if ch.unicodeScalars.contains(where: { $0.value == 0xFE0E }) {
            return false
        }
        
        // ✅ 检查是否是完整的国旗（两个区域指示符号）
        let regionalIndicators = ch.unicodeScalars.filter {
            $0.value >= 0x1F1E6 && $0.value <= 0x1F1FF
        }
        if regionalIndicators.count == 2 {
            // 完整的国旗，作为表情处理
            return true
        } else if regionalIndicators.count == 1 {
            // 不完整的国旗，作为文字处理
            return false
        }
        
        // 检查字符中是否包含真正的表情符号
        for scalar in ch.unicodeScalars {
            // 跳过变体选择器
            if scalar.value == 0xFE0E || scalar.value == 0xFE0F {
                continue
            }
            if isEmojiScalar(scalar) { return true }
        }
        return false
    }

    private func rebuildAttributedTextAndLayout() {
        let full = text
        
        // ✅ 暂时不判断是否需要截断，先构建完整的 attributedText
        // 在 layoutSubviews 之后再判断（因为此时 bounds 可能还是 0）
        let displayText = full

        let maskAttr = NSMutableAttributedString()
        let emojiAttr = NSMutableAttributedString()

        let normalColorForMask = UIColor.white

        for ch in displayText {
            let str = String(ch)
            let isEmoji = characterContainsEmoji(ch)

            if isEmoji {
                // ✅ 真正的彩色表情（如 👑 😀）：使用系统字体
                let emojiFont = UIFont.systemFont(ofSize: font.pointSize)
                
                // 在 mask 中透明，让 emojiLabel 显示彩色表情
                maskAttr.append(NSAttributedString(string: str, attributes: [
                    .font: emojiFont,
                    .foregroundColor: UIColor.clear
                ]))
                
                // 在 emoji label 中显示原色
                emojiAttr.append(NSAttributedString(string: str, attributes: [
                    .font: emojiFont
                ]))
            } else {
                // ✅ 普通文字和文本样式符号（如 ★ ❤︎）：应用渐变效果
                // 在 mask 中白色（用于渐变）
                maskAttr.append(NSAttributedString(string: str, attributes: [
                    .font: font,
                    .foregroundColor: normalColorForMask
                ]))
                // 在 emoji label 中透明
                emojiAttr.append(NSAttributedString(string: str, attributes: [
                    .font: font,
                    .foregroundColor: UIColor.clear
                ]))
            }
        }

        maskLabel.attributedText = maskAttr
        maskLabel2.attributedText = maskAttr

        emojiLabel.attributedText = emojiAttr
        emojiLabel2.attributedText = emojiAttr

        updateTextSize()
        setNeedsLayout()
        layoutIfNeeded()

        if enableMarquee {
            resetMarqueeToStartPosition()
        } else {
            // ✅ 静态模式：在 layoutSubviews 之后再处理截断
            emojiLabel.isHidden = false
            emojiLabel2.isHidden = false
            updateEmojiLabelVisibility()
        }
    }
    
    /// 判断文字是否会被截断（需要在 bounds 确定后调用）
    private func willTextBeTruncated(_ text: String) -> Bool {
        guard bounds.width > 0 else { return false }
        
        // ✅ 使用 maskLabel 的 attributedText 来测量，更准确
        guard let attrText = maskLabel.attributedText, attrText.length > 0 else {
            return false
        }
        
        let textWidth = attrText.boundingRect(
            with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: bounds.height),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        ).width
        
        return textWidth > bounds.width
    }
    
    /// 手动截断文字并添加省略号
    private func truncateTextWithEllipsis(_ text: String) -> NSAttributedString {
        let ellipsis = "..."
        
        // ✅ 使用 attributedString 计算省略号宽度，更准确
        let ellipsisAttr = NSAttributedString(string: ellipsis, attributes: [.font: font])
        let ellipsisWidth = ellipsisAttr.boundingRect(
            with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: bounds.height),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        ).width
        
        // ✅ 添加安全边距（4 像素），确保不会超出
        let safetyMargin: CGFloat = 4
        let maxWidth = bounds.width - ellipsisWidth - safetyMargin
        
        var result = ""
        var currentAttr = NSMutableAttributedString()
        
        for ch in text {
            let charStr = String(ch)
            let isEmoji = characterContainsEmoji(ch)
            let charFont = isEmoji ? UIFont.systemFont(ofSize: font.pointSize) : font
            
            // ✅ 使用 attributedString 计算字符宽度，更准确
            let charAttr = NSAttributedString(string: charStr, attributes: [.font: charFont])
            let charWidth = charAttr.boundingRect(
                with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: bounds.height),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                context: nil
            ).width
            
            // ✅ 测试添加这个字符后的总宽度
            let testAttr = NSMutableAttributedString(attributedString: currentAttr)
            testAttr.append(charAttr)
            let testWidth = testAttr.boundingRect(
                with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: bounds.height),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                context: nil
            ).width
            
            if testWidth > maxWidth {
                break
            }
            
            result.append(ch)
            currentAttr.append(charAttr)
        }
        
        result += ellipsis
        
        // 构建 attributedText
        let maskAttr = NSMutableAttributedString()
        let emojiAttr = NSMutableAttributedString()
        
        for ch in result {
            let str = String(ch)
            let isEmoji = characterContainsEmoji(ch)
            
            if isEmoji {
                let emojiFont = UIFont.systemFont(ofSize: font.pointSize)
                maskAttr.append(NSAttributedString(string: str, attributes: [
                    .font: emojiFont,
                    .foregroundColor: UIColor.clear
                ]))
                emojiAttr.append(NSAttributedString(string: str, attributes: [
                    .font: emojiFont
                ]))
            } else {
                maskAttr.append(NSAttributedString(string: str, attributes: [
                    .font: font,
                    .foregroundColor: UIColor.white
                ]))
                emojiAttr.append(NSAttributedString(string: str, attributes: [
                    .font: font,
                    .foregroundColor: UIColor.clear
                ]))
            }
        }
        
        return maskAttr
    }
    
    /// 应用手动截断（在 layoutSubviews 之后调用）
    private func applyManualTruncationIfNeeded() {
        guard !enableMarquee else {
            // 跑马灯模式：不需要截断
            hasAppliedManualTruncation = false
            return
        }
        guard bounds.width > 0 else { return }
        guard willTextBeTruncated(text) else {
            // 文字不会被截断：不需要手动截断
            hasAppliedManualTruncation = false
            return
        }
        
        // ✅ 避免重复应用截断
        guard !hasAppliedManualTruncation else { return }
        
        // 手动截断并更新 attributedText
        let truncatedMaskAttr = truncateTextWithEllipsis(text)
        maskLabel.attributedText = truncatedMaskAttr
        maskLabel2.attributedText = truncatedMaskAttr
        
        // 同时更新 emojiLabel
        let emojiAttr = NSMutableAttributedString()
        if let maskStr = truncatedMaskAttr.string as String? {
            for ch in maskStr {
                let str = String(ch)
                let isEmoji = characterContainsEmoji(ch)
                
                if isEmoji {
                    let emojiFont = UIFont.systemFont(ofSize: font.pointSize)
                    emojiAttr.append(NSAttributedString(string: str, attributes: [
                        .font: emojiFont
                    ]))
                } else {
                    emojiAttr.append(NSAttributedString(string: str, attributes: [
                        .font: font,
                        .foregroundColor: UIColor.clear
                    ]))
                }
            }
        }
        emojiLabel.attributedText = emojiAttr
        emojiLabel2.attributedText = emojiAttr
        
        // ✅ 标记已应用手动截断
        hasAppliedManualTruncation = true
    }

    // MARK: - Layout & Size
    private func updateTextSize() {
        if enableMarquee {
            // ✅ 跑马灯模式：先测量文字宽度，判断是否真的需要滚动
            let textSize = maskLabel.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: bounds.height))
            let needsScroll = textSize.width > bounds.width * marqueeThreshold
            
            if needsScroll {
                // 需要滚动：使用文字的实际宽度
                maskLabel.frame.size = textSize
                maskLabel2.frame.size = textSize
                emojiLabel.frame.size = textSize
                emojiLabel2.frame.size = textSize
            } else {
                // ✅ 不需要滚动：直接使用 bounds，避免闪烁
                maskLabel.frame = bounds
                maskLabel2.frame = bounds
                emojiLabel.frame = bounds
                emojiLabel2.frame = bounds
            }
        } else {
            maskLabel.frame = bounds
            maskLabel2.frame = bounds
            emojiLabel.frame = bounds
            emojiLabel2.frame = bounds
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        gradientContainerLayer.frame = bounds
        maskContainerLayer.frame = bounds

        layoutGradientLayerForSeamlessTransform()

        updateTextSize()

        if !enableMarquee {
            emojiLabel.frame = bounds
            emojiLabel2.isHidden = true
            maskLabel2.isHidden = true  // ✅ 兜底：确保隐藏
            
            // ✅ 静态模式：应用手动截断
            applyManualTruncationIfNeeded()
        } else {
            emojiLabel.isHidden = false
            emojiLabel2.isHidden = false
            maskLabel2.isHidden = false  // ✅ 确保显示

            maskLabel.frame.origin.y = 0
            maskLabel2.frame.origin.y = 0
            emojiLabel.frame.origin.y = 0
            emojiLabel2.frame.origin.y = 0

            maskLabel.frame.size.height = bounds.height
            maskLabel2.frame.size.height = bounds.height
            emojiLabel.frame.size.height = bounds.height
            emojiLabel2.frame.size.height = bounds.height
            
            // ✅ 兜底：如果启用了跑马灯但没有启动，重新启动
            if marqueeDisplayLink == nil && maskLabel.frame.width > bounds.width {
                startMarquee()
            }
        }

        ensureGradientAnimatingIfNeeded()
    }

    private func layoutGradientLayerForSeamlessTransform() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        let w = bounds.width
        let h = bounds.height

        switch gradientDirection {
        case .horizontalLeftToRight:
            // 向右移动：从 x=0 开始，向右移动到 x=w
            gradientLayer.frame = CGRect(x: -w, y: 0, width: w * 2, height: h)
            
        case .horizontalRightToLeft:
            // 向左移动：从 x=0 开始，向左移动到 x=-w
            gradientLayer.frame = CGRect(x: 0, y: 0, width: w * 2, height: h)

        case .verticalTopToBottom:
            // 向下移动：从 y=0 开始，向下移动到 y=h
            gradientLayer.frame = CGRect(x: 0, y: -h, width: w, height: h * 2)
            
        case .verticalBottomToTop:
            // 向上移动：从 y=0 开始，向上移动到 y=-h
            gradientLayer.frame = CGRect(x: 0, y: 0, width: w, height: h * 2)

        case .diagonalDownRight:
            // 向右下移动
            gradientLayer.frame = CGRect(x: -w, y: -h, width: w * 2, height: h * 2)
            
        case .diagonalDownLeft:
            // 向左下移动
            gradientLayer.frame = CGRect(x: 0, y: -h, width: w * 2, height: h * 2)
            
        case .diagonalUpRight:
            // 向右上移动
            gradientLayer.frame = CGRect(x: -w, y: 0, width: w * 2, height: h * 2)
            
        case .diagonalUpLeft:
            // 向左上移动
            gradientLayer.frame = CGRect(x: 0, y: 0, width: w * 2, height: h * 2)
        }

        CATransaction.commit()
    }

    // MARK: - Gradient Animation

    private func ensureGradientAnimatingIfNeeded() {
        guard autoStartAnimation else { return }
        guard window != nil else { return }
        guard bounds.width > 0, bounds.height > 0 else { return }
        guard !text.isEmpty else { return }
        if !isAnimating {
            startAnimation()
        }
    }

    func startAnimation() {
        guard !isAnimating else { return }
        isAnimating = true

        gradientDisplayLink?.invalidate()
        gradientDisplayLink = CADisplayLink(target: self, selector: #selector(updateGradientFrame))
        gradientDisplayLink?.preferredFramesPerSecond = preferredFramesPerSecond
        gradientDisplayLink?.add(to: .main, forMode: .common)

        gradientStartTime = CACurrentMediaTime()
    }

    func stopAnimation() {
        isAnimating = false
        gradientDisplayLink?.invalidate()
        gradientDisplayLink = nil

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        gradientLayer.transform = CATransform3DIdentity
        CATransaction.commit()
    }

    @objc private func updateGradientFrame() {
        let w = bounds.width
        let h = bounds.height
        guard w > 0, h > 0 else { return }

        let now = CACurrentMediaTime()
        // ✅ 使用 getCurrentAnimationDuration() 获取当前应该使用的时长
        let duration = max(getCurrentAnimationDuration(), 0.001)
        let elapsed = now - gradientStartTime
        
        // ✅ 关键：使用 truncatingRemainder 保持在 [0, 1) 范围
        // 但因为 gradientLayer 是 2 倍大小且 locations 均匀分布，循环是无缝的
        let speed = 1.0 / duration
        let cycles = elapsed * speed
        var phase = CGFloat(cycles.truncatingRemainder(dividingBy: 1.0))
        
        // ✅ 修复：确保 phase 永远小于 1.0（避免浮点数精度问题）
        if phase >= 1.0 {
            phase = 0.0
        }
        
        #if DEBUG
        // 只在 phase 接近 0 或 1 时打印（循环点）
        if phase < 0.05 || phase > 0.95 {
            let colors = gradientLayer.colors?.count ?? 0
            let locations = gradientLayer.locations?.count ?? 0
            print("🎨 [Gradient] phase: \(String(format: "%.3f", phase)), duration: \(duration), direction: \(gradientDirection), colors: \(colors), locations: \(locations), frame: \(gradientLayer.frame)")
        }
        #endif
        
        let dx: CGFloat
        let dy: CGFloat

        switch gradientDirection {
        case .horizontalLeftToRight:
            // 左到右：波浪向右移动（gradientLayer 向右移动）
            dx = w * phase
            dy = 0
            
        case .horizontalRightToLeft:
            // 右到左：波浪向左移动（gradientLayer 向左移动）
            dx = -w * phase
            dy = 0
            
        case .verticalTopToBottom:
            // 上到下：波浪向下移动（gradientLayer 向下移动）
            dx = 0
            dy = h * phase
            
        case .verticalBottomToTop:
            // 下到上：波浪向上移动（gradientLayer 向上移动）
            dx = 0
            dy = -h * phase
            
        case .diagonalDownRight:
            // 左上到右下：波浪向右下移动
            dx = w * phase
            dy = h * phase
            
        case .diagonalDownLeft:
            // 右上到左下：波浪向左下移动
            dx = -w * phase
            dy = h * phase
            
        case .diagonalUpRight:
            // 左下到右上：波浪向右上移动
            dx = w * phase
            dy = -h * phase
            
        case .diagonalUpLeft:
            // 右下到左上：波浪向左上移动
            dx = -w * phase
            dy = -h * phase
        }

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        gradientLayer.transform = CATransform3DMakeTranslation(dx, dy, 0)
        CATransaction.commit()
    }

    // MARK: - Marquee Animation
    private func startMarquee() {
        updateTextSize()

        // ✅ 跑马灯模式：恢复 emojiLabel 的可见性
        emojiLabel.alpha = 1.0
        emojiLabel2.alpha = 1.0

        // ✅ 使用实际测量的文字宽度，而不是 maskLabel.frame.width
        let textWidth = maskLabel.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: bounds.height)).width
        let containerWidth = bounds.width
        let needsScroll = textWidth > containerWidth * marqueeThreshold
        
        #if DEBUG
        print("🎬 [Marquee] startMarquee called")
        print("   - Text (property): \(text)")
        print("   - Text (maskLabel): \(maskLabel.text ?? "nil")")
        print("   - Text (attributedText): \(maskLabel.attributedText?.string ?? "nil")")
        print("   - textWidth: \(textWidth)")
        print("   - containerWidth: \(containerWidth)")
        print("   - threshold: \(marqueeThreshold) (\(containerWidth * marqueeThreshold)px)")
        print("   - needsScroll: \(needsScroll)")
        print("   - window: \(window != nil ? "✅" : "❌")")
        #endif
        
        guard needsScroll else {
            // ✅ 不需要滚动时，updateTextSize() 已经设置好了 frame
            // 只需要隐藏第二份内容即可，不要再次设置 frame（避免闪烁）
            maskLabel2.isHidden = true
            emojiLabel2.isHidden = true
            
            #if DEBUG
            print("   ⚠️ Text too short, marquee not needed")
            #endif
            return
        }

        // ✅ 需要滚动时，显示第二份内容
        maskLabel2.isHidden = false
        emojiLabel2.isHidden = false

        marqueeDisplayLink?.invalidate()
        marqueeDisplayLink = CADisplayLink(target: self, selector: #selector(updateMarquee))
        marqueeDisplayLink?.add(to: .main, forMode: .common)

        resetMarqueeToStartPosition()
        marqueeStartTime = CACurrentMediaTime() + marqueeDelay
        
        // ✅ 跑马灯启动后，速度会自动改变（通过 getCurrentAnimationDuration）
        // 不需要重置 gradientStartTime，让动画平滑过渡
        
        #if DEBUG
        print("   ✅ Marquee started, delay: \(marqueeDelay)s")
        print("   🎨 Current animation duration: \(getCurrentAnimationDuration())s")
        #endif
    }

     func stopMarquee() {
        marqueeDisplayLink?.invalidate()
        marqueeDisplayLink = nil

        maskLabel.frame = bounds
        maskLabel2.frame = bounds
        emojiLabel.frame = bounds
        emojiLabel2.frame = bounds
        
        // ✅ 兜底：确保第二份内容隐藏
        maskLabel2.isHidden = true
        emojiLabel2.isHidden = true
        
        // ✅ 跑马灯停止后，速度会自动恢复（通过 getCurrentAnimationDuration）
        // 不需要重置 gradientStartTime，让动画平滑过渡
        
        #if DEBUG
        print("🎬 [Marquee] Stopped, gradient speed restored")
        print("   🎨 Current animation duration: \(getCurrentAnimationDuration())s")
        #endif
    }

    private func resetMarqueeToStartPosition() {
        let w = maskLabel.frame.width
        let gap = marqueeGap

        switch marqueeDirection {
        case .rightToLeft:
            // 从右往左：第一份从右边开始（x=0），第二份在第一份右边
            maskLabel.frame.origin.x = 0
            maskLabel2.frame.origin.x = w + gap
            
            emojiLabel.frame.origin.x = 0
            emojiLabel2.frame.origin.x = w + gap
            
        case .leftToRight:
            // 从左往右：第一份从左边开始（x=0），第二份在第一份左边
            maskLabel.frame.origin.x = 0
            maskLabel2.frame.origin.x = -(w + gap)
            
            emojiLabel.frame.origin.x = 0
            emojiLabel2.frame.origin.x = -(w + gap)
        }

        maskLabel.frame.origin.y = 0
        maskLabel2.frame.origin.y = 0
        emojiLabel.frame.origin.y = 0
        emojiLabel2.frame.origin.y = 0

        maskLabel.frame.size.height = bounds.height
        maskLabel2.frame.size.height = bounds.height
        emojiLabel.frame.size.height = bounds.height
        emojiLabel2.frame.size.height = bounds.height

        emojiLabel2.isHidden = false
    }

    @objc private func updateMarquee() {
        let now = CACurrentMediaTime()
        guard now >= marqueeStartTime else { return }

        let w = maskLabel.frame.width
        let gap = marqueeGap
        let cycleLen = w + gap
        guard cycleLen > 0 else { return }

        let elapsed = now - marqueeStartTime
        let speed = max(marqueeSpeed, 0.1)
        let offset = (CGFloat(elapsed) * speed).truncatingRemainder(dividingBy: cycleLen)

        let x1: CGFloat
        let x2: CGFloat
        
        switch marqueeDirection {
        case .rightToLeft:
            // 从右往左：向左移动
            // 第一份：从 0 移动到 -cycleLen
            // 第二份：从 cycleLen 移动到 0
            x1 = -offset
            x2 = x1 + cycleLen
            
        case .leftToRight:
            // 从左往右：向右移动
            // 第一份：从 0 移动到 cycleLen
            // 第二份：从 -cycleLen 移动到 0
            x1 = offset
            x2 = x1 - cycleLen
        }

        maskLabel.frame.origin.x = x1
        maskLabel2.frame.origin.x = x2

        emojiLabel.frame.origin.x = x1
        emojiLabel2.frame.origin.x = x2
    }
}

