//
//  EventCell.swift
//  RxSamples
//
//  Created by Dmitry Trimonov on 21/03/2019.
//  Copyright © 2019 Dmitry Trimonov. All rights reserved.
//

import Foundation
import Utils

struct KudaGoEvent: Codable {
    var title: String
    var description: String
}

class KudaGoEventCell: BindableTableViewCell {
    typealias Model = KudaGoEvent

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(to model: KudaGoEvent) {
        self.textLabel?.text = model.title.uppercaseFirstLetterString()
        self.detailTextLabel?.attributedText = model.description.htmlToAttributedString
    }
}

extension String {
    var htmlToAttributedString: NSAttributedString? {
        guard let data = data(using: .utf8) else { return NSAttributedString() }
        do {
            return try NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding:String.Encoding.utf8.rawValue], documentAttributes: nil)
        } catch {
            return NSAttributedString()
        }
    }
    var htmlToString: String {
        return htmlToAttributedString?.string ?? ""
    }

    public func uppercaseFirstLetterString() -> String {
        if self.isEmpty {
            return self
        } else {
            return String(self.characters.prefix(1)).uppercased(with: Locale.current) + String(self.characters.suffix(count - 1))
        }
    }
}
