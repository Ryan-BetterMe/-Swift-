//
//  QuickCheck.swift
//  函数式Swift学习
//
//  Created by Ryan on 2021/1/28.
//

import Foundation
import CoreGraphics

/*
 QuickCheck (Claessen and Hughes 2000) 是一个用于随机测试的 Haskell 库。
 相较于独立的单元测试中每个部分都依赖特定输入来测试函数是否正确，QuickCheck 允许你描述函数的抽象特性并生成测试来验证这些特性。
 当一个特性通过了测试，就没有必要再证明它的准确性。
 
 “更确切地说，QuickCheck 旨在找到证明特性错误的临界条件。”
 */
//MARK: - QuickCheck的特性
//1. 需要一个方法生成随机数
//2. 需要实现check函数，将随机数传递给它的特性参数
//3. “如果一个测试失败了，我们会希望测试的输入值尽可能小。比方说，如果我们在对一个有 100 个元素的数组进行测试时失败了，我们会尝试让数组元素更少一些，然后看一看测试是否依然失败。”
//4. “最后，我们还需要做一些额外的工作以确保检验函数适用于带有泛型的类型。

//MARK: 生成随机数
protocol Arbitary: Smaller {
    static func arbitary() -> Self
}

extension Int: Arbitary {
    /// 生成随机数
    static func arbitary() -> Int {
        // arc3random 是生成 0 ~ 2的32次方中的随机数
        return Int(arc4random())
    }
    
    /// 避免越界
    static func arbitary(in range: CountableRange<Int>) -> Int {
        let diff = range.upperBound - range.lowerBound
        return range.lowerBound + (Int.arbitary() % diff)
    }
}

//UnicodeScalar是代表单个的unicode字符，可以直接赋值单个字符，或者是通过数值表示来初始化
extension UnicodeScalar: Arbitary {
    static func arbitary() -> UnicodeScalar {
        return UnicodeScalar(Int.arbitary(in: 65..<90))!
    }
    
    func smaller() -> Unicode.Scalar? {
        return nil
    }
}

extension String: Arbitary {
    static func arbitary() -> String {
        let randomLength = Int.arbitary(in: 0..<40)
        let randomScalars = (0..<randomLength).map { _ in
            UnicodeScalar.arbitary()
        }
        return String(UnicodeScalarView(randomScalars))
    }
}

func check1<A: Arbitary>(_ message: String, _ property: (A) -> Bool) -> () {
    for _ in 0..<20 {
        let value = A.arbitary()
        guard property(value) else {
            print("\"\(message)\" doesn't hold: \(value)")
            return
        }
    }
    print("\"\(message)\" passed \(20) tests.")
}

extension CGSize {
    var area: CGFloat {
        return width * height
    }
}

extension CGSize: Arbitary {
    static func arbitary() -> CGSize {
        return CGSize.init(width: .arbitary(), height: .arbitary())
    }
    
    func smaller() -> CGSize? {
        return nil
    }
}

/// 失败的输入不够简单，这里自动对失败的输入值进行缩减，并且重新测试
protocol Smaller {
    func smaller() -> Self?
}

// 对于整数，尝试将其除以2，直到0
extension Int: Smaller {
    func smaller() -> Int? {
        return self == 0 ? nil : self/2
    }
}
// 100.smaller() // Optional(50)

// 对于字符串，则是移除第一个字符（除非该支付穿为空）
extension String: Smaller {
    func smaller() -> String? {
        return isEmpty ? nil : String(unicodeScalars.dropFirst())
    }
}

/// 反复缩小范围: 使用递归的方式来循坏调用
func iterate<A>(while condition:(A) -> Bool, initial: A, next: (A) -> A?) -> A {
    guard let x = next(initial), condition(x) else {
        return initial
    }
    return iterate(while: condition, initial: x, next: next)
}

