//
//  Map.swift
//  RxKit
//
//  Created by Dmitry Trimonov on 09/03/2019.
//  Copyright © 2019 Dmitry Trimonov. All rights reserved.
//

import Foundation

extension IObservable {
    public func map<R>(transform: @escaping (Element) -> R) -> Observable<R> {
        return MapObservable<Element, R>(source: self.asObservable(), transform: transform)
    }
}

class MapObservable<TFrom, TTo>: Observable<TTo> {

    private let source: Observable<TFrom>
    private let transform: (TFrom) -> TTo

    init(source: Observable<TFrom>, transform: @escaping (TFrom) -> TTo) {
        self.source = source
        self.transform = transform
    }

    override func subscribe<O>(_ observer: O) -> Disposable where TTo == O.Element, O: IObserver {
        return source.subscribe(MapObserver<TFrom, TTo>(observer, transform: transform))
    }
}

class MapObserver<TFrom, TTo>: Observer<TFrom> {

    private let coreOn: (Event<TTo>) -> Void
    private let transform: (TFrom) -> TTo

    init<O>(_ observer: O, transform: @escaping (TFrom) -> TTo) where O: IObserver, O.Element == TTo {
        self.coreOn = observer.on
        self.transform = transform
    }

    override func on(_ event: Event<TFrom>) {
        switch event {
        case .success(let value):
            let transformedValue = self.transform(value)
            coreOn(.success(transformedValue))
        case .error(let error):
            coreOn(.error(error))
        case .completed:
            coreOn(.completed)
        }
    }
}

