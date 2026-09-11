
import SwiftUI
import SwiftData

struct OnboardingCategoryView: View {
    
    @Environment(\.modelContext) private var modelContext
    
    @State private var categoryName = ""
    @State private var selectedIcon: String?
    @State private var selectedQuickName: String?
    
    var onNext: () -> Void
    
    @Query(sort: \Category.sortIndex)
    private var categories: [Category]
    
    // よく使うカテゴリー(名前, アイコン)
    private let quickCategories: [(name: String, icon: String)] = [
        ("家賃", "house"),
        ("食費", "fork.knife"),
        ("日用品", "cart"),
        ("交通費", "car"),
        ("医療費", "cross.case"),
        ("娯楽", "gamecontroller")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            
            // MARK: - 進捗表示
            VStack(spacing: 8) {
                Text("1 / 2")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.gray)
                
                HStack(spacing: 10) {
                    Circle()
                        .fill(Color.black)
                        .frame(width: 11, height: 11)
                    
                    Circle()
                        .fill(Color.gray.opacity(0.5))
                        .frame(width: 11, height: 11)
                }
            }
            .padding(.top, 18)
            .padding(.horizontal, 10)
            
//            Spacer(minLength: 0)
            
            // MARK: - 説明
            VStack(spacing: 10) {
                Image(systemName: "square.grid.2x2")
                    .font(.system(size: 40))
                    .foregroundStyle(.black)
//                    .frame(width: 52, height: 52)
//                    .background(Color.black)
//                    .clipShape(Circle())
                
                VStack(spacing: 6) {
                    Text("カテゴリーを追加")
//                        .font(.system(size: 18, weight: .semibold))
                        .font(.title)
                        .foregroundStyle(.black)
                    
                    Text("よく使う支出のカテゴリーを\n1つ登録しましょう")
                        .font(.system(size: 17))
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.top, 35)
            .padding(.horizontal, 10)

            
            // MARK: - 入力
            VStack(alignment: .leading, spacing: 6) {
                Text("カテゴリー名")
                    .font(.system(size: 12))
                    .foregroundStyle(.gray)
                
                TextField("例: 賞与、教育費、交通費...", text: $categoryName)
                    .font(.system(size: 15))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color(uiColor: .systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.black.opacity(0.1), lineWidth: 0.5)
                    )
            }
            .padding(.top, 40)
            .padding(.horizontal, 10)
            
            // MARK: - クイック選択
            VStack(alignment: .leading, spacing: 8) {
                Text("よく使うカテゴリーから選ぶ")
                    .font(.system(size: 12))
                    .foregroundStyle(.gray)
                    .padding(.top, 20)
                
                QuickCategoryFlowLayout(spacing: 8) {
                    ForEach(quickCategories, id: \.name) { item in
                        quickCategoryButton(name: item.name, icon: item.icon)
                    }
                }
            }
            .padding(.top, 15)
            .padding(.horizontal, 10)
            
            Spacer(minLength: 0)
            
            // MARK: - 補足
            Text("あとで設定画面から編集できます")
                .font(.system(size: 13))
                .foregroundStyle(.gray.opacity(0.7))
                .padding(.top, 12)
                .padding(.bottom, 10)
            
            // MARK: - 追加ボタン
            Button {
                addCategory()
            } label: {
                Text("追加")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        categoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ? Color.black.opacity(0.3)
                        : Color.black
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .disabled(categoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .padding(.bottom, 24)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemGray6).opacity(0.5))
    }
    
    @ViewBuilder
    private func quickCategoryButton(name: String, icon: String) -> some View {
        let isSelected = selectedQuickName == name
        
        Button {
            categoryName = name
            selectedIcon = icon
            selectedQuickName = name
        } label: {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(name)
                    .font(.system(size: 16))
            }
            .foregroundStyle(isSelected ? .white : .black)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(isSelected ? Color.black : Color.white)
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.black : Color.gray.opacity(0.4), lineWidth: 1)
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
    
    private func addCategory() {
        let trimmedName = categoryName
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            return
        }
        
        let newSortIndex = (categories.map(\.sortIndex).max() ?? -1) + 1
        
        let newCategory = Category(
            name: trimmedName,
            imageName: selectedIcon ?? "ellipsis.circle",
            sortIndex: newSortIndex
        )
        
        modelContext.insert(newCategory)
        
        onNext()
    }
}

// MARK: - 折り返し可能なFlowレイアウト(ピルボタンを並べる用)

private struct QuickCategoryFlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rowWidth: CGFloat = 0
        var totalHeight: CGFloat = 0
        var rowHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth + size.width > maxWidth, rowWidth > 0 {
                totalHeight += rowHeight + spacing
                rowWidth = 0
                rowHeight = 0
            }
            rowWidth += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        totalHeight += rowHeight
        
        return CGSize(width: maxWidth, height: totalHeight)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

#Preview {
    OnboardingCategoryView(onNext: {})
}
