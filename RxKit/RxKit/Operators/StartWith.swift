//
//  StartWith.swift
//  RxKit
//
//  Created by Dmitry Trimonov on 16/03/2019.
//  Copyright © 2019 Dmitry Trimonov. All rights reserved.
//

import Foundation

extension IObservable {
    public func startWith(element: Element) -> Observable<Element> {
        return StartWithObservable<Element>(source: self.asObservable(), startElement: element)
    }
}

class StartWithObservable<T>: Observable<T> {

    private let source: Observable<T>
    private let startElement: T

    init(source: Observable<T>, startElement: T) {
        self.source = source
        self.startElement = startElement
    }

    override func subscribe<O>(_ observer: O) -> Disposable where T == O.Element, O : IObserver {
        return source.subscribe(StartWithObserver<T>(observer, startElement: startElement))
    }
}

class StartWithObserver<T>: Observer<T> {

    private let coreOn: (Event<T>) -> Void

    init<O>(_ observer: O, startElement: T) where O: IObserver, O.Element == T {
        self.coreOn = observer.on
        observer.on(Event<T>.next(startElement))
    }

    override func on(_ event: Event<T>) {
        switch event {
        case .next(let value):
            coreOn(.next(value))
        case .error(let error):
            coreOn(.error(error))
        case .completed:
            coreOn(.completed)
        }
    }
}
