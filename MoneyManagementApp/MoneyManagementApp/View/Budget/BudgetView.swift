import SwiftUI
import SwiftData

// MARK: - 予算管理画面
/// 上部: 月の選択(前月・翌月) / 総予算カード / カテゴリー別カード(リスト+バー)
/// データは Budget(期間ごとに1行) + Transaction(使用額) + Category(表示情報) から算出する。
struct BudgetView: View {
    @State private var month: Int = YearMonth.make(from: Date())
    /// 予算は支出のみ
    private let type = TransactionType.expense
    @State private var isShowingSetup = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                BudgetMonthCapsule(
                    month: month,
                    onPrevious: { month = YearMonth.previous(month) },
                    onNext: { month = YearMonth.next(month) }
                )
                BudgetMonthContent(month: month, type: type)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("予算")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingSetup = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("予算を設定")
                }
            }
            .sheet(isPresented: $isShowingSetup) {
                BudgetSetupSheet(initialMonth: month)
            }
        }
    }
}

// MARK: - 月の選択
private struct BudgetMonthHeader: View {
    let month: Int
    let onPrevious: () -> Void
    let onNext: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onPrevious) {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("前月")
            
            Spacer()
            Text("\(month / 100)年\(month % 100)月")
                .font(.headline)
            Spacer()
            
            Button(action: onNext) {
                Image(systemName: "chevron.right")
                    .font(.headline)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("翌月")
        }
        .padding(.horizontal, 12)
    }
}

// MARK: - 月ごとの内容
private struct BudgetMonthContent: View {
    let month: Int
    let type: TransactionType
    
    @Query private var budgets: [Budget]
    @Query(sort: \Category.sortIndex) private var categories: [Category]
    @Query private var transactions: [Transaction]
    
    init(month: Int, type: TransactionType) {
        self.month = month
        self.type = type
        
        // 取引はその月の範囲のみ取得(種別は列挙型のためメモリ上で絞り込む)
        let range = Self.dateRange(of: month)
        let start = range.lowerBound
        let end = range.upperBound
        _transactions = Query(filter: #Predicate<Transaction> { $0.date >= start && $0.date < end })
        
        // 予算は開始月が対象月以前のものを取得(終了月はメモリ上で判定)
        let m = month
        _budgets = Query(filter: #Predicate<Budget> { $0.startMonth <= m })
    }
    
    var body: some View {
        let rows = makeRows()
        // 総予算 = カテゴリー予算の合計。使用済みは予算のあるカテゴリー分のみ集計
        let totalBudget = rows.reduce(0) { $0 + $1.budget }
        let totalSpent = rows.reduce(0) { $0 + $1.spent }
        
        ScrollView {
            VStack(spacing: 16) {
                if rows.isEmpty {
                    Text("この月の予算は設定されていません")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.top, 60)
                } else {
                    BudgetTotalCard(type: type, budget: totalBudget, spent: totalSpent)
                    ForEach(rows) { row in
                        NavigationLink {
                            BudgetDetailView(
                                categoryID: row.id, name: row.name, imageName: row.imageName,
                                colorHex: row.colorHex, month: month, type: type
                            )
                        } label: {
                            BudgetCategoryCard(row: row, type: type)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
    }
    
    // MARK: 行データの作成
    private func makeRows() -> [BudgetRow] {
        // 対象月に適用される予算(カテゴリーごとに1件。期間は重ならない想定だが、念のため新しい方を採用)
        var applied: [UUID: Budget] = [:]
        for b in budgets where b.type == type && b.contains(month: month) {
            if let current = applied[b.categoryID] {
                if (b.startMonth, b.updatedAt) > (current.startMonth, current.updatedAt) {
                    applied[b.categoryID] = b
                }
            } else {
                applied[b.categoryID] = b
            }
        }
        
        // カテゴリーごとの使用額
        let monthTransactions = transactions.filter { $0.type == type }
        let spentByCategory = Dictionary(grouping: monthTransactions, by: \.categoryID)
            .mapValues { $0.map(\.amount).reduce(0, +) }
        
        let categoryByID = Dictionary(categories.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        
        let rows: [BudgetRow] = applied.values.map { b in
            let spent = spentByCategory[b.categoryID] ?? 0
            if let c = categoryByID[b.categoryID] {
                return BudgetRow(
                    id: b.categoryID, name: c.name, imageName: c.imageName, colorHex: c.colorHex,
                    budget: b.amount, spent: spent, sortIndex: c.sortIndex
                )
            }
            // 削除済みカテゴリー(過去月の予算は残る): 取引にコピー保存された情報を使う
            if let t = monthTransactions.first(where: { $0.categoryID == b.categoryID }) {
                return BudgetRow(
                    id: b.categoryID, name: t.categoryName ?? "-", imageName: t.categoryImageName ?? "-", colorHex: t.categoryColorHex ?? "-",
                    budget: b.amount, spent: spent, sortIndex: Int.max
                )
            }
            return BudgetRow(
                id: b.categoryID, name: "削除済みのカテゴリー", imageName: "questionmark.circle", colorHex: "#9E9E9E",
                budget: b.amount, spent: spent, sortIndex: Int.max
            )
        }
        
        return rows.sorted {
            $0.sortIndex != $1.sortIndex ? $0.sortIndex < $1.sortIndex : $0.name < $1.name
        }
    }
    
    private static func dateRange(of yyyymm: Int) -> Range<Date> {
        let calendar = Calendar.current
        let start = calendar.date(from: DateComponents(year: yyyymm / 100, month: yyyymm % 100, day: 1)) ?? Date()
        let end = calendar.date(byAdding: .month, value: 1, to: start) ?? start
        return start..<end
    }
}

// MARK: - 表示用の行データ
private struct BudgetRow: Identifiable {
    let id: UUID          // categoryID
    let name: String
    let imageName: String
    let colorHex: String
    let budget: Int
    let spent: Int
    let sortIndex: Int
    
    var remaining: Int { budget - spent }
    var isOver: Bool { remaining < 0 }
    var remainingRatio: Double { budgetRemainingRatio(budget: budget, spent: spent) }
}

// MARK: - 総予算カード(上部)
/// 総予算を最も強調し、使用済みを少し強調。使用率のバーは白、背景はグラデーション。
private struct BudgetTotalCard: View {
    let type: TransactionType
    let budget: Int
    let spent: Int
    
    private var remainingRatio: Double { budgetRemainingRatio(budget: budget, spent: spent) }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(type.totalTitle)
                .font(.subheadline.weight(.medium))
                .opacity(0.5)
            
            Text(budgetYen(budget))
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            
            BudgetProgressBar(progress: remainingRatio, fill: .white, track: .white.opacity(0.3), height: 10)
            
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Spacer()
                
                Text(type.spentTitle)
                    .font(.subheadline)
                    .opacity(0.5)
                Text(budgetYen(spent))
                    .font(.title3.weight(.semibold))
            }
        }
        .foregroundStyle(.black)
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LinearGradient.budgetTotal)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 8, y: 3)
    }
}

// MARK: - カテゴリー別カード
/// 左: カテゴリー名 / バーの上の左端に予算 / バー / バーの下の右端に使用済み
/// 右: 残り金額を色付きパネルで表示
private struct BudgetCategoryCard: View {
    let row: BudgetRow
    let type: TransactionType
    
    private var color: Color { Color(budgetHex: row.colorHex) }
    /// 支出で予算超過のときはパネルを赤にする
    private var isExpenseOver: Bool { type == .expense && row.isOver }
    private var panelColor: Color { isExpenseOver ? .red : color.opacity(0.8) }
    private var remainingTitle: String { row.isOver ? type.overTitle : type.remainingTitle }
    
    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: row.imageName)
                        .foregroundStyle(color)
                        .frame(width: 24)
                    Text(row.name)
                        .font(.headline)
                        .lineLimit(1)
                }
                
