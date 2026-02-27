//
//  WaveGradientLabel.swift
//  波浪渐变动画Label
//
//  Created by hule on 2026/1/16.
//

import UIKit

// MARK: - 渐变方向枚举
enum WaveGradientDirection {
    case horizontal        // 水平：左到右
    case vertical          // 垂直：上到下
    case topLeftToBottomRight    // 左上到右下
    case topRightToBottomLeft    // 右上到左下

    var points: (start: CGPoint, end: CGPoint) {
        switch self {
        case .horizontal:
            return (CGPoint(x: 0, y: 0.5), CGPoint(x: 1, y: 0.5))
        case .vertical:
            return (CGPoint(x: 0.5, y: 0), CGPoint(x: 0.5, y: 1))
        case .topLeftToBottomRight:
            return (CGPoint(x: 0, y: 0), CGPoint(x: 1, y: 1))
        case .topRightToBottomLeft:
            return (CGPoint(x: 1, y: 0), CGPoint(x: 0, y: 1))
        }
    }
}

// MARK: - WaveGradientLabel
/// 渐变波浪文字 + 可选跑马灯；✅ Emoji 不参与渐变渲染（保持原色）
class WaveGradientLabel: UIView {

    // MARK: - Layers
    private let gradientLayer = CAGradientLayer()

    /// 只用于做渐变遮罩：非 emoji 正常显示，emoji 位置透明（挖空）
    private let maskLabel = UILabel()

    /// 覆盖在上面只显示 emoji（原色），非 emoji 透明
    private let emojiLabel = UILabel()

    // MARK: - State
    private var isAnimating = false
    private var marqueeDisplayLink: CADisplayLink?
    private var marqueeStartTime: CFTimeInterval = 0

    // MARK: - Public Properties

    /// 文字内容
    var text: String = "" {
        didSet { rebuildAttributedTextAndLayout() }
    }

    /// 字体
    var font: UIFont = UIFont.systemFont(ofSize: 40, weight: .bold) {
        didSet {
            maskLabel.font = font
            emojiLabel.font = font
            rebuildAttributedTextAndLayout()
        }
    }

    /// 文字颜色（仅用于 emojiLabel 的 emoji 原色渲染时不需要；这里保留用于兼容非渐变模式/普通文字）
    var textColor: UIColor = .white {
        didSet {
            // 普通文字颜色实际在 maskLabel 的 attributedText 里设置为 white（只要不透明就行）
            // emojiLabel 默认不设置 textColor（emoji 原色渲染不依赖它）
            rebuildAttributedTextAndLayout()
        }
    }

    /// 渐变颜色数组
    var gradientColors: [UIColor] = [.systemPink, .systemPurple, .systemBlue, .systemTeal] {
        didSet { updateGradientColors() }
    }

    /// 渐变方向
    var gradientDirection: WaveGradientDirection = .horizontal {
        didSet { updateGradientDirection() }
    }

    /// 动画时长
    var animationDuration: TimeInterval = 3.0

    /// 是否启用跑马灯效果
    var enableMarquee: Bool = false {
        didSet {
            if enableMarquee {
                startMarquee()
            } else {
                stopMarquee()
            }
        }
    }

    /// 跑马灯滚动速度（点/秒）
    var marqueeSpeed: CGFloat = 50.0

