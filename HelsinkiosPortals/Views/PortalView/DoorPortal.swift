//
//  DoorPortal.swift
//  HelsinkiosPortals
//
//  Created by Matti Dahlbom on 3.2.2024.
//

import SwiftUI
import RealityKit
import RealityKitContent

class DoorPortal: Entity {
    static let objectName = "DoorPortal"
    
    private(set) var doorBoundingBox = BoundingBox()
    private(set) var doorOriginalOrientation = simd_quatf()
    
    required init() {
        super.init()

        self.name = DoorPortal.objectName
        
        // TODO add the portal behind the door
        
        let entity = try! Entity.load(named: "Door", in: realityKitContentBundle)
        let door = entity.children.first!
        doorOriginalOrientation = door.orientation

        // Extract the bounding box of the door
        let c = door.findEntity(named: "Door_Cube")!.components[ModelComponent.self]!
        doorBoundingBox = c.mesh.bounds
              
        // Reposition the child elements of the 'Door' group so that the door will open (rotate) using
        // the hinges side as pivot point instead of its center
        let halfDoorWidth = (doorBoundingBox.max.x - doorBoundingBox.min.x) / 2
        door.descendants.compactMap { $0 as? ModelEntity }.forEach {
            $0.position.x += halfDoorWidth
        }
        
        // Make the entity hit-testable by adding a collision + input target component
        door.generateCollisionShapes(recursive: true)
        door.components.set(InputTargetComponent())
        
        // Make the entity highlight on hover
        door.components.set(HoverEffectComponent())

        self.addChild(door)
    }
    
    func updateDoorRotation(angle: Float) {
        guard let door = findEntity(named: "Door") else {
            fatalError("Door not found")
        }

        print("updating Door to rotation: \(angle)")
        
        var transform = door.transform
        transform.rotation = self.doorOriginalOrientation * simd_quatf(angle: angle, axis: [0, 0, 1])
        door.move(to: transform, relativeTo: self, duration: 1.2, timingFunction: .easeInOut)
    }
}

