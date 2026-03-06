//
//  ViewController.swift
//  波浪渐变动画Label
//
//  Created by hule on 2026/1/16.
//

import UIKit

class ViewController: UIViewController {
    
    // 创建多个 GMGradientNameView 来测试不同的 VIP 等级
    let nameLabels: [GMGradientNameView] = (0...7).map { _ in GMGradientNameView() }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        
        // 测试数据
        let testData: [(text: String, level: Int)] = [
            ("普通用户", 0),
            ("VIP1用户名😊", 1),
            ("VIP2这是一个很长的用户名需要滚动显示", 2),
            ("VIP3用户👑", 3),
            ("VIP4🌟StarUser🌟", 4),
            ("VIP5超级会员", 5),
            ("VIP6至尊用户", 6),
            ("VIP7🔥传奇用户🔥这个名字特别长需要跑马灯", 7)
        ]
        
        // 布局所有 label
        for (index, nameLabel) in nameLabels.enumerated() {
            let yPosition = 100 + CGFloat(index) * 60
            nameLabel.frame = CGRect(x: 50, y: yPosition, width: 200, height: 40)
            nameLabel.backgroundColor = UIColor(white: 0.1, alpha: 1.0)
            nameLabel.layer.cornerRadius = 8
            nameLabel.clipsToBounds = true
            view.addSubview(nameLabel)
            
            // 配置
            let data = testData[index]
            nameLabel.configUI(
                text: data.text,
                font: UIFont.systemFont(ofSize: 16, weight: .bold),
                sameDirectionAnimationDuration: 1.4,
                level: data.level,
                defaultColors: [.white],
                isAutoScroll: false
            )
            
            // 添加点击事件来调试
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(labelTapped(_:)))
            nameLabel.addGestureRecognizer(tapGesture)
            nameLabel.isUserInteractionEnabled = true
        }
        
        // 添加切换语言按钮
        let switchButton = UIButton(type: .system)
        switchButton.frame = CGRect(x: 50, y: 50, width: 200, height: 40)
        switchButton.setTitle("切换语言方向", for: .normal)
        switchButton.backgroundColor = .systemBlue
        switchButton.setTitleColor(.white, for: .normal)
        switchButton.layer.cornerRadius = 8
        switchButton.addTarget(self, action: #selector(switchLanguage), for: .touchUpInside)
        view.addSubview(switchButton)
        
        // 添加重启跑马灯按钮
        let restartButton = UIButton(type: .system)
        restartButton.frame = CGRect(x: 270, y: 50, width: 100, height: 40)
        restartButton.setTitle("重启跑马灯", for: .normal)
        restartButton.backgroundColor = .systemGreen
        restartButton.setTitleColor(.white, for: .normal)
        restartButton.layer.cornerRadius = 8
        restartButton.addTarget(self, action: #selector(restartMarquee), for: .touchUpInside)
        view.addSubview(restartButton)
    }
    
    @objc func labelTapped(_ gesture: UITapGestureRecognizer) {
        guard let label = gesture.view as? GMGradientNameView else { return }
        
        print("\n========================================")
        print("点击了 label: \(label.text)")
        print("========================================")
        label.debugMarqueeStatus()
        print("========================================\n")
    }
    
    @objc func switchLanguage() {
        // 切换语言方向
        GMLanguageChange.shared.isMiddleEast.toggle()
        
        print("\n========================================")
        print("切换语言方向: \(GMLanguageChange.shared.isMiddleEast ? "阿语（从左往右）" : "英语（从右往左）")")
        print("========================================\n")
        
        // 重新配置所有 label
        let testData: [(text: String, level: Int)] = [
            ("普通用户", 0),
            ("VIP1用户名😊", 1),
            ("VIP2这是一个很长的用户名需要滚动显示", 2),
            ("VIP3用户👑", 3),
            ("VIP4🌟StarUser🌟", 4),
            ("VIP5超级会员", 5),
            ("VIP6至尊用户", 6),
            ("VIP7🔥传奇用户🔥这个名字特别长需要跑马灯", 7)
        ]
        
        for (index, nameLabel) in nameLabels.enumerated() {
            let data = testData[index]
            nameLabel.configUI(
                text: data.text,
                font: UIFont.systemFont(ofSize: 16, weight: .bold),
                sameDirectionAnimationDuration: 1.4,
                level: data.level,
                defaultColors: [.white],
                isAutoScroll: false
            )
        }
    }
    
    @objc func restartMarquee() {
        print("\n========================================")
        print("重启所有跑马灯")
        print("========================================\n")
        
        for nameLabel in nameLabels {
            nameLabel.restartMarqueeIfNeeded()
        }
    }
}
