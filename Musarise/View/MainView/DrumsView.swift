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
                                    self.showModal = true
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
                    }
                    .frame(maxWidth: .infinity)
                    .padding(30)
                }
                .navigationTitle("Choose sound")
            }
            .task {
                await fetchDrumsAudios()
            }

            if showModal{
                Color.black
                    .opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        self.showModal = false
                    }
                GeometryReader{geo in
                    if let audioSelected = audioSelected{
                        SelectSoundView(
                            onClose: {
                                self.showModal = false
                            },
                            audioSelected: audioSelected
                        )
                        .frame(width: geo.size.width, height: geo.size.height)
                        .position(x: geo.size.width/2, y: geo.size.height/2)
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

struct PlayCardView: View {
    let motionManager = CMMotionManager()
    var onClose: () -> Void
    
    @State private var accelerationData: CMAcceleration? = nil
    @State private var isDetected: Bool = false
    @State private var startime: Date?
    @State private var systemNameCancel = "xmark.circle"
    @State private var systemNameDone = "checkmark.circle"
    
    @StateObject var screenRecorder = ScreenRecorder()
    @State private var isRecording = false
    @State private var recorded = false
    @State private var confirmSave = false
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    
    @State var players: [AVPlayer] = []
    @State var audioURL: URL
    
    var body: some View {
        VStack{
            if let acceleration = accelerationData {
                VStack{
                    Circle()
                        .fill(Color.yellow)
                        .frame(width: 150, height: 150)
                        .overlay(
                            VStack{
                                Text("Record")
                                    .foregroundColor(.white)
                                    .font(.system(size: 25))
                                
                                Text("\(elapsedTime, specifier: "%.1f")s")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.top, 10)
                            }
                                .padding(.bottom, 5)
                                .padding(.top, 15)
                        )
                        .onTapGesture {
                            if isRecording {
                                self.isRecording = false
                                self.timer?.invalidate()
                                self.recorded = true
                                screenRecorder.stopRecording()
                            } else {
                                self.isRecording = true
                                self.recorded = false
                                self.elapsedTime = 0
                                screenRecorder.startRecording(mic:true)
                                self.timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                                    if self.isRecording {
                                        self.elapsedTime += 0.1
                                    } else {
                                        timer.invalidate()
                                    }
                                }
                            }
                        }
                    
                    Button(action: {
                        print("let's save!")
                        self.confirmSave = true
                    }) {
                        Text("Save")
                    }
                    .disabled(!recorded)
                }
                
            } else {
                ProgressView()
            }
        }
        .sheet(isPresented: $confirmSave) {
            SaveSoundForm(instrument: "Drums", instrumentIcon: "🥁", recorded: $recorded, confirmSave: $confirmSave)
        }
        .frame(width: UIScreen.main.bounds.size.width / 1.3, height: UIScreen.main.bounds.size.height / 3)
        .padding(.bottom, 10)
        .padding(.top, 30)
        .background(isRecording ? Color.yellow : Color.white)
        .cornerRadius(20)
        .onAppear {
            startAccelerometerUpdates()
        }
        .onDisappear {
            stopAccelerometerUpdates()
            players.forEach { $0.pause() }
            players.removeAll()
        }
    }
    
    func playSound(audioURL: URL, volume: Float){
        let playerItem: AVPlayerItem = AVPlayerItem(url:audioURL)
        let player = AVPlayer(playerItem: playerItem)
        self.players.append(player)
        player.volume = volume
        player.play()
    }

    func getAmplitude(duration: TimeInterval) -> Double{
        let min_duration = 1.0
        let max_duration = 10.0
        
        let volume = 1 - ((duration - min_duration) / (max_duration - min_duration))
        return volume
    }
    
    func checkAcceleration(acceleration: CMAcceleration) {
        
        // aceleração inicialmente positiva
        if (acceleration.y >= 0 && !isDetected) {
            isDetected = false
        }
        // aceleração positiva para negativa
        else if (acceleration.y < 0 && !isDetected) {
            isDetected = true
            startime = Date()
        }
        // aceleração negativa para positiva
        else if (acceleration.y >= 0 && isDetected){
            if let startime = startime{
                let duration = Date().timeIntervalSince(startime)
                let volume = getAmplitude(duration: duration)
                playSound(audioURL: audioURL, volume: Float(volume))
            }
            isDetected = false
        }
    }

    func startAccelerometerUpdates(){
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.001
            motionManager.startAccelerometerUpdates(to: .main) { data, error in
                if let acceleration = data?.acceleration {
                    accelerationData = acceleration
                    checkAcceleration(acceleration: acceleration)
                }
            }
        }
    }

    func stopAccelerometerUpdates(){
        motionManager.stopAccelerometerUpdates()
    }
}
