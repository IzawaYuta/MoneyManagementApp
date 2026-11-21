import Foundation
import SwiftData

@MainActor
enum CategoryService {
    
    /// 保存ボタンを押せる条件(AddCategoryView.canSave と同じ)
    static func isValid(name: String, imageName: String?, colorHex: String?) -> Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
        && imageName != nil
        && colorHex != nil
    }
    
    /// 末尾(最大sortIndex + 1)にカテゴリーを追加する
    @discardableResult
    static func add(
        name: String,
        imageName: String,
        colorHex: String,
        in context: ModelContext
    ) throws -> Category {
        let all = try context.fetch(FetchDescriptor<Category>())
        let newSortIndex = (all.map(\.sortIndex).max() ?? -1) + 1
        
        let category = Category(
            name: name,
            imageName: imageName,
            colorHex: colorHex,
            sortIndex: newSortIndex
        )
        context.insert(category)
        return category
    }
    
    /// 名前・アイコン・色を更新する(sortIndexは変えない)
    static func update(
        _ category: Category,
        name: String,
        imageName: String,
        colorHex: String
    ) {
        category.name = name
        category.imageName = imageName
        category.colorHex = colorHex
    }
    
    /// 指定IDのカテゴリーを削除し、残りのsortIndexを0から詰め直す
    /// - 削除するカテゴリーの予算は、今月以降を削除する(過去の月は残す)
    static func delete(
        ids: Set<UUID>,
        in context: ModelContext,
        now: Date = Date(),
        calendar: Calendar = .current
    ) throws {
        let all = try context.fetch(
            FetchDescriptor<Category>(sortBy: [SortDescriptor(\.sortIndex)])
        )
        let currentMonth = YearMonth.make(from: now, calendar: calendar)
        
        for category in all where ids.contains(category.id) {
            try BudgetService.removeBudgets(
                categoryID: category.id, fromMonth: currentMonth, context: context
            )
            context.delete(category)
        }
        
        let remaining = all.filter { !ids.contains($0.id) }
        for (index, category) in remaining.enumerated() {
            category.sortIndex = index
        }
    }
}
