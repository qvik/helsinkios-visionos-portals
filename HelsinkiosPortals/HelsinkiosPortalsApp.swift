//
//  HelsinkiosPortalsApp.swift
//  HelsinkiosPortals
//
//  Created by Matti Dahlbom on 2.2.2024.
//

import SwiftUI
import OSLog

/// Global logger instance
let log = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "app")

@main
struct HelsinkiosPortalsApp: App {
    @State private var portalImmersionStyle: ImmersionStyle = .mixed
    
    var body: some Scene {
        ImmersiveSpace(id: "PortalView") {
            PortalView()
        }.immersionStyle(selection: $portalImmersionStyle, in: .mixed)
    }
}
