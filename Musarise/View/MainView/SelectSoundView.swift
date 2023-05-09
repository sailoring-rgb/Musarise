import SwiftUI
import CoreMotion
import AVKit

struct SelectSoundView: View {

    var onClose: () -> Void
    @State var showPlayCard: Bool = false
    @State var audioSelected: URL
    
    var body: some View {
        Color.clear
        ZStack{
            VStack(alignment: .center, spacing: 15){
                HStack{
                    Image(systemName: "music.quarternote.3")
                        .renderingMode(.original)
                        .resizable()
                        .foregroundColor(.yellow)
                        .frame(width: 38, height: 38)
                        .padding(.horizontal, 5)
                    
                    Image(systemName: "music.note.list")
                        .renderingMode(.original)
                        .resizable()
                        .foregroundColor(.yellow)
                        .frame(width: 38, height: 38)
                        .padding(.horizontal, 5)
                }
                
                Button(action: {
                    self.showPlayCard = true
                }){
                    Text("Select")
                        .foregroundColor(.white)
                        .frame(width: 100, height:10)
                        .fillView(.yellow)
                }
                .padding(.top, 10)
                
                Button{
                    onClose()
                } label: {
                    Text("Choose another one")
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .fillView(.clear)
                }
            }
            .frame(width: UIScreen.main.bounds.size.width / 2.0)
            .padding(.bottom, 10)
            .padding(.top, 30)
            .background(Color.white)
            .cornerRadius(20)
        }
        
        if showPlayCard{
            PlayCardView(onClose: {
                self.showPlayCard = false
                onClose()
            }, audioURL: audioSelected,
               freeMode: false,
               playersFreeMode: []
            )
        }
    }
}

struct PlayCardView: View {
    let motionManager = CMMotionManager()
    var onClose: () -> Void
    @State var players: [AVPlayer] = []
    @State var audioURL: URL
    @State var freeMode: Bool
    @State var playersFreeMode: [Drum]
    
    @State private var freeModeDrum: Int = -1
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
                                screenRecorder.startRecording()
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
            SaveSoundForm(instrument: "Drums", instrumentIcon: "🥁", recorded: $recorded, confirmSave: $confirmSave, screenRecorder: screenRecorder)
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
    
    func playSound(volume: Float){

        if !freeMode{
            let playerItem: AVPlayerItem = AVPlayerItem(url: self.audioURL)
            let player: AVPlayer = AVPlayer(playerItem: playerItem)
            self.players.append(player)
            player.volume = volume
            player.play()
        }
        else {
            let playerItem: AVPlayerItem = AVPlayerItem(url: self.playersFreeMode[freeModeDrum].soundURL)
            let player: AVPlayer = AVPlayer(playerItem: playerItem)
            self.players.append(player)
            player.volume = volume
            player.play()
        }
    }

    func getAmplitude(duration: TimeInterval) -> Double{
        let min_duration = 1.0
        let max_duration = 10.0
        
        let volume = 1 - ((duration - min_duration) / (max_duration - min_duration))
        return volume
    }
    
    // retorna a posição da aceleração (0 a 2), que correspondem a cada posição dos drums (caso seja free mode)
    func checkAcceleration(acceleration: CMAcceleration) -> Int{
        
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
                playSound(volume: Float(volume))
            }
            isDetected = false
        }
        
        return checkMovement(acceleration: acceleration)
    }
    
    func checkMovement(acceleration: CMAcceleration) -> Int{
        print(acceleration.x)
        
        if freeMode{
            // posição mais à direita
            if (acceleration.x >= 0.2) {
                return 2
            }
            // posição mais à esquerda
            else if (acceleration.x <= -0.2) {
                return 0
            }
            // posição central (local)
            else{
                return 1
            }
        }
        else{
            // se não for free mode, retorna -1
            return -1
        }
    }

    func startAccelerometerUpdates(){
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.001
            motionManager.startAccelerometerUpdates(to: .main) { data, error in
                if let acceleration = data?.acceleration {
                    accelerationData = acceleration
                    freeModeDrum = checkAcceleration(acceleration: acceleration)
                }
            }
        }
    }

    func stopAccelerometerUpdates(){
        motionManager.stopAccelerometerUpdates()
    }
}
