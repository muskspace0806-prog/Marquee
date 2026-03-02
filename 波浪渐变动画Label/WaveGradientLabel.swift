//
//  WaveGradientLabel.swift
//  波浪渐变动画Label
//
//  Created by hule on 2026/1/16.
//

import UIKit

// MARK: - 渐变方向枚举
enum WaveGradientDirection {
    case horizontal
    case vertical
    case topLeftToBottomRight
    case topRightToBottomLeft

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

// MARK: - WaveGradientLabelView
/// 渐变波浪文字 + 可选跑马灯；✅ Emoji 不参与渐变渲染（保持原色）
class WaveGradientLabelView: UIView {

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

    // ✅ 自动开启动画（默认 true）：不走跑马灯也会自动动
    var autoStartAnimation: Bool = true {
        didSet {
            if autoStartAnimation {
                ensureGradientAnimatingIfNeeded()
            } else {
                // 只是不自动开，不强行停；外部可手动 stopAnimation()
            }
        }
    }

    // MARK: - Public Properties
    var text: String = "" {
        didSet {
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

    var gradientDirection: WaveGradientDirection = .horizontal {
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

    var enableMarquee: Bool = false {
        didSet {
            if enableMarquee {
                startMarquee()
            } else {
                stopMarquee()
            }
        }
    }

    var marqueeSpeed: CGFloat = 50.0
    var marqueeDelay: TimeInterval = 2.0
    var marqueeGap: CGFloat = 40.0

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

    // ✅ 进/出 window 生命周期：自动开/停，避免耗电
    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            ensureGradientAnimatingIfNeeded()
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

        maskLabel.textAlignment = .center
        maskLabel.font = font
        maskLabel.numberOfLines = 1
        maskLabel.backgroundColor = .clear

        maskLabel2.textAlignment = .center
        maskLabel2.font = font
        maskLabel2.numberOfLines = 1
        maskLabel2.backgroundColor = .clear

        maskContainerLayer.addSublayer(maskLabel.layer)
        maskContainerLayer.addSublayer(maskLabel2.layer)

        emojiLabel.textAlignment = .center
        emojiLabel.font = font
        emojiLabel.numberOfLines = 1
        emojiLabel.backgroundColor = .clear
        emojiLabel.isUserInteractionEnabled = false
        addSubview(emojiLabel)

        emojiLabel2.textAlignment = .center
        emojiLabel2.font = font
        emojiLabel2.numberOfLines = 1
        emojiLabel2.backgroundColor = .clear
        emojiLabel2.isUserInteractionEnabled = false
        addSubview(emojiLabel2)

        rebuildAttributedTextAndLayout()
        ensureGradientAnimatingIfNeeded()
    }

    private func updateGradientDirection() {
        let points = gradientDirection.points
        gradientLayer.startPoint = points.start
        gradientLayer.endPoint = points.end
    }

    private func updateGradientColors() {
        let colors = gradientColors.map { $0.cgColor }
        gradientLayer.colors = colors + colors

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
    private func isEmojiScalar(_ scalar: UnicodeScalar) -> Bool {
        if scalar.properties.isEmojiPresentation { return true }
        if scalar.properties.generalCategory == .otherSymbol, scalar.properties.isEmoji { return true }
        if scalar.properties.isEmoji && (scalar.value >= 0x1F000) { return true }
        return false
    }

    private func characterContainsEmoji(_ ch: Character) -> Bool {
        for scalar in ch.unicodeScalars {
            if isEmojiScalar(scalar) { return true }
        }
        return false
    }

    private func rebuildAttributedTextAndLayout() {
        let full = text

        let maskAttr = NSMutableAttributedString()
        let emojiAttr = NSMutableAttributedString()

        let normalColorForMask = UIColor.white

        for ch in full {
            let str = String(ch)
            let isEmoji = characterContainsEmoji(ch)

            if isEmoji {
                maskAttr.append(NSAttributedString(string: str, attributes: [
                    .font: font,
                    .foregroundColor: UIColor.clear
                ]))
                emojiAttr.append(NSAttributedString(string: str, attributes: [
                    .font: font
                ]))
            } else {
                maskAttr.append(NSAttributedString(string: str, attributes: [
                    .font: font,
                    .foregroundColor: normalColorForMask
                ]))
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
        }
    }

    // MARK: - Layout & Size
    private func updateTextSize() {
        if enableMarquee {
            let size = maskLabel.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: bounds.height))
            maskLabel.frame.size = size
            maskLabel2.frame.size = size
            emojiLabel.frame.size = size
            emojiLabel2.frame.size = size
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
        } else {
            emojiLabel.isHidden = false
            emojiLabel2.isHidden = false

            maskLabel.frame.origin.y = 0
            maskLabel2.frame.origin.y = 0
            emojiLabel.frame.origin.y = 0
            emojiLabel2.frame.origin.y = 0

            maskLabel.frame.size.height = bounds.height
            maskLabel2.frame.size.height = bounds.height
            emojiLabel.frame.size.height = bounds.height
            emojiLabel2.frame.size.height = bounds.height
        }

        ensureGradientAnimatingIfNeeded()
    }

    /// ✅ 关键：斜向回到 2w×2h（纹理比例稳定，不会“收缩/展开”）
    /// 同时 TR->BL 需要 y = -h，保证 dy 正向移动不露底
    private func layoutGradientLayerForSeamlessTransform() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        let w = bounds.width
        let h = bounds.height

        switch gradientDirection {
        case .horizontal:
            gradientLayer.frame = CGRect(x: 0, y: 0, width: w * 2, height: h)

        case .vertical:
            gradientLayer.frame = CGRect(x: 0, y: 0, width: w, height: h * 2)

        case .topLeftToBottomRight:
            // 2w×2h + dx/dy 用 w/h 周期即可无缝
            gradientLayer.frame = CGRect(x: 0, y: 0, width: w * 2, height: h * 2)

        case .topRightToBottomLeft:
            // dy 需要往下（+h），因此把 layer 往上挪一格，避免露底
            gradientLayer.frame = CGRect(x: 0, y: -h, width: w * 2, height: h * 2)
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

    /// ✅ 斜向无缝且不“顿一下”：frame=2w×2h，周期就用 w/h
    @objc private func updateGradientFrame() {
        let w = bounds.width
        let h = bounds.height
        guard w > 0, h > 0 else { return }

        let now = CACurrentMediaTime()
        let duration = max(animationDuration, 0.001)
        let t = (now - gradientStartTime) / duration
        let phase = CGFloat(t.truncatingRemainder(dividingBy: 1.0))   // [0,1)

        let dx: CGFloat
        let dy: CGFloat

        switch gradientDirection {
        case .horizontal:
            dx = -w * phase
            dy = 0
        case .vertical:
            dx = 0
            dy = -h * phase
        case .topLeftToBottomRight:
            dx = -w * phase
            dy = -h * phase
        case .topRightToBottomLeft:
            dx = -w * phase
            dy =  h * phase
        }

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        gradientLayer.transform = CATransform3DMakeTranslation(dx, dy, 0)
        CATransaction.commit()
    }

    // MARK: - Marquee Animation
    private func startMarquee() {
        updateTextSize()

        guard maskLabel.frame.width > bounds.width else {
            maskLabel.frame = bounds
            emojiLabel.frame = bounds
            emojiLabel2.isHidden = true
            return
        }

        marqueeDisplayLink?.invalidate()
        marqueeDisplayLink = CADisplayLink(target: self, selector: #selector(updateMarquee))
        marqueeDisplayLink?.add(to: .main, forMode: .common)

        resetMarqueeToStartPosition()
        marqueeStartTime = CACurrentMediaTime() + marqueeDelay
    }

    private func stopMarquee() {
        marqueeDisplayLink?.invalidate()
        marqueeDisplayLink = nil

        maskLabel.frame = bounds
        maskLabel2.frame = bounds
        emojiLabel.frame = bounds
        emojiLabel2.frame = bounds
        emojiLabel2.isHidden = true
    }

    private func resetMarqueeToStartPosition() {
        let w = maskLabel.frame.width
        let gap = marqueeGap

        maskLabel.frame.origin.x = 0
        maskLabel2.frame.origin.x = w + gap

        emojiLabel.frame.origin.x = 0
        emojiLabel2.frame.origin.x = w + gap

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

        let x1 = -offset
        let x2 = x1 + cycleLen

        maskLabel.frame.origin.x = x1
        maskLabel2.frame.origin.x = x2

        emojiLabel.frame.origin.x = x1
        emojiLabel2.frame.origin.x = x2
    }
}
