import SwiftUI

struct RecordPianoView: View {

    var onClose: () -> Void
    @State private var showPianoView: Bool = false
    @Binding var toRecord: Bool
    
    var body: some View {
        Color.clear
        ZStack{
            VStack(alignment: .center, spacing: 15){
                Button(action: {
                    self.toRecord = true
                    onClose()
                }){
                    Label("Record", systemImage: "record.circle")
                        .foregroundColor(.white)
                        .frame(width: 100, height:10)
                        .fillView(.yellow)
                }
                .padding(.top, 10)
                
                Button{
                    self.toRecord = false
                    onClose()
                } label: {
                    Text("No recording for now..")
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .fillView(.clear)
                }
            }
            .frame(width: UIScreen.main.bounds.size.width / 2.0)
            .padding(.bottom, 10)
            .padding(.top, 30)
            .background(Color.white)
            .cornerRadius(20)
        }
    }
}
