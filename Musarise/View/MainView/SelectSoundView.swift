import SwiftUI

struct SelectSoundView: View {

    var onClose: () -> Void
    @State var showPlayCard: Bool = false
    @State var audioSelected: URL
    
    var body: some View {
        Color.clear
        ZStack{
            VStack(alignment: .center, spacing: 15){
                HStack{
                    Image(systemName: "music.quarternote.3")
                        .renderingMode(.original)
                        .resizable()
                        .foregroundColor(.yellow)
                        .frame(width: 38, height: 38)
                        .padding(.horizontal, 5)
                    
                    Image(systemName: "music.note.list")
                        .renderingMode(.original)
                        .resizable()
                        .foregroundColor(.yellow)
                        .frame(width: 38, height: 38)
                        .padding(.horizontal, 5)
                }
                
                Button(action: {
                    self.showPlayCard = true
                }){
                    Text("Select")
                        .foregroundColor(.white)
                        .frame(width: 100, height:10)
                        .fillView(.yellow)
                }
                .padding(.top, 10)
                
                Button{
                    onClose()
                } label: {
                    Text("Choose another one")
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
        
        if showPlayCard{
            PlayCardView(onClose: {
                self.showPlayCard = false
                onClose()
            }, audioURL: audioSelected)
        }
    }
}
