
import SwiftUI
import SwiftData

// MARK: - 予算設定シート
/// 予算管理画面の「+」ボタンから開くシート。
/// 月の切り替え / 総予算 / 保存してあるカテゴリーごとの予算金額を表示し、
/// カテゴリーをタップすると金額と適用範囲を設定できる(BudgetEditSheet を使用)。
struct BudgetSetupSheet: View {
    /// 予算は支出のみ
    private let type = TransactionType.expense
    
    @State private var month: Int
    @State private var editingTarget: EditTarget?
    
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Category.sortIndex) private var categories: [Category]
    @Query private var budgets: [Budget]
    
    init(initialMonth: Int) {
        _month = State(initialValue: initialMonth)
    }
    
    /// 金額を設定するカテゴリー(シートを開くための情報)
    private struct EditTarget: Identifiable {
        let id: UUID        // categoryID
        let name: String
        let amount: Int
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    BudgetMonthCapsule(
                        month: month,
                        onPrevious: { month = YearMonth.previous(month) },
                        onNext: { month = YearMonth.next(month) }
                    )
                    
                    totalCard
                    
                    categoryList
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("予算を設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") { dismiss() }
                }
            }
            .sheet(item: $editingTarget) { target in
                BudgetEditSheet(
                    categoryID: target.id,
                    name: target.name,
                    month: month,
                    type: type,
                    currentAmount: target.amount
                )
                .presentationDetents([.medium, .large])
            }
        }
    }
    
    // MARK: 総予算
    /// 総予算 = その月のカテゴリー予算の合計(削除済みカテゴリーの予算も含む。予算管理画面と同じ)
    private var totalAmount: Int {
        let ids = Set(budgets.map(\.categoryID))
        return ids.compactMap { id in
            BudgetService.applied(
                in: budgets.filter { $0.categoryID == id },
                type: type,
                month: month
            )?.amount
        }
        .reduce(0, +)
    }
    
    private var totalCard: some View {
        let colors = [Color(budgetHex: "#4F46E5"), Color(budgetHex: "#9333EA")]
        
        return VStack(spacing: 4) {
            Text("\(month % 100)月の総予算")
                .font(.subheadline.weight(.medium))
                .opacity(0.85)
            Text(budgetYen(totalAmount))
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 8, y: 3)
    }
    
    // MARK: カテゴリー別の予算
    private func amount(for category: Category) -> Int? {
        BudgetService.applied(
            in: budgets.filter { $0.categoryID == category.id },
            type: type,
            month: month
        )?.amount
    }
    
    @ViewBuilder
    private var categoryList: some View {
        if categories.isEmpty {
            Text("カテゴリーがありません。先にカテゴリーを追加してください。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 24)
        } else {
            VStack(spacing: 0) {
                ForEach(Array(categories.enumerated()), id: \.element.id) { index, category in
                    categoryRow(category)
                    
                    if index < categories.count - 1 {
                        Divider().padding(.leading, 62)
                    }
                }
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
    
    private func categoryRow(_ category: Category) -> some View {
        let amount = amount(for: category)
        
        return Button {
            editingTarget = EditTarget(id: category.id, name: category.name, amount: amount ?? 0)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: category.imageName)
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(Color(budgetHex: category.colorHex), in: Circle())
                
                Text(category.name)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                Spacer()
                
                if let amount {
                    Text(budgetYen(amount))
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                } else {
                    Text("未設定")
                        .foregroundStyle(.secondary)
                }
                
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
    
    return BudgetSetupSheet(initialMonth: ym)
        .modelContainer(container)
}
