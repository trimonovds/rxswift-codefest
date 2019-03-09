//
//  Filter.swift
//  RxKit
//
//  Created by Dmitry Trimonov on 09/03/2019.
//  Copyright © 2019 Dmitry Trimonov. All rights reserved.
//

import Foundation

extension IObservable {
    public func filter(predicate: @escaping (Element) -> Bool) -> Observable<Element> {
        return FilterObservable<Element>(source: self.asObservable(), predicate: predicate)
    }
}

class FilterObservable<T>: Observable<T> {

    private let source: Observable<T>
    private let predicate: (T) -> Bool

    init(source: Observable<T>, predicate: @escaping (T) -> Bool) {
        self.source = source
        self.predicate = predicate
    }

    override func subscribe<O>(_ observer: O) -> Disposable where T == O.Element, O : IObserver {
        return source.subscribe(FilterObserver<T>(observer, predicate: predicate))
    }
}

class FilterObserver<T>: Observer<T> {

    private let coreOn: (Event<T>) -> Void
    private let predicate: (T) -> Bool

    init<O>(_ observer: O, predicate: @escaping (T) -> Bool) where O: IObserver, O.Element == T {
        self.coreOn = observer.on
        self.predicate = predicate
    }

    override func on(_ event: Event<T>) {
        switch event {
        case .success(let value):
            if predicate(value) {
                coreOn(.success(value))
            }
        case .error(let error):
            coreOn(.error(error))
        case .completed:
            coreOn(.completed)
        }
    }
}
