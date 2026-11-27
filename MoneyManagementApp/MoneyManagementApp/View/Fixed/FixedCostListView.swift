
import SwiftUI
import SwiftData

// MARK: - 頻度の表示(編集画面と共通で使える)

extension FixedCostFrequency {
    /// 頻度を「値 + 単位」で表す(日付の計算に使う)
    func interval(customInterval: Int,
                  customUnit: FixedCostCustomUnit) -> (value: Int, unit: FixedCostCustomUnit)? {
        switch self {
        case .once:     return nil
        case .daily:    return (1, .day)
        case .weekly:   return (1, .week)
        case .biweekly: return (2, .week)
        case .monthly:  return (1, .month)
        case .yearly:   return (1, .year)
        case .custom:   return (max(customInterval, 1), customUnit)
        }
    }
    
    /// 「毎日」「毎週 土曜日」「隔週 土曜日」「毎月 25日」「毎年 4月1日」「3か月ごと」
    func label(startDate: Date,
               customInterval: Int = 1,
               customUnit: FixedCostCustomUnit = FixedCostCustomUnit.month) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "ja_JP")
        let comps = calendar.dateComponents([.month, .day, .weekday], from: startDate)
        let weekday = calendar.weekdaySymbols[(comps.weekday ?? 1) - 1]
        
        switch self {
        case .once:     return "1度のみ"
        case .daily:    return "毎日"
        case .weekly:   return "毎週 \(weekday)"
        case .biweekly: return "隔週 \(weekday)"
        case .monthly:  return "毎月 \(comps.day ?? 1)日"
        case .yearly:   return "毎年 \(comps.month ?? 1)月\(comps.day ?? 1)日"
        case .custom:   return "\(max(customInterval, 1))\(customUnit.suffix)"
        }
    }
}

// MARK: - 一覧画面

struct FixedCostListView: View {
    @Query(sort: \FixedCost.title) private var fixedCosts: [FixedCost]
    
    @State private var showFixedCostEditView: Bool = false
    /// 行をタップしたとき(編集画面を開く)
    let onSelect: (FixedCost) -> Void
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(fixedCosts) { cost in
                    Button {
                        onSelect(cost)
                    } label: {
                        FixedCostRow(cost: cost)
                    }
                    .foregroundStyle(.primary)
                }
            }
            .navigationTitle("固定費")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        showFixedCostEditView.toggle()
                    }) {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("固定費を追加")
                }
            }
            .fullScreenCover(isPresented: $showFixedCostEditView) {
                FixedCostEditView(onSave: {_ in })
            }
            .overlay {
                if fixedCosts.isEmpty {
                    ContentUnavailableView(
                        "固定費がありません",
                        systemImage: "calendar.badge.clock",
                        description: Text("「＋」から登録すると、指定した日に自動で記録されます")
                    )
                }
            }
        }
    }
}

// MARK: - 行(タイトル・頻度・金額)

private struct FixedCostRow: View {
    let cost: FixedCost
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(cost.title)
                Text(cost.frequency.label(startDate: cost.startDate,
                                          customInterval: cost.customInterval,
                                          customUnit: cost.customUnit))
                .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("¥\(cost.amount.formatted(.number))")
                .monospacedDigit()
        }
        .contentShape(Rectangle())
        // 無効の固定費は薄く表示する
        .opacity(cost.isEnabled ? 1 : 0.5)
    }
}

// MARK: - Preview

private func previewCost(_ title: String,
                         _ amount: Int,
                         _ frequency: FixedCostFrequency,
                         month: Int = 12,
                         day: Int,
                         isEnabled: Bool = true) -> FixedCost {
    let cost = FixedCost()
    cost.title = title
    cost.amount = amount
    cost.frequency = frequency
    cost.startDate = Calendar.current.date(from: DateComponents(year: 2026, month: month, day: day)) ?? .now
    cost.isEnabled = isEnabled
    return cost
}

#Preview("固定費あり") {
    let container = try! ModelContainer(
        for: FixedCost.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    [
        previewCost("家賃", 68_000, .monthly, day: 25),
        previewCost("携帯電話", 4_980, .monthly, day: 10),
        previewCost("動画配信", 1_490, .monthly, day: 5),
        previewCost("自動車保険", 96_000, .yearly, month: 4, day: 1),
        previewCost("ジム", 2_000, .weekly, day: 5, isEnabled: false)
    ].forEach { container.mainContext.insert($0) }
    
    return FixedCostListView(onSelect: { _ in })
        .modelContainer(container)
}

#Preview("固定費なし") {
    let container = try! ModelContainer(
        for: FixedCost.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    return FixedCostListView(onSelect: { _ in })
        .modelContainer(container)
}
