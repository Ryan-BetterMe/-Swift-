//
//  DrawGraphics.swift
//  函数式Swift学习
//
//  Created by Ryan on 2021/4/21.
//

import Foundation
import UIKit

// 之前封装CoreImage自定义了滤镜链条
// 现在封装Core Graphic来进行函数式的封装，可以得到一条更易于组合的API

// Core Graphic 只作用于当前的上下文 我决定绘制一个圆形
func draw01() -> UIImage {
    let bounds = CGRect(origin: CGPoint.init(x: 0, y: 0), size: CGSize.init(width: 300, height: 300))
    let renderer = UIGraphicsImageRenderer(bounds: bounds)
    let image = renderer.image { (context) in
//        UIColor.blue.setFill()
//        context.fill(CGRect(x: 0.0, y: 37.5, width: 75.0, height: 75.0))
//        UIColor.red.setFill()
//        context.fill(CGRect(x: 75.0, y: 0.0, width: 150.0, height: 150.0))
//        UIColor.green.setFill()
//        context.cgContext.fillEllipse(in:
//        CGRect(x: 225.0, y: 37.5, width: 75.0, height: 75.0))
        
        context.cgContext.draw(.text("我可是一个不幸运的人呐"), in: bounds)
        context.cgContext.draw(Diagram.align(CGPoint.init(x: 0, y: 0.5), Diagram.beside(.primitive(CGSize.init(width: 100, height: 100), .rectangle), .primitive(CGSize.init(width: 100, height: 100), .ellipse))), in: bounds)
    }
    
    return image
}

// 问题提出：1、难以维护，很难拓展 2、违反了OCP原则

//MARK: -
//MARK: - 核心数据结构
// 1.绘制不同类型的数据，定义一个枚举:椭圆 矩形 文字
enum Primitive {
    case ellipse
    case rectangle
    case text(String)
}

enum Attribute {
    case fillColor(UIColor)
}

indirect enum Diagram {
    // 单个图形：椭圆 或者 矩形 或者 文字
    case primitive(CGSize, Primitive)
    // 相邻的（水平）
    case beside(Diagram, Diagram)
    // 上下的（垂直）
    case below(Diagram, Diagram)
    // 带样式的图表
    case attributed(Attribute, Diagram)
    // 描述对其方式 默认垂直居中
    case align(CGPoint, Diagram)
}

// .align(CGPoint(x:0.5, y:0), blueSquare) ||| redSquare

//MARK: -
//MARK: - 计算与绘制
extension Diagram {
    var size: CGSize {
        switch self {
        case .primitive(let size, _):
            return size
        case .attributed(_, let x):
            return x.size
        case let .beside(l, r):
            let sizeL = l.size
            let sizeR = r.size
            
            return CGSize(width: sizeL.width + sizeR.width, height: max(sizeL.height, sizeR.height))
        case let .below(l, r):
            return CGSize(width: max(l.size.width, r.size.width), height: l.size.height + r.size.height)
        case .align(_, let r):
            return r.size
        }
    }
}

extension CGSize {
    // 此方法确保某尺寸值长宽比边的情况下，安装传入的矩形进行缩放
    // alignment “如果该 CGPoint 的 x 为 0 表示左对齐，为 1 则表示右对齐。类似地，y 为 0 时表示上对齐，为 1 时则表示下对齐：”
    func fit(into rect: CGRect, alignment: CGPoint) -> CGRect {
        let scale = min(rect.width / width, rect.height / height)
        let targetSize = scale * self
        
        let spacerSize = alignment.size * (rect.size - targetSize)
        return CGRect(origin: rect.origin + spacerSize.point, size: targetSize)
    }
}

extension CGSize {
    var point: CGPoint {
        return CGPoint(x: self.width, y: self.height)
    }
}

extension CGPoint {
    var size: CGSize {
        return CGSize(width: x, height: y)
    }
}

func *(l: CGFloat, r: CGSize) -> CGSize {
    return CGSize(width: l * r.width, height: l * r.height)
}

func *(l: CGSize, r: CGSize) -> CGSize {
    return CGSize(width: l.width * r.width, height: l.height * r.height)
}

func -(l: CGSize, r: CGSize) -> CGSize {
    return CGSize(width: l.width - r.width, height: l.height - r.height)
}

func +(l: CGPoint, r: CGPoint) -> CGPoint {
    return CGPoint(x: l.x + r.x, y: l.y + r.y)
}

extension CGRect {
    func split(ratio: CGFloat, edge: CGRectEdge) -> (CGRect, CGRect) {
        let length = edge.isHorizontal ? width : height
        return divided(atDistance: length * ratio, from: edge)
    }
}

extension CGRectEdge {
    var isHorizontal: Bool {
        return self == .maxXEdge || self == .minXEdge
    }
}

extension CGContext {
    func draw(_ primitive: Primitive, in frame: CGRect) {
        switch primitive {
        // 矩形：直接填充即可
        case .rectangle:
            fill(frame)
        // 给定矩形区域，但是填充椭圆
        case .ellipse:
            fillEllipse(in: frame)
        // 直接绘制文本
        case .text(let text):
            let font = UIFont.systemFont(ofSize: 12)
            let attributes = [NSAttributedString.Key.font: font]
            let attributedText = NSAttributedString(string: text, attributes: attributes)
            attributedText.draw(in: frame)
        }
    }
    
    func draw(_ diagram: Diagram, in bounds: CGRect) {
        switch diagram {
        case let .primitive(size, primitive):
            let bounds = size.fit(into: bounds, alignment: CGPoint.init(x: 0.5, y: 0.5))
            draw(primitive, in: bounds)
            
        case .align(let alignment, let diagram):
            let bounds = diagram.size.fit(into: bounds, alignment: alignment)
            draw(diagram, in: bounds)
            
        case .beside(let left, let right):
            let (lBounds, rBounds) = bounds.split(ratio: left.size.width / diagram.size.width, edge: .minXEdge)
            draw(left, in: lBounds)
            draw(right, in: rBounds)
            
        case .below(let top, let bottom):
            let (tBounds, bBounds) = bounds.split(ratio: top.size.height/diagram.size.height, edge: .minYEdge)
            draw(top, in: tBounds)
            draw(bottom, in: bBounds)
            
        case let .attributed(.fillColor(color), diagram):
            saveGState()
            color.set()
            draw(diagram, in: bounds)
            restoreGState()
        }
    }
}

// 额外的遍历函数
func rect(width: CGFloat, height: CGFloat) -> Diagram {
    return .primitive(CGSize.init(width: width, height: height), .rectangle)
}

func cricle(diameter: CGFloat) -> Diagram {
    return .primitive(CGSize.init(width: diameter, height: diameter), .ellipse)
}

func text(_ theText: String, width: CGFloat, height: CGFloat) -> Diagram {
    return .primitive(CGSize.init(width: width, height: height), .text(theText))
}

func square(side: CGFloat) -> Diagram {
    return rect(width: side, height: side)
}

precedencegroup HorizontalCombination {
    higherThan: VerticalCombination
    associativity: left
}

infix operator |||: HorizontalCombination
func |||(l: Diagram, r: Diagram) -> Diagram {
    return .beside(l, r)
}

precedencegroup VerticalCombination {
    associativity: left
}
infix operator --- : VerticalCombination
func ---(l: Diagram, r: Diagram) -> Diagram {
    return .below(l, r)
}


/// 问题来了，通过这些小巧的代码，就可以创造出强大的图表绘制库！！！
/// 可以说，这两个库都是定义了一种领域特定语言（domain - specific - language) DSL

