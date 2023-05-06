import SwiftUI
import AVKit
import CoreMotion
import Firebase
import FirebaseFirestore
import FirebaseStorage
import ReplayKit

struct VoiceView: View {
    @State private var elapsedTime: TimeInterval = 0
    @State private var isRecording = false
    @State private var recorded = false
    @State private var timer: Timer?
    @StateObject var screenRecorder = ScreenRecorder()
    @State private var confirmSave: Bool = false
    @State private var soundDescription = ""
    
    var body: some View {
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
                self.confirmSave = true // open PopUp
            }) {
                Text("Save")
            }
            .disabled(!recorded)
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
                        screenRecorder.saveSoundInFirebase(instrumentName: "Voice", instrumentIcon: "🎙",soundDescription: self.soundDescription)
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
        }
        .onDisappear {
        }
    }
}

struct VoiceView_Previews: PreviewProvider {
    static var previews: some View {
        VoiceView()
    }
}
