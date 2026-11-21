
import SwiftUI
import SwiftData
import Charts

// MARK: - Screen

struct MonthlyChartView: View {
    @Query(sort: \Transaction.date) private var allTransactions: [Transaction]
    // 色の割り当て用。並び順(sortIndex → 名前)で安定させる
    @Query(sort: [SortDescriptor(\Category.sortIndex), SortDescriptor(\Category.name)])
    private var categories: [Category]
    
    @State private var month: Date = Date()
    @State private var transactionType: TransactionType = .expense
    @State private var selectedID: UUID?
    
    /// カテゴリーの色。公開後は順番・色を変更しないこと(将来のcolorHex移行で固定するため)
    private static let palette: [Color] = [
        Color(hex: 0x3B6FB6), Color(hex: 0xE8833A), Color(hex: 0x8A5CC2),
        Color(hex: 0x2E9E8F), Color(hex: 0xD9A92E), Color(hex: 0xC2547A),
        Color(hex: 0x1F8A4C), Color(hex: 0x8892A0), Color(hex: 0x2B8FD6),
        Color(hex: 0xB5452F), Color(hex: 0x7A8F1F), Color(hex: 0x5B4FCF)
    ]
    
    /// カテゴリーの並び順で色を割り当てる(12個までは重ならない)
    private func color(for id: UUID) -> Color {
        guard let index = categories.firstIndex(where: { $0.id == id }) else {
            return Color(.systemGray)   // 削除済みカテゴリー
        }
        return Self.palette[index % Self.palette.count]
    }
    
    // MARK: 集計
    
    /// 選択中の月・種別(収入/支出)で絞り込み、カテゴリーごとに合計
    private var summaries: [CategorySummary] {
        MonthlyChartService.summaries(from: allTransactions, month: month, type: transactionType)
    }
    
    // MARK: Body
    
