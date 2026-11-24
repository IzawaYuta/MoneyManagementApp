import XCTest

@MainActor
final class CalendarUITests: AppUITestCase {
    
    private var monthTitle: XCUIElement {
        app.staticTexts["calendar.monthTitle"]
    }
    
    // MARK: - 日付セルと一覧
    
    func testSavedExpenseShowsOnTodayCellAndList() throws {
        saveExpenseAndOpenRecords()
        
        XCTAssertTrue(cellAmounts(today).contains("1000"), "今日のセル: \(dayCell(today).label)")
        let row = recordRows.firstMatch
        XCTAssertTrue(row.label.contains("-1,000円"), "金額が違います: \(row.label)")
        XCTAssertTrue(row.label.contains("食費"), "カテゴリーが違います: \(row.label)")
        XCTAssertEqual(recordRows.count, 1)
    }
    
    func testSelectingOtherDayShowsEmptyAndBackShowsRecord() throws {
        saveExpenseAndOpenRecords()
        
        dayCell(otherDay).tap()
        XCTAssertTrue(emptyMessage.waitForExistence(timeout: 5), "記録のない日に、空のメッセージが出ませんでした")
        XCTAssertEqual(recordRows.count, 0)
        
        dayCell(today).tap()
        XCTAssertTrue(recordRows.firstMatch.waitForExistence(timeout: 5), "今日に戻しても、記録が表示されませんでした")
        XCTAssertEqual(recordRows.count, 1)
    }
    
    func testIncomeAndExpenseOnSameDay() throws {
        saveExpense(1000)
        saveIncome(5000)
        openRecordsTab()
        XCTAssertTrue(recordRows.firstMatch.waitForExistence(timeout: 5))
        
        let amounts = cellAmounts(today)
        XCTAssertTrue(amounts.contains("1000"), "支出が、今日のセルにありません: \(dayCell(today).label)")
        XCTAssertTrue(amounts.contains("5000"), "収入が、今日のセルにありません: \(dayCell(today).label)")
        XCTAssertEqual(recordRows.count, 2)
    }
    
    // MARK: - 月の切り替え
    
    func testMonthNavigationMovesAndComesBack() throws {
        saveExpenseAndOpenRecords()
        let original = monthTitle.label
        
        app.buttons["calendar.prevMonth"].tap()
        XCTAssertNotEqual(monthTitle.label, original, "前月に移動していません")
        // 前の月の同じ日には、今日の記録の金額は出ない(その日が存在しない月は除く)
        if dayCell(today).exists {
            XCTAssertFalse(cellAmounts(today).contains("1000"), "前月のセルに金額が出ています: \(dayCell(today).label)")
        }
        
        app.buttons["calendar.nextMonth"].tap()
        XCTAssertEqual(monthTitle.label, original, "元の月に戻っていません")
        XCTAssertTrue(cellAmounts(today).contains("1000"), "元の月のセルに、金額が戻っていません: \(dayCell(today).label)")
    }
    
    // MARK: - 上書き
    
    func testOverwriteUpdatesListAndCell() throws {
        saveExpenseAndOpenRecords()
        openOverwriteScreen()
        clearOverwriteAmount()
        app.textFields["overwrite.amountField"].typeText("2500")
        
        saveOverwrite()
        
        let row = recordRows.firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        XCTAssertTrue(row.label.contains("-2,500円"), "一覧の金額が違います: \(row.label)")
        XCTAssertTrue(cellAmounts(today).contains("2500"), "セルの金額が違います: \(dayCell(today).label)")
        XCTAssertFalse(cellAmounts(today).contains("1000"), "古い金額が残っています: \(dayCell(today).label)")
        XCTAssertEqual(recordRows.count, 1)
    }
    
    func testDiscardChangesKeepsOriginalRecord() throws {
        saveExpenseAndOpenRecords()
        openOverwriteScreen()
        clearOverwriteAmount()
        app.textFields["overwrite.amountField"].typeText("2500")
        
        app.buttons["overwrite.closeButton"].tap()
        let alert = app.alerts["変更を破棄"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5), "破棄の確認アラートが出ませんでした")
        alert.buttons["破棄"].tap()
        
        waitUntilGone(app.navigationBars["上書き"])
        let row = recordRows.firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        XCTAssertTrue(row.label.contains("-1,000円"), "破棄したのに、金額が変わっています: \(row.label)")
    }
    
    func testDiscardCancelStaysOnOverwriteScreen() throws {
        saveExpenseAndOpenRecords()
        openOverwriteScreen()
        
        app.buttons["overwrite.closeButton"].tap()
        let alert = app.alerts["変更を破棄"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        alert.buttons["キャンセル"].tap()
        
        waitUntilGone(alert)
        XCTAssertTrue(app.navigationBars["上書き"].exists, "キャンセルしたのに、上書き画面が閉じました")
    }
    
    // MARK: - 削除
    
    func testDeleteRemovesRecord() throws {
        saveExpenseAndOpenRecords()
        openOverwriteScreen()
        
        app.buttons["削除"].tap()
        let alert = app.alerts["削除確認"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5), "削除の確認アラートが出ませんでした")
        alert.buttons["削除"].tap()
        
        waitUntilGone(app.navigationBars["上書き"])
        XCTAssertTrue(emptyMessage.waitForExistence(timeout: 5), "削除後に、空のメッセージが出ませんでした")
        XCTAssertEqual(recordRows.count, 0)
        XCTAssertFalse(cellAmounts(today).contains("1000"), "セルに、削除した金額が残っています: \(dayCell(today).label)")
    }
    
    func testDeleteCancelKeepsRecord() throws {
        saveExpenseAndOpenRecords()
        openOverwriteScreen()
        
        app.buttons["削除"].tap()
        let alert = app.alerts["削除確認"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        alert.buttons["キャンセル"].tap()
        
        waitUntilGone(alert)
        XCTAssertTrue(app.navigationBars["上書き"].exists, "キャンセルしたのに、上書き画面が閉じました")
    }
}
