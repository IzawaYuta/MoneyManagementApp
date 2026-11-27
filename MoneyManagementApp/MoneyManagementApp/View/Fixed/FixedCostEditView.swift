
import SwiftUI
import SwiftData

// MARK: - 固定費編集画面

// MARK: - 頻度・土日祝の扱い

enum FixedCostFrequency: String, CaseIterable, Identifiable, Codable {
    case once       // 1度のみ
    case daily      // 毎日
    case weekly     // 毎週
    case monthly    // 毎月
    case yearly     // 毎年
    case biweekly   // 隔週
    case custom     // カスタム
    
    var id: String { rawValue }
}

/// カスタムの単位(日・週・月・年)
enum FixedCostCustomUnit: String, CaseIterable, Identifiable, Codable {
    case day, week, month, year
    
    var id: String { rawValue }
    
    /// Pickerの表示
    var title: String {
        switch self {
        case .day:   return "日"
        case .week:  return "週"
        case .month: return "月"
        case .year:  return "年"
        }
    }
    
    /// 「3日ごと」「2週間ごと」「3か月ごと」「1年ごと」の語尾
    var suffix: String {
        switch self {
        case .day:   return "日ごと"
        case .week:  return "週間ごと"
        case .month: return "か月ごと"
        case .year:  return "年ごと"
        }
    }
}

enum HolidayRule: String, CaseIterable, Identifiable, Codable {
    case previousBusinessDay   // 前の平日
    case nextBusinessDay       // 後の平日
    case asIs                  // 何もしない

    var id: String { rawValue }

    var title: String {
        switch self {
        case .previousBusinessDay: return "前の平日"
        case .nextBusinessDay:     return "後の平日"
        case .asIs:                return "何もしない"
        }
    }
}

/// 平日かどうかの判定。祝日も除外したい場合は、祝日判定を持つ実装に差し替える。
protocol BusinessDayChecking {
    func isBusinessDay(_ date: Date, calendar: Calendar) -> Bool
}

/// 標準実装: 土日のみ休みとして扱う(祝日は未対応)
struct WeekdayOnlyBusinessDays: BusinessDayChecking {
    func isBusinessDay(_ date: Date, calendar: Calendar) -> Bool {
        !calendar.isDateInWeekend(date)
    }
}

// MARK: - 編集中の下書き

struct FixedCostDraft: Equatable {
    var title = ""
    var type: TransactionType = .expense
    var amount = 0
    var category: Category?
    var paymentMethod: PaymentMethod?
    var memo = ""
    var frequency: FixedCostFrequency = .monthly
    var customInterval = 3
    var customUnit: FixedCostCustomUnit = .month
    var startDate = Calendar.current.startOfDay(for: .now)
    var endDate: Date?
    var holidayRule: HolidayRule = .asIs
    var isEnabled = true

    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty && amount > 0
    }
}

extension FixedCostDraft {
    /// n回目の記録日(土日祝の調整前)。29〜31日指定の月は、その月の末日に記録する。
    func occurrence(_ n: Int, calendar: Calendar) -> Date? {
        guard let step = frequency.interval(customInterval: customInterval, customUnit: customUnit) else {
            return n == 0 ? startDate : nil   // 1度のみ: 開始日の1回だけ
        }
        let count = step.value * n
        switch step.unit {
        case .day:   return calendar.date(byAdding: .day, value: count, to: startDate)
        case .week:  return calendar.date(byAdding: .day, value: 7 * count, to: startDate)
        case .month: return shifted(byMonths: count, calendar: calendar)
        case .year:  return shifted(byMonths: 12 * count, calendar: calendar)
        }
    }
    
    private func shifted(byMonths months: Int, calendar: Calendar) -> Date? {
        let comps = calendar.dateComponents([.year, .month, .day], from: startDate)
        guard let firstOfMonth = calendar.date(from: DateComponents(year: comps.year, month: comps.month, day: 1)),
              let target = calendar.date(byAdding: .month, value: months, to: firstOfMonth),
              let days = calendar.range(of: .day, in: .month, for: target)?.count
        else { return nil }
        var result = calendar.dateComponents([.year, .month], from: target)
        result.day = min(comps.day ?? 1, days)
        return calendar.date(from: result)
    }
    
    /// 土日祝の設定に合わせて記録日をずらす
    func adjusted(_ date: Date, calendar: Calendar, businessDays: BusinessDayChecking) -> Date {
        let step: Int
        switch holidayRule {
        case .asIs: return date
        case .previousBusinessDay: step = -1
        case .nextBusinessDay: step = 1
        }
        var current = date
        var guardCount = 0
        while !businessDays.isBusinessDay(current, calendar: calendar), guardCount < 14 {
            guard let next = calendar.date(byAdding: .day, value: step, to: current) else { break }
            current = next
            guardCount += 1
        }
        return current
    }
    
