import SwiftUI

struct ReusablePostsView: View {
    @Binding var posts: [Post]
    @State var isFetching: Bool = false
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false){
            
        }
    }
}

struct ReusablePostsView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
