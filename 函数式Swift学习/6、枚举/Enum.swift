//
//  Enum.swift
//  函数式Swift学习
//
//  Created by Ryan on 2021/2/19.
//

import Foundation

//MARK: ========== 关联值 ==========
// 因为有时候不知道返回值的对或者错，所以可以选择返回一个result的枚举类型。
// result携带具体的结果或者错误 -》这里利用的是枚举的关联值的特性
enum LookupError: Error {
    case capitalNotFound
    case populationNotFound
}

enum PopulationResult {
    case success(Int)
    case error(LookupError)
}

let exampleSuccess: PopulationResult = .success(1000)

func populationOfCapital(country: String) -> PopulationResult {
    guard let capital = capitals[country] else {
        return .error(.capitalNotFound)
    }
    
    guard let population = aCities[capital] else {
        return .error(.populationNotFound)
    }
    
    return .success(population)
}
 
/* 接下来再调用该方法的结果中通过switcase语句来判断
     switch populationOfCapital(country: "France") {
     case let .success(population):
         print("France's capital has \(population) thousand inhabitants")
     case let .error(error):
         print("Error: \(error)")
     }
 */

//MARK: ========== 泛型 ==========
// 需求变化：写一个类似的函数，但是需要查询的是一个国家首都的市长
let mayors = ["Paris": "Hidalgo",
              "Madrid": "Carmena",
              "Amsterdam": "van der laan",
              "Berlin": "Muller"]
func mayorOfCapital(country: String) -> String? {
    return capitals[country].flatMap { mayors[$0] }
}

// 问题来了：可选值确实可以作为返回类型，可是你却不知道为什么会失败？
// 解决方案：通过复用PopulationResult来放回错误，可是没有和success相关联的Int值，虽然可以将字符串转化为Int，但是这并不是一个好的设计，所以要使用更加严密的类型

///方案一：使用String类型
enum MayorResult {
    case success(String)
    case fail(Error)
}

///方案二：使用泛型
enum Result<T> {
    case success(T)
    case error(Error)
}

func newPopulationOfCapital(country: String) -> Result<Int> {
    guard let capital = capitals[country] else {
        return .error(LookupError.capitalNotFound)
    }
    
    guard let population = aCities[capital] else {
        return .error(LookupError.populationNotFound)
    }
    
    return .success(population)
}

func newMayorOfCapital(country: String) -> Result<String> {
    guard let capital = capitals[country] else {
        return .error(LookupError.capitalNotFound)
    }
    
    guard let mayor = mayors[capital] else {
        return .error(LookupError.capitalNotFound)
    }
    
    return .success(mayor)
}

//MARK: ========== 再聊聊可选值 ==========
// 内建的可选值和Result类型很像，同时可选值也提供了一些语法糖，比如？或者？？
func ??<T>(result: Result<T>, handleError:(Error) -> T) -> T {
    switch result {
    case .success(let value):
        return value
    case .error(let error):
        return handleError(error)
    }
}

//MARK: ========== 数据结构中的代数学 ==========
// 使用枚举和结构体定义的类型有时候被称为代数数学类型，因为它们像自然数一样，具有代数学结构。
enum Zero {}
enum Left {
    case distance
    case duration
}
enum Right {
    case distance
    case duration
}

// 理解加法的含义，Add类型的枚举可以理解为两个类型的T，U的和
// 如果T有三个枚举值，U有七个枚举值，那么Add其实有10种值
enum Add<T, U> {
    case inLeft(T)
    case inRight(U)
}

// 什么是同构呢？直观的解释是两个类型在相互转换时不会丢失任何信息。
// 这里书籍讲得是有一些问题的，和实际上同构的概念是有一些区别的，其实重点是要明白枚举和结构体确实和自然数某些方面一样，可以进行一些运算。


//MARK: ========== 为什么要使用枚举？ ==========
/*
 1、可选值可能还是会比上文定义的Result类型更好用
 2、可以使用枚举类型去定义自己的类型去解决具体的需求，并不是说一定要使用Result来处理错误
 */
