import SwiftUI
import Firebase
import FirebaseFirestore
import AVKit

struct PianoView: View {
    @State private var keys: [Piano] = []
    @State private var player: AVPlayer?
    @State private var showModal: Bool = true
    @State private var toRecord: Bool = false
    
    var body: some View {
        ZStack {
            NavigationStack {
                VStack(alignment: .center){
                    ForEach(Array(keys.enumerated()), id: \.1.id) { index, key in
                        BlackFrameView(colorCode: index+1, key: key)
                    }
                }
                .scaleEffect(0.9)
                .padding(.top, -15)
                .padding(.bottom, 70)
                .task {
                    await fetchPianoSounds()
                }
                .toolbar(content: {
                    if toRecord{
                        ToolbarItem(placement: .navigationBarTrailing){
                            Button(action: {
                                toRecord = false
                            }) {
                                HStack{
                                    Text("Stop")
                                        .tint(.black)
                                        .scaleEffect(0.9)
                                    
                                    Image(systemName: "stop.circle")
                                        .tint(.black)
                                        .scaleEffect(0.9)
                                }
                            }
                        }
                    }
                    else {
                        ToolbarItem(placement: .navigationBarLeading){
                            Button(action: {
                                toRecord = true
                            }) {
                                HStack{
                                    Image(systemName: "stop.circle.fill")
                                        .tint(.black)
                                        .scaleEffect(0.9)
                                    
                                    Text("Start")
                                        .tint(.black)
                                        .scaleEffect(0.9)
                                }
                            }
                        }
                    }
                })
            }
            .navigationBarTitleDisplayMode(.inline)
            .padding(.top,15)
            
            if showModal{
                Color.black
                    .opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        self.showModal = false
                    }
                GeometryReader{geo in
                    RecordPianoView(onClose: {
                        self.showModal = false
                    }, toRecord: $toRecord)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .position(x: geo.size.width/2, y: geo.size.height/2.1)
                    
                }
            }
            
            if toRecord{
                // START RECORDING
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
            }.sorted { (piano1, piano2) -> Bool in
                return piano1.name.lowercased() < piano2.name.lowercased()
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
    @State private var players: [AVPlayer] = []
    @State private var isTapped: Bool = false
    @State private var scaleNote: CGFloat = 1.0
    
    var body: some View {
        Color.clear
        ZStack {
            VStack {
                if colorCode % 3 == 0 {
                    Text("♫")
                        .font(.system(size: 25))
                        .rotationEffect(.degrees(90))
                        .foregroundColor(.yellow)
                        .scaleEffect(scaleNote)
                } else if colorCode % 2 == 0 {
                    Text("𝄞")
                        .font(.system(size: 50))
                        .rotationEffect(.degrees(90))
                        .foregroundColor(.yellow)
                        .scaleEffect(scaleNote)
                } else {
                    Text("♪")
                        .font(.system(size: 35))
                        .rotationEffect(.degrees(90))
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
                playSound(audioURL: key.soundURL)
                
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
        player.volume = 0.5
        player.play()
        self.players.append(player)
    }
}
