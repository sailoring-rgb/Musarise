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
    @State private var rotationRateData: CMRotationRate? = nil
    @State var players: [AVPlayer] = []
    @State var audioURL: URL?
    @State private var systemNameCancel = "xmark.circle"
    @State private var systemNameDone = "checkmark.circle"
    @State private var elapsedTime: TimeInterval = 0
    @State private var isRecording = false
    @State private var recorded = false
    @State private var timer: Timer?
    @StateObject var screenRecorder = ScreenRecorder()
    @State private var confirmSave: Bool = false
    @State private var soundTitle = ""
    @State private var soundDescription = ""
    @State private var halfDistance: Double = 6.14
    @State private var sumDistance: Double = 0.0
    @State private var noteState: Int = 0
    @State private var numberOfNotes: Int = 6
    
    var body: some View {
        VStack{
            if let rotation = rotationRateData{
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
                Text("Enter a title")
                    .bold()
                    .font(.system(size: 32))
                    .padding(.horizontal,16)
                TextField("Title", text: $soundTitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal,16)
                Text("Enter a description")
                    .bold()
                    .font(.system(size: 32))
                    .padding(.horizontal,16)
                    .padding(.top,30)
                TextField("Description", text: $soundDescription)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal,16)
                HStack {
                    Button(action: {
                        screenRecorder.saveSoundInFirebase(instrumentName: "Guitar", instrumentIcon: "🎸", soundTitle: self.soundTitle, soundDescription: self.soundDescription)
                        confirmSave.toggle()
                        self.recorded = false
                        
                    }){
                        Text("Confirm")
                            .padding(10)
                    }
                    .foregroundColor(.white)
                    .background(Color.yellow)
                    .cornerRadius(10)
                    .frame(width: 150)
                    .padding(.horizontal,16)
                    .padding(.top,35)
                    
                    Spacer()
                    
                    Button(action: {
                        confirmSave.toggle()
                    }){
                        Text("Cancel")
                            .padding(10)
                    }
                    .foregroundColor(.white)
                    .background(Color.red)
                    .cornerRadius(10)
                    .frame(width: 150)
                    .padding(.horizontal,10)
                    .padding(.top,35)
                }
            }
            .frame(maxHeight: UIScreen.main.bounds.height / 2)
        }
        .frame(width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height)
        .background(isRecording ? Color.yellow : Color.white)
        .onAppear {
            startGyroscopeUpdates()
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
    
    func getNumberOfNotesToPlay(angularVelocity:Double) -> Int {
        let value = (angularVelocity * Double(self.numberOfNotes)) / self.halfDistance
        if (value < 1.0){return -1}
        return Int(value)
    }
    
    func checkRotation(rotation: CMRotationRate) {
        do{
            let numberOfNotesToPlay:Int = getNumberOfNotesToPlay(angularVelocity: abs(rotation.x))
            if (numberOfNotesToPlay == -1){return}
            if rotation.x > 0{
                for i in 0...self.numberOfNotes{
                    if (self.noteState == (self.numberOfNotes-1)){
                        return
                    }
                    self.playSound(audioURL:self.guitarNotes[self.noteState].soundURL)
                    self.noteState+=1
                }
            }else{
                for i in 0...self.numberOfNotes{
                    if (self.noteState == 0){
                        return
                    }
                    self.playSound(audioURL:self.guitarNotes[self.noteState].soundURL)
                    self.noteState-=1
                }
            }
        }catch{
            print("Variation do not correspond to a note")
        }
    }
    
    
    func startGyroscopeUpdates() {
        if motionManager.isGyroAvailable {
            motionManager.gyroUpdateInterval = 0.001
            motionManager.startGyroUpdates(to: .main) { data, error in
                if let rotationRate = data?.rotationRate {
                    self.rotationRateData = rotationRate
                    checkRotation(rotation:rotationRate)
                }
            }
        }
    }

    func stopAccelerometerUpdates(){
        motionManager.stopGyroUpdates()
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
                self.guitarNotes = fetchedGuitarNotes
                self.numberOfNotes = self.guitarNotes.count
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
