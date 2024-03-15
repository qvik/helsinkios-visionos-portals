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

struct PortalImmersiveView: View {
    enum ViewState {
        case doors, alley
    }
    
    private let logoEntityName = "portals_logo"
    private let viewStateAttachmentId = "view_state_attachment"
    
    @State private var landscapePortalState = DoorPortal.State.closed
    @State private var videoPortalState = DoorPortal.State.closed
    @State private var corridorPortalState = DoorPortal.State.closed
    
    @State private var viewState: ViewState = .doors

    @ObservedObject var handGestureModel: HandGestureModel

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
        ZStack {
            createDoorRealityView()
                .opacity(viewState == .doors ? 1.0 : 0.0)
            createAlleyRealityView()
                .opacity(viewState == .alley ? 1.0 : 0.0)
            createLogoRealityView()
        }
    }
    
    private let logoDoorsPosition: SIMD3<Float> = [0.3, 2.5, -1.8]
    private let logoAlleyPosition: SIMD3<Float> = [0.9, 2.5, -0.8]
    
    private func createLogoRealityView() -> some View {
        RealityView { content, attachments  in
            let logo = createLogo()
            logo.position = viewState == .doors ? logoDoorsPosition : logoAlleyPosition
            logo.enableGroundShadow()
            content.add(logo)
        } update: { content, attachments in
            if let logo = content.entities.first(where: { $0.name == logoEntityName }) {
                // Set logo position according to view state as the scenes are quite different
                let newPosition = viewState == .doors ? logoDoorsPosition : logoAlleyPosition
                logo.move(to: .init(translation: newPosition), relativeTo: nil, duration: 1.0, timingFunction: .easeInOut)
            }

#if targetEnvironment(simulator)
            // On simulator - with no way of generating the hand gesture - always show the
            // scene selection attachment in stationary position
            if let attachment = attachments.entity(for: viewStateAttachmentId) {
                attachment.position = [-0.1, 1, -1]
                content.add(attachment)
            }
#else
            // On device, show the scene selection attachment when hand gesture is active,
            // positioned slightly over the hand generating the gesture
            if let attachment = attachments.entity(for: viewStateAttachmentId),
               let handWorldPosition = handGestureModel.handGesturePosition {
                attachment.position = handWorldPosition
                attachment.position.y += 0.15
                content.add(attachment)
            }
#endif
        } attachments: {
            Attachment(id: viewStateAttachmentId) {
                ViewStateAttachmentView(viewState: $viewState)
                    .frame(width: 250, height: 150)
                    .glassBackgroundEffect()
#if !targetEnvironment(simulator)
                    .opacity(handGestureModel.handGesturePosition != nil ? 1.0 : 0.0)
#endif
            }
        }
        .task {
            await handGestureModel.start()
        }
        .task {
            await handGestureModel.processEvents()
        }
        .task {
            await handGestureModel.listenToHandtrackingUpdates()
        }
    }
    
    private func createDoorRealityView() -> some View {
        RealityView { content in
            let doorYPosition: Float = 1.04
            
            let landscapePortal = LandscapeDoorPortal()
            landscapePortal.orientation *= simd_quatf(angle: Constants.deg35, axis: [0, 1, 0])
            landscapePortal.position = [-1.7, doorYPosition, -1.5]
            landscapePortal.enableGroundShadow()
            content.add(landscapePortal)
            
            let corridorPortal = CorridorDoorPortal()
            corridorPortal.position = [-0.2, doorYPosition, -2.2]
            corridorPortal.enableGroundShadow()
            content.add(corridorPortal)
            
            let videoPortal = VideoDoorPortal()
            videoPortal.orientation *= simd_quatf(angle: -Constants.deg50, axis: [0, 1, 0])
            videoPortal.position = [1.4, doorYPosition, -1.6]
            videoPortal.enableGroundShadow()
            content.add(videoPortal)
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
    
    private func createAlleyRealityView() -> some View {
        RealityView { content in
            let alleyPortal = createAlleyPortal()
            alleyPortal.position = [0, 0, -1]
            content.add(alleyPortal)
        }
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
        
        logo.name = logoEntityName
        
        return logo
    }
    
    private func createAlleyPortal() -> Entity {
        let alleyPortal = try! Entity.load(named: "AlleyPortal", in: realityKitContentBundle)
        
        // Override the placeholder material on Occlusion_Cube with OcclusionMaterial
        // to hide geometry on the other side of the portal.
        let occlusionEntity = alleyPortal.findEntity(named: "Occlusion_Cube") as! ModelEntity
        occlusionEntity.model!.materials = [OcclusionMaterial()]

        return alleyPortal
    }

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
    PortalImmersiveView(handGestureModel: HandGestureModel())
}
