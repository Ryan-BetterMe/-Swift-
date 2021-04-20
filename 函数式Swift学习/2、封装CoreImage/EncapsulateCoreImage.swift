//
//  EncapsulateCoreImage.swift
//  函数式Swift学习
//
//  Created by Ryan on 2021/1/22.
//

import Foundation
import CoreImage
import UIKit

/*相关的概念
 弱类型：弱类型语言有更宽松的类型规则，这可能产生不可预测的甚至是错误的结果，也可能在运行时发送隐式的类型转换。
 
 CoreImage是弱类型的API，因为使用了KVC来配置滤镜。
 
 新API将使用类型来避免运行时的错误。
 */

//MARK: -
//MARK: 类型选择
// 滤镜是CI的核心类，通过kCIInputImageKey提供输入图像，再使用outputImage取出处理后的图像
// 所以函数为：CIImage -> CIImage 接受图像参数并且返回新的图像
typealias Filter = (CIImage) -> CIImage


//MARK: -
//MARK: 高斯模糊滤镜
func blur(radius: Double) -> Filter {
    return { image in
        let parameters: [String: Any] = [kCIInputRadiusKey: radius, kCIInputImageKey: image]
        guard let filter = CIFilter(name: "CIGaussianBlur", parameters: parameters) else { fatalError() }
        guard let outputImage = filter.outputImage else { fatalError() }
        return outputImage
    }
}

//MARK: -
//MARK: 纯色叠层滤镜
/// 生成颜色的滤镜
func generate(color: UIColor) -> Filter {
    return { _ in
        let parameters = [kCIInputColorKey: CIColor(cgColor: color.cgColor)]
        guard let filter = CIFilter(name: "CIConstantColorGenerator", parameters: parameters) else { fatalError() }
        guard let outputImage = filter.outputImage else { fatalError() }
        return outputImage
    }
}

/// 组合滤镜
func compositeSourceOver(overlay: CIImage) -> Filter {
    return { image in
        let parameters = [kCIInputBackgroundImageKey: image, kCIInputImageKey: overlay]
        guard let filter = CIFilter(name: "CISourceOverCompositing", parameters: parameters) else { fatalError() }
        guard let outputImage = filter.outputImage else { fatalError() }
        return outputImage.cropped(to: image.extent) // 将输出图像剪裁为输入图像一样的尺寸
    }
}

func overlay(color: UIColor) -> Filter {
    return { image in
        let overlay = generate(color: color)(image).cropped(to: image.extent)
        return compositeSourceOver(overlay: overlay)(image)
    }
}

// sobel算法 提取边缘
func sobel() -> Filter {
    return { image in
        let sobel: [CGFloat] = [-1, 0, 1, -2, 0, 2, -1, 0, 1]
        let weight = CIVector(values: sobel, count: 9)
        guard let filter = CIFilter(name: "CIConvolution3X3",
                                    parameters: [kCIInputWeightsKey: weight,
                                                 kCIInputBiasKey: 0.5,
                                                 kCIInputImageKey: image]) else { fatalError() }
        
        guard let outImage = filter.outputImage else { fatalError() }
        
        return outImage.cropped(to: image.extent)
    }
}


// Sobel算子: 边缘提取算法
func relief() -> Filter {
    return { image in
        let vector: [CGFloat] = [1, 0, 0, 0, 0, 0, 0, 0, -1]
        let weight = CIVector(values: vector, count: 9)
        guard let filter = CIFilter(name: "CIConvolution3X3",
                                    parameters: [kCIInputWeightsKey: weight,
                                                 kCIInputBiasKey: 0.5,
                                                 kCIInputImageKey: image]) else { fatalError() }
        
        guard let outImage = filter.outputImage else { fatalError() }
        
        return outImage.cropped(to: image.extent)
    }
}

// 图像颜色反转
func colorInvert() -> Filter {
    return { image in
        guard let filter = CIFilter(name: "CIColorInvert",
                                    parameters: [kCIInputImageKey: image]) else { fatalError() }
        guard let outImage = filter.outputImage else { fatalError() }
        return outImage.cropped(to: image.extent)
    }
}

/// 图像变色
func colorControls(h: NSNumber, s: NSNumber, b: NSNumber) -> Filter {
    return { image in
        guard let filter = CIFilter(name: "CIColorControls", parameters: [kCIInputImageKey: image, kCIInputSaturationKey: h, kCIInputContrastKey: s, kCIInputBrightnessKey: b]) else { fatalError() }
        
        guard let outImage = filter.outputImage else { fatalError() }
        
        return outImage.cropped(to: image.extent)
    }
}

//MARK: -
//MARK: 复合函数
func compose(_ filter1: @escaping Filter, _ filter2: @escaping Filter) -> Filter {
    return { image in
        return filter2(filter1(image))
    }
}


/// 使用自定义运算符，在这里可以让代码更清晰易读
//infix operator >>>
//public func >>>(filter1: @escaping Filter, filter2: @escaping Filter) -> Filter {
//    return { image in
//        filter2(filter1(image))
//    }
//}

/// >>> 运算符 左结合的 所以滤镜是以从左到右顺序加在图像上的
//let blurAndOverlay2 = blur(radius: 5) >>> overlay(color: UIColor.red)

//MARK: -
//MARK: 理论背景 - 柯里化
// 将一个接受多参数的函数变换为一系列只接受单个参数的函数，这个过程为柯里化
// 如果被科里化了，那么对于接受多参数的函数，我们的选择就可以：使用一个或两个参数来调用。

//MARK: -
//MARK: 讨论
// 以上例子阐释了将复杂代码拆解为小块的方式，而这些小块可以使用函数式的方式进行重新装配，并形成完整的功能。
// 那么相比于苹果自己的API，这种方式的优点什么呢？
// 1、安全
// 没有未定义的键，没有强制的类型转换，减少了崩溃的可能性；没有状态的保存，所以减少了内存泄漏的可能性
// 2、模块化
// 使用>>>运算符很容易进行滤镜的组合，可以将复杂滤镜拆解为更小，更简单且可复用的组件。同时每个滤镜都可以独立测试和理解。
// 3、清晰易懂
// 不需要特定的kCIInputImageKey之类的键值对来进行初始化，直接通过函数名称就可以得知具体的含义，非常清晰易于理解。



