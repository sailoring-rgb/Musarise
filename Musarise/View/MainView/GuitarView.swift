import SwiftUI
import AVKit
import CoreMotion
import Firebase
import FirebaseFirestore
import FirebaseStorage
import ReplayKit

struct GuitarView: View {
    @State private var guitarNotes: [Guitar] = []
    let motionManager = CMMotionManager()
    @State private var accelerationData: CMAcceleration? = nil
    @State var players: [AVPlayer] = []
    @State var audioURL: URL?
    @State var previousAccY: Double = -10
    @State var maxDistDebug: Double = 0
    @State var minDistDebug: Double = 0
    @State private var systemNameCancel = "xmark.circle"
    @State private var systemNameDone = "checkmark.circle"
    @State private var elapsedTime: TimeInterval = 0
    @State private var isRecording = false
    @State private var recorded = false
    @State private var timer: Timer?
    @StateObject var screenRecorder = ScreenRecorder()
    @State private var confirmSave: Bool = false
    @State private var soundDescription = ""
    
    var body: some View {
        VStack{
            if let acceleration = accelerationData {
                VStack{
                    ZStack {
                        Circle()
                            .fill(Color.yellow)
                            .frame(width: 150, height: 150)
                            .overlay(
                                VStack{
                                    Text(isRecording ? "Stop" : "Record")
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
                    }
                    Button(action: {
                        print("let's save!")
                        self.confirmSave = true // open PopUp
                    }) {
                        Text("Save")
                    }
                    .disabled(!recorded)
                }
            }else {
                ProgressView()
            }
        }
        .sheet(isPresented: $confirmSave) {
            VStack(alignment: .leading){
                Text("Enter a description")
                    .bold()
                    .font(.system(size: 32))
                    .padding(.horizontal,16)
                TextField("Enter text", text: $soundDescription)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal,16)
                HStack {
                    Button(action: {
                        screenRecorder.saveSoundInFirebase(instrumentName: "Guitar", instrumentIcon: "🎸",soundDescription: self.soundDescription)
                        confirmSave.toggle()
                        self.recorded = false
                        
                    }){
                        Text("Confirm")
                            .padding(10)
                    }
                    .foregroundColor(.white)
                    .cornerRadius(5)
                    .background(Color.yellow)
                    .frame(width: 150)
                    .padding(.horizontal,16)
                    .cornerRadius(5)
                    Spacer()
                    Button(action: {
                        confirmSave.toggle()
                    }){
                        Text("Cancel")
                            .padding(10)
                    }
                    .foregroundColor(.white)
                    .cornerRadius(5)
                    .background(Color.red)
                    .frame(width: 150)
                    .padding(.horizontal,10)
                }
            }
            .frame(maxHeight: UIScreen.main.bounds.height / 2)
        }
        .frame(width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height)
        .background(isRecording ? Color.yellow : Color.white)
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
