//
//  RxKitTests.swift
//  RxKitTests
//
//  Created by Dmitry Trimonov on 03/03/2019.
//  Copyright © 2019 Dmitry Trimonov. All rights reserved.
//

import XCTest
import RxSwift
import RxTest
@testable import RxKit

class RxKitTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        let testScheduler = TestScheduler(initialClock: 0)
        let sourceArray = [1,2,3,4,6,12]
        let testObserver = testScheduler.start { () -> Observable<Int> in
            Observable<Int>
                .from(sourceArray)
                .duplicate()
        }

        let expected = (sourceArray.count * 2 + 1)
        XCTAssert(testObserver.events.count == expected)
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
