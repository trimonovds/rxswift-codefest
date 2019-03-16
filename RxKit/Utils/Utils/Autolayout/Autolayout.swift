//
//  Autolayout.swift
//  Utils
//
//  Created by Dmitry Trimonov on 16/03/2019.
//  Copyright © 2019 Dmitry Trimonov. All rights reserved.
//

import UIKit

extension UIView {

    public func pinTo(layoutGuide: UILayoutGuide, withEdges edges: UIRectEdge) -> [NSLayoutConstraint] {
        var result = [NSLayoutConstraint]()
        if edges.contains(.left) {
            result.append(layoutGuide.leftAnchor.constraint(equalTo: self.leftAnchor))
        }
        if edges.contains(.top) {
            result.append(layoutGuide.topAnchor.constraint(equalTo: self.topAnchor))
        }
        if edges.contains(.right) {
            result.append(layoutGuide.rightAnchor.constraint(equalTo: self.rightAnchor))
        }
        if edges.contains(.bottom) {
            result.append(layoutGuide.bottomAnchor.constraint(equalTo: self.bottomAnchor))
        }
        return result
    }

    public func pinTo(view: UIView, withEdges edges: UIRectEdge) -> [NSLayoutConstraint] {
        var result = [NSLayoutConstraint]()
        if edges.contains(.left) {
            result.append(view.leftAnchor.constraint(equalTo: self.leftAnchor))
        }
        if edges.contains(.top) {
            result.append(view.topAnchor.constraint(equalTo: self.topAnchor))
        }
        if edges.contains(.right) {
            result.append(view.rightAnchor.constraint(equalTo: self.rightAnchor))
        }
        if edges.contains(.bottom) {
            result.append(view.bottomAnchor.constraint(equalTo: self.bottomAnchor))
        }
        return result
    }

    public func pinToParent() -> [NSLayoutConstraint] {
        guard let parent = superview else { assert(false); return [] }
        return self.pinTo(view: parent, withEdges: .all)
    }

    public func pinToParentSafe() -> [NSLayoutConstraint] {
        guard let parent = superview else { assert(false); return [] }
        let layoutGuide = parent.safeAreaLayoutGuide
        return self.pinTo(layoutGuide: layoutGuide, withEdges: .all)
    }

    public func pinToParent(withEdges edges: UIRectEdge) -> [NSLayoutConstraint] {
        guard let parent = superview else { assert(false); return [] }
        return self.pinTo(view: parent, withEdges: edges)
    }

    public func pinToParentSafe(withEdges edges: UIRectEdge) -> [NSLayoutConstraint] {
        guard let parent = superview else { assert(false); return [] }
        let layoutGuide = parent.safeAreaLayoutGuide
        return self.pinTo(layoutGuide: layoutGuide, withEdges: edges)
    }
}
