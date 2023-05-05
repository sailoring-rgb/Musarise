import SwiftUI
import AVKit
import CoreMotion

struct PlayCardView: View {
    let motionManager = CMMotionManager()
    var onClose: () -> Void
    
    @State private var accelerationData: CMAcceleration? = nil
    @State private var isDetected: Bool = false
    @State private var startime: Date?
    @State private var isRecording = false
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var systemNameCancel = "xmark.circle"
    @State private var systemNameDone = "checkmark.circle"
    
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
                        .gesture(
                            LongPressGesture(minimumDuration: 100.0)
                            .onEnded { _ in
                                self.isRecording = false
                                self.timer?.invalidate()
                            }
                            .onChanged { _ in
                                self.isRecording = true
                                self.elapsedTime = 0
                                self.timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                                    if self.isRecording {
                                        self.elapsedTime += 0.1
                                    } else {
                                        timer.invalidate()
                                    }
                                }
                            }
                        )
                    
                    HStack{
                        Button(action: {
                            systemNameCancel = "xmark.circle.fill"
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                onClose()
                            }
                        }) {
                            Image(systemName: systemNameCancel)
                                .foregroundColor(.black)
                                .scaleEffect(1.4)
                        }
                        .padding(.horizontal, 30)
                        
                        Button(action: {
                            systemNameDone = "checkmark.circle.fill"
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                // RECORD AUDIO
                            }
                        }) {
                            Image(systemName: systemNameDone)
                                .foregroundColor(.black)
                                .scaleEffect(1.4)
                        }
                        .padding(.horizontal, 30)
                    }
                    .padding(.top, 30)
                }
                
                
            } else {
                ProgressView()
            }
        }
        .frame(width: UIScreen.main.bounds.size.width / 1.3, height: UIScreen.main.bounds.size.height / 3)
        .padding(.bottom, 10)
        .padding(.top, 30)
        .background(Color.white)
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
