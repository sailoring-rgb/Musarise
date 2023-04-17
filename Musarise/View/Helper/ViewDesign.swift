//
//  ViewDesign.swift
//  Musarise
//
//  Created by annaphens on 12/04/2023.
//

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

    func fontSize() -> CGFloat{
        let screenWidth = UIScreen.main.bounds.size.width

        var fontSize: CGFloat = 0.0
        
        switch screenWidth {
            case 375, 390:
                fontSize = 9.0
            case 414:
                fontSize = 12.0
            case 428:
                fontSize = 14.0
            default:
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
