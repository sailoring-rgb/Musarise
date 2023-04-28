import SwiftUI
import AVKit
import CoreMotion

struct PlayCard: View {
    let motionManager = CMMotionManager()
    var onClose: () -> Void
    
    @State private var accelerationData : CMAcceleration? = nil
    @State private var isDetected : Bool = false
    @State private var itsTimeToPlay : Bool = false
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
                                // do something
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
        .frame(width: 300, height: 400)
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
    
    func playSound(audioURL:URL){
        let playerItem: AVPlayerItem = AVPlayerItem(url:audioURL)
        let player = AVPlayer(playerItem: playerItem)
        self.players.append(player)
        player.volume = 1
        player.play()
    }
    
    func checkAcceleration(acceleration: CMAcceleration) {
        var startTime : TimeInterval = 0
        var duration : TimeInterval = 0
        
        // aceleração inicialmente positiva
        if (acceleration.z >= 0 && !isDetected) {
            isDetected = false
            itsTimeToPlay = false
            startTime = Date().timeIntervalSinceReferenceDate
            print(itsTimeToPlay)
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
            //itsTimeToPlay = true
            //print(itsTimeToPlay)
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
        motionManager.stopAccelerometerUpdates()
    }
}
