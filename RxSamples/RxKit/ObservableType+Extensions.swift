//
//  ObservableType+Extensions.swift
//  RxSamples
//
//  Created by Dmitry Trimonov on 03/03/2019.
//  Copyright © 2019 Dmitry Trimonov. All rights reserved.
//

import Foundation
import RxSwift

extension ObservableType {

    public func duplicate() -> Observable<E> {
        return Duplicate(source: self.asObservable()).asObservable()
    }
}

final private class DuplicateSink<O: ObserverType>: ObserverType {
    typealias Element = O.E

    fileprivate let _observer: O

    init(observer: O) {
        self._observer = observer
    }

    func on(_ event: Event<Element>) {
        switch event {
        case .next(let value):
            self._observer.on(.next(value))
            self._observer.on(.next(value))
        case .completed, .error:
            self._observer.on(event)
        }
    }
}

final private class Duplicate<Element>: ObservableType {
    typealias E = Element

    private let _source: Observable<Element>

    init(source: Observable<Element>) {
        self._source = source
    }

    func subscribe<O>(_ observer: O) -> Disposable where O : ObserverType, Duplicate<Element>.E == O.E {
        let sink = DuplicateSink(observer: observer)
        let subscr = _source.subscribe(sink)
        return subscr
    }
}
