import XCTest

@MainActor
final class ZeroAmountUITests: AppUITestCase {
    
    // MARK: - Helper
    
    private var zeroAlert: XCUIElement {
        app.alerts["金額が0円です"]
    }
    
    private func waitForAlert(file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(zeroAlert.waitForExistence(timeout: 5), "0円のアラートが出ませんでした", file: file, line: line)
    }
    
    private func waitForAlertToClose() {
        waitUntilGone(zeroAlert)
    }
    
    // MARK: - ホーム: 0円のとき
    
    func testHomeZeroAmountShowsAlert() throws {
        app.buttons["home.confirmButton"].tap()
        
        waitForAlert()
        XCTAssertTrue(zeroAlert.buttons["キャンセル"].exists)
        XCTAssertTrue(zeroAlert.buttons["0円で記録"].exists)
    }
    
    func testHomeZeroAmountCancelDoesNotSave() throws {
        app.buttons["home.confirmButton"].tap()
        waitForAlert()
        
        zeroAlert.buttons["キャンセル"].tap()
        waitForAlertToClose()
        
        openRecordsTab()
        XCTAssertTrue(emptyMessage.waitForExistence(timeout: 5))
        XCTAssertEqual(recordRows.count, 0)
    }
    
    func testHomeZeroAmountRecordSavesZeroYen() throws {
        app.buttons["home.confirmButton"].tap()
        waitForAlert()
        
        zeroAlert.buttons["0円で記録"].tap()
        waitForAlertToClose()
        
        openRecordsTab()
        let row = recordRows.firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5), "記録の行が表示されませんでした")
        XCTAssertTrue(row.label.contains("-0円"), "金額が違います: \(row.label)")
        XCTAssertEqual(recordRows.count, 1)
    }
    
    func testHomeCancelThenEnterAmountSavesWithoutAlert() throws {
        app.buttons["home.confirmButton"].tap()
        waitForAlert()
        zeroAlert.buttons["キャンセル"].tap()
        waitForAlertToClose()
        
        tapQuick(500)
        confirmAndWait()
        
        XCTAssertFalse(zeroAlert.exists, "1円以上なのにアラートが出ました")
        openRecordsTab()
        let row = recordRows.firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        XCTAssertTrue(row.label.contains("-500円"), "金額が違います: \(row.label)")
        XCTAssertEqual(recordRows.count, 1)
    }
    
    // MARK: - ホーム: 1円以上のとき(アラートが出ない)
    
    func testHomeNonZeroAmountSavesWithoutAlert() throws {
        tapQuick(1000)
        
        confirmAndWait()
        
        XCTAssertFalse(zeroAlert.exists, "1円以上なのにアラートが出ました")
        XCTAssertEqual(amountDigits(), "0")      // 保存されて、入力欄が空に戻る
        openRecordsTab()
        XCTAssertTrue(recordRows.firstMatch.waitForExistence(timeout: 5))
        XCTAssertEqual(recordRows.count, 1, "記録が1件になっていません")
    }
    
    // MARK: - 上書き画面: 0円のとき
    
    func testOverwriteZeroAmountShowsAlert() throws {
        saveExpenseAndOpenRecords()
        openOverwriteScreen()
        clearOverwriteAmount()
        
        app.buttons["上書きする"].tap()
        
        waitForAlert()
        XCTAssertTrue(zeroAlert.buttons["キャンセル"].exists)
        XCTAssertTrue(zeroAlert.buttons["0円で上書き"].exists)
    }
    
    func testOverwriteZeroAmountCancelStaysOnScreen() throws {
        saveExpenseAndOpenRecords()
        openOverwriteScreen()
        clearOverwriteAmount()
        app.buttons["上書きする"].tap()
        waitForAlert()
        
        zeroAlert.buttons["キャンセル"].tap()
        waitForAlertToClose()
        
        XCTAssertTrue(app.navigationBars["上書き"].exists, "キャンセルしたのに、上書き画面が閉じました")
    }
    
    func testOverwriteZeroAmountSavesZeroYen() throws {
        saveExpenseAndOpenRecords()
        openOverwriteScreen()
        clearOverwriteAmount()
        app.buttons["上書きする"].tap()
        waitForAlert()
        
        zeroAlert.buttons["0円で上書き"].tap()
        
        waitUntilGone(app.navigationBars["上書き"])
        let row = recordRows.firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        XCTAssertTrue(row.label.contains("-0円"), "金額が違います: \(row.label)")
        XCTAssertEqual(recordRows.count, 1, "記録が1件のままになっていません")
    }
    
    func testOverwriteNonZeroAmountSavesWithoutAlert() throws {
        saveExpenseAndOpenRecords()
        openOverwriteScreen()
        clearOverwriteAmount()
        app.textFields["overwrite.amountField"].typeText("2500")
        
        app.buttons["上書きする"].tap()
        
        waitUntilGone(app.navigationBars["上書き"])
        XCTAssertFalse(zeroAlert.exists, "1円以上なのにアラートが出ました")
        let row = recordRows.firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        XCTAssertTrue(row.label.contains("-2,500円"), "金額が違います: \(row.label)")
        XCTAssertEqual(recordRows.count, 1)
    }
    
    func testOverwriteWithoutChangesSavesWithoutAlert() throws {
        saveExpenseAndOpenRecords()
        openOverwriteScreen()
        
        app.buttons["上書きする"].tap()
        
        waitUntilGone(app.navigationBars["上書き"])
        XCTAssertFalse(zeroAlert.exists, "金額を変えていないのにアラートが出ました")
        XCTAssertTrue(recordRows.firstMatch.label.contains("-1,000円"))
    }
}
