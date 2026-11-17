
import SwiftUI

// MARK: - アプリ共通カラー

extension Color {
    
    // MARK: 基本カラー
    
    static let checkRGB = Color(
        red: 41.0 / 255.0,
        green: 187.0 / 255.0,
        blue: 107.0 / 255.0
    )
    
    // MARK: 背景カラー
    
    static let appBackground = Color(
        red: 240 / 255.0,
        green: 242 / 255.0,
        blue: 241 / 255.0
    )
    
    // MARK: アクセントカラー
    
    static let appAccent = Color(
        red: 19 / 255.0,
        green: 78 / 255.0,
        blue: 94 / 255.0
    )
    
    static let appSubAccent = Color(
        red: 113 / 255.0,
        green: 178 / 255.0,
        blue: 128 / 255.0
    )
}

// MARK: - Preview

struct RGBColor: View {
    
    private let colors: [(String, Color)] = [
        ("appBlack", .checkRGB),
//        ("appBackground", .appBackground),
//        ("appAccent", .appAccent),
//        ("appSubAccent", .appSubAccent)
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                
                ForEach(colors, id: \.0) { item in
                    HStack(spacing: 16) {
                        
                        RoundedRectangle(cornerRadius: 12)
                            .fill(item.1)
                            .frame(width: 80, height: 80)
                            .overlay {
                                Image(systemName: "paintpalette.fill")
                                    .font(.system(size: 24))
                                    .foregroundStyle(.white)
                            }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text(item.0)
                                .font(.headline)
                            
                            Text("サンプルテキスト")
                                .foregroundStyle(item.1)
                            
                            Image(systemName: "star.fill")
                                .foregroundStyle(item.1)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding()
        }
        .background(Color.appBackground)
    }
}

#Preview {
    RGBColor()
}
