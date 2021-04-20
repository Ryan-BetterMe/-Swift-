//
//  AsyncTestViewController.swift
//  函数式Swift学习
//
//  Created by Ryan on 2021/3/18.
//

import Foundation
import UIKit
import PromiseKit

enum WebError: Error {
    case wrongURL
    case wrongParams
    case responseError
}

struct WebAPI {
    
    static func request(params: Dictionary<String, Any>, completion: @escaping (Result<Array<Any>>) -> Void) {
        guard let url = URL(string: "https://httpbin.org/post") else {
            completion(.error(WebError.wrongURL))
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: params, options: [])
            urlRequest.httpBody = jsonData
        } catch {
            completion(.error(WebError.wrongParams))
            return
        }
        
        URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            guard error == nil else {
                completion(.error(WebError.responseError))
                return
            }
            
            guard let data = data else {
                completion(.error(WebError.responseError))
                return
            }
            
            do {
                let resultDictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] ?? [:]
                
                guard let dataDictnary = resultDictionary["json"] as? [String: Any],
                      let roles = dataDictnary["roles"] as? Array<String> else {
                    completion(.error(WebError.responseError))
                    return
                }
                
                completion(.success(roles))
                return
            } catch {
                completion(.error(WebError.responseError))
                return
            }
        }.resume()
    }
    
    static func requestNaruto(completion: @escaping (Result<Array<Any>>) -> Void) {
        request(params: ["roles": ["鸣人", "佐助", "小樱", "我爱罗", "卡卡西"]], completion: completion)
    }
    
    static func requestOnePiece(completion: @escaping (Result<Array<Any>>) -> Void) {
        request(params: ["roles": ["路飞", "索隆", "乔巴", "娜美", "香吉士"]], completion: completion)
    }
}

