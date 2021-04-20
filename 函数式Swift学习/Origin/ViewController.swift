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
    }
    
    @IBAction func action(_ sender: UIButton) {
        
        
        let trie1 = Trie.init(isElement: true, children: ["c": Trie.init(isElement: true, children: [:]), "d": Trie.init(isElement: true, children: [:])])
        let trie2 = Trie.init(isElement: false, children: ["a": trie1, "b": Trie.init(isElement: true, children: [:])])
        print(trie2.elements)
        
        print(trie2.loopup(key: ["a", "d"]))
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
}





































































































































































































































































