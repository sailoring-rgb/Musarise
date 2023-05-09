import SwiftUI

extension VerticalAlignment{
    
    private enum CustomAlignment: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            print(context.height)
                return context.height / 2
        }
    }
        
    static let custom = VerticalAlignment(CustomAlignment.self)
}

extension View{
    
    // When the Sign in and Sign up buttons are pressed, the active keyboard is closed.
    func closeKeyboard(){
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    func scaleSize() -> CGFloat{
        let screenWidth = UIScreen.main.bounds.size.width
        var scale: CGFloat = 0.0
        if screenWidth <= 390{
            scale = 0.65
        }
        else if screenWidth > 390 && screenWidth <= 414{
            scale = 0.75
        }
        else if screenWidth > 414{
            scale = 0.9
        }
        return scale

    }
    
    func fontSize() -> CGFloat{
        let screenWidth = UIScreen.main.bounds.size.width
        var fontSize: CGFloat = 0.0
        if screenWidth <= 390{
            fontSize = 7.5
        }
        else if screenWidth > 390 && screenWidth <= 414{
            fontSize = 11.5
        }
        else if screenWidth > 414{
            fontSize = 14.0
        }
        return fontSize
    }
    
    func disableOpacity(_ condition: Bool) -> some View{
        self
            .disabled(condition)
            .opacity(condition ? 0.6 : 1)
    }
    
    func hAlign(_ alignment: Alignment)->some View{
        self.frame(maxWidth: .infinity, alignment: alignment)
    }
    
    func vAlign(_ alignment: Alignment)->some View{
        self.frame(maxHeight: .infinity, alignment: alignment)
    }
    
    func border(_ width: CGFloat, _ color: Color)->some View{
        self.padding(.horizontal,15).padding(.vertical,10).background{
            RoundedRectangle(cornerRadius: 5, style: .continuous).stroke( color, lineWidth: width)
        }
    }
    
    func fillView(_ color: Color)->some View{
        self.padding(.horizontal,15).padding(.vertical,10).background{
            RoundedRectangle(cornerRadius: 5, style: .continuous).fill(color)
        }
    }
}