// 解决一个同步请求的问题
class AsyncTestViewController: UIViewController {
    var tableView: UITableView!
    var statusLabel: UILabel!
    var sectionOne: [String] = []
    var sectionTwo: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addViews()
    }
    
    func addViews() {
        view.backgroundColor = .white
        
        let button = UIButton.init(type: .custom)
        button.backgroundColor = .brown
        button.setTitle("同步数据", for: .normal)
        button.frame = CGRect.init(x: 16, y: 44, width: 100, height: 44)
        view.addSubview(button)
        button.addTarget(self, action: #selector(syncDataFour), for: .touchUpInside)
        
        statusLabel = UILabel.init()
        statusLabel.textAlignment = .left
        statusLabel.text = "还未开始同步呢"
        statusLabel.frame = CGRect.init(x: 160, y: 44, width: UIScreen.main.bounds.size.width - 160, height: 44)
        view.addSubview(statusLabel)
        
        tableView = UITableView.init(frame: CGRect.init(x: 0, y: 100, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height - 100), style: .plain)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)
        
        // 一个关于tableview的故事
        // 调用reloadSections:withRowAnimation:方法时，UITableView会校验其他section，如果发现UITableView内记录的某section的row的数量和[dataSource tableView:numberOfRowsInSection]返回的不一致时，抛出NSInternalInconsistencyException异常。
    }
    
    // 需求是先请求a 再请求b
    // 问题：1、数据修改和UI修改耦合在一起 2、多重嵌套 3、对修改是闭合的，对拓展是开放的，如果拓展的话，肯定回去修改它 4、相当于是swift对oc的直接翻译，没有用处
    
    @objc func syncData() {
        self.statusLabel.text = "正在同步火影忍者数据"
        
        WebAPI.requestNaruto { (firstResult) in
            if case .success(let result) = firstResult {
                self.sectionOne = result.map { $0 as? String ?? "" }
                DispatchQueue.main.async {
                    self.tableView.reloadSections([0], with: .automatic)
                    
                    self.statusLabel.text = "正在同步海贼王数据"
                    WebAPI.requestOnePiece { (secondResult) in
                        if case Result.success(let result) = secondResult {
                            self.sectionTwo = result.map { $0 as? String ?? "" }
                            DispatchQueue.main.async {
                                self.statusLabel.text = "同步海贼王数据成功"
                                self.tableView.reloadSections([1], with: .automatic)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // 1.隔离UI逻辑
    func requestNaruto(completion:@escaping () -> Void) {
        WebAPI.requestNaruto { (result) in
            if case .success(let result) = result {
                self.sectionOne = result.map { $0 as? String ?? "" }
                
                completion()
            }
        }
    }
    
    func requestOnePiece(completion:@escaping () -> Void) {
        WebAPI.requestOnePiece { (result) in
            if case .success(let result) = result {
                self.sectionTwo = result.map { $0 as? String ?? "" }
                
                completion()
            }
        }
    }
    
    @objc func syncDataTwo() {
        self.statusLabel.text = "正在同步火影忍者数据"
        requestNaruto {
            DispatchQueue.main.async {
                self.tableView.reloadSections([0], with: .automatic)
                
                self.statusLabel.text = "正在同步海贼王数据"
                self.requestOnePiece {
                    DispatchQueue.main.async {
                        self.statusLabel.text = "同步数据成功"
                        self.tableView.reloadSections([1], with: .automatic)
                    }
                }
            }
        }
    }
    
    // 3、提取重复代码
    @objc func syncDataThere() {
        // 嵌套函数
        func updateStatus(text: String, reload: (isReload: Bool, section: Int)) {
            DispatchQueue.main.async {
                self.statusLabel.text = text
                if reload.isReload { self.tableView.reloadSections([reload.section], with: .automatic) }
            }
        }
        
        updateStatus(text: "正在同步火影忍者数据", reload: (false, 0))
        
        // (Request, Action) -> Request
        // (Request, Request) -> Request
        // (Request, Action) -> Action
        requestNaruto {
            updateStatus(text: "正在同步海贼王数据", reload: (true, 0))
            self.requestOnePiece {
                updateStatus(text: "同步数据成功", reload: (true, 1))
            }
        }
    }
    
    // 4、解开嵌套，把函数黏起来
    @objc func syncDataFour() {
        func updateStatus(text: String, reload: (isReload: Bool, section: Int)) {
            DispatchQueue.main.async {
                self.statusLabel.text = text
                if reload.isReload { self.tableView.reloadSections([reload.section], with: .automatic) }
            }
        }
        
        updateStatus(text: "正在同步火影忍者数据", reload: (false, 0))

        // 我们来拆解一下函数：要把函数抽象出来，这一点非常的重要
        // (Request, Action) -> Request
        // (Request, Request) -> Request
        // (Request, Action) -> Action
        // 通过这样的拆解方式就可以开始定义方法了
        let task: Action =
            requestNaruto
            ->> { updateStatus(text: "正在同步海贼王数据", reload: (true, 0)) }
            ->> requestOnePiece
            ->> { updateStatus(text: "同步数据成功", reload: (true, 1)) }
        task()
    }
    
    // 这里就提到经常会被使用的一个框架PromiseKit，RxSwift都可以用来处理异步编程，PromiseKit的zhen方法是不是就和这个类似呢？
}

// 左结合 且 中缀
infix operator ->>: AdditionPrecedence
typealias Action = () -> Void
typealias Request = (@escaping Action) -> Void

func ->>(lhs: @escaping Request, rhs: @escaping Action) -> Request {
    return { action -> Void in
        lhs { rhs(); action() }
    }
}

func ->>(lhs: @escaping Request, rhs: @escaping Action) -> Action {
    return {
        lhs { rhs() }
    }
}

func ->>(lhs: @escaping Request, rhs: @escaping Request) -> Request {
    return { action -> Void in
        lhs { rhs(action) }
    }
}

extension AsyncTestViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "火影忍者"
        }
        
        if section == 1 {
            return "海贼王"
        }
        
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 36
    }
}

extension AsyncTestViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return sectionOne.count
        case 1:
            return sectionTwo.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tableViewCell = tableView.dequeueReusableCell(withIdentifier: "cell") as! UITableViewCell
        
        switch indexPath.section {
        case 0:
            tableViewCell.textLabel?.text = sectionOne[indexPath.row]
        case 1:
            tableViewCell.textLabel?.text = sectionTwo[indexPath.row]
        default:
            break;
        }
        
        return tableViewCell
    }
}

