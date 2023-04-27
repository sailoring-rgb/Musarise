import SwiftUI
import AVKit
import CoreMotion

struct PlayCard: View {
    let motionManager = CMMotionManager()
    
    @State private var accelerationData : CMAcceleration? = nil
    @State private var isDetected : Bool = false
    @State private var played : Bool = false
    @State var player: AVPlayer
    @State var audioURL: URL
    
    var body: some View {
        VStack{
            Text("Funciona please")
            if let acceleration = accelerationData {
                Text("X: \(acceleration.x)\nY: \(acceleration.y)\nZ: \(acceleration.z)")
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
        .onChange(of: played) { newValue in
            if newValue == true {
                let playerItem: AVPlayerItem = AVPlayerItem(url: audioURL)
                player = AVPlayer(playerItem: playerItem)
                player.volume = 0.5
                player.play()
            }
        }
    }
    
    func checkAcceleration(acceleration: CMAcceleration) {
        var startTime : TimeInterval = 0
        var duration : TimeInterval = 0
        
        // aceleração inicialmente positiva
        if (acceleration.z >= 0 && !isDetected) {
            isDetected = false
            played = false
            startTime = Date().timeIntervalSinceReferenceDate
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
