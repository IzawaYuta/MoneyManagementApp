
import SwiftUI
import SwiftData

struct TransactionListView: View {
    
    @Query(sort: \Transaction.date, order: .reverse)
    private var transactions: [Transaction]
    
    private var groupedTransactions: [(date: Date, transactions: [Transaction])] {
        let calendar = Calendar.current
        
        let grouped = Dictionary(
            grouping: transactions
        ) { transaction in
            calendar.startOfDay(for: transaction.date)
        }
        
        return grouped
            .sorted { $0.key > $1.key }
            .map { date, transactions in
                (
                    date: date,
                    transactions: transactions.sorted {
                        $0.date > $1.date
                    }
                )
            }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(groupedTransactions, id: \.date) { group in
                    
                    Section {
                        ForEach(group.transactions) { transaction in
                            transactionRow(transaction)
                                .listRowSeparatorTint(.black.opacity(0.5))
//                                .listRowSeparator(.visible, edges: .bottom)
//                                .listRowInsets(
//                                    EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)
//                                )
                        }
                    } header: {
                        Text(
                            group.date.formatted(
                                .dateTime
                                    .month()
                                    .day()
                                    .weekday(.wide)
                                    .locale(Locale(identifier: "ja_JP"))
                            )
                        )
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                    }
                }
            }
            .navigationTitle("履歴")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    @ViewBuilder
    private func transactionRow(_ transaction: Transaction) -> some View {
        HStack(spacing: 12) {
            
            // 収入・支出を視覚的に表示
            Image(
                systemName: transaction.type == .income
                ? "arrow.down.circle.fill"
                : "arrow.up.circle.fill"
            )
            .font(.title2)
            .foregroundStyle(
                transaction.type == .income
                ? .green
                : .red
            )
            
            VStack(alignment: .leading, spacing: 4) {
                
                HStack {
                    //メモ
                    Text(transaction.memo?.isEmpty == false ? transaction.memo! : "-")
                        .font(.body)
                    
                    Spacer()
                    
                    //金額
                    Text(
                        transaction.type == .income
                        ? "+\(transaction.amount)円"
                        : "-\(transaction.amount)円"
                    )
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(
                        transaction.type == .income
                        ? .green
                        : .red
                    )
                }
                
                //支払方法
                if let paymentMethod = transaction.paymentMethod {
                    Text(paymentMethod.name)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                
                //カテゴリー
                Text(transaction.category.name)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

            }
        }
        .padding(.vertical, 5)
    }
}

//#Preview {
//    makePreview()
//}
//
//@MainActor
//private func makePreview() -> some View {
//    let container = try! ModelContainer(
//        for: Schema([
//            Transaction.self,
//            Category.self,
//            PaymentMethod.self
//        ]),
//        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
//    )
//    
//    let context = container.mainContext
//    
//    let food = Category(
//        name: "食費",
//        imageName: "fork.knife"
//    )
//    
//    let cash = PaymentMethod(
//        name: "現金",
//        type: .cash
//    )
//    
//    context.insert(food)
//    context.insert(cash)
//    
//    context.insert(
//        Transaction(
//            date: Date(),
//            amount: 1200,
//            type: .expense,
//            category: food,
//            memo: "",
//            paymentMethod: cash
//        )
//    )
//    
//    return TransactionListView()
//        .modelContainer(container)
//}