    /// 開始日がずっと前でも、探し始める回を絞る(毎日などで上限に達しないように)
    private func startIndex(for today: Date, calendar: Calendar) -> Int {
        guard let step = frequency.interval(customInterval: customInterval, customUnit: customUnit) else {
            return 0
        }
        let days = calendar.dateComponents([.day], from: startDate, to: today).day ?? 0
        guard days > 0 else { return 0 }
        switch step.unit {
        case .day:   return max(0, days / step.value - 1)
        case .week:  return max(0, days / (7 * step.value) - 1)
        case .month, .year: return 0
        }
    }
    
    func nextRecord(from today: Date,
                    calendar: Calendar,
                    businessDays: BusinessDayChecking) -> (base: Date, actual: Date)? {
        let start = calendar.startOfDay(for: today)
        let first = startIndex(for: today, calendar: calendar)
        for n in first..<(first + 1200) {
            guard let base = occurrence(n, calendar: calendar) else { return nil }
            if let end = endDate, base > end { return nil }
            if base < start { continue }
            return (base, adjusted(base, calendar: calendar, businessDays: businessDays))
        }
        return nil
    }
}

// MARK: - 編集画面

struct FixedCostEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Category.sortIndex) private var categories: [Category]
    @Query private var paymentMethods: [PaymentMethod]
    
    @FocusState private var titleFocus: Bool

    private let initial: FixedCostDraft
    private let businessDays: BusinessDayChecking
    private let onSave: (FixedCostDraft) -> Void
    private let onDelete: (() -> Void)?

    @State private var draft: FixedCostDraft
    @State private var showDiscardAlert = false
    @State private var showDeleteAlert = false

    private var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.locale = Locale(identifier: "ja_JP")
        return c
    }

    /// 新規追加: draft を省略 / 編集: 既存の内容を渡し、onDelete も渡す
    init(draft: FixedCostDraft = FixedCostDraft(),
         businessDays: BusinessDayChecking = WeekdayOnlyBusinessDays(),
         onSave: @escaping (FixedCostDraft) -> Void,
         onDelete: (() -> Void)? = nil) {
        self.initial = draft
        self._draft = State(initialValue: draft)
        self.businessDays = businessDays
        self.onSave = onSave
        self.onDelete = onDelete
    }

    var body: some View {
        NavigationStack {
            Form {
                titleSection
                amountSection
                scheduleSection
                holidaySection
                actionSection
            }
            .navigationTitle("固定費")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { titleFocus = true }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        if draft == initial { dismiss() } else { showDiscardAlert = true }
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.red)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    moreMenu
                }
            }
            .alert("変更を破棄しますか?", isPresented: $showDiscardAlert) {
                Button("破棄", role: .destructive) { dismiss() }
                Button("編集を続ける", role: .cancel) {}
            }
            .alert("この固定費を削除しますか?", isPresented: $showDeleteAlert) {
                Button("削除", role: .destructive) {
                    onDelete?()
                    dismiss()
                }
                Button("キャンセル", role: .cancel) {}
            }
        }
        .interactiveDismissDisabled(draft != initial)
    }

    // MARK: Sections

    private var titleSection: some View {
        Section("タイトル") {
            TextField("例: 家賃", text: $draft.title)
                .focused($titleFocus)
        }
    }

    private var amountSection: some View {
        Section {
            Picker("収支", selection: $draft.type) {
                Text("収入").tag(TransactionType.income)
                Text("支出").tag(TransactionType.expense)
            }
            
            LabeledContent("金額") {
                TextField("¥0", text: amountBinding)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
            }

            Picker("カテゴリー", selection: $draft.category) {
                Text("未設定").tag(Category?.none)
                ForEach(categories) { category in
                    Label {
                        Text(category.name)
                    } icon: {
                        Circle()
                            .fill(fixedCostColor(hex: category.colorHex))
                            .frame(width: 12, height: 12)
                    }
                    .tag(Optional(category))
                }
            }
            .pickerStyle(.navigationLink)

            Picker("支払方法", selection: $draft.paymentMethod) {
                Text("未設定").tag(PaymentMethod?.none)
                ForEach(paymentMethods) { method in
                    Text(method.name).tag(Optional(method))
                }
            }
            .pickerStyle(.navigationLink)

            TextField("メモ", text: $draft.memo)
                .lineLimit(1)
        }
    }

    private var scheduleSection: some View {
        Section("スケジュール") {
            NavigationLink {
                FrequencySelectionView(
                    frequency: $draft.frequency,
                    customInterval: $draft.customInterval,
                    customUnit: $draft.customUnit,
                    startDate: draft.startDate
                )
            } label: {
                LabeledContent("頻度") {
                    Text(draft.frequency.label(
                        startDate: draft.startDate,
                        customInterval: draft.customInterval,
                        customUnit: draft.customUnit
                    ))
                }
            }
            
            DatePicker("開始日", selection: $draft.startDate, displayedComponents: .date)
                .environment(\.locale, Locale(identifier: "ja_JP"))

            LabeledContent("終了日") {
                if let end = draft.endDate {
                    HStack(spacing: 8) {
                        DatePicker(
                            "終了日",
                            selection: Binding(get: { end }, set: { draft.endDate = $0 }),
                            in: draft.startDate...,
                            displayedComponents: .date
                        )
                        .labelsHidden()
                        .environment(\.locale, Locale(identifier: "ja_JP"))

                        Button {
                            draft.endDate = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                        }
                        .buttonStyle(.borderless)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("終了日を解除")
                    }
                } else {
                    Button("設定しない") {
                        draft.endDate = calendar.date(byAdding: .year, value: 1, to: draft.startDate)
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var holidaySection: some View {
        Section {
            Picker("土日祝に当たる場合", selection: $draft.holidayRule) {
                ForEach(HolidayRule.allCases) { rule in
                    Text(rule.title).tag(rule)
                }
            }
        } footer: {
            Text(nextRecordFooter)
        }
    }
    
    private var actionSection: some View {
        Section {
            Button {
                onSave(draft)
                dismiss()
            } label: {
                Text("保存")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .controlSize(.large)
            .disabled(!draft.isValid)
            .listRowBackground(Color.clear)

            if onDelete != nil {
                Button("この固定費を削除", role: .destructive) {
                    showDeleteAlert = true
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
            }
        }
    }

    // MARK: 右上の有効/無効ボタン

    private var moreMenu: some View {
        Menu {
            if draft.isEnabled {
                // 有効中: 赤い点 + 「無効にする」
                Button(role: .destructive) {
                    draft.isEnabled = false
                } label: {
                    Label("無効にする", systemImage: "circle.fill")
                }
            } else {
                // 無効中: 逆に「有効にする」
                Button {
                    draft.isEnabled = true
                } label: {
                    Label("有効にする", systemImage: "circle")
                }
            }
        } label: {
            Image(systemName: "ellipsis")
        }
        .accessibilityLabel("その他")
    }
    
    // MARK: 表示用

    /// 「¥1,490」のように、入力中も ¥ とカンマ区切りで表示する
    private var amountBinding: Binding<String> {
        Binding(
            get: {
                guard draft.amount > 0,
                      let text = Self.amountFormatter.string(from: NSNumber(value: draft.amount))
                else { return "" }
                return "¥" + text
            },
            set: { newValue in
                let digits = newValue.filter(\.isNumber).prefix(9)
                draft.amount = Int(String(digits)) ?? 0
            }
        )
    }
    
    private var nextRecordFooter: String {
        guard let next = draft.nextRecord(from: .now, calendar: calendar, businessDays: businessDays) else {
            return "今後の記録予定はありません。"
        }
        let actual = Self.longDateFormatter.string(from: next.actual)
        if calendar.isDate(next.base, inSameDayAs: next.actual) {
            return "次回の記録: \(actual)"
        }
        let base = Self.shortDateFormatter.string(from: next.base)
        let direction = draft.holidayRule == .previousBusinessDay ? "前" : "後"
        return "次回の記録: \(actual)。\(base)は土日祝のため、\(direction)の平日に記録されます。"
    }

    private static let amountFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = Locale(identifier: "ja_JP")
        return f
    }()

    private static let longDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "yyyy年M月d日(E)"
        return f
    }()

    private static let shortDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "M月d日(E)"
        return f
    }()
}

// MARK: - 色("#FF6B6B" 形式の文字列から Color)

private func fixedCostColor(hex: String?) -> Color {
    guard let hex else { return .gray }
    let trimmed = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
    guard trimmed.count == 6, let value = UInt32(trimmed, radix: 16) else { return .gray }
    return Color(
        red: Double((value >> 16) & 0xFF) / 255,
        green: Double((value >> 8) & 0xFF) / 255,
        blue: Double(value & 0xFF) / 255
    )
}

#Preview {
    FixedCostEditView(onSave: { _ in })
        .modelContainer(for: [Category.self, PaymentMethod.self], inMemory: true)
}
