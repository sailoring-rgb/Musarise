import SwiftUI
import CoreMotion
import Firebase
import FirebaseFirestore
import AVKit

struct DrumsView: View {
    @State private var drums: [Drum] = []
    @State private var player: AVPlayer?
    @State private var showSelectModal : Bool = false
    @State private var audioSelected : URL?
    @State private var freeMode: Bool = false
    @State private var playersFreeMode: [Drum] = []
    @State private var showPlayCardModal: Bool = false
    
    var body: some View {
        ZStack {
            NavigationView{
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))],spacing: 20) {
                        ForEach(drums) { drum in
                            VStack {
                                Text(drum.name)
                                    .font(.system(size: 22))
                                    .padding(10)
                                    .foregroundColor(Color.black)
                                Image(systemName: "music.note")
                                    .font(.system(size: 40))
                                    .foregroundColor(.yellow)
                            }
                            .frame(width:140,height:140)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                            .gesture(TapGesture().onEnded{
                                self.audioSelected = drum.soundURL
                                withAnimation{
                                    self.showSelectModal = true
                                }
                                do {
                                    let playerItem: AVPlayerItem = AVPlayerItem(url: drum.soundURL)
                                    player = AVPlayer(playerItem: playerItem)
                                    player?.volume = 0.5
                                    player?.play()
                                } catch {
                                    print("Error playing audio")
                                }
                            })
                        }
                        
                        Button(action: {
                            withAnimation{
                                self.showPlayCardModal = true
                                self.freeMode = true
                            }
                        }){
                            Text("Choose free mode")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                        }
                        .frame(width:100, height: 100)
                        .background(Color.yellow)
                        .cornerRadius(10)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(30)
                }
                .navigationTitle("Choose sound")
            }
            .alert("There are 3 different drums in 3 different positions. Move your phone horizontally to play them.", isPresented: $freeMode, actions: {})
            .task {
                await fetchDrumsAudios()
            }

            if showSelectModal || showPlayCardModal{
                Color.black
                    .opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        self.showSelectModal = false
                        self.showPlayCardModal = false
                    }
                GeometryReader{geo in
                    if showSelectModal{
                        if let audioSelected = audioSelected{
                            SelectSoundView(
                                onClose: {
                                    self.showSelectModal = false
                                },
                                audioSelected: audioSelected
                            )
                            .frame(width: geo.size.width, height: geo.size.height)
                            .position(x: geo.size.width/2, y: geo.size.height/2)
                        }
                    }
                    else if showPlayCardModal{
                        if let audioSelected = audioSelected{
                            PlayCardView(
                                onClose: {
                                    self.showPlayCardModal = false
                                },
                                audioURL: audioSelected
                            )
                            .frame(width: geo.size.width, height: geo.size.height)
                            .position(x: geo.size.width/2, y: geo.size.height/2)
                        }
                    }
                }
            }
        }
    }
    
    func fetchDrumsAudios() async{
        do{
            var query: Query!
            query = Firestore.firestore().collection("Drums")
            let docs = try await query.getDocuments()
            let fetchedDrums = docs.documents.compactMap{ doc -> Drum? in
                try? doc.data(as: Drum.self)
            }
            
            await MainActor.run {
                drums.append(contentsOf: fetchedDrums)
            } 
        }
        catch {
            print(error.localizedDescription)
        }
    }
}
