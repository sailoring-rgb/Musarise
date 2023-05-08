import SwiftUI

struct SaveSoundForm: View {
    @State private var soundTitle: String = ""
    @State private var soundDescription: String = ""
    @State var instrument: String
    @State var instrumentIcon: String
    @Binding var recorded: Bool
    @Binding var confirmSave: Bool
    @State var screenRecorder: ScreenRecorder
    
    var body: some View{
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
                    screenRecorder.saveSoundInFirebase(instrumentName: self.instrument, instrumentIcon: self.instrumentIcon, soundTitle: self.soundTitle, soundDescription: self.soundDescription)
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
                .padding(.top, 35)
                
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
                .padding(.top, 35)
            }
        }
        .frame(maxHeight: UIScreen.main.bounds.height / 2)
    }
}
