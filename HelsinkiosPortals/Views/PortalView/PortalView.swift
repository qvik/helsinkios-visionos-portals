//
//  PortalView.swift
//  HelsinkiosPortals
//
//  Created by Matti Dahlbom on 2.2.2024.
//

import RealityKit
import SwiftUI
import AVKit

struct PortalView: View {
    @State private var landscapePortalState = DoorPortal.State.closed
    @State private var videoPortalState = DoorPortal.State.closed

    var tap: some Gesture {
        SpatialTapGesture()
            .targetedToAnyEntity()
            .onEnded { value in
                guard let doorPortal = findDoorPortalAncestor(for: value.entity) else {
                    print("Something else than a door tapped")
                    return
                }

                switch doorPortal {
                case is LandscapeDoorPortal:
                    landscapePortalState = landscapePortalState == .open ? .closed : .open
                case is VideoDoorPortal:
                    videoPortalState = videoPortalState == .open ? .closed : .open
                default:
                    fatalError("unknown DoorPortal type")
                }
            }
    }
    
    var body: some View {
        RealityView { content in
            let landscapePortal = LandscapeDoorPortal()
            landscapePortal.transform.translation = .init(-0.9, 1.0, -1.2)
            landscapePortal.orientation *= simd_quatf(angle: Constants.deg20, axis: [0, 1, 0])
            content.add(landscapePortal)
            
            let videoPortal = VideoDoorPortal()
            videoPortal.transform.translation = .init(0.4, 1.0, -1.2)
            videoPortal.orientation *= simd_quatf(angle: -Constants.deg20, axis: [0, 1, 0])
            content.add(videoPortal)
            
            // TODO add the floating 3D logo
            
        } update: { content in
            if let landscapeDoorPortal = content.entities.first(where: { $0 is LandscapeDoorPortal }) as? DoorPortal {
                landscapeDoorPortal.setState(state: landscapePortalState)
            }
            
            if let videoDoorPortal = content.entities.first(where: { $0 is VideoDoorPortal }) as? DoorPortal {
                videoDoorPortal.setState(state: videoPortalState)
            }
        }
        .gesture(tap)
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
