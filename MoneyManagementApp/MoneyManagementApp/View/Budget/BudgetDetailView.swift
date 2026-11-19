
import SwiftUI
import SwiftData

// MARK: - 詳細予算画面(カテゴリー別)
/// 予算管理画面でカテゴリーのカードをタップしたときの遷移先。
/// サマリー(予算・使用済み・残り) / 予算の変更 / その月の取引一覧
struct BudgetDetailView: View {
    let categoryID: UUID
    let name: String
    let imageName: String
    let colorHex: String
    let month: Int
    let type: TransactionType
    
    @Query private var budgets: [Budget]
    @Query private var transactions: [Transaction]
    @State private var showingEdit = false
    
    init(categoryID: UUID, name: String, imageName: String, colorHex: String, month: Int, type: TransactionType) {
        self.categoryID = categoryID
        self.name = name
        self.imageName = imageName
        self.colorHex = colorHex
        self.month = month
        self.type = type
        
        let id = categoryID
        let range = YearMonth.dateRange(month)
        let start = range.lowerBound
        let end = range.upperBound
        _budgets = Query(filter: #Predicate<Budget> { $0.categoryID == id })
        _transactions = Query(
            filter: #Predicate<Transaction> { $0.categoryID == id && $0.date >= start && $0.date < end },
            sort: \Transaction.date,
            order: .reverse
        )
    }
    
    var body: some View {
        let budget = BudgetService.applied(in: budgets, type: type, month: month)
        let amount = budget?.amount ?? 0
        let monthTransactions = transactions.filter { $0.type == type }
        let spent = monthTransactions.reduce(0) { $0 + $1.amount }
        
        ScrollView {
            VStack(spacing: 16) {
                BudgetDetailSummaryCard(
                    name: name, imageName: imageName, colorHex: colorHex,
                    month: month, type: type, budget: amount, spent: spent
                )
                
                VStack(spacing: 6) {
                    Button {
                        showingEdit = true
                    } label: {
                        Label(budget == nil ? "予算を設定" : "予算を変更", systemImage: "pencil")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(budgetHex: colorHex))
                    
                    if let period = periodText(of: budget) {
                        Text("適用期間: \(period)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                transactionsSection(monthTransactions)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEdit) {
            BudgetEditSheet(
                categoryID: categoryID, name: name, month: month, type: type, currentAmount: amount
            )
            .presentationDetents([.medium, .large])
        }
    }
    
    // MARK: 適用期間の表示
    private func periodText(of budget: Budget?) -> String? {
        guard let b = budget else { return nil }
        if let end = b.endMonth {
            return b.startMonth == end
            ? "\(YearMonth.label(b.startMonth))のみ"
            : "\(YearMonth.label(b.startMonth))〜\(YearMonth.label(end))"
        }
        return "\(YearMonth.label(b.startMonth))〜"
    }
    
    // MARK: その月の取引一覧
    @ViewBuilder
    private func transactionsSection(_ items: [Transaction]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("この月の\(type.rawValue)(\(items.count)件)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                if items.isEmpty {
                    Text("この月の取引はありません")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                } else {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, t in
                        HStack(spacing: 12) {
                            Text(t.date, format: .dateTime.month().day())
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .frame(width: 64, alignment: .leading)
                            Text((t.memo ?? "").isEmpty ? "メモなし" : (t.memo ?? ""))
                                .font(.subheadline)
                                .foregroundStyle((t.memo ?? "").isEmpty ? .secondary : .primary)
                                .lineLimit(1)
                            Spacer()
                            Text(budgetYen(t.amount))
                                .font(.subheadline.weight(.semibold))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        
                        if index < items.count - 1 {
                            Divider().padding(.leading, 14)
                        }
                    }
                }
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}

// MARK: - サマリーカード
/// カテゴリーの色のグラデーション背景。予算を最も強調し、使用済み・残りを下段に表示。
/// 支出で予算超過のときは赤。
private struct BudgetDetailSummaryCard: View {
    let name: String
    let imageName: String
    let colorHex: String
    let month: Int
    let type: TransactionType
    let budget: Int
    let spent: Int
    
    private var remaining: Int { budget - spent }
    private var isOver: Bool { remaining < 0 }
    private var progress: Double {
        if budget > 0 { return min(Double(spent) / Double(budget), 1) }
        return spent > 0 ? 1 : 0
    }
    
    private var gradient: LinearGradient {
        let base: Color = (type == .expense && isOver) ? .red : Color(budgetHex: colorHex)
        return LinearGradient(
            colors: [base, base.opacity(0.7)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: imageName)
                    .font(.title3)
                    .frame(width: 40, height: 40)
                    .background(.white.opacity(0.22), in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(name).font(.headline)
                    Text(YearMonth.label(month)).font(.caption).opacity(0.85)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(type.budgetTitle)
                    .font(.subheadline)
                    .opacity(0.85)
                Text(budgetYen(budget))
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            
            BudgetProgressBar(progress: progress, fill: .white, track: .white.opacity(0.3), height: 10)
            
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(type.spentTitle).font(.caption).opacity(0.85)
                    Text(budgetYen(spent)).font(.title3.weight(.semibold))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(isOver ? type.overTitle : type.remainingTitle).font(.caption).opacity(0.85)
                    Text(budgetYen(abs(remaining))).font(.title3.weight(.semibold))
                }
            }
        }
        .foregroundStyle(.white)
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(gradient)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 8, y: 3)
    }
}

// MARK: - 予算の変更シート
/// 金額と適用範囲(この月のみ / この月以降すべて)を選んで保存する
struct BudgetEditSheet: View {
    let categoryID: UUID
    let name: String
    let month: Int
    let type: TransactionType
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var amountText: String
    @State private var scope: BudgetScope = .fromThisMonth
    @State private var errorMessage: String?
    @FocusState private var amountFocused: Bool
    
    init(categoryID: UUID, name: String, month: Int, type: TransactionType, currentAmount: Int) {
        self.categoryID = categoryID
        self.name = name
        self.month = month
        self.type = type
        _amountText = State(initialValue: currentAmount > 0 ? String(currentAmount) : "")
    }
    
    private var parsedAmount: Int? { Int(amountText) }
    
    private var scopeFooter: String {
        switch scope {
        case .thisMonthOnly:
            return "\(YearMonth.label(month))だけ変更します。他の月の\(type.budgetTitle)はそのままです。"
        case .fromThisMonth:
            return "\(YearMonth.label(month))以降の\(type.budgetTitle)をこの金額にします。以降に設定済みの個別の変更は上書きされます。"
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(type.budgetTitle) {
                    HStack {
                        Text("¥").foregroundStyle(.secondary)
                        TextField("0", text: $amountText)
                            .keyboardType(.numberPad)
                            .focused($amountFocused)
                            .onChange(of: amountText) { _, newValue in
                                let digits = newValue.filter(\.isNumber)
                                if digits != newValue { amountText = digits }
                            }
                    }
                }
                
                Section {
                    Picker("適用範囲", selection: $scope) {
                        ForEach(BudgetScope.allCases) { s in
                            Text(s.rawValue).tag(s)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                } header: {
                    Text("適用範囲")
                } footer: {
                    Text(scopeFooter)
                }
            }
            .navigationTitle("\(name)の\(type.budgetTitle)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存", action: save)
                        .disabled(parsedAmount == nil)
                }
            }
            .alert("保存できませんでした", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
            .onAppear { amountFocused = true }
        }
    }
    
    private func save() {
        guard let amount = parsedAmount else { return }
        do {
            try BudgetService.apply(
                amount: amount, categoryID: categoryID, type: type,
                month: month, scope: scope, context: modelContext
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
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
    context.insert(food)
    
    let ym = YearMonth.make(from: Date())
    context.insert(Budget(categoryID: food.id, type: .expense, amount: 30000, startMonth: ym))
    
    for (amount, memo) in [(1280, "スーパー"), (3400, "ランチ"), (7820, "まとめ買い")] {
        context.insert(Transaction(
            date: Date(), amount: amount, type: .expense, memo: memo,
            categoryID: food.id, categoryName: food.name,
            categoryImageName: food.imageName, categoryColorHex: food.colorHex
        ))
    }
    
    return NavigationStack {
        BudgetDetailView(
            categoryID: food.id, name: food.name, imageName: food.imageName,
            colorHex: food.colorHex, month: ym, type: .expense
        )
    }
    .modelContainer(container)
}
