//
//  SimplifiedDrawerHidingBehavior.swift
//  RxSamples
//
//  Created by Dmitry Trimonov on 21/03/2019.
//  Copyright © 2019 Dmitry Trimonov. All rights reserved.
//

import Foundation
import RxSwift

// Режим автовращения - режим, в котором камера поворачивается так,
// чтобы направление движения пользователя всегда было "вверх" экрана

/// Нужно закрывать шторку при возникновении одного из 2-х событий
/// 1. Скорость пользователя стала выше 2.5 м/с при включенном режиме автовращения
/// 2. Был включен режим автовращения при скорости выше 2.5 м/с
struct SimpleDrawerHidingStrategy: DrawerHidingStrategy {
    func hideEvents(didChangeAutoRotationMode: Observable<Bool>, didUpdateSpeed: Observable<Double>) -> Observable<Void> {
        let speedIsAboveThreshold = didUpdateSpeed.map { $0 > 2.5 }.distinctUntilChanged()
        let autoRotationIsOn = didChangeAutoRotationMode.distinctUntilChanged()
        return Observable.combineLatest(speedIsAboveThreshold, autoRotationIsOn).filter { $0.0 && $0.1 }.mapTo(())
    }
}


/// Аналогичные требования, но нужно удостовериться, что превышение порога скорости - не случайное событие
/// - ошибка или секундное явление
/// 1. Скорость пользователя стала выше 2.5 м/с при включенном режиме автовращения и продержалась
///    на этом уровне (> 2.5 м/с) 5 секунд при этом режим автовращения не был выключен за эти 5 секунд
/// 2. Был включен режим автовращения при скорости выше 2.5 м/с
struct SmartDrawerHidingStrategy: DrawerHidingStrategy {
    init(timerScheduler: SchedulerType) {
        self.timerScheduler = timerScheduler
    }

    func hideEvents(didChangeAutoRotationMode: Observable<Bool>, didUpdateSpeed: Observable<Double>) -> Observable<Void> {
        let autoRotationIsOn = didChangeAutoRotationMode.distinctUntilChanged()
        let autoRotationDidTurnOn = autoRotationIsOn.filter { $0 }.mapTo(())
        let autoRotationDidTurnOff = autoRotationIsOn.filter { !$0 }.mapTo(())

        let speedIsAboveThreshold = didUpdateSpeed.map { $0 > 2.5 }.distinctUntilChanged()
        let speedDidExceedThreshold = speedIsAboveThreshold.filter { $0 }.mapTo(())
        let speedDidFallBelowThreshold = speedIsAboveThreshold.filter { !$0 }.mapTo(())

        let speedDidExceedThresholdWhileAutorotationIsOn = speedDidExceedThreshold
            .withLatestFrom(autoRotationIsOn)
            .filter { $0 }
            .mapTo(())

        let timerFor5Sec = Observable<Int>.timer(5.0, period: nil, scheduler: timerScheduler).mapTo(())
        let timeShouldStop = Observable<Void>.merge(autoRotationDidTurnOff, speedDidFallBelowThreshold)
        let speedConditionDidSucceed = speedDidExceedThresholdWhileAutorotationIsOn
            .flatMapLatest { _ -> Observable<Void> in
                return timerFor5Sec.takeUntil(timeShouldStop)
            }

        let autoRotationConditionDidSucceed = autoRotationDidTurnOn
            .withLatestFrom(speedIsAboveThreshold)
            .filter { $0 }
            .mapTo(())

        return Observable.merge(autoRotationConditionDidSucceed, speedConditionDidSucceed)
    }

    private let timerScheduler: SchedulerType
}

extension ObservableType {
    func mapTo<T>(_ t: T) -> Observable<T> {
        return self.map { _ in t }
    }
}
