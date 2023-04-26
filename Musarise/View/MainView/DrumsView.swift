import SwiftUI
import CoreMotion

struct DrumsView: View {
    let motionManager = CMMotionManager()
    @State private var accelerationData : CMAcceleration? = nil
    @State private var isDetected : Bool = false
    @State private var played : Bool = false
    
    var body: some View {
        VStack {
            if let acceleration = accelerationData {
                Text("X: \(acceleration.x)\nY: \(acceleration.y)\nZ: \(acceleration.z)")
                if played {
                    Text("BATEU!")
                }
            } else {
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

    func startAccelerometerUpdates() {
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

    func stopAccelerometerUpdates() {
        // Para a atualização dos dados de aceleração
        motionManager.stopAccelerometerUpdates()
    }
}

struct DrumsView_Previews: PreviewProvider {
    static var previews: some View {
        DrumsView()
    }
}
