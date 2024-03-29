import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseStorage
import AVKit

struct GarageView: View {
    @State private var sounds: [PlaygroundSound] = []
    @AppStorage("user_UID") var userUID: String = ""
    @State private var player: AVPlayer?
    @State private var isPlaying: Bool = false
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
    @State private var showTrash: Bool = false
    @State private var selectedSound: PlaygroundSound?
    
    var body: some View {
        NavigationView{
            ScrollView {
                LazyVGrid(columns: [GridItem()],spacing: 35) {
                    ForEach(sounds) { sound in
                        VStack(alignment: .leading) {
                            HStack{
                                Text(sound.instrumentIcon+" "+sound.instrumentName)
                                    .font(.system(size: fontSize() + 7.0))
                                    .foregroundColor(Color.black)
                                    .bold()
                                    .padding(.horizontal, 10)
                                    .padding(.top,10)
                                
                                Button(action: {
                                    if isPlaying {
                                        self.player?.pause()
                                        self.isPlaying = false
                                    } else {
                                        selectedSound = sound
                                        self.isPlaying = true
                                        do {
                                            let playerItem: AVPlayerItem = AVPlayerItem(url: sound.soundURL)
                                            self.player = AVPlayer(playerItem: playerItem)
                                            self.player?.volume = 1
                                            self.player?.play()
                                        } catch {
                                            print("Error playing audio")
                                        }
                                    }
                                }){
                                    Image(systemName: selectedSound?.soundURL == sound.soundURL && isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(.white)
                                        .colorMultiply(.yellow)
                                        .hAlign(.trailing)
                                        .padding(.top,5)
                                        .padding(.horizontal, 10)
                                }
                            }
                            Text(sound.soundTitle)
                                .font(.system(size: fontSize() + 7.0))
                                .foregroundColor(Color.black)
                                .bold()
                                .padding(.horizontal, 10)
                                .padding(.top,5)
                            Text(sound.publishedDate.formatted(date: .numeric, time: .shortened))
                                .font(.system(size: fontSize() + 2.0))
                                .foregroundColor(Color.gray)
                                .padding(.horizontal, 10)
                                .padding(.top,-2)
                            Text(sound.soundDescription)
                                .font(.system(size: fontSize() + 7.0))
                                .foregroundColor(Color.black)
                                .padding(.horizontal, 10)
                                .padding(.top,10)
                            Button(action: {
                                self.selectedSound = sound
                                if let selectedSound = self.selectedSound{
                                    deleteSound(sound: selectedSound)
                                }
                            }){
                                Image(systemName: "trash")
                                    .tint(.red)
                                    .hAlign(.trailing)
                                    .vAlign(.bottom)
                                    .padding(.horizontal, 15)
                            }
                            Divider()
                                .padding(.horizontal,5)
                                .padding(.top, 10)
                                .padding(.bottom,10)
                        }
                        .frame(width: UIScreen.main.bounds.width - 25, height: UIScreen.main.bounds.height/5,alignment: .topLeading)
                    }
                }
                .padding(10)
            }
            .task{
                await self.fetchUserSounds()
            }
            .navigationTitle("Garage")
        }
    }
    
    func fetchUserSounds() async{
        do{
            var query: Query!
            query = Firestore.firestore().collection("Playground").whereField("userid", isEqualTo: userUID)
            let docs = try await query.getDocuments()
            let fetchedSounds = docs.documents.compactMap{ doc -> PlaygroundSound? in
                try? doc.data(as: PlaygroundSound.self)
            }
            
            await MainActor.run {
                self.sounds = fetchedSounds
                print(self.sounds)
            }
        }
        catch {
            print(error.localizedDescription)
        }
    }
    
    func deleteSound(sound: PlaygroundSound){
        Task{
            do{
                //let mediaNameAux = (sound.soundURL.absoluteString).split(separator: "Playground_media%")[1]
                //let mediaName = mediaNameAux.split(separator: "?alt")[0]
                //let storageRef = Storage.storage().reference().child("Playground_media").child("\(mediaName)")
                //try await storageRef.delete()
                guard let soundID = sound.id else {return}
                try await Firestore.firestore().collection("Playground").document(soundID).delete()
                if let index = sounds.firstIndex(where: { $0.id == sound.id }) {
                    sounds.remove(at: index)
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}

struct GarageView_Previews: PreviewProvider {
    static var previews: some View {
        GarageView()
    }
}
