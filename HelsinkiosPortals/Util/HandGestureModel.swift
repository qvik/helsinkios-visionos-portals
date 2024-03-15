//
//  HandGestureModel.swift
//  HelsinkiosPortals
//
//  Created by Matti Dahlbom on 15.3.2024.
//

import ARKit

/**
 Provides information on recognized hand gestures.
 */
@MainActor
final class HandGestureModel: ObservableObject {
    let session = ARKitSession()
    var handTrackingProvider = HandTrackingProvider()
    
    private var leftHandGesturePosition: SIMD3<Float>? = nil
    private var rightHandGesturePosition: SIMD3<Float>? = nil
    
    @Published var handGesturePosition: SIMD3<Float>?
    
    // MARK: Public methods
    
    /// Starts tracking hand gestures
    func start() async {
        log.debug("Starting ARKit session..")
        do {
            if HandTrackingProvider.isSupported {
                try await session.run([handTrackingProvider])
            }
        } catch {
            log.error("Caught error while starting ARKit hand tracking session")
        }
    }
    
    /// Run event processing loop
    func processEvents() async {
        log.debug("Processing ARKit events..")
        for await event in session.events {
            switch event {
            case .authorizationChanged(let type, let status):
                if type == .handTracking && status != .allowed {
                    // Hand tracking no longer allowed
                    log.info("Hand tracking has been disallowed; stopping ARKitSession processing")
                    session.stop()
                    return
                }
            default:
                print("Session event \(event)")
            }
        }
    }
    
    /// Listen to updates from hand tracking system
    func listenToHandtrackingUpdates() async {
        log.debug("Listening to hand tracking updates..")
        for await update in handTrackingProvider.anchorUpdates {
            switch update.event {
            case .updated:
                if !update.anchor.isTracked {
                    continue
                }
                
                // We're not interested in chirality (which hand it is)
                detectGesture(handAnchor: update.anchor)
            default:
                break
            }
        }
    }
    
    // MARK: Private methods
    
    private func updateGestureActiveStatus() {
        handGesturePosition = leftHandGesturePosition ?? rightHandGesturePosition ?? nil
    }
    
    private func detectGesture(handAnchor: HandAnchor) {
        guard
            let wrist = handAnchor.handSkeleton?.joint(.wrist),
            let indexFingerTip = handAnchor.handSkeleton?.joint(.indexFingerTip),
            let middleFingerBase = handAnchor.handSkeleton?.joint(.middleFingerIntermediateBase),
            wrist.isTracked && indexFingerTip.isTracked && middleFingerBase.isTracked else {
            return
        }
        
        let middleFingerBaseWorldTransform = matrix_multiply(
            handAnchor.originFromAnchorTransform, middleFingerBase.anchorFromJointTransform
        )
        let middleFingerBaseWorldPosition = middleFingerBaseWorldTransform.position
        
        let wristWorldTransform = matrix_multiply(
            handAnchor.originFromAnchorTransform, wrist.anchorFromJointTransform
        )
        let wristWorldPosition = wristWorldTransform.position
        
        // Calculate the approximate hand location as middle point between wrist and middle finger base
        let handPosition = wristWorldPosition + ((middleFingerBaseWorldPosition - wristWorldPosition) * 0.5)
        
        // The coordinate systems are different depending on the hand. For example, when holding
        // the right hand flat, palm down, the "up" vector of the transform points World Up;
        // for left hand, it points to World Down.
        let chiralityModifier: Float = handAnchor.chirality == .left ? -1.0 : 1.0
        
        let wristWorldUpVector = wristWorldTransform.up * chiralityModifier
        
        // Our gesture is active for this hand if the hand is visible with its palm facing up
        let gestureActive = wristWorldUpVector.y < -0.8
        
        var handWorldPosition = gestureActive ? handPosition : nil
        
        switch handAnchor.chirality {
        case .left:
            leftHandGesturePosition = handWorldPosition
        case .right:
            rightHandGesturePosition = handWorldPosition
        }
        
        updateGestureActiveStatus()
    }
}
