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

    /// Enumerates every Entity in the hierarchy, including the root node.
    func enumerateHierarchy(_ callback: (Entity) -> Void) {
        callback(self)
        children.forEach { $0.enumerateHierarchy(callback) }
    }
    
    /// Enables ground shadow on all ModelEntities in the hierarchy.
    func enableGroundShadow() {
        enumerateHierarchy {
            if $0 is ModelEntity {
                $0.components.set(GroundingShadowComponent(castsShadow: true))
            }
        }
    }
}
