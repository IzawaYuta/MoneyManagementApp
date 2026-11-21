//
//  CategoryDeleteBudgetTests.swift
//  MoneyManagementApp
//
//  Created by Engineer MacBook Air on 2026/11/21.
//


import Testing
import Foundation
import SwiftData
@testable import MoneyManagementApp  // ← Product Module Name に合わせる

@MainActor
struct CategoryDeleteBudgetTests {

    // MARK: - Helper

    private var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        return c
    }

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d, hour: 12))!
    }

    /// 今日は2026年11月15日(今月 = 202611)として扱う
    private var now: Date { date(2026, 11, 15) }

    private func makeContext() throws -> ModelContext {
        let schema = Schema(versionedSchema: SchemaV2.self)
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        return ModelContext(container)
    }

    private func makeCategory(_ name: String, sort: Int = 0, in context: ModelContext) -> Category {
        let category = Category(name: name, imageName: "tray", colorHex: "#4DABF7", sortIndex: sort)
        context.insert(category)
        return category
    }

    private func seedBudget(
        _ context: ModelContext, _ categoryID: UUID, _ amount: Int, _ start: Int, _ end: Int? = nil
    ) throws {
        context.insert(Budget(
            categoryID: categoryID, type: .expense, amount: amount, startMonth: start, endMonth: end
        ))
        try context.save()
    }

    private func deleteCategories(_ context: ModelContext, _ ids: Set<UUID>, at now: Date? = nil) throws {
        try CategoryService.delete(ids: ids, in: context, now: now ?? self.now, calendar: calendar)
        try context.save()
    }

    private func shape(_ context: ModelContext, _ categoryID: UUID) throws -> [String] {
        try context.fetch(FetchDescriptor<Budget>(sortBy: [SortDescriptor(\.startMonth)]))
            .filter { $0.categoryID == categoryID }
            .map { "\($0.startMonth)-\($0.endMonth.map(String.init) ?? ""):\($0.amount)" }
    }

    // MARK: - Tests

    @Test("今月以降に始まる予算は、削除される")
    func futureBudgetsAreDeleted() throws {
        let context = try makeContext()
        let food = makeCategory("食費", in: context)
        try seedBudget(context, food.id, 1000, 202611, 202611)
        try seedBudget(context, food.id, 2000, 202612)

        try deleteCategories(context, [food.id])

        #expect(try shape(context, food.id).isEmpty)
    }

    @Test("今月をまたぐ予算は、前月で終わる")
    func spanningBudgetEndsLastMonth() throws {
        let context = try makeContext()
        let food = makeCategory("食費", in: context)
        try seedBudget(context, food.id, 30000, 202610)

        try deleteCategories(context, [food.id])

        #expect(try shape(context, food.id) == ["202610-202610:30000"])
    }

    @Test("過去の月で終わっている予算は、残る")
    func pastBudgetsRemain() throws {
        let context = try makeContext()
        let food = makeCategory("食費", in: context)
        try seedBudget(context, food.id, 1000, 202609, 202610)

        try deleteCategories(context, [food.id])

        #expect(try shape(context, food.id) == ["202609-202610:1000"])
    }

    @Test("他のカテゴリーの予算には、影響しない")
    func otherCategoriesAreNotAffected() throws {
        let context = try makeContext()
        let food = makeCategory("食費", sort: 0, in: context)
        let transport = makeCategory("交通費", sort: 1, in: context)
        try seedBudget(context, food.id, 30000, 202610)
        try seedBudget(context, transport.id, 7000, 202610)

        try deleteCategories(context, [food.id])

        #expect(try shape(context, transport.id) == ["202610-:7000"])
    }

    @Test("複数のカテゴリーをまとめて削除すると、それぞれの予算が整理される")
    func multipleCategories() throws {
        let context = try makeContext()
        let food = makeCategory("食費", sort: 0, in: context)
        let transport = makeCategory("交通費", sort: 1, in: context)
        try seedBudget(context, food.id, 30000, 202610)
        try seedBudget(context, transport.id, 7000, 202612)

        try deleteCategories(context, [food.id, transport.id])

        #expect(try shape(context, food.id) == ["202610-202610:30000"])
        #expect(try shape(context, transport.id).isEmpty)
    }

    @Test("予算のないカテゴリーを削除しても、エラーにならない")
    func categoryWithoutBudgets() throws {
        let context = try makeContext()
        let food = makeCategory("食費", in: context)

        try deleteCategories(context, [food.id])

        #expect(try context.fetch(FetchDescriptor<Category>()).isEmpty)
    }

    @Test("年をまたぐ場合(2027年1月に削除)も、前月は2026年12月になる")
    func acrossYear() throws {
        let context = try makeContext()
        let food = makeCategory("食費", in: context)
        try seedBudget(context, food.id, 30000, 202610)

        try deleteCategories(context, [food.id], at: date(2027, 1, 10))

        #expect(try shape(context, food.id) == ["202610-202612:30000"])
    }

    @Test("削除後は、今月・未来の月の予算画面に出ず、過去の月には記録の情報で残る")
    func deletedCategoryDisappearsFromFutureRows() throws {
        let context = try makeContext()
        let food = makeCategory("食費", in: context)
        try seedBudget(context, food.id, 30000, 202609)
        let pastTransaction = SchemaV2.Transaction(
            date: date(2026, 10, 5), amount: 800, type: .expense,
            categoryID: food.id, categoryName: "食費",
            categoryImageName: "fork.knife", categoryColorHex: "#FF6B6B"
        )
        context.insert(pastTransaction)

        try deleteCategories(context, [food.id])

        let budgets = try context.fetch(FetchDescriptor<Budget>())
        let categories = try context.fetch(FetchDescriptor<Category>())
        func rows(_ month: Int) -> [BudgetRow] {
            BudgetService.rows(
                budgets: budgets, categories: categories,
                transactions: month == 202610 ? [pastTransaction] : [],
                month: month, type: .expense
            )
        }

        #expect(rows(202611).isEmpty)
        #expect(rows(202612).isEmpty)
        #expect(rows(202610).map(\.name) == ["食費"])
        #expect(rows(202610).first?.spent == 800)
    }
}