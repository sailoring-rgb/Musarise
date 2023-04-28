import SwiftUI
import AVKit
import CoreMotion
import Firebase
import FirebaseFirestore

struct GuitarView: View {
    @State private var guitarNotes: [Guitar] = []
    let motionManager = CMMotionManager()
    @State private var accelerationData: CMAcceleration? = nil
    @State var players: [AVPlayer] = []
    @State var audioURL: URL?
    @State var previousAccY: Double = -10
    @State var maxDistDebug: Double = 0
    @State var minDistDebug: Double = 0
    
    var body: some View {
        VStack {
            if let acceleration = accelerationData {
                Text("Guitarra!")
                    .font(.system(size: 30))
            } else {
                ProgressView()
            }
        }
        .onAppear {
            startAccelerometerUpdates()
        }
        .onDisappear {
            stopAccelerometerUpdates()
            players.forEach { $0.pause() }
            players.removeAll()
            
        }
        .task {
            await fetchGuitarAudios()
            print(guitarNotes)
        }
    }
    
    func playSound(audioURL:URL){
        let playerItem = AVPlayerItem(url: audioURL)
        let player = AVPlayer(playerItem: playerItem)
        self.players.append(player)
        player.play()
    }

    func checkAcceleration(acceleration: CMAcceleration) {
        //playSound(audioURL: audioURL)
        
        /*
        // debug to find max value
        if distance > self.maxDistDebug{
            self.maxDistDebug = distance
        }
        
        // debug to find min value
        if distance < self.minDistDebug{
            self.minDistDebug = distance
        }
        
        print("max:" + String(self.maxDistDebug))
        print("min:" + String(self.minDistDebug))
        */
        
        do{
            var distance:Double = 0
            if (self.previousAccY != -10){
                distance = acceleration.z + self.previousAccY
            }else{
                distance = acceleration.z
            }
            var noteIndex = getNoteIndex(distance:distance)
            if acceleration.z * self.previousAccY < 0{
            
                self.playSound(audioURL: self.guitarNotes[noteIndex].soundURL)
            }
        }catch{
            print("Variation do not correspond to a note")
        }
        self.previousAccY = acceleration.z
    }
    
    func getNoteIndex(distance: Double) -> Int{
        var index = Int(distance + 3)
        if index < 0{
            return 0
        }else if (index > 5){
            return 5
        }
        return index
    }

    func startAccelerometerUpdates(){
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.05
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
    
    func fetchGuitarAudios() async{
        do{
            var query: Query!
            query = Firestore.firestore().collection("Guitar")
            let docs = try await query.getDocuments()
            let fetchedGuitarNotes = docs.documents.compactMap{ doc -> Guitar? in
                try? doc.data(as: Guitar.self)
            }
            
            await MainActor.run {
                guitarNotes.append(contentsOf: fetchedGuitarNotes)
            }
        }
        catch {
            print(error.localizedDescription)
        }
    }
}

struct GuitarView_Previews: PreviewProvider {
    static var previews: some View {
        GuitarView()
    }
}
