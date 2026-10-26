
import SwiftUI
import Charts

// MARK: - Model

enum RecordType: String, CaseIterable, Identifiable {
    case income = "収入"
    case expense = "支出"
    var id: String { rawValue }
}

enum MoneyCategory: String, CaseIterable, Identifiable {
    // 収入
    case salary = "給与"
    case sideJob = "副業"
    case extra = "臨時収入"
    // 支出
    case housing = "住居費"
    case food = "食費"
    case entertainment = "娯楽"
    case transport = "交通費"
    case daily = "日用品"
    case telecom = "通信費"
    
    var id: String { rawValue }
    
    var color: Color {
        switch self {
        case .salary:        return Color(hex: 0x1F8A4C)
        case .sideJob:       return Color(hex: 0x2B8FD6)
        case .extra:         return Color(hex: 0xC2547A)
        case .housing:       return Color(hex: 0x3B6FB6)
        case .food:          return Color(hex: 0xE8833A)
        case .entertainment: return Color(hex: 0x8A5CC2)
        case .transport:     return Color(hex: 0x2E9E8F)
        case .daily:         return Color(hex: 0xD9A92E)
        case .telecom:       return Color(hex: 0x8892A0)
        }
    }
    
    var systemImage: String {
        switch self {
        case .salary:        return "yensign.circle"
        case .sideJob:       return "laptopcomputer"
        case .extra:         return "gift"
        case .housing:       return "house"
        case .food:          return "fork.knife"
        case .entertainment: return "play.circle"
        case .transport:     return "bus"
        case .daily:         return "bag"
        case .telecom:       return "iphone"
        }
    }
}

struct MoneyRecord: Identifiable {
    let id = UUID()
    let category: MoneyCategory
    let amount: Int          // 常に正の値
    let type: RecordType
}

// MARK: - Dummy data

enum DummyData {
    static let records: [MoneyRecord] = [
        // 収入
        .init(category: .salary,        amount: 280_000, type: .income),
        .init(category: .sideJob,       amount: 45_000,  type: .income),
        .init(category: .extra,         amount: 12_000,  type: .income),
        // 支出
        .init(category: .housing,       amount: 72_000,  type: .expense),
        .init(category: .food,          amount: 48_200,  type: .expense),
        .init(category: .entertainment, amount: 21_800,  type: .expense),
        .init(category: .transport,     amount: 12_400,  type: .expense),
        .init(category: .daily,         amount: 9_600,   type: .expense),
        .init(category: .telecom,       amount: 8_900,   type: .expense)
    ]
}

// MARK: - Screen

struct MonthlyChartView: View {
    @State private var month: Date = {
        var c = DateComponents(); c.year = 2026; c.month = 10; c.day = 1
        return Calendar.current.date(from: c) ?? .now
    }()
    @State private var recordType: RecordType = .expense
    @State private var selectedCategory: MoneyCategory?
    
    private let allRecords = DummyData.records
    private var records: [MoneyRecord] { allRecords.filter { $0.type == recordType } }
    private var total: Int { records.reduce(0) { $0 + $1.amount } }
    
