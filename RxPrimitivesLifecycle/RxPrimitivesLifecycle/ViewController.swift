//
//  ViewController.swift
//  RxPrimitivesLifecycle
//
//  Created by Dmitry Trimonov on 17/03/2019.
//  Copyright © 2019 Dmitry Trimonov. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class PrintObserver<T>: ObserverType {
    typealias E = T
    deinit { print("PrintObserver<\(T.self)> deallocated") }
    func on(_ event: Event<T>) { print("PrintObserver<\(T.self)> did receive: \(event)") }
}

class ViewController: UIViewController {
override func viewDidLoad() {
    super.viewDidLoad()

    // Try to send on(.completed) to BehaviorRelay
    Observable<Bool>.empty().bind(to: active)

    let printObserver = PrintObserver<Bool>()
    _ = active.subscribe(printObserver)
}
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        active.accept(true)
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        active.accept(false)
    }
    private let active = BehaviorRelay<Bool>(value: false)
}

//class ViewController: UIViewController {
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        Observable<Bool>.empty().bind(to: active)
//        let printObserver = PrintObserver<Bool>()
//        _ = active.subscribe(printObserver)
//
//    }
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        active.onNext(true)
//    }
//    override func viewDidDisappear(_ animated: Bool) {
//        super.viewDidDisappear(animated)
//        active.onNext(false)
//    }
//    private let active = BehaviorSubject<Bool>(value: false)
//}

