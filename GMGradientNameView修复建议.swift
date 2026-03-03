// GMGradientNameView.swift
// 修复后的版本

import UIKit

/// vip渐变名字配置
class GMGradientNameView: GMWaveGradientLabelView {
    
    /// 配置文字大小和颜色
    func configUI(font: UIFont, level: Int, defaultColors: [UIColor]) {
        // 1) 先清理（复用最关键）
        stopAnimation()
        enableMarquee = false   // 会 stopMarquee()
        
        // 2) 设置基本属性
        self.gradientDirection = .topRightToBottomLeft
        self.font = font
        self.gradientColors = getColors(level: level, defaultColors: defaultColors)
        
        // 3) 如果是 VIP，配置跑马灯
        if level > 0 {
            self.animationDuration = 2.0
            self.marqueeSpeed = 20
            self.marqueeDelay = 1.0
            self.marqueeGap = 10
            
            // ✅ 修复：降低阈值，让稍短的文字也能滚动
            self.marqueeThreshold = 0.85  // 文字达到容器 85% 就启动跑马灯
            
            // ✅ 修复：延迟启用，确保 text 和 bounds 都已设置
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                // 强制重新计算文字大小
                self.setNeedsLayout()
                self.layoutIfNeeded()
                
                // 启用跑马灯
                self.enableMarquee = true
                
                // 调试输出
                #if DEBUG
                self.debugMarqueeStatus()
                #endif
            }
        }
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
            return [UIColor.init(hexColor: "#FF00D5"),
                    UIColor.init(hexColor: "#FFCB00"),
                    UIColor.init(hexColor: "#FF3FBF"),
                    UIColor.init(hexColor: "#FFDC00")]
        }
        else if level == 5 {
            return [UIColor.init(hexColor: "#0A5AFF"),
                    UIColor.init(hexColor: "#7BF9FF"),
                    UIColor.init(hexColor: "#073FB3")]
        }
        else if level == 6 {
            return [UIColor.init(hexColor: "#CB0A0A"),
                    UIColor.init(hexColor: "#FFB43E"),
                    UIColor.init(hexColor: "#F20000")]
        }
        else if level == 7 {
            return [UIColor.init(hexColor: "#8015FF"),
                    UIColor.init(hexColor: "#EC34FF"),
                    UIColor.init(hexColor: "#6500FF")]
        }
        return defaultColors
    }
}

// MARK: - 使用示例

/*
 // 在 Cell 或 ViewController 中使用
 
 let nameLabel = GMGradientNameView()
 nameLabel.text = "GG2668🙂🙂🙂🤪"  // 先设置文字
 nameLabel.configUI(font: UIFont.systemFont(ofSize: 20, weight: .semibold), 
                    level: 1, 
                    defaultColors: [.white])
 
 // 如果是在 Cell 中，在 willDisplay 时再次检查
 func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
     if let cell = cell as? YourCell {
         cell.nameLabel.restartMarqueeIfNeeded()
     }
 }
 */
