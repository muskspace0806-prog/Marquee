//
//  ViewController.swift
//  波浪渐变动画Label
//
//  Created by hule on 2026/1/16.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        setupExamples()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // ✅ 兜底：确保所有跑马灯都正常启动
        // 在某些情况下（如复杂布局、异步加载），可能需要在 viewDidAppear 中再次检查
        view.subviews.compactMap { $0 as? WaveGradientLabelView }.forEach { label in
            label.restartMarqueeIfNeeded()
        }
    }
    
    private func setupExamples() {
        // 示例1：水平方向（左到右）
        let horizontalLTRLabel = WaveGradientLabelView(frame: CGRect(x: 20, y: 80, width: view.bounds.width - 40, height: 50))
        horizontalLTRLabel.text = "水平左→右"
        horizontalLTRLabel.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        horizontalLTRLabel.gradientColors = [.systemPink, .systemPurple, .systemBlue]
        horizontalLTRLabel.gradientDirection = .horizontalLeftToRight
        horizontalLTRLabel.animationDuration = 3.0
        horizontalLTRLabel.startAnimation()
        view.addSubview(horizontalLTRLabel)
        
        // 示例2：水平方向（右到左）
        let horizontalRTLLabel = WaveGradientLabelView(frame: CGRect(x: 20, y: 140, width: view.bounds.width - 40, height: 50))
        horizontalRTLLabel.text = "水平右→左"
        horizontalRTLLabel.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        horizontalRTLLabel.gradientColors = [.systemPink, .systemPurple, .systemBlue]
        horizontalRTLLabel.gradientDirection = .horizontalRightToLeft
        horizontalRTLLabel.animationDuration = 3.0
        horizontalRTLLabel.startAnimation()
        view.addSubview(horizontalRTLLabel)
        
        // 示例3：垂直方向（上到下）
        let verticalTTBLabel = WaveGradientLabelView(frame: CGRect(x: 20, y: 200, width: view.bounds.width - 40, height: 50))
        verticalTTBLabel.text = "垂直上→下"
        verticalTTBLabel.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        verticalTTBLabel.gradientColors = [.systemRed, .systemOrange, .systemYellow]
        verticalTTBLabel.gradientDirection = .verticalTopToBottom
        verticalTTBLabel.animationDuration = 3.0
        verticalTTBLabel.startAnimation()
        view.addSubview(verticalTTBLabel)
        
        // 示例4：垂直方向（下到上）
        let verticalBTTLabel = WaveGradientLabelView(frame: CGRect(x: 20, y: 260, width: view.bounds.width - 40, height: 50))
        verticalBTTLabel.text = "垂直下→上"
        verticalBTTLabel.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        verticalBTTLabel.gradientColors = [.systemRed, .systemOrange, .systemYellow]
        verticalBTTLabel.gradientDirection = .verticalBottomToTop
        verticalBTTLabel.animationDuration = 3.0
        verticalBTTLabel.startAnimation()
        view.addSubview(verticalBTTLabel)
        
        // 示例5：左上到右下
        let diagonalDownRightLabel = WaveGradientLabelView(frame: CGRect(x: 20, y: 320, width: view.bounds.width - 40, height: 50))
        diagonalDownRightLabel.text = "左上→右下"
        diagonalDownRightLabel.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        diagonalDownRightLabel.gradientColors = [.systemGreen, .systemTeal, .systemCyan]
        diagonalDownRightLabel.gradientDirection = .diagonalDownRight
        diagonalDownRightLabel.animationDuration = 3.0
        diagonalDownRightLabel.startAnimation()
        view.addSubview(diagonalDownRightLabel)
        
        // 示例6：右上到左下
        let diagonalDownLeftLabel = WaveGradientLabelView(frame: CGRect(x: 20, y: 380, width: view.bounds.width - 40, height: 50))
        diagonalDownLeftLabel.text = "右上→左下"
        diagonalDownLeftLabel.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        diagonalDownLeftLabel.gradientColors = [.systemIndigo, .systemPurple, .systemPink]
        diagonalDownLeftLabel.gradientDirection = .diagonalDownLeft
        diagonalDownLeftLabel.animationDuration = 3.0
        diagonalDownLeftLabel.startAnimation()
        view.addSubview(diagonalDownLeftLabel)
        
        // 示例7：左下到右上
        let diagonalUpRightLabel = WaveGradientLabelView(frame: CGRect(x: 20, y: 440, width: view.bounds.width - 40, height: 50))
        diagonalUpRightLabel.text = "左下→右上"
        diagonalUpRightLabel.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        diagonalUpRightLabel.gradientColors = [.systemBlue, .systemCyan, .systemMint]
        diagonalUpRightLabel.gradientDirection = .diagonalUpRight
        diagonalUpRightLabel.animationDuration = 3.0
        diagonalUpRightLabel.startAnimation()
        view.addSubview(diagonalUpRightLabel)
        
        // 示例8：右下到左上
        let diagonalUpLeftLabel = WaveGradientLabelView(frame: CGRect(x: 20, y: 500, width: view.bounds.width - 40, height: 50))
        diagonalUpLeftLabel.text = "右下→左上"
        diagonalUpLeftLabel.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        diagonalUpLeftLabel.gradientColors = [.systemOrange, .systemYellow, .systemPink]
        diagonalUpLeftLabel.gradientDirection = .diagonalUpLeft
        diagonalUpLeftLabel.animationDuration = 3.0
        diagonalUpLeftLabel.startAnimation()
        view.addSubview(diagonalUpLeftLabel)
        
        // 示例9：跑马灯效果（从右往左，默认）
        let marqueeLabel = WaveGradientLabelView(frame: CGRect(x: 20, y: 560, width: view.bounds.width - 40, height: 50))
        marqueeLabel.text = "😯这是一段很长的文字，会自动滚动显示跑马灯效果😯mo🐔"
        marqueeLabel.font = UIFont.systemFont(ofSize: 30, weight: .heavy)
        marqueeLabel.gradientColors = [.systemYellow, .systemOrange, .systemRed, .systemPink]
        marqueeLabel.gradientDirection = .horizontalLeftToRight
        marqueeLabel.animationDuration = 2.0
        marqueeLabel.enableMarquee = true
        marqueeLabel.marqueeDirection = .rightToLeft  // 从右往左（默认）
        marqueeLabel.marqueeSpeed = 10
        marqueeLabel.marqueeDelay = 1.0
        marqueeLabel.startAnimation()
        view.addSubview(marqueeLabel)
        
        // 示例10：跑马灯效果（从左往右，阿语等 RTL 语言）
        let marqueeRTLLabel = WaveGradientLabelView(frame: CGRect(x: 20, y: 620, width: view.bounds.width - 40, height: 50))
        marqueeRTLLabel.text = "مرحبا بك في التطبيق 😀 هذا نص طويل"
        marqueeRTLLabel.font = UIFont.systemFont(ofSize: 30, weight: .heavy)
        marqueeRTLLabel.gradientColors = [.systemGreen, .systemTeal, .systemCyan, .systemBlue]
        marqueeRTLLabel.gradientDirection = .horizontalLeftToRight
        marqueeRTLLabel.animationDuration = 2.0
        marqueeRTLLabel.enableMarquee = true
        marqueeRTLLabel.marqueeDirection = .leftToRight  // 从左往右（RTL）
        marqueeRTLLabel.marqueeSpeed = 10
        marqueeRTLLabel.marqueeDelay = 1.0
        marqueeRTLLabel.startAnimation()
        view.addSubview(marqueeRTLLabel)
    }
}
