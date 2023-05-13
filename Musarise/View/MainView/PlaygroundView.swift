import SwiftUI
import SDWebImageSwiftUI

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
                    Text("Musarise brings the entire musical environment to you! Your movements are converted into sounds and your ideas are transformed into reality.").font(.system(size:fontSize() + 5.5)).padding(.leading,10).padding(.top,10).padding(.trailing,10)
                    WebImage(url:URL(string:"https://firebasestorage.googleapis.com/v0/b/csound-967d4.appspot.com/o/General%2Fbanda.png?alt=media&token=33271b06-e62f-4319-af17-9e76b0ca46f0"))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaledToFit()
                        .scaleEffect(0.93)
                        .clipped()
                        .padding(.bottom,10)
                    
                    .navigationTitle("Music Instruments")
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
