
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
            Group {
                if transactions.isEmpty {
                    VStack(alignment: .center, spacing: 5) {
                        Image(systemName: "list.bullet.rectangle.portrait")
                            .font(.system(size: 32))
                            .foregroundStyle(.gray)
                        
                        Text("収支の履歴はありません")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.black)
                    }
                    
                } else {
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
//                                        .alignmentGuide(.listRowSeparatorLeading) {
//                                            $0[.leading]
//                                        }
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
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(uiColor: .systemGray6).opacity(0.5))
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
                    //カテゴリー
                    Text(transaction.category.name)
                        .font(.body)
                        .foregroundStyle(.secondary)

                    
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
                
                //メモ
                Text(transaction.memo?.isEmpty == false ? transaction.memo! : "-")
                    .font(.subheadline)
                
            }
        }
        .padding(.vertical, 5)
    }
}

#Preview("空の場合") {
    let container = try! ModelContainer(
        for: Category.self,
        PaymentMethod.self,
        Transaction.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    
    return TransactionListView()
        .modelContainer(container)
}

#Preview("ダミー") {
    let container = try! ModelContainer(
        for: Category.self,
        PaymentMethod.self,
        Transaction.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    
    let context = container.mainContext
    
    let food = Category(
        name: "食費",
        imageName: "fork.knife",
        sortIndex: 0
    )
    
    let transportation = Category(
        name: "交通費",
        imageName: "car",
        sortIndex: 1
    )
    
    let cash = PaymentMethod(
        name: "現金",
        type: .cash,
        memo: nil,
        sortIndex: 0
    )
    
    let payPay = PaymentMethod(
        name: "PayPay",
        type: .qrCode,
        memo: "普段使い",
        sortIndex: 1
    )
    
    context.insert(food)
    context.insert(transportation)
    context.insert(cash)
    context.insert(payPay)
    
    context.insert(
        Transaction(
            date: Date(),
            amount: 1200,
            type: .expense,
            category: food,
            memo: "昼ごはん",
            paymentMethod: cash
        )
    )
    
    context.insert(
        Transaction(
            date: Date(),
            amount: 3000,
            type: .expense,
            category: transportation,
            memo: nil,
            paymentMethod: payPay
        )
    )
    
    context.insert(
        Transaction(
            date: Date().addingTimeInterval(-86400),
            amount: 250000,
            type: .income,
            category: food,
            memo: "給料",
            paymentMethod: nil
        )
    )
    
    return TransactionListView()
        .modelContainer(container)
}
