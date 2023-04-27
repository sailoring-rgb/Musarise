import SwiftUI
import CoreMotion
import Firebase
import FirebaseFirestore
import AVKit

struct DrumsView: View {
    @State private var drums: [Drum] = []
    @State private var player: AVPlayer?
    @State private var showModal : Bool = false
    @State private var audioSelected : URL?
    
    var body: some View {
        VStack{
                Text("Choose the sound")
                    .font(.system(size: 40).bold())
                
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(drums) { drum in
                            VStack {
                                Text(drum.name)
                                    .font(.system(size: 15))
                                    .padding(10)
                                Button(action: {
                                    self.audioSelected = drum.soundURL
                                    showModal = true
                                    do{
                                        let playerItem:AVPlayerItem = AVPlayerItem(url: drum.soundURL)
                                        player = AVPlayer(playerItem: playerItem)
                                        player?.volume = 0.5
                                        player?.play()
                                    }
                                    catch{
                                        print("Error playing audio")
                                    }
                                }) {
                                    Image(systemName: "music.note")
                                        .font(.system(size: 40))
                                        .foregroundColor(.yellow)
                                }
                                .sheet(isPresented: $showModal){
                                    if let player = player, let audioSelected = audioSelected{
                                        PlayCard(player: player, audioURL: audioSelected)
                                    }
                                }
                            }
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(12)
                            .padding(10)
                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
        }
        .task {
            await fetchDrumsAudios()
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

struct DrumsView_Previews: PreviewProvider {
    static var previews: some View {
        DrumsView()
    }
}
