//
//  BudgetMonthCapsule.swift
//  MoneyManagementApp
//
//  Created by Engineer MacBook Air on 2026/11/18.
//


import SwiftUI

// MARK: - 月の選択(カプセル型)
/// 「‹ 2026年11月 ›」を1つの白いカプセルにまとめた月の切り替え部品。
/// `month` は yyyymm 形式(例: 202611)。
struct BudgetMonthCapsule: View {
    let month: Int
    let onPrevious: () -> Void
    let onNext: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            arrowButton(systemName: "chevron.left", label: "前月", action: onPrevious)

            Text(YearMonth.label(month))
                .font(.headline)
                .frame(minWidth: 128)
                .accessibilityAddTraits(.isHeader)

            arrowButton(systemName: "chevron.right", label: "翌月", action: onNext)
        }
        .padding(2)
        .background(Color(.secondarySystemGroupedBackground), in: Capsule())
        .shadow(color: .black.opacity(0.08), radius: 4, y: 1)
        .frame(maxWidth: .infinity)   // 画面の中央に配置
        .padding(.vertical, 8)
    }

    private func arrowButton(systemName: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 44, height: 44)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
        .accessibilityLabel(label)
    }
}

// MARK: - Preview
#Preview {
    struct Demo: View {
        @State private var month = 202611
        var body: some View {
            BudgetMonthCapsule(
                month: month,
                onPrevious: { month = YearMonth.previous(month) },
                onNext: { month = YearMonth.next(month) }
            )
            .background(Color(.systemGroupedBackground))
        }
    }
    return Demo()
}