    /// 月の総合計(種別ごと)。セグメントの選択に関わらず常に両方を表示
    private func monthTotal(of type: RecordType) -> Int {
        allRecords.filter { $0.type == type }.reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                monthHeader
                totalsSummary
                pieChart
                    .frame(height: 240)
                    .padding(.vertical, 12)
                recordList
            }
            .padding(.horizontal, 20)
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Picker("種別", selection: $recordType) {
                        ForEach(RecordType.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 180)
                }
            }
            .onChange(of: recordType) { _, _ in
                selectedCategory = nil
            }
        }
    }
    
    // MARK: Header
    
    private var monthHeader: some View {
        HStack {
            Button { changeMonth(by: -1) } label: {
                Image(systemName: "chevron.left")
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color(.systemBackground)))
            }
            .accessibilityLabel("前月")
            
            Spacer()
            Text(month.formatted(.dateTime.year().month().locale(Locale(identifier: "ja_JP"))))
                .font(.title2.bold())
            Spacer()
            
            Button { changeMonth(by: 1) } label: {
                Image(systemName: "chevron.right")
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color(.systemBackground)))
            }
            .accessibilityLabel("翌月")
        }
        .foregroundStyle(.primary)
        .padding(.top, 8)
    }
    
    private func changeMonth(by value: Int) {
        if let next = Calendar.current.date(byAdding: .month, value: value, to: month) {
            month = next
            selectedCategory = nil
        }
    }
    
    // MARK: Totals
    
    private var totalsSummary: some View {
        let isIncome = recordType == .income
        return totalColumn(title: "\(recordType.rawValue)合計", amount: total,
                           prefix: isIncome ? "+" : "-",
                           color: isIncome ? Color(hex: 0x1F6E40) : .primary)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemBackground)))
        .padding(.top, 12)
    }
    
    private func totalColumn(title: String, amount: Int, prefix: String, color: Color) -> some View {
        VStack(spacing: 5) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("\(prefix)¥\(amount.formatted())")
                .font(.headline.monospacedDigit())
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
    
    // MARK: Pie chart
    
    private var pieChart: some View {
        Chart(records) { item in
            SectorMark(
                angle: .value("金額", item.amount),
                outerRadius: .ratio(radiusRatio(for: item.category)),
                angularInset: 1.5
            )
            .cornerRadius(4)
            .foregroundStyle(item.category.color)
            .opacity(opacity(for: item.category))
        }
        .chartLegend(.hidden)
        .animation(.spring(duration: 0.35), value: selectedCategory)
        .animation(.spring(duration: 0.35), value: recordType)
        // 扇形の上だけを反応させるため、自前でヒットテストする
        .chartOverlay { proxy in
            GeometryReader { geo in
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        guard let plot = proxy.plotFrame else { return }
                        handleTap(at: location, plotFrame: geo[plot])
                    }
            }
        }
        .overlay { selectionLabel }
    }
    
    /// タップ位置が扇形の内側にあるときだけ選択を切り替える
    private func handleTap(at point: CGPoint, plotFrame: CGRect) {
        let center = CGPoint(x: plotFrame.midX, y: plotFrame.midY)
        let fullRadius = min(plotFrame.width, plotFrame.height) / 2
        let dx = point.x - center.x
        let dy = point.y - center.y
        let distance = hypot(dx, dy)
        
        // 12時方向を0として時計回りの角度(0〜2π)
        var angle = atan2(dx, -dy)
        if angle < 0 { angle += 2 * .pi }
        let value = angle / (2 * .pi) * Double(total)
        
        guard let tapped = category(at: value) else { return }
        // 現在の表示半径(拡大・縮小後)の外側(余白)は無視
        guard distance <= fullRadius * radiusRatio(for: tapped) else { return }
        
        withAnimation(.spring(duration: 0.35)) {
            // 強調中をタップで解除、別カテゴリーなら強調を移す
            selectedCategory = (selectedCategory == tapped) ? nil : tapped
        }
    }
    
    @ViewBuilder
    private var selectionLabel: some View {
        if let selected = selectedCategory,
           let amount = records.first(where: { $0.category == selected })?.amount {
            VStack(spacing: 2) {
                Text(selected.rawValue)
                    .font(.headline)
                Text("¥\(amount.formatted())")
                    .font(.subheadline.monospacedDigit())
                Text(String(format: "%.1f%%", Double(amount) / Double(total) * 100))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .transition(.scale.combined(with: .opacity))
            .allowsHitTesting(false)
        }
    }
    
    /// 選択中は大きく、他は小さく、未選択時は標準
    private func radiusRatio(for category: MoneyCategory) -> Double {
        guard let selected = selectedCategory else { return 0.9 }
        return selected == category ? 1.0 : 0.8
    }
    
    /// 選択中以外は薄くする
    private func opacity(for category: MoneyCategory) -> Double {
        guard let selected = selectedCategory else { return 1.0 }
        return selected == category ? 1.0 : 0.3
    }
    
    /// 角度に対応する累計金額からカテゴリーを求める
    private func category(at value: Double) -> MoneyCategory? {
        var cumulative = 0.0
        for item in records {
            cumulative += Double(item.amount)
            if value <= cumulative { return item.category }
        }
        return nil
    }
    
    // MARK: List
    
    private var recordList: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(records) { record in
                    recordRow(record)
                    if record.id != records.last?.id {
                        Divider().padding(.leading, 56)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 20).fill(Color(.systemBackground)))
        }
        .scrollIndicators(.hidden)
        .padding(.bottom, 8)
    }
    
    private func recordRow(_ record: MoneyRecord) -> some View {
        let isDimmed = selectedCategory != nil && selectedCategory != record.category
        let isIncome = record.type == .income
        return HStack(spacing: 12) {
            // Image
            Image(systemName: record.category.systemImage)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(record.category.color)
                .frame(width: 40, height: 40)
                .background(Circle().fill(record.category.color.opacity(0.15)))
            
            // カテゴリー
            Text(record.category.rawValue)
                .font(.body.weight(.medium))
            
            Spacer()
            
            // 金額
            Text("\(isIncome ? "+" : "-")¥\(record.amount.formatted())")
                .font(.body.bold().monospacedDigit())
                .foregroundStyle(isIncome ? Color(hex: 0x1F6E40) : .primary)
        }
        .frame(height: 52)
        .opacity(isDimmed ? 0.4 : 1.0)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(duration: 0.35)) {
                selectedCategory = (selectedCategory == record.category) ? nil : record.category
            }
        }
    }
}

// MARK: - Helpers

extension Color {
    init(hex: UInt32) {
        self.init(
            red:   Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue:  Double(hex & 0xFF) / 255
        )
    }
}

#Preview {
    MonthlyChartView()
}
