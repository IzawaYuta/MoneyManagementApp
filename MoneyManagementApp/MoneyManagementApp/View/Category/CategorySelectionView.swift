import SwiftUI

struct CategorySelectionView: View {
    
    
    @State private var isShowingAddCategory = false
    @Binding var selectedCategory: String
    @State private var selectDeleteCategory: Array = []
    @Environment(\.dismiss) private var dismiss
    
    private let categories = [
        "食費",
        "日用品",
        "交通費",
        "光熱費",
        "家賃",
        "通信費",
        "医療費",
        "娯楽",
        "衣服",
        "交際費",
        "教育費",
        "その他"
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ],
                    spacing: 12
                ) {
                    ForEach(categories, id: \.self) { category in
                        Button {
                            selectedCategory = category
                            dismiss()
                        } label: {
                            VStack(spacing: 10) {
                                Image(systemName: iconName(for: category))
                                    .font(.system(size: 24))
                                    .foregroundStyle(.black)
                                
                                Text(category)
                                    .font(.system(size: 14))
                                    .foregroundStyle(.black)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 100)
                            .background(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.black, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            .background(
                Color(uiColor: .systemGray6)
                    .opacity(0.5)
            )
            .navigationTitle("カテゴリー")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(uiColor: .systemGray6).opacity(0.5))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(action: {
                            isShowingAddCategory = true
                        }) {
                            Text("追加")
                        }
                        Button(action: {
                        }) {
                            Text("削除")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $isShowingAddCategory) {
                AddCategoryView()
            }
        }
    }
    
    private func iconName(for category: String) -> String {
        switch category {
        case "食費":
            return "fork.knife"
        case "日用品":
            return "basket"
        case "交通費":
            return "car"
        case "光熱費":
            return "bolt"
        case "家賃":
            return "house"
        case "通信費":
            return "iphone"
        case "医療費":
            return "cross.case"
        case "娯楽":
            return "gamecontroller"
        case "衣服":
            return "tshirt"
        case "交際費":
            return "person.2"
        case "教育費":
            return "book"
        case "その他":
            return "ellipsis"
        default:
            return "square.grid.2x2"
        }
    }
}

#Preview {
    CategorySelectionView(selectedCategory: .constant("食費"))
}