    var body: some View {
        let items = summaries
        let total = items.reduce(0) { $0 + $1.amount }
        
        NavigationStack {
            VStack(spacing: 0) {
                monthHeader
                totalsSummary(total: total)
                pieChart(items: items, total: total)
                    .frame(height: 240)
                    .padding(.vertical, 12)
                recordList(items: items)
            }
            .padding(.horizontal, 20)
            .background(Color(uiColor: .systemGray5))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Picker("種別", selection: $transactionType) {
                        ForEach(TransactionType.allCases, id: \.self) {
                            Text($0.rawValue).tag($0)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 180)
                }
            }
            .onChange(of: transactionType) { _, _ in
                selectedID = nil
            }
            // データ変更でカテゴリーが消えた場合に選択を解除
            .onChange(of: items.map(\.id)) { _, ids in
                if let id = selectedID, !ids.contains(id) { selectedID = nil }
            }
        }
    }
    
    private func colorFromHex(_ hex: String) -> Color {
        let value = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let number = UInt64(value, radix: 16) ?? 0
        
        return Color(
            .sRGB,
            red: Double((number >> 16) & 0xFF) / 255,
            green: Double((number >> 8) & 0xFF) / 255,
            blue: Double(number & 0xFF) / 255,
            opacity: 1
        )
    }
    
    // MARK: Header
    
    private var monthHeader: some View {
        HStack {
            Button {
                changeMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.black)
                    .frame(width: 32, height: 32)
                    .background(Color(uiColor: .systemGray6))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            Text(month.formatted(.dateTime.year().month().locale(Locale(identifier: "ja_JP"))))
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.black)
            
            Spacer()
            
            Button {
                changeMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.black)
                    .frame(width: 32, height: 32)
                    .background(Color(uiColor: .systemGray6))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 30)
    }
    
    private func changeMonth(by value: Int) {
        if let next = Calendar.current.date(byAdding: .month, value: value, to: month) {
            month = next
            selectedID = nil
        }
    }
    
    // MARK: Totals
    
    private func totalsSummary(total: Int) -> some View {
        let isIncome = transactionType == .income
        return totalColumn(title: "\(transactionType.rawValue)合計", amount: total,
                           prefix: isIncome ? "+" : "-",
                           color: Color.primary)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemBackground)))
        .padding(.top, 12)
    }
    
    private func totalColumn(title: String, amount: Int, prefix: String, color: Color) -> some View {
        VStack(spacing: 2) {
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
    
    @ViewBuilder
    private func pieChart(items: [CategorySummary], total: Int) -> some View {
        if items.isEmpty {
            ZStack {
                Circle()
                    .stroke(Color(.systemGray4), style: StrokeStyle(lineWidth: 2, dash: [6, 6]))
                    .padding(12)
                Text("データがありません")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        } else {
            Chart(items) { item in
                SectorMark(
                    angle: .value("金額", item.amount),
                    outerRadius: .ratio(radiusRatio(for: item.id)),
                    angularInset: 1.5
                )
                .cornerRadius(4)
                .foregroundStyle(colorFromHex(item.color))
                .opacity(opacity(for: item.id))
            }
            .chartLegend(.hidden)
            .animation(.spring(duration: 0.35), value: selectedID)
            // 扇形の上だけを反応させるため、自前でヒットテストする
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { location in
                            guard let plot = proxy.plotFrame else { return }
                            handleTap(at: location, plotFrame: geo[plot],
                                      items: items, total: total)
                        }
                }
            }
            .overlay { selectionLabel(items: items, total: total) }
        }
    }
    
    /// タップ位置が扇形の内側にあるときだけ選択を切り替える
    private func handleTap(at point: CGPoint, plotFrame: CGRect,
                           items: [CategorySummary], total: Int) {
        let center = CGPoint(x: plotFrame.midX, y: plotFrame.midY)
        let fullRadius = min(plotFrame.width, plotFrame.height) / 2
        
        guard let tapped = MonthlyChartService.tappedCategoryID(
            at: point, center: center, fullRadius: fullRadius,
            items: items, selectedID: selectedID
        ) else { return }
        
        withAnimation(.spring(duration: 0.35)) {
            // 強調中をタップで解除、別カテゴリーなら強調を移す
            selectedID = (selectedID == tapped) ? nil : tapped
        }
    }

    
    @ViewBuilder
    private func selectionLabel(items: [CategorySummary], total: Int) -> some View {
        if let selected = items.first(where: { $0.id == selectedID }) {
            VStack(spacing: 2) {
                Text(selected.name)
                    .font(.headline)
                Text("¥\(selected.amount.formatted())")
                    .font(.subheadline.monospacedDigit())
                Text(MonthlyChartService.percentText(amount: selected.amount, total: total))
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
    private func radiusRatio(for id: UUID) -> Double {
        MonthlyChartService.radiusRatio(for: id, selectedID: selectedID)
    }
    
    /// 選択中以外は薄くする
    private func opacity(for id: UUID) -> Double {
        MonthlyChartService.opacity(for: id, selectedID: selectedID)
    }
    
    // MARK: List
    
    private func recordList(items: [CategorySummary]) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(items) { item in
                    recordRow(item)
                    if item.id != items.last?.id {
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
    
    private func recordRow(_ item: CategorySummary) -> some View {
        let isDimmed = selectedID != nil && selectedID != item.id
        let isIncome = transactionType == .income
        let color = colorFromHex(item.color)
        
        return HStack(spacing: 12) {
            // Image
            Image(systemName: item.imageName)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 40, height: 40)
                .background(Circle().fill(color.opacity(0.15)))
            
            // カテゴリー
            Text(item.name)
                .font(.body.weight(.medium))
            
            Spacer()
            
            // 金額
            Text("\(isIncome ? "+" : "-")\(item.amount.formatted())")
                .font(.body.bold().monospacedDigit())
            //                .foregroundStyle(isIncome ? Color(hex: 0x1F6E40) : .primary)
                .foregroundStyle(Color.primary)
        }
        .frame(height: 52)
        .opacity(isDimmed ? 0.4 : 1.0)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(duration: 0.35)) {
                selectedID = (selectedID == item.id) ? nil : item.id
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

// MARK: - Preview

@MainActor
enum PreviewData {
    static var container: ModelContainer {
        let container = try! ModelContainer(
            for: Category.self, PaymentMethod.self, Transaction.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let samples: [(String, String, Int, TransactionType)] = [
            ("給与", "yensign.circle", 280_000, .income),
            ("副業", "laptopcomputer", 45_000, .income),
            ("住居費", "house", 72_000, .expense),
            ("食費", "fork.knife", 48_200, .expense),
            ("娯楽", "play.circle", 21_800, .expense),
            ("交通費", "bus", 12_400, .expense),
            ("日用品", "bag", 9_600, .expense),
            ("通信費", "iphone", 8_900, .expense)
        ]
        for (index, sample) in samples.enumerated() {
            let category = Category(name: sample.0, imageName: sample.1, colorHex: "#342A40", sortIndex: index)
            container.mainContext.insert(category)
            container.mainContext.insert(
                Transaction(
                    date: Date(),
                    amount: sample.2,
                    type: sample.3,
                    categoryID: category.id,
                    categoryName: category.name,
                    categoryImageName: category.imageName,
                    categoryColorHex: category.colorHex
                )
            )
        }
        return container
    }
}

#Preview {
    MonthlyChartView()
        .modelContainer(PreviewData.container)
}
