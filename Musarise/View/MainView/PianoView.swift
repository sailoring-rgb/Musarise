import SwiftUI
import Firebase
import FirebaseFirestore
import AVKit

struct PianoView: View {
    @State private var keys: [Piano] = []
    @State private var player: AVPlayer?
    
    var body: some View {
        ZStack {
            NavigationView{
                VStack{
                    ForEach(Array(keys.enumerated()), id: \.1.id) { index, key in
                        BlackFrameView(colorCode: index+1, key: key)
                    }
                }
                .padding(.bottom, 85)
                .padding(.top, 10)
                .task {
                    await fetchPianoSounds()
                }
            }
        }
    }
    
    func fetchPianoSounds() async{
        do{
            var query: Query!
            query = Firestore.firestore().collection("Piano")
            let docs = try await query.getDocuments()
            let fetchedPianos = docs.documents.compactMap{ doc -> Piano? in
                try? doc.data(as: Piano.self)
            }
            
            await MainActor.run {
                keys.append(contentsOf: fetchedPianos)
            }
        }
        catch {
            print(error.localizedDescription)
        }
    }
}

struct PianoView_Previews: PreviewProvider {
    static var previews: some View {
        PianoView()
    }
}

struct BlackFrameView: View {
    @State var colorCode: Int
    @State var key: Piano
    @State var players: [AVPlayer] = []
    @State var isTapped: Bool = false
    @State private var scaleNote: CGFloat = 1.0
    
    var body: some View {
        Color.clear
        ZStack {
            VStack(alignment: .center) {
                if colorCode % 3 == 0 {
                    Text("♫")
                        .font(.system(size: 25))
                        .foregroundColor(.yellow)
                        .scaleEffect(scaleNote)
                } else if colorCode % 2 == 0 {
                    Text("𝄞")
                        .font(.system(size: 50))
                        .foregroundColor(.yellow)
                        .scaleEffect(scaleNote)
                } else {
                    Text("♪")
                        .font(.system(size: 35))
                        .foregroundColor(.yellow)
                        .scaleEffect(scaleNote)
                }
                Spacer()
                Spacer()
                Spacer()
                Spacer()
                Spacer()
            }
            .frame(width: UIScreen.main.bounds.size.width / 1.2, height: UIScreen.main.bounds.size.height / 20.0)
            .padding(.bottom,10)
            .padding(.top, 50)
            .background(isTapped ? backgroundColor : .black)
            .cornerRadius(10)
            .onTapGesture {
                do {
                    playSound(audioURL: key.soundURL)
                } catch {
                    print("Error playing audio")
                }
                withAnimation(.easeInOut(duration: 0.4)) {
                    isTapped = true
                    scaleNote = 2.0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isTapped = false
                    }
                    withAnimation(.easeInOut(duration: 0.5)) {
                        scaleNote = 1.0
                    }
                }
            }
        }
    }

    var backgroundColor: Color {
        switch colorCode {
        case 1:
            return .red
        case 2:
            return .orange
        case 3:
            return .yellow
        case 4:
            return .green
        case 5:
            return .blue
        default:
            return .purple
        }
    }
    
    func playSound(audioURL: URL){
        let playerItem: AVPlayerItem = AVPlayerItem(url:audioURL)
        let player = AVPlayer(playerItem: playerItem)
        self.players.append(player)
        player.volume = 1.0
        player.play()
    }
}
