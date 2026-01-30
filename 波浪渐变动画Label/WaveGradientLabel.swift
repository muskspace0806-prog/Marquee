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
    case vertical         // 垂直：上到下
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
class WaveGradientLabel: UIView {
    
    // MARK: - Properties
    private let gradientLayer = CAGradientLayer()
    private let textLabel = UILabel()
    private var isAnimating = false
    private var marqueeDisplayLink: CADisplayLink?
    private var marqueeStartTime: CFTimeInterval = 0
    
    /// 文字内容
    var text: String = "" {
        didSet {
            textLabel.text = text
            updateTextSize()
        }
    }
    
    /// 字体
    var font: UIFont = UIFont.systemFont(ofSize: 40, weight: .bold) {
        didSet {
            textLabel.font = font
            updateTextSize()
        }
    }
    
    /// 文字颜色（用于非渐变状态）
    var textColor: UIColor = .white {
        didSet {
            textLabel.textColor = textColor
        }
    }
    
    /// 渐变颜色数组
    var gradientColors: [UIColor] = [.systemPink, .systemPurple, .systemBlue, .systemTeal] {
        didSet {
            updateGradientColors()
        }
    }
    
    /// 渐变方向
    var gradientDirection: WaveGradientDirection = .horizontal {
        didSet {
            updateGradientDirection()
        }
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
        
        // 设置渐变层
        updateGradientDirection()
        updateGradientColors()
        layer.addSublayer(gradientLayer)
        
        // 设置文字 Label
        textLabel.textAlignment = .center
        textLabel.font = font
        textLabel.textColor = textColor
        textLabel.text = text
        addSubview(textLabel)
        
        // 使用文字 Label 的 layer 作为渐变的遮罩
        gradientLayer.mask = textLabel.layer
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
        let step = 1.0 / Double(gradientColors.count)
        var locations: [NSNumber] = []
        for i in 0..<gradientColors.count {
            locations.append(NSNumber(value: Double(i) * step * 0.5))
        }
        for i in 0..<gradientColors.count {
            locations.append(NSNumber(value: 0.5 + Double(i) * step * 0.5))
        }
        gradientLayer.locations = locations
    }
    
    private func updateTextSize() {
        if enableMarquee {
            let size = textLabel.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: bounds.height))
            textLabel.frame.size = size
        } else {
            textLabel.frame = bounds
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        updateTextSize()
    }
    
    // MARK: - Gradient Animation
    /// 开始波浪动画
    func startAnimation() {
        guard !isAnimating else { return }
        isAnimating = true
        
        let animation = CABasicAnimation(keyPath: "locations")
        
        // 创建波浪移动效果
        let step = 1.0 / Double(gradientColors.count)
        var fromLocations: [NSNumber] = []
        var toLocations: [NSNumber] = []
        
        for i in 0..<gradientColors.count {
            fromLocations.append(NSNumber(value: Double(i) * step * 0.5))
        }
        for i in 0..<gradientColors.count {
            fromLocations.append(NSNumber(value: 0.5 + Double(i) * step * 0.5))
        }
        
        for i in 0..<gradientColors.count {
            toLocations.append(NSNumber(value: 0.5 + Double(i) * step * 0.5))
        }
        for i in 0..<gradientColors.count {
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
        guard textLabel.frame.width > bounds.width else { return }
        
        marqueeDisplayLink?.invalidate()
        marqueeDisplayLink = CADisplayLink(target: self, selector: #selector(updateMarquee))
        marqueeDisplayLink?.add(to: .main, forMode: .common)
        marqueeStartTime = CACurrentMediaTime() + marqueeDelay
    }
    
    private func stopMarquee() {
        marqueeDisplayLink?.invalidate()
        marqueeDisplayLink = nil
        textLabel.frame = bounds
    }
    
    @objc private func updateMarquee() {
        let currentTime = CACurrentMediaTime()
        
        // 延迟后开始滚动
        guard currentTime >= marqueeStartTime else { return }
        
        let textWidth = textLabel.frame.width
        let viewWidth = bounds.width
        let totalDistance = textWidth + viewWidth
        
        // 计算当前位置
        let elapsed = currentTime - marqueeStartTime
        let distance = CGFloat(elapsed) * marqueeSpeed
        let position = distance.truncatingRemainder(dividingBy: totalDistance)
        
        textLabel.frame.origin.x = viewWidth - position
        
        // 如果滚动完成一轮，重置开始时间（添加延迟）
        if position < marqueeSpeed / 60.0 { // 接近起点
            marqueeStartTime = currentTime + marqueeDelay
        }
    }
}
