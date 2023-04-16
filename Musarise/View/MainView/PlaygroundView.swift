//
//  PlaygroundView.swift
//  Musarise
//
//  Created by annaphens on 16/04/2023.
//

import SwiftUI

struct PlaygroundView: View {
    var body: some View {
        NavigationView {
            List {
                NavigationLink(
                    destination: GuitarView(),
                    label: {
                        Label("Guitar", systemImage: "guitars.fill")
                    })
                
                NavigationLink(
                    destination: DrumsView(),
                    label: {
                        Label("Drums", systemImage: "play")
                    })
                
                NavigationLink(
                    destination: PianoView(),
                    label: {
                        Label("Piano", systemImage: "pianokeys.inverse")
                    })
                
                NavigationLink(
                    destination: FreeView(),
                    label: {
                        Label("Free", systemImage: "square.grid.3x3.topleft.fill")
                    })
                
            }
            .navigationTitle("Music Instruments")
        }
    }
}

struct PlaygroundView_Previews: PreviewProvider {
    static var previews: some View {
        PlaygroundView()
    }
}
