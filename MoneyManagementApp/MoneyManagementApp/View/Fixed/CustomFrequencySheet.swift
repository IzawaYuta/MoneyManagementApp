
import SwiftUI

/// 頻度で「カスタム」を選んだときに開くsheet。
/// 数字(間隔)と、日・週・月・年の単位を選ぶ。
struct CustomFrequencySheet: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocused: Bool

    @State private var intervalText: String
    @State private var unit: FixedCostCustomUnit

    /// 「完了」を押したとき(間隔, 単位)
    private let onDone: (Int, FixedCostCustomUnit) -> Void

    init(interval: Int,
         unit: FixedCostCustomUnit,
         onDone: @escaping (Int, FixedCostCustomUnit) -> Void) {
        self._intervalText = State(initialValue: String(interval))
        self._unit = State(initialValue: unit)
        self.onDone = onDone
    }

    /// 1〜999 のときだけ有効
    private var interval: Int? {
        guard let value = Int(intervalText), (1...999).contains(value) else { return nil }
        return value
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("間隔") {
                        TextField("1", text: $intervalText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .focused($isFocused)
                    }

                    Picker("単位", selection: $unit) {
                        ForEach(FixedCostCustomUnit.allCases) { unit in
                            Text(unit.title).tag(unit)
                        }
                    }
                } footer: {
                    if let interval {
                        Text("\(interval)\(unit.suffix)に記録されます")
                    } else {
                        Text("1〜999の数字を入力してください")
                    }
                }
            }
            .navigationTitle("カスタム")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") {
                        guard let interval else { return }
                        onDone(interval, unit)
                        dismiss()
                    }
                    .disabled(interval == nil)
                }
            }
            // 数字以外は入力できないようにする(3桁まで)
            .onChange(of: intervalText) { _, newValue in
                let filtered = String(newValue.filter(\.isNumber).prefix(3))
                if filtered != newValue { intervalText = filtered }
            }
            .onAppear { isFocused = true }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    CustomFrequencySheet(interval: 3, unit: .month) { _, _ in }
}
