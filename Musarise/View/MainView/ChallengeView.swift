import SDWebImageSwiftUI
import SwiftUI
import AVKit
import Firebase
import FirebaseFirestore

struct ChallengeView: View {
    @State private var fetchedChallenges: [Challenge] = []
    @State private var isPlaying: Bool = false
    @State private var player: AVPlayer?
    @State var isFetching: Bool = true
    @State private var soundUrlSelected: URL = URL(fileURLWithPath: "")
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false){
            if isFetching{
                ProgressView()
                    .padding(.top, 30)
            }else{
                if fetchedChallenges.isEmpty{
                    Text("No challenges were found..")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top, 30)
                } else{
                    ForEach(fetchedChallenges) { challenge in
                        VStack(alignment: .leading, spacing: 6){
                            Text(challenge.challengeTitle)
                                .font(.callout)
                                .fontWeight(.semibold)
                            
                            Text(challenge.publishedDate.formatted(date: .numeric, time: .shortened))
                                .font(.caption2)
                                .foregroundColor(.gray)
                            
                            ZStack {
                                WebImage(url: challenge.imageURL)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .overlay(Color.black.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                Button(action: {
                                    if isPlaying{
                                        self.isPlaying = false
                                        self.player?.pause()
                                    }
                                    else{
                                        soundUrlSelected = challenge.soundURL
                                        self.isPlaying = true
                                        let playerItem: AVPlayerItem = AVPlayerItem(url: challenge.soundURL)
                                        self.player = AVPlayer(playerItem: playerItem)
                                        self.player?.volume = 1
                                        self.player?.play()
                                    }
                                }) {
                                    Image(systemName: soundUrlSelected == challenge.soundURL && isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                        .font(.system(size: 50))
                                        .foregroundColor(.white)
                                        .colorMultiply(.yellow)
                                }
                            }
                            
                            Text(challenge.instrumentIcon+" "+challenge.instrumentName)
                                .font(.system(size: fontSize() + 7.0))
                                .foregroundColor(Color.black)
                                .bold()
                                .padding(.horizontal, 10)
                                .padding(.top,10)
                            
                            Text(challenge.challengeDescription)
                                .textSelection(.enabled)
                                .padding(.vertical,8)
                            
                            Divider()
                        }
                        
                        .padding(.horizontal, 20)
                        .padding(.top, 6)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Challenges")
        .task{
            self.isFetching = true
            await fetchChallenges()
            self.isFetching = false
        }
        .refreshable{
            self.isFetching = true
            await fetchChallenges()
            self.isFetching = false
        }
    }
    
    func fetchChallenges() async{
        do{
            var query: Query!
            query = Firestore.firestore().collection("Challenges")
            let docs = try await query.getDocuments()
            let fetchedChallenges = docs.documents.compactMap{ doc -> Challenge? in
                try? doc.data(as: Challenge.self)
            }
            
            await MainActor.run {
                self.fetchedChallenges = fetchedChallenges
                print(self.fetchedChallenges)
            }
        }
        catch {
            print(error.localizedDescription)
        }
    }
}

struct ChallengeView_Previews: PreviewProvider {
    static var previews: some View {
        ChallengeView()
    }
}
