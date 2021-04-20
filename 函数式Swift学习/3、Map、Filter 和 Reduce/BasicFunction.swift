//
//  BasicFunction.swift
//  函数式Swift学习
//
//  Created by Ryan on 2021/1/26.
//

import Foundation

//MARK: - 泛型的介绍
/// 数组每个元素 + 1
func increment(array: [Int]) -> [Int] {
    var result: [Int] = []
    for x in array {
        result.append(x + 1)
    }
    return result
}

/// 数组的每个元素double
func double(array: [Int]) -> [Int] {
    var result: [Int] = []
    for x in array {
        result.append(x * 2)
    }
    return result
}

//MARK: 改进1 （抽象出transform模块）
/// 改进： 因为函数有大量相同代码，所以可以抽象出来
func compute(array: [Int], transform: (Int) -> Int) -> [Int] {
    var result: [Int] = []
    for x in array {
        result.append(transform(x))
    }
    return result
}

func double2(array: [Int]) -> [Int] {
    return compute(array: array) { $0 * 2 }
}

/// 如果是生成的String类型，Double类型,那么都得去重新定义，所以使用泛型来解决此问题, 因为它们的区别就是*类型签名*（type signature）
func isEven(array: [Int]) -> [Bool] {
//    return compute(array: array) { $0 % 2 == 0 })
    return []
}

//MARK: 改进2 （消解类型签名的不同，让输出变成泛型T）
func genericCompute<T>(array:[Int], transform:(Int) -> T) -> [T] {
    var result: [T] = []
    for x in array {
        result.append(transform(x))
    }
    return result
}

//MARK: 改进3 （将输入也变成泛型，更一般化）
func map<Element, T>(_ array: [Element], transform:(Element) -> T) -> [T] {
    var result: [T] = []
    for x in array {
        result.append(transform(x))
    }
    return result
}

/// 通过map来定义GenericCompute
func genericCompute2<T>(array: [Int], transform: (Int) -> T) -> [T] {
    return map(array, transform: transform)
}

//MARK: 更通用的做法，将其作为array的一个拓展方法
extension Array {
    func map<T>(_ transform: (Element) -> T) -> [T] {
        var result: [T] = []
        for x in self {
            result.append(transform(x))
        }
        return result
    }
}

func genericCompute3<T>(array:[Int], transform:(Int) -> T) -> [T] {
    return array.map(transform)
}

/**
  重点：其实map的定义并没有什么特别的魔法，其实自己就可以轻松地定义它
 */

//MARK: - 顶层函数和拓展
// 在swift2的诞生里，顶层函数就已经从标准库里删除了，但是增加了一个新的工具（protocol extensions）
// 建议遵守规则，并把处理确定类型的函数定义为该类型的拓展。优点：自动补全更完善 + 有歧义的命名少 + 代码结构清晰

//MARK: Filter
let exampleFiles = ["aaa.swift", "flyBird.md", "helloWorld.swift"]
func getSwiftFiles(in files: [String]) -> [String] {
    var result: [String] = []
    for file in files {
        if file.hasSuffix(".swift") {
            result.append(file)
        }
    }
    return result
}

extension Array {
    func filter(_ includeElement: (Element) -> Bool) -> [Element] {
        var result: [Element] = []
        for x in self where includeElement(x) {
            result.append(x)
        }
        return result
    }
}

func getSwiftFiles2(in files: [String]) -> [String] {
    return files.filter(){ $0.hasSuffix(".swift") }
}

//MARK: Reduce
/// 相加
func sum(integers: [Int]) -> Int {
    var result: Int = 0
    for x in integers {
        result += x
    }
    return result
}

let sumResult = sum(integers: [1, 2, 4, 5])

/// 相乘
func product(integers: [Int]) -> Int {
    var result: Int = 0
    for x in integers {
        result *= x
    }
    return result
}

