//
//  IteratorsAndSequences.swift
//  函数式Swift学习
//
//  Created by Ryan on 2021/4/22.
//

import Foundation

/*
 迭代器 以及 序列
 

 
 */

// 任何类型只要遵守 IteratorProtol 就是一个迭代器了

struct ReverseIndexIterator: IteratorProtocol {
    
    var index: Int
    
    init<T>(array: [T]) {
        index = array.endIndex - 1
    }
    
    mutating func next() -> Int? {
        guard index >= 0 else { return nil }
        
        // defer 在离开作用域之后执行，也就是说return之后还会执行
        defer { index -= 1 }
        return index
    }
}

struct PowerIterator: IteratorProtocol {
    var power: NSDecimalNumber = 1
    
    mutating func next() -> NSDecimalNumber? {
        power = power.multiplying(by: 2)
        return power
    }
    
    mutating func find(where predicate: (NSDecimalNumber) -> Bool) -> NSDecimalNumber? {
        while let x = next() {
            if predicate(x) {
                return x
            }
        }
        return nil
    }
}


/// 以上都是数字类型的迭代器，接下来我们来可以生成其他类型的迭代器，如字符串
struct FileLinesIterator: IteratorProtocol {
    let lines: [String]
    var currentLine: Int = 0
    
    init(filename: String) throws {
        let contents: String = try String(contentsOfFile: filename)
        lines = contents.components(separatedBy: .newlines)
    }
    
    mutating func next() -> String? {
        guard currentLine < lines.endIndex else { return nil }
        defer {
            currentLine += 1
        }
        return lines[currentLine]
    }
}

extension IteratorProtocol {
    mutating func find(predicate: (Element) -> Bool) -> Element? {
        while let x = next() {
            if predicate(x) {
                return x
            }
        }
        return nil
    }
}

/// 层级式的组合迭代器是可行的。如限制生成元素的个数，缓冲生成的值。
struct LimitIterator<l: IteratorProtocol>: IteratorProtocol {
    var limit = 0
    var iterator: l
    
    init(limit: Int, iterator: l) {
        self.limit = limit
        self.iterator = iterator
    }
    
    mutating func next() -> l.Element? {
        guard limit > 0 else { return nil }
        limit -= 1
        return iterator.next()
    }
}
//
//extension AnyIterator<Element>: IteratorProtocol {
//    typealias Element = Int
//
//    init(_ body: @escaping() -> Element?) {
//
//    }
//}


/// AnyIterator: 传入的其实就是一个next函数
func +<I: IteratorProtocol, J: IteratorProtocol>(first: I, second: @escaping @autoclosure() -> J) -> AnyIterator<I.Element> where I.Element == J.Element {
    var one = first
    
    var other: J? = nil
    
    return AnyIterator {
        if other != nil {
            return other!.next()
        } else if let result = one.next() {
            return result
        } else {
            other = second()
            return other!.next()
        }
    }
}

extension Int {
    func countDown() -> AnyIterator<Int> {
        var i = self - 1
        return AnyIterator{
            guard i >= 0 else { return nil }
            defer { i -= 1 }
            return i
        }
    }
}

//MARK: -
//MARK: - 序列
// “每一个序列都有一个关联的迭代器类型和一个创建新迭代器的方法。我们可以据此使用该迭代器来遍历序列”
// 迭代器的问题是什么？它只提供了“单次触发”的机制以反复地计算下一个元素。
// 通过Sequence封装迭代器，这和面向对象中的使用 + 创建进行分离的思想一脉相承的，代码因此具备了更高的内聚性。

struct ReverseArrayIndices<T>: Sequence {
    let array: [T]
    
    init(array: [T]) {
        self.array = array
    }
    
    func makeIterator() -> ReverseIndexIterator {
        return ReverseIndexIterator(array: array)
    }
}

//MARK: -
//MARK: - 延迟化序列
// 通过简短易懂的变换步骤组合起来，这段代码给出了一个数字数组，进行过滤之后，再将结果平方
// (1...10).filter{ $0 % 3 == 0 }.map { $0 * $0 }
// 注意：map以及filter 都只会生成一个数组而不是返回新的序列

//MARK: -
//MARK: - 延迟化序列
// 使用map和filter
// 命令式：执行起来快，因为只对序列进行了一次迭代，并且将过滤和映射合并为一步。同时数组result只被创建了一次
// 函数式：filter和map都被迭代了两次，还生成了一个过渡数组用于将filter的结果传递至map操作，效率不高
// 那么我们可以做什么操作呢？通过使用lazySequence，一次性计算
// let lazyResult = (1...10).lazy.filter { $0 % 3 == 0 }.map { $0 * $0 }


//MARK: -
//MARK: - 遍历二叉树
extension BinarySearchTree: Sequence {
    func makeIterator() -> AnyIterator<Element> {
        switch self {
        case .leaf:
            return AnyIterator {
                return nil
            }
        case let .node(l, element, r):
            return l.makeIterator() + CollectionOfOne(element).makeIterator() + r.makeIterator()
        }
    }
}

//MARK: -
//MARK: - 优化QuickCheck的范围收缩
protocol SmallerQ {
    func smallerQ() -> AnyIterator<Self>
}

extension Array: SmallerQ {
    func smallerQ() -> AnyIterator<Array<Element>> {
        var i = 0
        
        // 只要next存在就会一直递归下去！
        // 问题来了，它在哪里调用了next呢？？？
        return AnyIterator {
            guard i < self.endIndex else { return nil }
            
            var result = self
            result.remove(at: i)
            i += 1
            return result
        }
    }
}










