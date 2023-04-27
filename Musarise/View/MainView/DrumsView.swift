import SwiftUI
import CoreMotion
import Firebase
import FirebaseFirestore
import AVKit

struct DrumsView: View {
    let motionManager = CMMotionManager()
    @State private var accelerationData : CMAcceleration? = nil
    @State private var isDetected : Bool = false
    @State private var played : Bool = false
    @State private var drums: [Drum] = []
    
    var body: some View {
        VStack{
            if let acceleration = accelerationData {
                //Text("X: \(acceleration.x)\nY: \(acceleration.y)\nZ: \(acceleration.z)")
                //if played {
                //    Text("BATEU!")
                //}
                Text("Choose the sound")
                    .font(.system(size: 40).bold())
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible(minimum: 0, maximum: .infinity)), GridItem(.flexible(minimum: 0, maximum: .infinity))], spacing: 10) {
                        ForEach(drums) { drum in
                            VStack {
                                Text("Drum")
                                    .font(.system(size: 20))
                                Button(action: {
                                    do{
                                        var player: AVPlayer!
                                        player = AVPlayer(url: drum.soundURL)
                                        print(player)
                                        player.volume = 1.0
                                        player.play()
                                    }catch{
                                        print("Error playing audio")
                                    }
                                }) {
                                    Image(systemName: "music.note")
                                        .font(.system(size: 50))
                                        .foregroundColor(.yellow)
                                }
                            }
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(20)
                        }
                    }
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
        .task {
            await fetchDrumsAudios()
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

struct DrumsView_Previews: PreviewProvider {
    static var previews: some View {
        DrumsView()
    }
}