// 作用：生成随机值，再检验他们是否满足property参数，一旦出现反例，就反复缩小其范围。
func check2<A: Arbitary>(_ message: String, _ property: (A) -> Bool) -> () {
    for _ in 0..<20 {
        let value = A.arbitary()
        guard property(value) else {
            // 即smaller之后，也是反例
            let smallerValue = iterate(while: { !property($0) }, initial: value) {
                $0.smaller()
            }
            print("\"\(message)\" doesn't hold: \(smallerValue)")
            return
        }
    }
    print("\"\(message)\" passed \(20) tests.")
}

//MARK: ========== 随机数组：快速排序 ==========
func qsort(_ input: [Int]) -> [Int] {
    var array = input
    if array.isEmpty { return [] }
    
    let pivot = array.removeFirst()
    let lesser = array.filter { $0 <= pivot } // 排序的稳定性
    let greater = array.filter { $0 > pivot }
    return qsort(lesser) + [pivot] + qsort(greater)
}

// 目的：生成一个由随机数组成的数组（确保可以生成随机数）
extension Array: Smaller {
    func smaller() -> Array<Element>? {
        guard !isEmpty else { return nil }
        return Array(dropLast())
    }
}

extension Array where Element: Arbitary {
    static func arbitrary() -> [Element] {
        let randomLength = Int.arbitary(in: 0..<50)
        return (0..<randomLength).map { _ in .arbitary() }
    }
}

// 表示数组的每一项都遵守该协议 但是这个限制无法表达为类型约束。所以选择修改check2函数
extension Array: Arbitary where Element: Arbitary {
    static func arbitary() -> Array<Element> {
        return []
    }
}

// 问题：check2<A>函数的问题在于它要求类型A遵循Arbitrary协议的拓展。
// 如果传入array的话，那也需要array遵守它的拓展，可是array遵守了它的拓展可以保证，但是无法保证element遵守它的拓展。
// 可是为什么element需要满足这个协议呢？因为我需要每一个元素的值也是随机数！

// 解决方案：将必要的函数smaller通过参数传入进入

/// 辅助结构体
struct ArbitaryInstance<T> {
    let arbitary: () -> T
    let smaller: (T) -> T?
}

func checkHelper<A>(_ arbitaryInstance: ArbitaryInstance<A>, _ property: (A) -> Bool, _ message: String) -> () {
    for _ in 0..<20 {
        let value = arbitaryInstance.arbitary()
        guard property(value) else {
            let smallerValue = iterate(while: { !property($0) }, initial: value, next: arbitaryInstance.smaller)
            print("\"\(message)\" doesn't hold: \(smallerValue)")
            return
        }
    }
    print("\"\(message)\" passed \(20) tests.")
}

func check<X:Arbitary>(_ message: String, property: (X) -> Bool) -> () {
    let instance = ArbitaryInstance(arbitary: X.arbitary, smaller: { $0.smaller() })
    
//    let instance = ArbitaryInstance(arbitary: X.arbitary) { (x: X) in return x.smaller() }
    
    checkHelper(instance, property, message)
}

// 如果有一个类型，无法对它定义所需要的Arbitary实例，就想数组的情况一样，我们可以重载check函数并自己构造所需的ArbitraryInstance结构体
func check<X: Arbitary>(_ message: String, property: ([X]) -> Bool) -> () {
    let instance = ArbitaryInstance(arbitary: Array.arbitrary, smaller: { (x: [X]) in x.smaller() })
    checkHelper(instance, property, message)
}

/**
 总结：
 1、如果想使用check库，可以使用SwiftCheck库，用来特性测试
 2、关于上述测试方法的实现由几个需要注意或者说迷惑的点：
   * 函数是值是可以用来传递的
          X.arbitary 传递的是static方法
         { $0.smaller() } 传递的是实例方法
   * 注意传递的是方法
   * iterate是不满足property验证的时候才继续迭代，迭代到最后一个满足smaller条件的值
 */

