
import SwiftUI

// MARK: - 浮き上がったボタン(クイック金額ボタン用)
/// 白いカードに影を付け、押すと影が縮んで3pt沈む。
struct RaisedButtonStyle: ButtonStyle {
    
    var cornerRadius: CGFloat = 14
    var normalShadowRadius: CGFloat = 1
    var pressedShadowRadius: CGFloat = 0.5
    var x: CGFloat = 3
    var normalY: CGFloat = 5
    var pressedY: CGFloat = 1
    
    func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed
        
        configuration.label
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.white)
                    .shadow(
                        color: .black.opacity(isPressed ? 0.1 : 0.3),
                        radius: isPressed ? pressedShadowRadius : normalShadowRadius,
                        x: x,
                        y: isPressed ? pressedY : normalY
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.black.opacity(0.9), lineWidth: 0.1)
                    }
            }
            .offset(y: isPressed ? 3 : 0)
            .animation(.easeOut(duration: 0.15), value: isPressed)
    }
}

// MARK: - カプセル型ボタン(確定・クリア用)
/// 白いカプセルの下にオレンジのカプセルを重ね、押すと8pt沈んで重なる。
struct CustomButtonStyle: ButtonStyle {
    
    var accentColor: Color = .orange
    
    func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed
        
        configuration.label
            .font(.system(size: 15, weight: .bold))
            .padding(10)
            .background(
                ZStack {
                    Capsule()
                        .fill(accentColor)
                        .stroke(.black, lineWidth: isPressed ? 0.5 : 1.0)
                        .offset(y: isPressed ? 0 : 5)
                    Capsule()
                        .fill(.white)
                        .stroke(.black, lineWidth: isPressed ? 0.5 : 1.5)
                }
            )
            .offset(y: isPressed ? 8 : 0)
    }
}
