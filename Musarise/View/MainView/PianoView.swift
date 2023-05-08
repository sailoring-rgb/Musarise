import SwiftUI
import Firebase
import FirebaseFirestore
import AVKit

struct PianoView: View {
    @State private var keys: [Piano] = []
    @State private var player: AVPlayer?
    @State private var toRecord: Bool = false
    
    @StateObject var screenRecorder = ScreenRecorder()
    @State private var recorded = false
    @State private var confirmSave = false
    @State private var timer: Timer?
    @State private var elapsedTime: TimeInterval = 0
    
    var body: some View {
        ZStack {
            NavigationStack {
                VStack(alignment: .center){
                    ForEach(Array(keys.enumerated()), id: \.1.id) { index, key in
                        BlackFrameView(colorCode: index+1, key: key)
                    }
                }
                .scaleEffect(0.9)
                .padding(.top, -20)
                .padding(.bottom, 70)
                .task {
                    await fetchPianoSounds()
                }
                .toolbar(content: {
                    if self.toRecord{
                        ToolbarItem(placement: .navigationBarTrailing){
                            Button(action: {
                                self.timer?.invalidate()
                                screenRecorder.stopRecording()
                                self.toRecord = false
                                self.recorded = true
                            }) {
                                HStack{
                                    Text("Stop")
                                        .tint(.black)
                                        .scaleEffect(1.0)
                                    
                                    Image(systemName: "stop.circle")
                                        .tint(.black)
                                        .scaleEffect(1.0)
                                }
                            }
                        }
                    }
                    else {
                        ToolbarItem(placement: .navigationBarLeading){
                            Button(action: {
                                self.toRecord = true
                                self.recorded = false
                                self.elapsedTime = 0
                                screenRecorder.startRecording(mic: false)
                                self.timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                                    if self.toRecord {
                                        self.elapsedTime += 0.1
                                    } else {
                                        timer.invalidate()
                                    }
                                }
                            }) {
                                HStack{
                                    Image(systemName: "stop.circle.fill")
                                        .tint(.black)
                                        .scaleEffect(1.0)
                                    
                                    Text("Start")
                                        .tint(.black)
                                        .scaleEffect(1.0)
                                }
                            }
                        }
                        if recorded{
                            ToolbarItem(placement: .navigationBarTrailing){
                                Button(action: {
                                    self.confirmSave = true
                                }) {
                                    Text("Save")
                                        .foregroundColor(Color.green)
                                }
                                .disabled(!recorded)
                            }
                        }
                    }
                    ToolbarItem(placement: .principal){
                        Text("\(elapsedTime, specifier: "%.1f")s")
                            .tint(.black)
                            .scaleEffect(1.0)
                    }
                })
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $confirmSave){
                SaveSoundForm(instrument: "Piano", instrumentIcon: "🎹", recorded: $recorded, confirmSave: $confirmSave)
            }
            .frame(width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height)
            .padding(.top,15)
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
