//
//  Observable.swift
//  RxKit
//
//  Created by Dmitry Trimonov on 09/03/2019.
//  Copyright © 2019 Dmitry Trimonov. All rights reserved.
//

import Foundation

open class Observable<T>: IObservable {
    public typealias Element = T

    public init() {
        
    }

    public func asObservable() -> Observable<T> {
        return self
    }

    open func subscribe<O>(_ observer: O) -> Disposable where O: IObserver, T == O.Element {
        fatalError("Implement in subclasses")
    }
}

class Observer<T>: IObserver {
    typealias Element = T

    func on(_ event: Event<T>) {
        fatalError("Implement in subclasses")
    }
}
