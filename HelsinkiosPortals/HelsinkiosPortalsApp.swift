//
//  HelsinkiosPortalsApp.swift
//  HelsinkiosPortals
//
//  Created by Matti Dahlbom on 2.2.2024.
//

import SwiftUI

@main
struct HelsinkiosPortalsApp: App {
    @State private var portalImmersionStyle: ImmersionStyle = .mixed
    
    var body: some Scene {
        ImmersiveSpace(id: "PortalView") {
            PortalView()
        }.immersionStyle(selection: $portalImmersionStyle, in: .mixed)
    }
}
