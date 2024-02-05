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
    enum State {
        case open, closed
    }
    
    private static let doorClosedAngle = Float(Angle(degrees: 0).radians)
    private static let doorOpenAngle = Float(Angle(degrees: 150).radians)
    
    private var doorBoundingBox = BoundingBox()
    private var doorOriginalOrientation = simd_quatf()
    private var doorScale = SIMD3<Float>()
    
    /// Returns the width of the door's geometry
    var doorWidth: Float {
        doorBoundingBox.max.x - doorBoundingBox.min.x
    }
    
    /// Returns the height of the door's geometry. The door's geometry is in the XZ plane, thats why z not y.
    var doorHeight: Float {
        doorBoundingBox.max.z - doorBoundingBox.min.z
    }

    /// Returns the width of the door (in world units)
    var worldDoorWidth: Float {
        doorWidth * doorScale.x
    }
    
    /// Returns the height of the door (in wodld units)
    var worldDoorHeight: Float {
        doorHeight * doorScale.z
    }

    required init() {
        super.init()

        self.name = String(describing: self)
        
        let entity = try! Entity.load(named: "Door", in: realityKitContentBundle)
        let door = entity.children.first!
        doorOriginalOrientation = door.orientation

        // Extract the bounding box of the door
        let c = door.findEntity(named: "Door_Cube")!.components[ModelComponent.self]!
        doorBoundingBox = c.mesh.bounds
        doorScale = door.scale
              
        // Reposition the child elements of the 'Door' group so that the door will open (rotate) using
        // the hinges side as pivot point instead of its center
        let halfDoorWidth = doorWidth / 2
        door.descendants.compactMap { $0 as? ModelEntity }.forEach {
            $0.position.x += halfDoorWidth
        }
        
        // Make the entity hit-testable by adding a collision + input target component
        door.generateCollisionShapes(recursive: true)
        door.components.set(InputTargetComponent())
        
        // Make the entity highlight on hover
        door.components.set(HoverEffectComponent())

        self.addChild(door)

        // Create a portal plane behind the door
        let portal = Entity()
        let world = createPortalWorld()
        
        portal.components[ModelComponent.self] = .init(mesh: .generatePlane(width: worldDoorWidth,
                                                                            height: worldDoorHeight,
                                                                            cornerRadius: 0),
                                                       materials: [PortalMaterial()])
        portal.components[PortalComponent.self] = .init(target: world)
        portal.position.x += worldDoorWidth / 2
        
        self.addChild(world)
        self.addChild(portal)
    }
    
    /// Creates a "sky sphere" with the given material
    func createSkySphere(material: RealityKit.Material) -> Entity {
        // Create spherical geometry with an immense radius to act as our "skybox"
        let skySphere = Entity()
        skySphere.components.set(ModelComponent(mesh: .generateSphere(radius: 1E3), materials: [material]))
        
        // Trick to flip vertex normals on the generated geometry so we can display
        // our image / video on the inside of the sphere
        skySphere.scale = .init(x: 1, y: 1, z: -1)
        
        return skySphere
    }
    
    /// Creates the portal world. Implemented by subclasses.
    func createPortalWorld() -> Entity {
        fatalError("not implemented")
    }
    
    func setState(state: State) {
        guard let door = findEntity(named: "Door") else {
            fatalError("Door not found")
        }
        
        let angle = state == .open ? DoorPortal.doorOpenAngle : DoorPortal.doorClosedAngle
        print("updating Door to rotation: \(angle)")
        
        var transform = door.transform
        transform.rotation = self.doorOriginalOrientation * simd_quatf(angle: angle, axis: [0, 0, 1])
        door.move(to: transform, relativeTo: self, duration: 1.2, timingFunction: .easeInOut)
    }
}

