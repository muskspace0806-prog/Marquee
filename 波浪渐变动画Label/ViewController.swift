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
    
    private func setupExamples() {
        // 示例1：水平方向
        let horizontalLabel = WaveGradientLabel(frame: CGRect(x: 20, y: 100, width: view.bounds.width - 40, height: 60))
        horizontalLabel.text = "水平渐变"
        horizontalLabel.font = UIFont.systemFont(ofSize: 40, weight: .bold)
        horizontalLabel.gradientColors = [.systemPink, .systemPurple, .systemBlue]
        horizontalLabel.gradientDirection = .horizontal
        horizontalLabel.animationDuration = 3.0
        horizontalLabel.startAnimation()
        view.addSubview(horizontalLabel)
        
        // 示例2：垂直方向
        let verticalLabel = WaveGradientLabel(frame: CGRect(x: 20, y: 200, width: view.bounds.width - 40, height: 60))
        verticalLabel.text = "垂直渐变"
        verticalLabel.font = UIFont.systemFont(ofSize: 40, weight: .bold)
        verticalLabel.gradientColors = [.systemRed, .systemOrange, .systemYellow]
        verticalLabel.gradientDirection = .vertical
        verticalLabel.animationDuration = 3.0
        verticalLabel.startAnimation()
        view.addSubview(verticalLabel)
        
        // 示例3：左上到右下
        let diagonalLabel1 = WaveGradientLabel(frame: CGRect(x: 20, y: 300, width: view.bounds.width - 40, height: 60))
        diagonalLabel1.text = "左上到右下"
        diagonalLabel1.font = UIFont.systemFont(ofSize: 40, weight: .bold)
        diagonalLabel1.gradientColors = [.systemGreen, .systemTeal, .systemCyan]
        diagonalLabel1.gradientDirection = .topLeftToBottomRight
        diagonalLabel1.animationDuration = 3.0
        diagonalLabel1.startAnimation()
        view.addSubview(diagonalLabel1)
        
        // 示例4：右上到左下
        let diagonalLabel2 = WaveGradientLabel(frame: CGRect(x: 20, y: 400, width: view.bounds.width - 40, height: 60))
        diagonalLabel2.text = "右上到左下"
        diagonalLabel2.font = UIFont.systemFont(ofSize: 40, weight: .bold)
        diagonalLabel2.gradientColors = [.systemIndigo, .systemPurple, .systemPink]
        diagonalLabel2.gradientDirection = .topRightToBottomLeft
        diagonalLabel2.animationDuration = 3.0
        diagonalLabel2.startAnimation()
        view.addSubview(diagonalLabel2)
        
        // 示例5：跑马灯效果
        let marqueeLabel = WaveGradientLabel(frame: CGRect(x: 20, y: 500, width: view.bounds.width - 40, height: 60))
        marqueeLabel.text = "这是一段很长的文字，会自动滚动显示跑马灯效果"
        marqueeLabel.font = UIFont.systemFont(ofSize: 35, weight: .heavy)
        marqueeLabel.gradientColors = [.systemYellow, .systemOrange, .systemRed, .systemPink]
        marqueeLabel.gradientDirection = .horizontal
        marqueeLabel.animationDuration = 2.0
        marqueeLabel.enableMarquee = true  // 启用跑马灯
        marqueeLabel.marqueeSpeed = 50    // 滚动速度（秒）
        marqueeLabel.marqueeDelay = 1.0    // 延迟时间（秒）
        marqueeLabel.startAnimation()
        view.addSubview(marqueeLabel)
    }
}
