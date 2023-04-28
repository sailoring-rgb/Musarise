import SwiftUI
import AVKit
import CoreMotion

struct PlayCard: View {
    let motionManager = CMMotionManager()
    
    @State private var accelerationData : CMAcceleration? = nil
    @State private var isDetected : Bool = false
    @State private var played : Bool = false
    @State var player: AVPlayer?
    @State var audioURL: URL
    @State private var isRecording = false
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    
    var body: some View {
        VStack{
            if let acceleration = accelerationData {
                //Text("X: \(acceleration.x)\nY: \(acceleration.y)\nZ: \(acceleration.z)")
                        Circle()
                        .fill(Color.yellow)
                        .frame(width: 150, height: 150)
                        .overlay(
                            VStack{
                                Text("Record")
                                    .foregroundColor(.white)
                                    .font(.system(size: 30))
                                Text("\(elapsedTime, specifier: "%.1f")s")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.top, 10)
                            }
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
                                })
                if played{
                    let _ = playSound(audioURL:audioURL)
                }
            }
            else {
                ProgressView()
            }
        }
        .onAppear {
            startAccelerometerUpdates()
        }
        .onDisappear {
            stopAccelerometerUpdates()
        }
    }
    
    func playSound(audioURL:URL){
        let playerItem: AVPlayerItem = AVPlayerItem(url:audioURL)
        self.player = AVPlayer(playerItem: playerItem)
        self.player?.volume = 0.5
        self.player?.play()
    }
    
    func checkAcceleration(acceleration: CMAcceleration) {
        var startTime : TimeInterval = 0
        var duration : TimeInterval = 0
        
        // aceleração inicialmente positiva
        if (acceleration.z >= 0 && !isDetected) {
            isDetected = false
            played = false
            startTime = Date().timeIntervalSinceReferenceDate
            print(played)
        }
        // aceleração positiva para negativa
        else if (acceleration.z < 0 && !isDetected) {
            isDetected = true
            startTime = Date().timeIntervalSinceReferenceDate
        }
        // aceleração negativa para positiva
        else if (acceleration.z >= 0 && isDetected){
            duration = Date().timeIntervalSinceReferenceDate - startTime
            // getAmplitude(duration: duration)
            isDetected = false
            played = true
            print(played)
            playSound(audioURL: audioURL)
        }
    }

    func startAccelerometerUpdates(){
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.1
            motionManager.startAccelerometerUpdates(to: .main) { data, error in
                if let acceleration = data?.acceleration {
                    accelerationData = acceleration
                    checkAcceleration(acceleration: acceleration)
                }
            }
        }
    }

    func stopAccelerometerUpdates(){
        // Para a atualização dos dados de aceleração
        motionManager.stopAccelerometerUpdates()
    }
}
