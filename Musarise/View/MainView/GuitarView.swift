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
                        screenRecorder.uploadRecordingToFirebase { result in
                           switch result {
                           case .success(let downloadURL):
                               print("Upload successful. Download URL: \(downloadURL)")
                           case .failure(let error):
                               print("Upload failed: \(error.localizedDescription)")
                           }
                       }
                        self.recorded = false
                    }) {
                        Text("Save")
                    }
                    .disabled(!recorded)
                }
            }else {
                ProgressView()
            }
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

class ScreenRecorder: NSObject, ObservableObject, RPPreviewViewControllerDelegate {
    
    private var videoFileURL: URL?
    
    private var storageRef = Storage.storage().reference()
    private var uploadTask: StorageUploadTask?
    private var downloadURL: URL?
    
    @Published var isRecording = false
    @Published var recorded = false
    
    func startRecording() {
        guard RPScreenRecorder.shared().isAvailable else {
            print("Screen recording is not available")
            return
        }
        
        RPScreenRecorder.shared().startRecording { [weak self] (error) in
            guard error == nil else {
                print("Error starting screen recording: \(error!.localizedDescription)")
                return
            }
            
            print("Screen recording started")
            self?.isRecording = true
        }
    }
    
    
    func tempURL(extensionS: String) -> URL? {
        let directory = NSTemporaryDirectory() as NSString
        
        if directory != "" {
            let path = directory.appendingPathComponent((NSUUID().uuidString) + extensionS)
            return URL(fileURLWithPath: path)
        }
        
        return nil
    };

    func stopRecording() {
        
        let outputURL = tempURL(extensionS:".mov")
        
        guard let outputURL = outputURL else {
            print("Failed to get outputURL")
            return
        }
        
        RPScreenRecorder.shared().stopRecording(withOutput: outputURL) { error in
            if let error = error {
                print("Failed to save video: \(error.localizedDescription)")
            } else {
                print("Video saved successfully")
                self.videoFileURL = outputURL
            }
        }
        
    }
    
    func uploadRecordingToFirebase(completion: @escaping (Result<URL, Error>) -> Void) {
        guard let videoFileURL = self.videoFileURL else {
            print("Error uploading recording: no file URL found")
            return
        }
        
        extractAudioFromVideo(at: videoFileURL) { result in
            switch result {
            case .success(let audioURL):
                print("Audio extracted successfully to \(audioURL)")
                let storageRef = Storage.storage().reference().child("Playground_media/\(UUID().uuidString).m4a")
                let metadata = StorageMetadata()
                metadata.contentType = "audio/m4a"
                
                self.uploadTask = storageRef.putFile(from: audioURL, metadata: metadata) { (metadata, error) in
                    if let error = error {
                        print("Error uploading recording: \(error.localizedDescription)")
                        completion(.failure(error))
                        return
                    }
                    
                    print("Recording uploaded")
                    
                    storageRef.downloadURL { (url, error) in
                        if let error = error {
                            print("Error getting download URL: \(error.localizedDescription)")
                            completion(.failure(error))
                            return
                        }
                        
                        guard let downloadURL = url else {
                            print("Error getting download URL: no URL returned")
                            completion(.failure(NSError(domain: "", code: 0, userInfo: nil)))
                            return
                        }
                        
                        self.downloadURL = downloadURL
                        completion(.success(downloadURL))
                    }
                }
            case .failure(let error):
                print("Failed to extract audio: \(error.localizedDescription)")
            }
        }

    }
    
    func extractAudioFromVideo(at videoURL: URL, completion: @escaping (Result<URL, Error>) -> Void) {
        let asset = AVURLAsset(url: videoURL)
        let audioOutputURL = tempURL(extensionS:".m4a")
        guard let audioOutputURL = audioOutputURL else {
            print("Failed to get outputURL")
            return
        }
        //let audioOutputURL = FileManager.default.temporaryDirectory.appendingPathComponent("audio.m4a")
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            completion(.failure(NSError(domain: "com.example.app", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create AVAssetExportSession"])))
            return
        }
        exportSession.outputURL = audioOutputURL
        exportSession.outputFileType = .m4a
        exportSession.exportAsynchronously {
            switch exportSession.status {
            case .completed:
                print("Success in the audio conversion")
                completion(.success(audioOutputURL))
            case .failed:
                completion(.failure(exportSession.error ?? NSError(domain: "com.example.app", code: -1, userInfo: [NSLocalizedDescriptionKey: "AVAssetExportSession failed"])))
            default:
                break
            }
        }
    }
}
