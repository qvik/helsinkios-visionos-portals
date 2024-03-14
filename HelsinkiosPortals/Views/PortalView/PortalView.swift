//
//  PortalView.swift
//  HelsinkiosPortals
//
//  Created by Matti Dahlbom on 2.2.2024.
//

import RealityKit
import RealityKitContent
import SwiftUI
import AVKit

struct PortalView: View {
    @State private var landscapePortalState = DoorPortal.State.closed
    @State private var videoPortalState = DoorPortal.State.closed
    @State private var corridorPortalState = DoorPortal.State.closed

    var tap: some Gesture {
        SpatialTapGesture()
            .targetedToAnyEntity()
            .onEnded { value in
                guard let doorPortal = findDoorPortalAncestor(for: value.entity) else {
                    log.error("Something else than a door tapped")
                    return
                }

                switch doorPortal {
                case is LandscapeDoorPortal:
                    log.debug("landscape portal tapped")
                    landscapePortalState = landscapePortalState == .open ? .closed : .open
                case is VideoDoorPortal:
                    log.debug("video portal tapped")
                    videoPortalState = videoPortalState == .open ? .closed : .open
                case is CorridorDoorPortal:
                    log.debug("corridor portal tapped")
                    corridorPortalState = corridorPortalState == .open ? .closed : .open
                default:
                    fatalError("unknown DoorPortal type")
                }
                
                doorPortal.playSound()
            }
    }
    
    var body: some View {
        RealityView { content in
            let doorYPosition: Float = 1.04

//            let landscapePortal = LandscapeDoorPortal()
//            landscapePortal.orientation *= simd_quatf(angle: Constants.deg35, axis: [0, 1, 0])
//            landscapePortal.position = [-1.7, doorYPosition, -1.5]
//            landscapePortal.enableGroundShadow()
//            content.add(landscapePortal)
//            
//            let corridorPortal = CorridorDoorPortal()
//            corridorPortal.position = [-0.2, doorYPosition, -2.2]
//            corridorPortal.enableGroundShadow()
//            content.add(corridorPortal)
//
//            let videoPortal = VideoDoorPortal()
//            videoPortal.orientation *= simd_quatf(angle: -Constants.deg50, axis: [0, 1, 0])
//            videoPortal.position = [1.4, doorYPosition, -1.6]
//            videoPortal.enableGroundShadow()
//            content.add(videoPortal)
//
//            let logo = createLogo()
//            logo.position = [0.3, 2.5, -1.8]
//            logo.enableGroundShadow()
//            content.add(logo)
//            
//            let windowPortal = createWindowPortal()
//            windowPortal.position = [0.0, 1.2, -1]
//            content.add(windowPortal)
            let alleyPortal = createAlleyPortal()
            alleyPortal.position = [0, 0, -1]
            content.add(alleyPortal)
        } update: { content in
            if let landscapeDoorPortal = content.entities.first(where: { $0 is LandscapeDoorPortal }) as? DoorPortal {
                landscapeDoorPortal.setState(state: landscapePortalState)
            }
            
            if let videoDoorPortal = content.entities.first(where: { $0 is VideoDoorPortal }) as? DoorPortal {
                videoDoorPortal.setState(state: videoPortalState)
            }
            
            if let corridorDoorPortal = content.entities.first(where: { $0 is CorridorDoorPortal }) as? DoorPortal {
                corridorDoorPortal.setState(state: corridorPortalState)
            }
        }
        .gesture(tap)
    }
    
    private func createLogoParticleSystem() -> ParticleEmitterComponent {
        var particles = ParticleEmitterComponent()
        
        particles.timing = .repeating(warmUp: 0.5, emit: ParticleEmitterComponent.Timing.VariableDuration(duration: 1.0))

        particles.emitterShape = .plane
        particles.birthLocation = .surface
        particles.emitterShapeSize = [1.2, 0.4, 0.2]
        particles.birthDirection = .world
        particles.emissionDirection = [0.0, -1.0, 0.0]
        particles.speed = 0.15
        particles.speedVariation = 0.12
        particles.spawnVelocityFactor = 0.5
        
        particles.mainEmitter.color = .evolving(start: .single(.blue), end: .single(.white))
        particles.mainEmitter.blendMode = .additive
        particles.mainEmitter.birthRate = 500
        particles.mainEmitter.birthRateVariation = 100
        particles.mainEmitter.size = 0.005
        particles.mainEmitter.lifeSpan = 1.5
        particles.mainEmitter.lifeSpanVariation = 0.75
        particles.mainEmitter.spreadingAngle = 0.7
        particles.mainEmitter.dampingFactor = 0.6
        
        return particles
    }

    private func createLogo() -> Entity {
        let logo = try! Entity.load(named: "Portals_logo", in: realityKitContentBundle)
        logo.orientation *= simd_quatf(angle: Constants.deg90, axis: [1, 0, 0])
        let scale: Float = 0.5
        logo.scale = [scale, scale, scale]
        
        // Create new child entity to the "Portals" logo to hold the particly system
        let portalsLogo = logo.findEntity(named: "Portals")!
        let particleEntity = Entity()
        particleEntity.position = [1.12, -0.05, 0.0]
        particleEntity.components.set(createLogoParticleSystem())
        portalsLogo.addChild(particleEntity)
        
        return logo
    }
    
    private func createAlleyPortal() -> Entity {
        let alleyPortal = try! Entity.load(named: "AlleyPortal", in: realityKitContentBundle)
        
        // Override the placeholder material on Occlusion_Cube with OcclusionMaterial
        // to hide geometry on the other side of the portal.
        let occlusionEntity = alleyPortal.findEntity(named: "Occlusion_Cube") as! ModelEntity
        let occlusionMaterial = OcclusionMaterial()
        occlusionEntity.model!.materials = [occlusionMaterial]

        return alleyPortal
    }

    /// Creates an ImageBasedLightComponent from a single-color source image. This can be
    /// used to override default scene lighting.
//    private func createIBLComponent() -> ImageBasedLightComponent {
//        // Create a CGImage filled with color
//        let size = CGSize(width: 200, height: 100)
//        UIGraphicsBeginImageContextWithOptions(size, true, 0.0)
//        let context = UIGraphicsGetCurrentContext()!
//        context.setFillColor(UIColor.white.cgColor)
//        context.fill(CGRect(origin: .zero, size: size))
//        let cgImage = context.makeImage()!
//        UIGraphicsEndImageContext()
//        
//        // Create the IBL component out of the image
//        let resource = try! EnvironmentResource.generate(fromEquirectangular: cgImage)
//        let iblComponent = ImageBasedLightComponent(source: .single(resource), intensityExponent: 10.0)
//        
//        return iblComponent
//    }

    /// Returns the DoorPortal entity that is the ancestor of the given entity, or nil if not found.
    private func findDoorPortalAncestor(for entity: Entity) -> DoorPortal? {
        guard let parent = entity.parent else {
            return nil
        }
        
        if let doorPortal = parent as? DoorPortal {
            return doorPortal
        }
        
        return findDoorPortalAncestor(for: parent)
    }
}

#Preview {
    PortalView()
}
