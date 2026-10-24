
import SwiftUI

struct BudgetView: View {
    
    // 仮データ
    let totalBudget = 100000
    let totalSpent = 62000
    
    let budgets = [
        BudgetItem(
            category: "食費",
            budget: 30000,
            spent: 18000
        ),
        BudgetItem(
            category: "日用品",
            budget: 20000,
            spent: 12000
        ),
        BudgetItem(
            category: "交通費",
            budget: 15000,
            spent: 9000
        ),
        BudgetItem(
            category: "娯楽",
            budget: 20000,
            spent: 16000
        ),
        BudgetItem(
            category: "その他",
            budget: 15000,
            spent: 7000
        )
    ]
    
    var totalRemaining: Int {
        totalBudget - totalSpent
    }
    
    var totalProgress: Double {
        guard totalBudget > 0 else { return 0 }
        return min(Double(totalSpent) / Double(totalBudget), 1.0)
    }
    
    var body: some View {
        NavigationStack {
            List {
                
                // MARK: - 合計予算
                
                Section {
                    VStack(alignment: .leading, spacing: 16) {
                        
                        Text("今月の予算")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Text(totalBudget, format: .currency(code: "JPY"))
                            .font(.system(size: 32, weight: .bold))
                        
                        VStack(alignment: .leading, spacing: 8) {
                            
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    
                                    Capsule()
                                        .fill(Color.gray.opacity(0.2))
                                    
                                    Capsule()
                                        .fill(Color.primary)
                                        .frame(
                                            width: geometry.size.width * totalProgress
                                        )
                                }
                            }
                            .frame(height: 10)
                            
                            HStack {
                                Text("使用済み ￥\(totalSpent)")
                                
                                Spacer()
                                
                                Text("残り ￥\(totalRemaining)")
                                    .fontWeight(.semibold)
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.secondarySystemBackground))
                    )
                    .listRowInsets(
                        EdgeInsets(
                            top: 8,
                            leading: 16,
                            bottom: 16,
                            trailing: 16
                        )
                    )
                    .listRowBackground(Color.clear)
                }
                
                // MARK: - カテゴリー別予算
                
                Section("カテゴリー別予算") {
                    
                    ForEach(budgets) { budget in
                        BudgetRow(budget: budget)
                    }
                }
            }
            .navigationTitle("予算管理")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}


// MARK: - カテゴリー予算

struct BudgetItem: Identifiable {
    let id = UUID()
    let category: String
    let budget: Int
    let spent: Int
    
    var remaining: Int {
        budget - spent
    }
    
    var progress: Double {
        guard budget > 0 else { return 0 }
        return min(Double(spent) / Double(budget), 1.0)
    }
}


// MARK: - カテゴリー行

struct BudgetRow: View {
    
    let budget: BudgetItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            
            HStack {
                Text(budget.category)
                    .font(.headline)
                
                Spacer()
                
                Text("予算 ￥\(budget.budget)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    
                    Capsule()
                        .fill(Color.gray.opacity(0.2))
                    
                    Capsule()
                        .fill(Color.primary)
                        .frame(
                            width: geometry.size.width * budget.progress
                        )
                }
            }
            .frame(height: 8)
            
            HStack {
                Text("使用済み ￥\(budget.spent)")
                
                Spacer()
                
                Text("あと ￥\(budget.remaining)")
                    .fontWeight(.semibold)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
    }
}


// MARK: - Preview

#Preview {
    BudgetView()
}

