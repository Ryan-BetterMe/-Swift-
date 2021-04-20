//
//  Battleship.swift
//  函数式Swift学习
//
//  Created by Ryan on 2021/1/21.
//

import Foundation

// 背景：如果使用面向对象的思维方式，在船舶射击游戏中需要考虑我方船只和敌方的距离，以及和友方的距离，那么这个时候，随之需求的增加就会发生如下的情况：

typealias Distance = Double

struct Position {
    var x: Double
    var y: Double
}

//MARK: -
//MARK: 假设当前船为原点，判断一个点是否在该原点范围之内
extension Position {
    func within(range: Distance) -> Bool {
        return sqrt(x*x + y*y) <= range
    }
}

//MARK: -
//MARK: 船有自己的位置，判断一个点是否在以它为圆心的某个范围之内
struct Ship {
    var position: Position
    var firingRange: Distance
    var unsafeRange: Distance
}

extension Ship {
    func canEngage(ship target: Ship) -> Bool {
        let dx = target.position.x - position.x
        let dy = target.position.y - position.y
        let targetDistance = sqrt(dx*dx + dy*dy)
        return targetDistance <= firingRange
    }
}

//MARK: -
//MARK: 船有自己的位置，判断一个点是否在以它为圆心的某个范围之内, 而且还需要避免目标船舶离我们过近
extension Ship {
    func canSafelyEngage(ship target: Ship) -> Bool {
        let dx = target.position.x - position.x
        let dy = target.position.y - position.y
        let targetDistance = sqrt(dx*dx + dy*dy)
        return targetDistance <= firingRange && targetDistance >= unsafeRange
    }
}

//MARK: -
//MARK: 添加需求，满足以上的同时，还需要避免敌方过于接近友方的船舶
extension Ship {
    func canSafelyEngage(ship target: Ship, friendly: Ship) -> Bool {
        let dx = target.position.x - position.x
        let dy = target.position.y - position.y
        let targetDistance = sqrt(dx*dx + dy*dy)
        
        let friendlyDx = target.position.x - friendly.position.x
        let friendlyDy = target.position.x - friendly.position.y
        let friendlyDistance = sqrt(friendlyDx*friendlyDx + friendlyDy*friendlyDy)
        return targetDistance <= firingRange && targetDistance > unsafeRange && friendlyDistance > unsafeRange
    }
}

//MARK: -
//MARK: 因为需求增加，代码变得复杂，所以可以添加辅助方法,同时原来复杂的方法变化如下
extension Position {
    func mimus(_ p: Position) -> Position {
        return Position(x: x-p.x, y: y-p.y)
    }
    var length: Double {
        return sqrt(x*x + y*y)
    }
}

extension Ship {
    func canSafelyEngage2(ship target: Ship, friendly: Ship) -> Bool {
        let targetDistance = target.position.mimus(position).length
        let friendlyDistance = target.position.mimus(position).length
        return targetDistance < firingRange && targetDistance > unsafeRange && friendlyDistance > unsafeRange
    }
}

//MARK: -
//MARK: 使用一等函数改造如下
/// 函数式编程有三个特点：模块化，对可变状态的谨慎处理，以及类型
/// 所以对待函数的类型时非常重要的，需要仔细考量

func pointInRange(position: Position) -> Bool {
    // 方法的具体实现: 就是判断某个点是否在一个range里
    return false
}

// 所以函数的类型为Range
// 这里并没有使用CheckInRegion这种表示函数类型的名字，而是使用了Region，因为函数式编程的核心就在于函数就是值！（和结构体，整型，布尔型没有差别）
// 既然函数是值，那就一定要理解这一层抽象，这里其实就是代表着区域！Region即是区域！理解了这一层，就勘破了基础。
typealias Region = (Position) -> Bool

/// 以原点为中心，position是否在范围之类
func circle(radius: Distance) -> Region {
    return { point in
        point.length <= radius
    }
}

let inCircle = circle(radius: 10)(Position(x: 5, y: 5))

/// 以任意center为中心，position是否在范围之内
func circle2(radius: Distance, center: Position) -> Region {
    return { point in
        point.mimus(center).length <= radius
    }
}

typealias Offset = Double
struct Vector {
    var dx: Offset
    var dy: Offset
}

let inCircle1 = circle2(radius: 10, center: Position(x: 0, y: 1))(Position(x: 8, y: 8))

/// 区域变换函数：将新点作为参数传递给Region闭包
/// ****
/// 函数式编程的核心：为了避免创造越来越复杂的函数，编写一个新的函数shift来改变另一个函数！
/// 值 ---------> 值
func shift(_ region: @escaping Region, by offset: Position) -> Region {
    return { point in region(point.mimus(offset)) } // 将每一个点都偏移了
}

// ------------------ 思维方式的转变 -------------
// 圆心为（5，5），半径为10的圆
let shifted = shift(circle(radius: 10), by: Position(x: 5, y: 5))

/// 反转区域：这个新产生的区域由原区域以外的所有点组成
func invert(_ region: @escaping Region) -> Region {
    return { point in
        !region(point)
    }
}

// 交集
func interect(_ region: @escaping Region, with other: @escaping Region) -> Region {
    return { point in region(point) && region(point) }
}

// 并集
func union(_ region: @escaping Region, with other: @escaping Region) -> Region {
    return { point in region(point) || other(point) }
}

// 差集
func subtract(_ region: @escaping Region, from original: @escaping Region) -> Region {
    return interect(original, with: invert(region))
}

//MARK:-
//MARK: 函数式的重构
extension Ship {
    func canSafelyEngageFP(ship target: Ship, friendly: Ship) -> Bool {
        let rangeRegion = subtract(circle(radius: unsafeRange), from: circle(radius: firingRange))
        let firingRange = shift(rangeRegion, by: position)
        
        let friendlyRange = shift(circle(radius: unsafeRange), by: friendly.position)
        let resultRange = subtract(friendlyRange, from: firingRange)
        return resultRange(target.position)
    }
}

/* 总结
 
 ## 类型驱动开发
 要选择适合的类型，这比其他的任何事情都重要。
 这里的例子中使用了region类型。
 
 
 ## 注解
 OC中引入了blocks来实现了对一等函数的支持，虽然语义上和swift中是一样的，但是它们并不像swift中那样一样方便。
 
 */
