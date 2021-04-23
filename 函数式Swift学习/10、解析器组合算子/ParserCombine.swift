//
//  ParserCombine.swift
//  函数式Swift学习
//
//  Created by Ryan on 2021/4/23.
//

import Foundation

//MARK: -
//MARK: - 解析器组合算子
// 这是一种函数式的解析方案
// 1、依旧是去思考如何创建一个函数类型
// 输入是字符串，输出呢？解析成功：结果 + 剩下字符串 ； 或者什么也不返回
//typealias Stream = String
//typealias Parser<Result> = (Stream) -> (Result, Stream)?
struct Parser<Result> {
    typealias Stream = Substring
    let parse:(Stream) -> (Result, Stream)?
}

func character(condition: @escaping (Character) -> Bool) -> Parser<Character> {
    return Parser { input in
        guard let char = input.first, condition(char) else { return nil }
        return (char, input.dropFirst())
    }
}


