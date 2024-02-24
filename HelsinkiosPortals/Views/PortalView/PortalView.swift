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

            let landscapePortal = LandscapeDoorPortal()
            landscapePortal.orientation *= simd_quatf(angle: Constants.deg35, axis: [0, 1, 0])
            landscapePortal.position = [-1.7, doorYPosition, -1.5]
            content.add(landscapePortal)
            
            let corridorPortal = CorridorDoorPortal()
            corridorPortal.position = [-0.2, doorYPosition, -2.2]
            content.add(corridorPortal)

            let videoPortal = VideoDoorPortal()
            videoPortal.orientation *= simd_quatf(angle: -Constants.deg50, axis: [0, 1, 0])
            videoPortal.position = [1.4, doorYPosition, -1.6]
            content.add(videoPortal)

            let logo = createLogo()
            logo.position = [0.3, 2.2, -1.8]
            content.add(logo)
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
    
    private func createLogo() -> Entity {
        let logo = try! Entity.load(named: "HelsinkiOSPortalsLogo", in: realityKitContentBundle)
        logo.orientation *= simd_quatf(angle: Constants.deg90, axis: [1, 0, 0])
        return logo
    }
    
    /// Returns the DoorPortal entity that is the ancestor of the given entity, or nil if nit found.
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
