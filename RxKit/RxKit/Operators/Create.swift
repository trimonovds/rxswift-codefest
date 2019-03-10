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
    public static func create(subscribe: @escaping (@escaping (Event<Element>) -> Void) -> Disposable) -> Observable<Element> {
        return CreateObservable(subscribe: subscribe)
    }
}

class CreateObservable<T>: Observable<T> {
    private let subscribeHandler: (@escaping (Event<T>) -> Void) -> Disposable

    init(subscribe: @escaping (@escaping (Event<T>) -> Void) -> Disposable) {
        self.subscribeHandler = subscribe
    }

    override func subscribe<O>(_ observer: O) -> Disposable where T == O.Element, O: IObserver {
        let createObserver = CreateObserver(observer)
        return self.subscribeHandler(createObserver.on)
    }
}

class CreateObserver<T>: Observer<T> {

    private let coreOn: (Event<T>) -> Void
    private var isStopped: Bool = false

    init<O>(_ observer: O) where O: IObserver, O.Element == T {
        self.coreOn = observer.on
    }

    override func on(_ event: Event<T>) {
        guard !isStopped else { return }
        switch event {
        case .next(let value):
            coreOn(.next(value))
        case .error(let error):
            coreOn(.error(error))
            isStopped = true
        case .completed:
            coreOn(.completed)
            isStopped = true
        }
    }
}


