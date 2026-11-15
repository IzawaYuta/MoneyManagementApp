
import SwiftUI

// MARK: - 日付ナビゲーター(カプセル型)
/// 「‹ 2026年11月15日 ›」を1つの白いカプセルにまとめた日付の切り替え部品。
/// - 左右の矢印: 前日・翌日へ移動
/// - 日付部分のタップ: `onTapDate` を呼ぶ(日付選択シートを開く用途)
struct DateCapsuleNavigator: View {
    @Binding var date: Date
    let onTapDate: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            arrowButton(systemName: "chevron.left", label: "前の日", days: -1)
            
            Button(action: onTapDate) {
                Text(
                    date.formatted(
                        .dateTime
                            .year()
                            .month()
                            .day()
                            .locale(Locale(identifier: "ja_JP"))
                    )
                )
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.black)
                .frame(minWidth: 150)
                .frame(height: 40)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("日付を選択します")
            
            arrowButton(systemName: "chevron.right", label: "次の日", days: 1)
        }
        .padding(2)
        .background(
            Capsule()
                .fill(Color.white)
                .shadow(color: .black.opacity(0.15), radius: 3, y: 1)
        )
    }
    
    private func arrowButton(systemName: String, label: String, days: Int) -> some View {
        Button {
            date = Calendar.current.date(byAdding: .day, value: days, to: date) ?? date
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.black)
                .frame(width: 40, height: 40)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

// MARK: - Preview
#Preview {
    struct Demo: View {
        @State private var date = Date()
        var body: some View {
            ZStack {
                LinearGradient(
                    colors: [.red, .orange],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .opacity(0.8)
                .ignoresSafeArea()
                
                DateCapsuleNavigator(date: $date) { }
            }
        }
    }
    return Demo()
}
