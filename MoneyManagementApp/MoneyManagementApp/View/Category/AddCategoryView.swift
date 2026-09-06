import SwiftUI

struct AddCategoryView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var categoryName = ""
    @State private var selectedIcon = "fork.knife"
    @State private var searchText = ""
    
    // 家計簿カテゴリー向けによく使うSF Symbolを厳選
    // (CategoryIconPickerView と同じ一覧を共有)
    private let allIcons: [String] = [
        "fork.knife", "cup.and.saucer", "cart", "bag",
        "basket", "takeoutbag.and.cup.and.straw",
        "car", "fuelpump", "bus", "tram", "airplane", "bicycle",
        "house", "bolt", "drop", "flame", "wifi",
        "cross.case", "pills", "stethoscope", "heart",
        "gamecontroller", "film", "music.note", "sportscourt",
        "book", "graduationcap", "pencil",
        "tshirt", "shoe", "scissors", "sparkles",
        "gift", "birthday.cake", "pawprint",
        "banknote", "creditcard", "wallet.pass",
        "briefcase", "building.2", "phone", "laptopcomputer",
        "airplane.departure", "bed.double", "beach.umbrella",
        "wrench.and.screwdriver", "hammer", "leaf",
        "ellipsis.circle"
    ]
    
    private var filteredIcons: [String] {
        guard !searchText.isEmpty else { return allIcons }
        return allIcons.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 4)
    
    var body: some View {
        NavigationStack {
            Form {
                Section("カテゴリー名") {
                    TextField("カテゴリー名を入力", text: $categoryName)
                }
                
                Section("アイコン") {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(filteredIcons, id: \.self) { symbol in
                            Button {
                                selectedIcon = symbol
                            } label: {
                                Image(systemName: symbol)
                                    .font(.system(size: 24))
                                    .foregroundStyle(
                                        selectedIcon == symbol
                                        ? .white
                                        : .black
                                    )
                                    .frame(width: 50, height: 50)
                                    .background(
                                        selectedIcon == symbol
                                        ? Color.black
                                        : Color(uiColor: .systemGray6)
                                    )
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("カテゴリーを追加")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "アイコンを検索")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("追加") {
                        // カテゴリー追加処理
                        dismiss()
                    }
                    .disabled(categoryName.isEmpty)
                }
            }
        }
    }
}

#Preview {
    AddCategoryView()
}

