import Firebase
import FirebaseFirestore
import FirebaseStorage
import ReplayKit
import SwiftUI

class ScreenRecorder: NSObject, ObservableObject, RPPreviewViewControllerDelegate {
    
    private var videoFileURL: URL?
    private var storageRef = Storage.storage().reference()
    private var uploadTask: StorageUploadTask?
    private var downloadURL: URL?
    @AppStorage("user_UID") private var userUID: String = ""
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
        
    func saveSoundInFirebase(instrumentName:String,instrumentIcon:String){
        self.uploadRecordingToFirebase { result in
           switch result {
           case .success(let downloadURL):
               print("Upload successful. Download URL: \(downloadURL)")
               
               let playgroundSound = PlaygroundSound(soundURL: downloadURL, instrumentName: instrumentName, instrumentIcon: instrumentIcon,userid: self.userUID)
               
               let doc = Firestore.firestore().collection("Playground").document()
               do{
                   try doc.setData(from: playgroundSound, completion: {
                       error in if error == nil {
                           print("Document added in Firestore!")
                       }
                   })
               }catch{
                   print("Add Document to Firestore failed!")
               }
           case .failure(let error):
               print("Upload failed: \(error.localizedDescription)")
           }
       }
    }
}
