//
//  PureSwiftDataStruct.swift
//  函数式Swift学习
//
//  Created by Ryan on 2021/2/26.
//

import Foundation

// 什么是纯函数式的数据结构？ 具有不变性的高效的数据结构！

//MARK: ========== 二叉搜索树 ==========
// 目的是创建一个库类似标准库中的Set来处理无序集合
// 会实现三种操作：
// 1. isEmpty - 检查一个无序集合是否为空
// 2. contains - 检查无序集合中是否包含某个元素
// 3. insert - 向无序集合中插入一个元素

// 第一反应是通过数组来实现
struct MySet<Element: Equatable> {
    var storage: [Element] = []
    var isEmpty: Bool {
        return storage.isEmpty
    }
    
    func contains(_ element: Element) -> Bool {
        return storage.contains(element)
    }
    
    func inserting(_ x: Element) -> MySet {
        return contains(x) ? self : MySet(storage: storage + [x])
    }
}

// 问题在于：大部分操作的性能是和无序集合的大小线性相关的。
// 解决方案：确保数组是经过排序的，然后使用二分查找来定位特定元素，或者直接定义二叉搜索树来表示无序集合，也可以使用indirect关键字，直接将二叉树定义为枚举
indirect enum BinarySearchTree<Element: Comparable> {
    case leaf
    case node(BinarySearchTree<Element>, Element, BinarySearchTree<Element>)
}

// 为什么不使用class呢？因为使用class的话用nil来表示空节点，或者表达空链表的话，这是会有歧义的，在算法的描述中是很致命的
// 而在Swift中可以使用嵌套enum来重新定义链表结构，这样的话，即使是空节点也是有意义的。
// 但是问题在于在值类型中嵌套自身是不可行的。因为如果没有indirection，对于引用自己的枚举类型来说，它有可能会无限大，因为它会一遍又一遍地包含自己，这是不合理的
// 所以使用indirect关键字其实就是告诉编译器插入需要的indirection层。

// 为什么呢？
// enum是值类型，由于Apple的策略，值类型的内存必须在编译期间就决定好，换言之，我得知道我们要在栈上分配多少内存。

let leaf: BinarySearchTree<Int> = .leaf
let five: BinarySearchTree<Int> = .node(leaf, 5, leaf)

extension BinarySearchTree {
    init() {
        self = .leaf // 默认为空节点
    }
    
    init(_ value: Element) {
        self = .node(.leaf, value, .leaf)
    }
}

// 计算树中存值的数
extension BinarySearchTree {
    var count: Int {
        switch self {
        case .leaf:
            return 0
        case let .node(left, _, right):
            return left.count + 1 + right.count
        }
    }
}

// 计算树中所有元素组成的数组
extension BinarySearchTree {
    var elements: [Element] {
        switch self {
        case .leaf:
            return []
        case let .node(left, x, right):
            return left.elements + [x] + right.elements
        }
    }
}

extension BinarySearchTree {
    /// 在node的情况下，它将递归地调用子节点，然后将结果与当前节点中的元素合并起来，这个被抽象出来的过程可以被称为fold或者reduce
    func reduce<A>(leaf leafF: A, node nodeF: (A, Element, A) -> A) -> A {
        switch self {
        case .leaf:
            return leafF
        case let .node(left, x, right):
            return nodeF(left.reduce(leaf: leafF, node: nodeF),
                         x,
                         right.reduce(leaf: leafF, node: nodeF))
        }
    }
    
    /// 那么我们就可以使用很少的代码来实现elements和count了
    var elementR: [Element] {
        return reduce(leaf: []) { $0 + [$1] + $2 }
    }
    
    var countR: Int {
        return reduce(leaf: 0) { $0 + 1 + $2 }
    }
}

/// 检查一个树是否为空
extension BinarySearchTree {
    var isEmpty: Bool {
        if case .leaf = self {
            return true
        } else {
            return false
        }
    }
}

// 由于编写为insert和contains无法使用其他特性，所以需要使用二叉搜索树的特性来提高其方法的性能
/*
 1、所有存储在左子树的值都小于其根节点的值
 2、所有存储在右子树的值都大于其根节点的值
 3、其左右子树都是二叉搜索树
 */

extension BinarySearchTree {
    /// 是否是平衡二叉树
    var isBST: Bool {
        switch self {
        case .leaf:
            return true
        case let .node(left, x, right):
            return left.elements.all { y in y < x}
                && right.elements.all { y in y < x }
                && left.isBST
                && right.isBST
        }
    }
}

extension Sequence {
    func all(predicate: (Iterator.Element) -> Bool) -> Bool {
        for x in self where !predicate(x) {
            return false
        }
        return true
    }
}

// 二叉搜索树的关键特性在于它的搞笑的查找，类始于在一个数组中找二分查找
extension BinarySearchTree {
    func contains(_ x: Element) -> Bool {
        switch self {
        case .leaf:
            return false
        case let .node(_, y, _) where x == y:
            return true
        case let .node(left, y, _) where x < y:
            return left.contains(x)
        case let .node(_, y, right) where x > y:
            return right.contains(x)
        default:
            fatalError("the impossiable occurred")
        }
    }
}

// 插入操作
extension BinarySearchTree {
    mutating func inset(_ x: Element) {
        switch self {
        case .leaf:
            self = BinarySearchTree.init(x)
        case .node(var left, let y, var right):
            if x < y { left.inset(x) }
            if x > y { right.inset(y) }
            self = .node(left, x, right)
        }
    }
}

/// 字典树: 如字符串的字典树 根节点为空，但是子节点都存储字符
struct Trie<Element: Hashable> {
    let isElement: Bool
    let children: [Element: Trie<Element>]
}

extension Trie {
    /// 初始化空字典
    init() {
        isElement = false
        children = [:]
    }
    
    // 将字典树flatten 为包含全部元素的数组
    // 如[[ca], [cat]...]]
    var elements: [[Element]] {
        var result: [[Element]] = isElement ? [[]] : []
        
        for (key, value) in children {
            result += value.elements.map { [key] + $0 }
        }
        
        return result
    }
}
