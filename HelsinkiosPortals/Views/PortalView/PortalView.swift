//
//  PortalView.swift
//  HelsinkiosPortals
//
//  Created by Matti Dahlbom on 2.2.2024.
//

import SwiftUI
import RealityKit
import AVKit

struct PortalView: View {
    var body: some View {
        RealityView { content in
            let staticWorld = makeStaticWorld()
            let staticPortal = makeStaticPortal(world: staticWorld)
            
            content.add(staticWorld)
            content.add(staticPortal)
            
            // TODO try using a "partial sphere" for the portal geometry
            
            let videoWorld = makeVideoWorld()
            let videoPortal = makeVideoPortal(world: videoWorld)
            
            content.add(videoWorld)
            content.add(videoPortal)
        }
    }

    private func createSkySphere(material: RealityKit.Material) -> Entity {
        // Create spherical geometry with an immense radius to act as our "skybox"
        let skySphere = Entity()
        skySphere.components.set(ModelComponent(mesh: .generateSphere(radius: 1E3), materials: [material]))
        
        // Trick to flip vertex normals on the generated geometry so we can display
        // our image / video on the inside of the sphere
        skySphere.scale = .init(x: 1, y: 1, z: -1)
        
        return skySphere
    }
    
    private func makeVideoWorld() -> Entity {
        let world = Entity()
        world.components[WorldComponent.self] = .init()
                
        let url = Bundle.main.url(forResource: "people_in_park", withExtension: "mov")!

        //create a simple AVPlayer
        let asset = AVURLAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        let player = AVPlayer()
        
        let material = VideoMaterial(avPlayer: player)
        
        let skySphere = createSkySphere(material: material)
        
        // Rotate the sky sphere to bring the people walking into view
        let rotationAngle = Float(Angle(degrees: -110).radians)
        skySphere.transform.rotation = .init(angle: rotationAngle, axis: .init(0.0, 1.0, 0.0))
        
        world.addChild(skySphere)
        
        // TODO loop the video
        player.replaceCurrentItem(with: playerItem)
        player.play()
        
        return world
    }

    private func makeVideoPortal(world: Entity) -> Entity {
        let portal = Entity()
        
        portal.components[ModelComponent.self] = .init(mesh: .generatePlane(width: 0.6,
                                                                            height: 0.6,
                                                                            cornerRadius: 0.02),
                                                       materials: [PortalMaterial()])
        portal.components[PortalComponent.self] = .init(target: world)
        
        portal.transform.translation = .init(-0.5, 1.0, -1.0)
        
        return portal
    }

    private func makeStaticWorld() -> Entity {
        let world = Entity()
        world.components[WorldComponent.self] = .init()

        let texture = try! TextureResource.load(named: "ocean_horn_environment")
        var material = UnlitMaterial()
        material.color = .init(texture: .init(texture))
        
        let skySphere = createSkySphere(material: material)

        world.addChild(skySphere)
        
        return world
    }
    
    private func makeStaticPortal(world: Entity) -> Entity {
        let portal = Entity()
        
        portal.components[ModelComponent.self] = .init(mesh: .generatePlane(width: 0.6,
                                                                            height: 0.6,
                                                                            cornerRadius: 0.02),
                                                       materials: [PortalMaterial()])
        portal.components[PortalComponent.self] = .init(target: world)
        
        portal.transform.translation = .init(0.5, 1.0, -1.0)
        
        return portal
    }
}

#Preview {
    PortalView()
}
