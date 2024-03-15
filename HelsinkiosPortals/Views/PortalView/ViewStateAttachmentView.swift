//
//  ViewStateAttachmentView.swift
//  HelsinkiosPortals
//
//  Created by Matti Dahlbom on 15.3.2024.
//

import SwiftUI

struct ViewStateAttachmentView: View {
    @Binding var viewState: PortalImmersiveView.ViewState
    
    var body: some View {
        VStack {
            Text("Select portal scene")
                .padding(20)
            
            HStack {
                Button("Doors") {
                    withAnimation(.smooth) {
                        viewState = .doors
                    }
                }
                .frame(width: 100)

                Button("Alley") {
                    withAnimation(.smooth) {
                        viewState = .alley
                    }
                }
                .frame(width: 100)
            }
        }
    }
}

#Preview(windowStyle: .automatic, body: {
    ViewStateAttachmentView(viewState: .constant(.doors))
        .previewLayout(.sizeThatFits)
})
