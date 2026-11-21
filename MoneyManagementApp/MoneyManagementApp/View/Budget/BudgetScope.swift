
import Foundation
import SwiftData

// MARK: - 変更の適用範囲
enum BudgetScope: String, CaseIterable, Identifiable {
    case thisMonthOnly = "この月のみ"
    case fromThisMonth = "この月以降すべて"

    var id: String { rawValue }
}

// MARK: - 予算の更新ルール
/// 同じカテゴリー・同じtypeの Budget は、期間(startMonth...endMonth)が重ならないように保つ。
enum BudgetService {
    
    /// 対象月に適用される予算(1件)。期間は重ならない想定だが、念のため新しい方を採用する
    static func applied(in budgets: [Budget], type: TransactionType, month: Int) -> Budget? {
        var result: Budget?
        for b in budgets where b.type == type && b.contains(month: month) {
            if let current = result {
                if (b.startMonth, b.updatedAt) > (current.startMonth, current.updatedAt) {
                    result = b
                }
            } else {
                result = b
            }
        }
        return result
    }
    
    /// 予算の金額を設定・変更する(保存まで行う)
    /// - 金額が0以下のときは「未設定」にする(その範囲の予算を作らない・消す)
    /// - thisMonthOnly: 指定月だけ変更。前後の月は元の金額のまま(行を前・中・後に分割)
    /// - fromThisMonth: 指定月以降を変更。以降に設定済みの行(単月変更など)は削除して上書き
    static func apply(
        amount: Int,
        categoryID: UUID,
        type: TransactionType,
        month: Int,
        scope: BudgetScope,
        context: ModelContext
    ) throws {
        let id = categoryID
        let descriptor = FetchDescriptor<Budget>(predicate: #Predicate { $0.categoryID == id })
        let rows = try context.fetch(descriptor).filter { $0.type == type }
        let now = Date()
        let isUnset = amount <= 0
        
        switch scope {
        case .fromThisMonth:
            // 指定月以降に始まる行は削除
            for b in rows where b.startMonth >= month {
                context.delete(b)
            }
            // 指定月をまたぐ行は前月で終了
            for b in rows where b.startMonth < month && b.contains(month: month) {
                b.endMonth = YearMonth.previous(month)
                b.updatedAt = now
            }
            if !isUnset {
                context.insert(Budget(
                    categoryID: categoryID, type: type, amount: amount,
                    startMonth: month, endMonth: nil, createdAt: now, updatedAt: now
                ))
            }
            
        case .thisMonthOnly:
            guard let target = applied(in: rows, type: type, month: month) else {
                // その月に予算がなければ、単月の行を追加するだけ(未設定なら何もしない)
                if !isUnset {
                    context.insert(Budget(
                        categoryID: categoryID, type: type, amount: amount,
                        startMonth: month, endMonth: month, createdAt: now, updatedAt: now
                    ))
                }
                break
            }
            if !isUnset && target.amount == amount { return }   // 変更なし
            
            let oldAmount = target.amount
            let oldEnd = target.endMonth
            
            // 後ろ: 翌月以降は元の金額で続ける
            let continuesAfter = (oldEnd == nil) || ((oldEnd ?? 0) > month)
            if continuesAfter {
                context.insert(Budget(
                    categoryID: categoryID, type: type, amount: oldAmount,
                    startMonth: YearMonth.next(month), endMonth: oldEnd, createdAt: now, updatedAt: now
                ))
            }
            
            // 前・中
            if target.startMonth < month {
                // 指定月より前から続く行: 前月で終了し、単月の行を追加(未設定なら追加しない)
                target.endMonth = YearMonth.previous(month)
                target.updatedAt = now
                if !isUnset {
                    context.insert(Budget(
                        categoryID: categoryID, type: type, amount: amount,
                        startMonth: month, endMonth: month, createdAt: now, updatedAt: now
                    ))
                }
            } else if isUnset {
                // 指定月から始まる行: 未設定ならその行を削除
                context.delete(target)
            } else {
                // 指定月から始まる行: その行自体を単月の行に変える
                target.amount = amount
                target.endMonth = month
                target.updatedAt = now
            }
        }
        
        try context.save()
    }
    
    /// カテゴリー削除時の予算の整理(指定月以降を削除、過去月は残す)
    /// カテゴリー本体の削除と同じタイミングで呼び、最後に1回だけ context.save() してください(ここでは保存しません)
    static func removeBudgets(categoryID: UUID, fromMonth month: Int, context: ModelContext) throws {
        let id = categoryID
        let descriptor = FetchDescriptor<Budget>(predicate: #Predicate { $0.categoryID == id })
        let rows = try context.fetch(descriptor)
        let now = Date()
        
        for b in rows {
            if b.startMonth >= month {
                context.delete(b)
            } else if b.contains(month: month) {
                b.endMonth = YearMonth.previous(month)
                b.updatedAt = now
            }
        }
    }
}
