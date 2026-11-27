
import SwiftUI

/// 頻度を選ぶ画面(編集画面から push で開く)。
/// 「カスタム」を選んだときは、この画面を表示したまま sheet を開き、
/// sheet の「完了」で sheet を閉じてから、前の画面に戻る。
struct FrequencySelectionView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var frequency: FixedCostFrequency
    @Binding var customInterval: Int
    @Binding var customUnit: FixedCostCustomUnit
    let startDate: Date

    @State private var showCustomSheet = false
    /// sheet で「完了」を押したかどうか(sheet が閉じたあとに画面を戻すために使う)
    @State private var shouldDismissAfterSheet = false

    var body: some View {
        List {
            ForEach(FixedCostFrequency.allCases) { option in
                Button {
                    select(option)
                } label: {
                    HStack {
                        Text(title(option))
                        Spacer()
                        if frequency == option {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.tint)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .foregroundStyle(.primary)
            }
        }
        .navigationTitle("頻度")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showCustomSheet, onDismiss: {
            // sheet が閉じ終わってから、前の画面に戻る
            if shouldDismissAfterSheet {
                shouldDismissAfterSheet = false
                dismiss()
            }
        }) {
            CustomFrequencySheet(interval: customInterval, unit: customUnit) { interval, unit in
                customInterval = interval
                customUnit = unit
                frequency = .custom
                shouldDismissAfterSheet = true
            }
        }
    }

    private func select(_ option: FixedCostFrequency) {
        if option == .custom {
            // この画面は残したまま sheet を出す(頻度はまだ変えない)
            showCustomSheet = true
        } else {
            frequency = option
            dismiss()
        }
    }

    private func title(_ option: FixedCostFrequency) -> String {
        option == .custom ? "カスタム" : option.label(startDate: startDate)
    }
}

#Preview {
    @Previewable @State var frequency: FixedCostFrequency = .monthly
    @Previewable @State var interval = 3
    @Previewable @State var unit: FixedCostCustomUnit = .month

    NavigationStack {
        FrequencySelectionView(
            frequency: $frequency,
            customInterval: $interval,
            customUnit: $unit,
            startDate: .now
        )
    }
}
