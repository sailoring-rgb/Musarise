//
//  GarageView.swift
//  Musarise
//
//  Created by parola on 06/05/2023.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import AVKit

struct GarageView: View {
    @State private var sounds: [PlaygroundSound] = []
    @AppStorage("user_UID") var userUID: String = ""
    @State private var player: AVPlayer?
    
    var body: some View {
        NavigationView{
            ScrollView {
                LazyVGrid(columns: [GridItem()],spacing: 10) {
                    ForEach(sounds) { sound in
                        VStack(alignment: .leading) {
                            Text(sound.instrumentIcon+sound.instrumentName)
                                .font(.system(size: 16))
                                .foregroundColor(Color.black)
                                .bold()
                                .padding(.horizontal, 10)
                                .padding(.top,10)
                            Text(sound.publishedDate.formatted(date: .numeric, time: .shortened))
                                .font(.system(size: 12))
                                .foregroundColor(Color.gray)
                                .padding(.horizontal, 10)
                                .padding(.top,2)
                            Text(sound.soundDescription)
                                .font(.system(size: 14))
                                .foregroundColor(Color.black)
                                .padding(.horizontal, 10)
                                .padding(.top,4)
                            
                        }
                        .frame(width: UIScreen.main.bounds.width - 25, height: UIScreen.main.bounds.height/5,alignment: .topLeading)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        .gesture(TapGesture().onEnded{
                            do {
                                let playerItem: AVPlayerItem = AVPlayerItem(url: sound.soundURL)
                                self.player = AVPlayer(playerItem: playerItem)
                                self.player?.volume = 1
                                self.player?.play()
                            } catch {
                                print("Error playing audio")
                            }
                        })
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
}

struct GarageView_Previews: PreviewProvider {
    static var previews: some View {
        GarageView()
    }
}
