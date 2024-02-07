//
//  VideoDoorPortal.swift
//  HelsinkiosPortals
//
//  Created by Matti Dahlbom on 5.2.2024.
//

import RealityKit
import SwiftUI
import AVKit

/// Implements a door portal that displays world rendering a 360 video 
class VideoDoorPortal: DoorPortal {
    
    override func createPortalWorld() -> Entity {
        let world = Entity()
        world.components[WorldComponent.self] = .init()
        
        let url = Bundle.main.url(forResource: "people_in_park", withExtension: "mov")!
        
        let asset = AVURLAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        let player = AVPlayer()
        
        let material = VideoMaterial(avPlayer: player)
        
        let skySphere = createSkySphere(material: material)
        
        // Rotate the sky sphere to bring the people walking into view
        let rotationAngle = Float(Angle(degrees: -130).radians)
        skySphere.transform.rotation = .init(angle: rotationAngle, axis: .init(0.0, 1.0, 0.0))
        
        world.addChild(skySphere)
        
        player.replaceCurrentItem(with: playerItem)
        player.play()

        // Loop the video
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: nil) { notif in
            player.seek(to: .zero)
            player.play()
        }
        
        // For bird sounds from the park, create an audio source on top of the portal, directed
        // downwards to create a positional audio field in front of the portal.
        let audioSource = Entity()
        audioSource.spatialAudio = SpatialAudioComponent(gain: -10, reverbLevel: -.infinity, directivity: .beam(focus: 1.0))
        addChild(audioSource)
        audioSource.setPosition([0.2, 0.5, 0.1], relativeTo: self)
        audioSource.look(at: [0, -1, 0], from: audioSource.position(relativeTo: nil), relativeTo: nil)

        let birdAudio = try! AudioFileResource.load(named: "bird_sounds.mp3", configuration: .init(shouldLoop: true, shouldRandomizeStartTime: true))
        audioSource.playAudio(birdAudio)
        
        return world
    }
}

