import SwiftUI
import AVKit
import CoreMotion
import Firebase
import FirebaseFirestore
import FirebaseStorage
import ReplayKit
import SDWebImageSwiftUI

struct VoiceView: View {
    @State private var elapsedTime: TimeInterval = 0
    @State private var isRecording = false
    @State private var recorded = false
    @State private var timer: Timer?
    @StateObject var screenRecorder = ScreenRecorder()
    @State private var confirmSave: Bool = false
    
    var body: some View {
        VStack{
            WebImage(url:URL(string:"https://firebasestorage.googleapis.com/v0/b/csound-967d4.appspot.com/o/General%2Fcantora.png?alt=media&token=7df4761e-2a4c-4a1b-8f78-0b7d7f5d88b8"))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width:UIScreen.main.bounds.size.width/2.8)
            Text("Let your voice out, let the melody take you. Dream of singing like Halsey? Then show us your talent!").padding(12).font(.system(size: fontSize() + 7.0))
            Divider().padding(12)
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.yellow)
                    .frame(width: 125, height: 125)
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
                            screenRecorder.startRecording(mic:true)
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
                self.confirmSave = true
            }) {
                Text("Save")
            }
            .disabled(!recorded)
            .padding(12)
        }
        .navigationTitle("Voice")
        .sheet(isPresented: $confirmSave) {
            SaveSoundForm(instrument: "Voice", instrumentIcon: "🎙", recorded: $recorded, confirmSave: $confirmSave, screenRecorder: screenRecorder)
        }
        .background(isRecording ? Color.yellow : Color.white)
    }
}

struct VoiceView_Previews: PreviewProvider {
    static var previews: some View {
        VoiceView()
    }
}
