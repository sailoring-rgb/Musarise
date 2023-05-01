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
                    destination: VoiceView(),
                    label: {
                        Label("Voice", systemImage: "music.mic")
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
