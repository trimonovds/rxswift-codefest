//
//  Debugging.swift
//  Utils
//
//  Created by Dmitry Trimonov on 18/03/2019.
//  Copyright © 2019 Dmitry Trimonov. All rights reserved.
//

import Foundation

public func currentTime() -> String {
    let timeString = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .long)
    return "[\(timeString)]"
}

public func log(_ message: String) {
    print("\(currentTime())\(message)")
}
