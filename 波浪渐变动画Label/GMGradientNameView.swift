//
//  GMGradientNameView.swift
//  波浪渐变动画Label
//
//  Created by hule on 2026/1/16.
//

import UIKit

/// 模拟语言切换类（如果你的项目中没有，需要添加）
class GMLanguageChange {
    static let shared = GMLanguageChange()
    var isMiddleEast: Bool = false  // 是否是中东语言（阿语等）
}

/// UIColor 扩展（如果你的项目中没有，需要添加）
extension UIColor {
    convenience init(hexColor: String) {
        var hexString = hexColor.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if hexString.hasPrefix("#") {
            hexString.remove(at: hexString.startIndex)
        }
        
        var rgbValue: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&rgbValue)
        
        let red = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgbValue & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}

/// vip渐变名字配置
class GMGradientNameView: GMWaveGradientLabelView {
    
    // ✅ 记录当前配置的文字，避免重复配置
    private var currentConfiguredText: String = ""
    
    /// 配置文字大小和颜色
    /// - Parameters:
    ///   - text: 要显示的文字
    ///   - font: 字体
    ///   - sameDirectionAnimationDuration: 渐变和跑马灯同向时的动画时长
    ///   - level: VIP 等级（0 表示非 VIP）
    ///   - defaultColors: 默认颜色
    ///   - isAutoScroll: 是否自动滚动（非 VIP 也可以滚动）
    func configUI(text: String,
                  font: UIFont,
                  sameDirectionAnimationDuration: TimeInterval = 1.4,
                  level: Int,
                  defaultColors: [UIColor],
                  isAutoScroll: Bool = false) {
        
        #if DEBUG
        print("\n🔧 [GMGradientNameView.configUI] Called")
        print("tt   - View instance: \(Unmanaged.passUnretained(self).toOpaque())")
        print("tt   - New text: \"\(text)\"")
        print("tt   - Current text: \"\(self.text)\"")
        print("tt   - Level: \(level)")
        #endif
        
        // ✅ 关键优化：先停止所有动画，避免异步问题
        self.stopAnimation()
        self.stopMarquee()
        
        // ✅ 步骤 1：设置文字（会自动触发 didSet 清理）
        self.text = text
        currentConfiguredText = text
        
        // ✅ 步骤 2：设置渐变方向和对齐方式
        self.gradientDirection = GMLanguageChange.shared.isMiddleEast ? .horizontalLeftToRight : .horizontalRightToLeft
        self.textAlignment = GMLanguageChange.shared.isMiddleEast ? .right : .left
        
        // ✅ 步骤 3：设置字体和颜色
        self.font = font
        self.gradientColors = getColors(level: level, defaultColors: defaultColors)
        
        // ✅ 步骤 4：如果是 VIP 或需要自动滚动，配置跑马灯
        if level > 0 || isAutoScroll {
            self.animationDuration = 4.5
            self.marqueeDirection = GMLanguageChange.shared.isMiddleEast ? .leftToRight : .rightToLeft
            self.sameDirectionAnimationDuration = sameDirectionAnimationDuration
            self.marqueeSpeed = 45
            self.marqueeDelay = 0.0
            self.marqueeGap = 10
            self.marqueeThreshold = 1.0
            self.enableMarquee = true
            self.startAnimation()
            
            #if DEBUG
            print("   ✅ Marquee enabled")
            #endif
        } else {
            self.enableMarquee = false
            self.startAnimation()
            
            #if DEBUG
            print("   ✅ Marquee disabled (level 0)")
            #endif
        }
        
        #if DEBUG
        print("✅ [GMGradientNameView.configUI] Completed")
        print("   - Final text: \"\(self.text)\"\n")
        #endif
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // ✅ 确保对齐方式正确（每次布局都检查）
        self.textAlignment = GMLanguageChange.shared.isMiddleEast ? .right : .left
    }
    
    deinit {
        print("GMGradientNameView -- 销毁了")
    }
    
    private func getColors(level: Int, defaultColors: [UIColor]) -> [UIColor] {
        if level == 1 {
            return [UIColor.init(hexColor: "#7584A2"),
                    UIColor.init(hexColor: "#C3D7FF"),
                    UIColor.init(hexColor: "#798BB2")]
        }
        else if level == 2 {
            return [UIColor.init(hexColor: "#CB6900"),
                    UIColor.init(hexColor: "#FFD0C3"),
                    UIColor.init(hexColor: "#CB6900")]
        }
        else if level == 3 {
            return [UIColor.init(hexColor: "#00A16A"),
                    UIColor.init(hexColor: "#B1FF00"),
                    UIColor.init(hexColor: "#006743")]
        }
        else if level == 4 {
            return [UIColor.init(hexColor: "#0A5AFF"),
                    UIColor.init(hexColor: "#7BF9FF"),
                    UIColor.init(hexColor: "#073FB3")]
        }
        else if level == 5 {
            return [UIColor.init(hexColor: "#CB0A0A"),
                    UIColor.init(hexColor: "#FFB43E"),
                    UIColor.init(hexColor: "#F20000")]
        }
        else if level == 6 {
            return [UIColor.init(hexColor: "#8015FF"),
                    UIColor.init(hexColor: "#EC34FF"),
                    UIColor.init(hexColor: "#6500FF")]
        }
        else if level == 7 {
            return [UIColor.init(hexColor: "#FF00D5"),
                    UIColor.init(hexColor: "#FFCB00"),
                    UIColor.init(hexColor: "#FF3FBF"),
                    UIColor.init(hexColor: "#FFDC00")]
        }
        return defaultColors
    }
}
