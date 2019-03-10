//
//  Create.swift
//  RxKit
//
//  Created by Dmitry Trimonov on 09/03/2019.
//  Copyright © 2019 Dmitry Trimonov. All rights reserved.
//

import Foundation

extension IObservable {

    /// Передаем такой subscribe, вместо: subscribe: @escaping (_ observer: O) -> Disposable потому, что
    /// передать в метод generic IObserver нельзя, соот-но нужно делать generic метод с конкретным O: IObserver,
    /// который будет отличаться от O в методе override func subscribe в нашем CreateObservable
    public static func create(subscribe: @escaping ((Event<Element>) -> Void) -> Disposable) -> Observable<Element> {
        return CreateObservable(subscribe: subscribe)
    }
}

class CreateObservable<T>: Observable<T> {
    private let subscribeHandler: ((Event<T>) -> Void) -> Disposable

    init(subscribe: @escaping ((Event<T>) -> Void) -> Disposable) {
        self.subscribeHandler = subscribe
    }

    override func subscribe<O>(_ observer: O) -> Disposable where T == O.Element, O: IObserver {
        return self.subscribeHandler(observer.on)
    }
}


