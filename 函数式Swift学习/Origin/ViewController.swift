//
//  ViewController.swift
//  函数式Swift学习
//
//  Created by Ryan on 2021/1/21.
//

import UIKit
import CoreImage

/// 使用自定义运算符，在这里可以让代码更清晰易读

infix operator >>>: AdditionPrecedence // 让它继承+操作符的优先级, 左结合
func >>>(filter1: @escaping Filter, filter2: @escaping Filter) -> Filter {
    return { image in
        filter2(filter1(image))
    }
}

class ViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
//        imageView.image = draw01()
    }
    
    @IBAction func action(_ sender: UIButton) {
        iteratorTest()
    }
    
    func setupFilter(imageView: UIImageView) {
        guard let image = imageView.image?.cgImage else { return }
        let inputImage = CIImage(cgImage: image)
        
        let filter = sobel()
            >>> colorInvert()
            >>> colorControls(h: 97, s: 8, b: 85)
        
        let outputImage = filter(inputImage)
        imageView.image = UIImage(ciImage: outputImage)
        
    }
    
    func quickCheckTest() {
        check("Int类型满足乘法的交换律") { (x: Int) -> Bool in
            return x*1 == 1*x
        }
        
        check("Int类型满足加法的交换律") { (x: Int) -> Bool in
            return x - 1 == 1 - x
        }
        
        check("自定义的快排的结果和自带的sort的结果是一致的") { (x: [Int]) -> Bool in
            return qsort(x) == x.sorted()
        }
    }
    
    func devideError(a: Int) throws {
        if a == 0 {
            throw LookupError.capitalNotFound
        } else {
            let _ = 1 / a
        }
    }
    
    func trie() {
        let trie1 = Trie.init(isElement: true, children: ["c": Trie.init(isElement: true, children: [:]), "d": Trie.init(isElement: true, children: [:])])
        let trie2 = Trie.init(isElement: false, children: ["a": trie1, "b": Trie.init(isElement: true, children: [:])])
        print(trie2.elements)
        
        let contents = ["cat", "car", "cart", "dog"]
        let trieOfWords = Trie<Character>.build(words: contents)
        let a = "car".complete(trieOfWords)
        
        print(a)
    }
    
    func iteratorTest() {
        //        let letters = ["a", "b", "c"]
        //        var iterator = ReverseIndexIterator(array: letters)
        //        while let i = iterator.next() {
        //            print("\(i)  \(letters[i])")
        //        }
        
//                var iterator = PowerIterator.init()
//                let a = iterator.find(where: { $0.intValue > 1000 })
//                print(a)
        
        let a = [1, 2, 3].smallerQ()
        print(a)
    }
}
































































































































































































































