                HStack(spacing: 4) {
                    Text(type.budgetTitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(budgetYen(row.budget))
                        .font(.subheadline.weight(.semibold))
                }
                
                BudgetProgressBar(progress: row.remainingRatio, fill: panelColor, track: panelColor.opacity(0.15))
                
                HStack(spacing: 4) {
                    Spacer()
                    Text(type.spentTitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(budgetYen(row.spent))
                        .font(.subheadline.weight(.semibold))
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 4) {
                Text(remainingTitle)
                    .font(.caption.weight(.medium))
                Text(budgetYen(abs(row.remaining)))
                    .font(.title3.bold())
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .foregroundStyle(.black)
            .padding(.horizontal, 8)
            .frame(width: 112)
            .frame(maxHeight: .infinity)
            .background(panelColor)
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
    }
}

// MARK: - Preview
#Preview {
    let container = try! ModelContainer(
        for: Category.self, PaymentMethod.self, Transaction.self, Budget.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let context = container.mainContext
    
    let food = Category(name: "食費", imageName: "fork.knife", colorHex: "#FF6B6B", sortIndex: 0)
    let transport = Category(name: "交通費", imageName: "tram.fill", colorHex: "#4D96FF", sortIndex: 1)
    let fun = Category(name: "娯楽", imageName: "gamecontroller.fill", colorHex: "#9B5DE5", sortIndex: 2)
    [food, transport, fun].forEach { context.insert($0) }
    
    let ym = YearMonth.make(from: Date())
    context.insert(Budget(categoryID: food.id, type: .expense, amount: 30000, startMonth: ym))
    context.insert(Budget(categoryID: transport.id, type: .expense, amount: 10000, startMonth: ym))
    context.insert(Budget(categoryID: fun.id, type: .expense, amount: 8000, startMonth: ym))
    
    for (category, amount) in [(food, 21000), (transport, 3500), (fun, 3000)] {
        context.insert(Transaction(
            date: Date(), amount: amount, type: .expense,
            categoryID: category.id, categoryName: category.name,
            categoryImageName: category.imageName, categoryColorHex: category.colorHex
        ))
    }
    
    return BudgetView().modelContainer(container)
}