// 连接字符串
func concatenate(strings: [String]) -> String {
    var result: String = ""
    for string in strings {
        result += string
    }
    return result
}

// 连接字符串: 添加首行，并且每一项都叠加换行符
func prettyPrint(setting: [String]) -> String {
    var result: String = "Entries in the arry xs /n"
    for string in setting {
        result = " " + result + string + "/n"
    }
    return result
}

extension Array {
    func reduce<T>(_ initial:T, combine:(T, Element) -> T) -> T {
        var result = initial
        for x in self {
            result = combine(result, x)
        }
        return result
    }
}

/// 具体使用：相加
func sumUsingReduce(integers: [Int]) -> Int {
    return integers.reduce(0) { result, x in result + x }
}

/// 具体使用：也可以直接使用运算符代表该含义
func productUsingReduce(integers: [Int]) -> Int {
    return integers.reduce(1, combine: *)
}

func productUsingReduce(strings: [String]) -> String {
    return strings.reduce("", combine: +)
}

/// 将二维数组转化为单一数组
func flatten<T>(_ xss: [[T]]) -> [T] {
    var result:[T] = []
    for x in xss {
        result += x
    }
    return result
}

func flattenUsingReduce<T>(_ xss: [[T]]) -> [T] {
    return xss.reduce([], combine: +)
}

// 更有甚者，我们可以直接使用reduce来定义map和filter
extension Array {
    func mapUsingReduce<T>(_ transform: (Element) -> T) -> [T] {
        return self.reduce([]) { result, x in result + [transform(x)] }
    }
    
    func mapUsingFilter(_ includeElement:(Element) -> Bool) -> [Element] {
        return self.reduce([]) { result, x in includeElement(x) ? result + [x] : result }
    }
}

//MARK: - Reduce的说明
/* Reduce 体现了一个常见的编程模式：计算数组并且计算结果
 
    实践中，如果使用reduce去实现filter或者map，其实并不是一个很好的idea，因为它会反复分配内存，以及复制大量内存中的内存。所以，比如使用可变数组来编写map的效率显然是更高的！
*/

//MARK: - 实际使用
struct City {
    let name: String
    let population: Int
}

let paris = City(name: "Paris", population: 2241)
let madrid = City(name: "Madrid", population: 3165)
let amsterdan = City(name: "Amsterdam", population: 827)
let berlin = City(name: "berlin", population: 3562)

let cities = [paris, madrid, amsterdan, berlin]

extension City {
    func scalePopulation() -> City {
        return City(name: name, population: population * 1000)
    }
}

// 1.先筛选
// 2.再map - 转换
// 4.最后再reduce 将数组映射为字符串
let city = cities
    .filter { $0.population > 1000 }
    .map { $0.scalePopulation() }
    .reduce("City:population") { (result, c) in
        return result + "\n" + "\(c.name):\(c.population)"
    }
    
//MARK: - 泛型和Any类型
// Swift还支持Any类型，它能代表任何类型的值。
// 区别很重要：泛型可以用于定义灵活的函数，但是类型检查依旧是由编译器来做
//           Any类型却可以避免swift的类型系统
func noOP<T>(_ x: T) -> T {
    return x
}

// 比如这里其实可以返回0, 任何调用Any的函数都不知道返回值会返回什么类型，结果就是运行时会造成大量的运行时错误。
func noOpAny(_ x: Any) -> Any {
    return x
}

/// 这个函数的类型具有通用性。在这里，B的类型是由f(A)决定的，C的类型时由g(B)决定的，也就是说函数的组合只有一种可能性！
infix operator >>>
func >>><A, B, C>(f: @escaping (A) -> B, g: @escaping (B) -> C) -> (A) -> C {
    return { x in g(f(x)) }
}

// 生成柯里化版本 【这个需要去理解】
func curry<A, B, C>(_ f:@escaping (A, B) -> C) -> (A) -> (B) -> C {
    return { x in { y in f(x, y) } }
}

//MARK: - 注释

