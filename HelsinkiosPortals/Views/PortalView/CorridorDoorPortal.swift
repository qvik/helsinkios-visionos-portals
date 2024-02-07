//
//  CorridorDoorPortal.swift
//  HelsinkiosPortals
//
//  Created by Matti Dahlbom on 6.2.2024.
//

import RealityKit
import RealityKitContent
import SwiftUI

/// Implements a door portal that displays a futuristic corridor in space
class CorridorDoorPortal: DoorPortal {
    override func createPortalWorld() -> Entity {
        let world = Entity()
        world.components[WorldComponent.self] = .init()
        
        let texture = try! TextureResource.load(named: "space_panorama")
        var material = UnlitMaterial()
        material.color = .init(texture: .init(texture))
        
        let skySphere = createSkySphere(material: material)
        
        world.addChild(skySphere)
        
        let entity = try! Entity.load(named: "Corridor", in: realityKitContentBundle)
        let corridor = entity.children.first!.children.first!

        corridor.orientation *= simd_quatf(angle: -Constants.deg90, axis: [1, 0, 0])
        corridor.position.y = -1.6

        // Get corridor's bounding box in world space
        let bounds = corridor.visualBounds(relativeTo: nil)
        let corridorLength = bounds.max.z - bounds.min.z
        let corridorWidth = bounds.max.x - bounds.min.x

        world.addChild(corridor)
        
        // Programmatically create a semitransparent floor for the corridor
        let floorPlane = Entity()
        var floorMaterial = PhysicallyBasedMaterial()
        let floorColor = UIColor.white
        floorMaterial.baseColor = .init(tint: floorColor)
        floorMaterial.roughness = .init(floatLiteral: 0.7)
        floorMaterial.metallic = .init(floatLiteral: 0.6)
        floorMaterial.specular = .init(floatLiteral: 0.2)
        floorMaterial.blending = .transparent(opacity: .init(floatLiteral: 0.2))

        floorPlane.components[ModelComponent.self] = .init(mesh: .generatePlane(width: corridorWidth,
                                                                                height: corridorLength,
                                                                                cornerRadius: 0),
                                                           materials: [floorMaterial])
        floorPlane.orientation *= simd_quatf(angle: -Constants.deg90, axis: [1, 0, 0])
        floorPlane.position.y = corridor.position.y
        floorPlane.position.z -= corridorLength / 2
        
        world.addChild(floorPlane)
        
        return world
    }

}

