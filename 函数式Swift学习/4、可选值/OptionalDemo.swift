//
//  OptionalDemo.swift
//  函数式Swift学习
//
//  Created by Ryan on 2021/1/27.
//

import Foundation

//MARK: -
//MARK: - 案例研究：字典
let aCities = ["Paris": 2241, "Madrid": 3165, "Amsterdam": 827, "Berlin": 3562]

// 检验查询是否成功
let madridPopulation: Int? = aCities["Madrid"]

// 原来的??会有一个问题，那就是如果可选值是非nil的话，也需要对defaultValue进行求值，可是这个开销可能是一个开销非常大的计算
// 所以作为T类型的替代，这里采用了() -> T类型的默认值，需要时才计算
func ??<T>(optinal: T?, defaultValue: () -> T) -> T {
    if let x = optinal {
        return x
    } else {
        return defaultValue()
    }
}

let testMadridPotulation = madridPopulation ?? { 2 }

// swift的标准库中使用了autoclosure类型标签来避免创建显示的闭包。
infix operator ??
func ??<T>(optional: T?, defaultValue: @autoclosure () throws -> T) rethrows -> T {
    if let x = optional {
        return x
    } else {
        return try defaultValue()
    }
}

//MARK: -
//MARK: - 玩转可选值

//MARK: 可选链
struct Order {
    let orderNumber: Int
    let person: Person?
}

struct Person {
    let name: String
    let address: Address?
}

struct Address {
    let streetName: String
    let city: String
    let state: String?
}

let order = Order(orderNumber: 42, person: nil)

/// 1.直接强制解包，可能会发生异常
let orderState = order.person!.address!.state

/// 2.使用可选绑定 (安全但是繁琐)
func optionalBind() {
    if let person = order.person {
        if let address = person.address {
            if let state = address.state {
                print("state: \(state)")
            }
        }
    }
}

/// 2.使用可选链
func optionalLink() {
    if let state = order.person?.address?.state {
        print("state: \(state)")
    } else {
        print("unknown person, address, or state")
    }
}

//MARK: 分支上的可选值
func switchOptional() {
    // switch中匹配可选值的时候，只需要为case语句里添加一个？就可以了
    switch madridPopulation {
    case 0?: print("Nobody in Madrid")
    case (1..<1000)?: print("Less than a million in Madrid")
    case let x?: print("x = \(x)")
    case nil: print("we donot know about Madrid")
    }
}

//MARK: 可选映射
/// 什么意思呢？就是如果可选值存在的话，你可能想操作它；如果是nil的话，就直接返回nil
func increment(optional: Int?) -> Int? {
    guard let x = optional else { return nil }
    return x + 1
}

// 我们可以将可选值定义为map函数，这样可以对int？类型的值做增量运算，还可以将想任何要执行的运算都作为参数传递给map函数
extension Optional {
    func map<U>(_ transform: (Wrapped) -> U) -> U? {
        guard let x = self else { return nil }
        return transform(x)
    }
}

// 问题来了：为什么将这个函数命名为map呢？这个运用于数组的map运算有什么共同点呢？后面会继续讨论这个问题
func incrementWithMap(optional: Int?) -> Int? {
    return optional.map { $0 + 1 }
}

//MARK:再谈可选绑定
// 实例如下：如果要让两个可选值相加呢？
// let x: Int? = 3
// let y: Int? = nil
// let z: Int? = x + y 这是不会被Swift编译器接受的，问题在于+不支持两个可选值之间相加
func add(_ optionalX: Int?, _ optionalY: Int?) -> Int? {
    if let x = optionalX {
        if let y = optionalY {
            return x + y
        }
    }
    return nil
}

func add2(_ optionalX: Int?, _ optionalY: Int?) -> Int? {
    if let x = optionalX, let y = optionalY {
        return x + y
    }
    return nil
}

func add3(_ optionalX: Int?, _ optionalY: Int?) -> Int? {
    guard let x = optionalX, let y = optionalY else { return nil }
    return x + y
}

let capitals = ["France": "Paris", "Spain": "Madrid", "The Netherlands": "Amsterdam"]
func populationOfCapital(country: String) -> Int? {
    guard let capital = capitals[country], let population = aCities[capital] else { return nil }
    return population * 1000
}

/// 还可以借助于标准库中的flatMap函数
/// flatMap过滤了可选值
extension Optional {
    func flatMap<U>(_ transform: (Wrapped) -> U?) -> U? {
        guard let x = self else { return nil }
        return transform(x)
    }
}

// 嵌套调用
func add4(_ optionalX: Int?, _ optionalY: Int?) -> Int? {
    return optionalX.flatMap { x in
        optionalY.flatMap { y in
            return x + y
        }
    } // transform(x)
}

func populationOfCapital2(country: String) -> Int? {
    return capitals[country].flatMap { capital in
        aCities[capital].flatMap { population in
            population * 1000
        }
    }
}

// 如果使用链式的调用语法，要注意就是编译器只会为flatMap推断出一种类型
// 为什么这里要说明呢？因为这说明两件事情：其一 swift内置的可选绑定并不神奇 其二 它们的组合是可以有很大的功能的
func populationOfCapital3(country: String) -> Int? {
    return capitals[country].flatMap { capital in
        aCities[capital]
    }.flatMap { population in
        population * 1000
    }
}

//MARK: -
//MARK: - 为什么使用可选值？
// 很值得玩味，OC中可以安全得向nil发送消息，然后根据不同的返回的类型得到nil,0这样的值，为什么Swift可以改变这种特性呢？
// 1.显示的可选类型更符合Swift增强静态安全的特点 2.强大的类型系统可以在编译时就捕捉到错误，避免由于缺失值而导致的意外崩溃
// OC的方法是有弊端的：因为向nil发送消息是安全的，但是使用它们发送消息之后的结果是很不安全的！比如给nil发送消息，需要去使用这个结果作为参数，可能就会发生崩溃

/// 函数的签名是指函数原型中除去返回值的部分, 包括函数名,形参表和关键字const(如果使用了的话)

/// 在Swift中如果坚持使用可选值可以从根本上杜绝这类错误，类型系统有助于判断

