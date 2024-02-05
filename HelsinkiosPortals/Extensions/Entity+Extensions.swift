//
//  Entity+Extensions.swift
//  HelsinkiosPortals
//
//  Created by Matti Dahlbom on 5.2.2024.
//

import RealityKit

extension Entity {
    /// Returns all the entity's descendants recursively
    var descendants: [Entity] {
        return children.flatMap { [$0] + $0.descendants }
    }
}
