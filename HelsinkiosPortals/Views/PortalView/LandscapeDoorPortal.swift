//
//  LandscapeDoorPortal.swift
//  HelsinkiosPortals
//
//  Created by Matti Dahlbom on 5.2.2024.
//

import RealityKit

/// Implements a door portal that displays a world rendering a spherical projection 360 image
class LandscapeDoorPortal: DoorPortal {
    override func createPortalWorld() -> Entity {
        let world = Entity()
        world.components[WorldComponent.self] = .init()
        
        let texture = try! TextureResource.load(named: "ocean_horn_environment")
        var material = UnlitMaterial()
        material.color = .init(texture: .init(texture))
        
        let skySphere = createSkySphere(material: material)
        
        world.addChild(skySphere)
        
        addAudioEntity(soundResourceName: "ocean_waves.mp3", gain: -25)

        return world
    }
}
