import SwiftUI

struct PlaygroundView: View {
    
    var body: some View {
        ZStack{
            NavigationView {
                VStack{
                    List {
                        NavigationLink(
                            destination: GuitarView(),
                            label: {
                                Text("🎸    Guitar")
                            })
                        
                        NavigationLink(
                            destination: DrumsView(),
                            label: {
                                Text("🥁    Drums")
                            })
                        
                        NavigationLink(
                            destination: PianoView(),
                            label: {
                                Text("🎹    Piano")
                            })
                        
                        NavigationLink(
                            destination:  VoiceView(),
                            label: {
                                Text("🎙    Voice")
                            })
                    }
                    .navigationTitle("Music Instruments")
                    .padding(.top, 20)
                }
                .background(Color.white)
            }
        }
    }
}

struct PlaygroundView_Previews: PreviewProvider {
    static var previews: some View {
        PlaygroundView()
    }
}
