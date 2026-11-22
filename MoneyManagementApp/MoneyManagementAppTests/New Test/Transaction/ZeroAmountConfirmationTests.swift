
import Testing
import Foundation
@testable import MoneyManagementApp 

@MainActor
struct ZeroAmountConfirmationTests {

    @Test("0・空・数字のない文字列は、0円として扱われる(確認アラートを出す)")
    func zeroLikeInputs() {
        for text in ["0", "", "¥0", "000", "abc", "¥"] {
            #expect(TransactionService.isZeroAmount(text), "入力: [\(text)]")
        }
    }

    @Test("1円以上は、0円ではない(確認アラートを出さない)")
    func nonZeroInputs() {
        for text in ["1", "1000", "¥1,280"] {
            #expect(!TransactionService.isZeroAmount(text), "入力: [\(text)]")
        }
    }
}