    /// 跑马灯延迟时间（秒）
    var marqueeDelay: TimeInterval = 2.0

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
    }

    // MARK: - Setup
    private func setupLayers() {
        clipsToBounds = true

        // 渐变层
        updateGradientDirection()
        updateGradientColors()
        layer.addSublayer(gradientLayer)

        // maskLabel：只用于 mask
        maskLabel.textAlignment = .center
        maskLabel.font = font
        maskLabel.numberOfLines = 1
        maskLabel.backgroundColor = .clear
        // 关键：用 maskLabel.layer 当渐变遮罩（emoji 位置透明）
        gradientLayer.mask = maskLabel.layer

        // emojiLabel：覆盖在上面，显示 emoji（原色）
        emojiLabel.textAlignment = .center
        emojiLabel.font = font
        emojiLabel.numberOfLines = 1
        emojiLabel.backgroundColor = .clear
        emojiLabel.isUserInteractionEnabled = false
        addSubview(emojiLabel)

        rebuildAttributedTextAndLayout()
    }

    private func updateGradientDirection() {
        let points = gradientDirection.points
        gradientLayer.startPoint = points.start
        gradientLayer.endPoint = points.end
    }

    private func updateGradientColors() {
        let colors = gradientColors.map { $0.cgColor }
        // 扩展颜色数组以创建波浪效果
        gradientLayer.colors = colors + colors

        // 设置颜色位置，创建波浪效果
        let step = 1.0 / Double(max(gradientColors.count, 1))
        var locations: [NSNumber] = []
        for i in 0..<gradientColors.count {
            locations.append(NSNumber(value: Double(i) * step * 0.5))
        }
        for i in 0..<gradientColors.count {
            locations.append(NSNumber(value: 0.5 + Double(i) * step * 0.5))
        }
        gradientLayer.locations = locations
    }

    // MARK: - Emoji handling

    /// 判断某个 UnicodeScalar 是否“像 emoji”
    /// 说明：emoji 识别很复杂，这里用系统属性做高可用判断（足够应对大部分 emoji + ZWJ 序列）。
    private func isEmojiScalar(_ scalar: UnicodeScalar) -> Bool {
        // properties.isEmoji 会把很多符号也算进去，但我们结合 presentation/emoji modifiers 做更接近“彩色 emoji”的判断
        if scalar.properties.isEmojiPresentation { return true }
        if scalar.properties.generalCategory == .otherSymbol, scalar.properties.isEmoji { return true }
        if scalar.properties.isEmoji && (scalar.value >= 0x1F000) { return true } // 常见 emoji 区段
        return false
    }

    /// 判断字符是否包含 emoji（用于逐 Character 分割时的近似判断）
    private func characterContainsEmoji(_ ch: Character) -> Bool {
        for scalar in ch.unicodeScalars {
            if isEmojiScalar(scalar) { return true }
        }
        return false
    }

    /// 构建两份 attributedText：
    /// - maskLabel：非 emoji 不透明，emoji 透明
    /// - emojiLabel：emoji 不透明，非 emoji 透明
    private func rebuildAttributedTextAndLayout() {
        let full = text

        let maskAttr = NSMutableAttributedString()
        let emojiAttr = NSMutableAttributedString()

        // 让 maskLabel 有 alpha 作为遮罩，颜色本身无所谓（只要不透明）
        // 这里用白色（或 textColor）都行；关键是 emoji 位置 alpha=0
        let normalColorForMask = UIColor.white

        for ch in full {
            let str = String(ch)
            let isEmoji = characterContainsEmoji(ch)

            if isEmoji {
                // mask：emoji 透明挖空
                maskAttr.append(NSAttributedString(string: str, attributes: [
                    .font: font,
                    .foregroundColor: UIColor.clear
                ]))
                // emojiLayer：emoji 原色显示
                // 注意：不要强行给 emoji 设置颜色，保持系统彩色渲染
                emojiAttr.append(NSAttributedString(string: str, attributes: [
                    .font: font
                ]))
            } else {
                // mask：普通文字不透明
                maskAttr.append(NSAttributedString(string: str, attributes: [
                    .font: font,
                    .foregroundColor: normalColorForMask
                ]))
                // emojiLayer：普通文字透明
                emojiAttr.append(NSAttributedString(string: str, attributes: [
                    .font: font,
                    .foregroundColor: UIColor.clear
                ]))
            }
        }

        maskLabel.attributedText = maskAttr
        emojiLabel.attributedText = emojiAttr

        updateTextSize()
        setNeedsLayout()
        layoutIfNeeded()
    }

    // MARK: - Layout & Size
    private func updateTextSize() {
        if enableMarquee {
            // 跑马灯：两层 label 都需要相同宽度
            let size = maskLabel.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: bounds.height))
            maskLabel.frame.size = size
            emojiLabel.frame.size = size
        } else {
            maskLabel.frame = bounds
            emojiLabel.frame = bounds
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds

        // 重要：maskLabel 不用 addSubview，但要保证 frame 正确
        updateTextSize()

        // emojiLabel 在 view 上显示，需要对齐
        if !enableMarquee {
            emojiLabel.frame = bounds
        }
    }

    // MARK: - Gradient Animation
    /// 开始波浪动画
    func startAnimation() {
        guard !isAnimating else { return }
        isAnimating = true

        let animation = CABasicAnimation(keyPath: "locations")

        // 创建波浪移动效果
        let count = max(gradientColors.count, 1)
        let step = 1.0 / Double(count)

        var fromLocations: [NSNumber] = []
        var toLocations: [NSNumber] = []

        for i in 0..<count {
            fromLocations.append(NSNumber(value: Double(i) * step * 0.5))
        }
        for i in 0..<count {
            fromLocations.append(NSNumber(value: 0.5 + Double(i) * step * 0.5))
        }

        for i in 0..<count {
            toLocations.append(NSNumber(value: 0.5 + Double(i) * step * 0.5))
        }
        for i in 0..<count {
            toLocations.append(NSNumber(value: 1.0 + Double(i) * step * 0.5))
        }

        animation.fromValue = fromLocations
        animation.toValue = toLocations
        animation.duration = animationDuration
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        gradientLayer.add(animation, forKey: "waveAnimation")
    }

    /// 停止波浪动画
    func stopAnimation() {
        isAnimating = false
        gradientLayer.removeAnimation(forKey: "waveAnimation")
    }

    // MARK: - Marquee Animation
    private func startMarquee() {
        updateTextSize()

        // 只要文字宽度超过视图就滚动（用 maskLabel 的宽度即可）
        guard maskLabel.frame.width > bounds.width else { return }

        marqueeDisplayLink?.invalidate()
        marqueeDisplayLink = CADisplayLink(target: self, selector: #selector(updateMarquee))
        marqueeDisplayLink?.add(to: .main, forMode: .common)
        marqueeStartTime = CACurrentMediaTime() + marqueeDelay
    }

    private func stopMarquee() {
        marqueeDisplayLink?.invalidate()
        marqueeDisplayLink = nil

        maskLabel.frame = bounds
        emojiLabel.frame = bounds
    }

    @objc private func updateMarquee() {
        let currentTime = CACurrentMediaTime()

        // 延迟后开始滚动
        guard currentTime >= marqueeStartTime else { return }

        let textWidth = maskLabel.frame.width
        let viewWidth = bounds.width
        let totalDistance = textWidth + viewWidth

        // 计算当前位置
        let elapsed = currentTime - marqueeStartTime
        let distance = CGFloat(elapsed) * marqueeSpeed
        let position = distance.truncatingRemainder(dividingBy: totalDistance)

        let x = viewWidth - position
        maskLabel.frame.origin.x = x
        emojiLabel.frame.origin.x = x

        // 如果滚动完成一轮，重置开始时间（添加延迟）
        if position < marqueeSpeed / 60.0 { // 接近起点
            marqueeStartTime = currentTime + marqueeDelay
        }
    }
}
