//
//  CollectionType+Find.swift
//  podverse
//
//  Created by Mitchell Downey on 9/26/15.
//  Copyright © 2015 Mitchell Downey. All rights reserved.
//

extension CollectionType {
    func find(@noescape predicate: (Self.Generator.Element) throws -> Bool) rethrows -> Self.Generator.Element? {
        return try indexOf(predicate).map({self[$0]})
    }
}