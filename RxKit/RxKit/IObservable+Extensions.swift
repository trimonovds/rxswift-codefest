//
//  IObservable+Extensions.swift
//  RxKit
//
//  Created by Dmitry Trimonov on 09/03/2019.
//  Copyright © 2019 Dmitry Trimonov. All rights reserved.
//

import Foundation

extension IObservable {
    public func subscribe(onNext: ((Element) -> Void)? = nil, onError: ((Error) -> Void)? = nil, onComplete: (() -> Void)? = nil) -> Disposable {
        let blockObserver = BlockObserver<Element>(
            onNext: onNext ?? { _ in },
            onError: onError ?? { _ in },
            onComplete: onComplete ?? { }
        )
        return self.subscribe(blockObserver)
    }

    public func subscribe(on: @escaping (Event<Element>) -> Void) -> Disposable {
        let blockObserver = BlockObserver<Element>(eventHandler: on)
        return self.subscribe(blockObserver)
    }
}

class BlockObserver<T>: IObserver {
    typealias Element = T

    private let eventHandler: (Event<T>) -> Void

    init(eventHandler: @escaping (Event<T>) -> Void) {
        self.eventHandler = eventHandler
    }

    func on(_ event: Event<T>) {
        eventHandler(event)
    }
}

extension BlockObserver {
    convenience init(onNext: @escaping (T) -> Void, onError: @escaping (Error) -> Void, onComplete: @escaping () -> Void) {
        let eventHandler = { (event: Event<T>) -> Void in
            switch event {
            case .success(let value):
                onNext(value)
            case .error(let error):
                onError(error)
            case .completed:
                onComplete()
            }
        }
        self.init(eventHandler: eventHandler)
    }
}
