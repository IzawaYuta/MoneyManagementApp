import XCTest

@MainActor
final class CalendarEditUITests: AppUITestCase {
    
    // MARK: - 記録を作る
    
    /// ホームの日付を「今日以外の日」に変えて、1000円の支出を保存し、記録タブでその日を選ぶ
    private func saveOnOtherDayAndOpenRecords() {
        changeHomeDate(toDay: otherDay)
        
        tapQuick(1000)
        confirmAndWait()
        openRecordsTab()
        dayCell(otherDay).tap()
        
        if !recordRows.firstMatch.waitForExistence(timeout: 5) {
            attachScreenshot("別の日を選んだ記録タブ")
            let cells = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'calendar.day.'"))
                .allElementsBoundByIndex.map { "id=[\($0.identifier)] label=[\($0.label)]" }
            XCTFail("別の日の記録が表示されませんでした\n--- 日付セル ---\n\(cells.joined(separator: "\n"))")
        }
    }
    
    // MARK: - 上書き画面の操作
    
    /// 種類を変える(メニューを開いて選ぶ)
    private func changeType(to name: String) {
        app.buttons["overwrite.typePicker"].tap()
        let item = app.buttons[name].exists ? app.buttons[name] : app.menuItems[name]
        XCTAssertTrue(item.waitForExistence(timeout: 5), "メニューに「\(name)」がありません\n\(app.debugDescription)")
        item.tap()
    }
    
    /// 選択シートの中の項目(文言の一部で探す)をタップし、シートが閉じて上書き画面に反映されるまで待つ
    /// 選ぶ名前は、今の表示と違うものにすること(開いている間に、上書き画面のボタンと取り違えないため)
    private func selectInSheet(_ name: String, opening button: String) {
        app.buttons[button].tap()
        
        // シートが開いている間だけ存在する「閉じる」ボタン
        let sheetClose = app.buttons["閉じる"]
        XCTAssertTrue(sheetClose.waitForExistence(timeout: 5), "選択シートが開きませんでした\n\(buttonSummary())")
        
        let item = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", name)).firstMatch
        XCTAssertTrue(item.waitForExistence(timeout: 5), "「\(name)」が見つかりません\n\(buttonSummary())")
        item.tap()
        
        // シートが閉じる(「閉じる」が消える)まで待つ
        let closed = expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: sheetClose)
        if XCTWaiter().wait(for: [closed], timeout: 5) != .completed {
            attachScreenshot("タップしてもシートが閉じない")
            XCTFail("「\(name)」をタップしても、シートが閉じません(アプリ側のタップ処理を確認)\n\(buttonSummary())")
            return
        }
        
        // 上書き画面のボタン(識別子で固定)の表示が、選んだ名前に変わる
        let opener = app.buttons[button]
        let reflected = expectation(for: NSPredicate(format: "label CONTAINS %@", name), evaluatedWith: opener)
        if XCTWaiter().wait(for: [reflected], timeout: 5) != .completed {
            XCTFail("シートは閉じましたが、ボタンの表示が「\(name)」になっていません: \(opener.label)")
        }
    }
    
    private func changeCategory(to name: String) {
        selectInSheet(name, opening: "overwrite.categoryButton")
    }
    
    private func changePaymentMethod(to name: String) {
        selectInSheet(name, opening: "overwrite.paymentButton")
    }
        
    /// 日付を「今月の◯日」に変える(日付ボタン → カレンダーの日をタップ。選ぶとシートが閉じる)
    private func changeDate(toDay day: Int) {
        app.buttons["overwrite.dateButton"].tap()
        let picker = app.datePickers.firstMatch
        XCTAssertTrue(picker.waitForExistence(timeout: 5), "日付ピッカーが開きませんでした")
        
        let cell = pickerDayButton(picker, day: day)
        if !cell.waitForExistence(timeout: 3) {
            let labels = picker.buttons.allElementsBoundByIndex.map { "[\($0.label)]" }
            XCTFail("\(day)日のボタンが見つかりません。ピッカー内のボタン:\n\(labels.joined(separator: "\n"))")
            return
        }
        cell.tap()
        waitUntilGone(app.datePickers.firstMatch)
    }
    
    private func expectDateButtonShows(day: Int) {
        let comps = Calendar.current.dateComponents([.year, .month], from: Date())
        let text = String(format: "%04d/%02d/%02d", comps.year ?? 0, comps.month ?? 0, day)
        let label = app.buttons["overwrite.dateButton"].label
        XCTAssertTrue(label.contains(text), "日付の表示が違います: \(label)(期待: \(text))")
    }
    
    // MARK: - 種類
    
    func testChangeTypeToIncomeUpdatesList() throws {
        saveExpenseAndOpenRecords()
        openOverwriteScreen()
        
        changeType(to: "収入")
        saveOverwrite()
        
        let row = recordRows.firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        XCTAssertTrue(row.label.contains("+1,000円"), "収入になっていません: \(row.label)")
        XCTAssertEqual(recordRows.count, 1)
    }
    
    // MARK: - カテゴリー・支払方法
    
    func testChangeCategoryUpdatesList() throws {
        saveExpenseAndOpenRecords()
        openOverwriteScreen()
        
        changeCategory(to: "交通費")
        saveOverwrite()
        
        let row = recordRows.firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        XCTAssertTrue(row.label.contains("交通費"), "カテゴリーが変わっていません: \(row.label)")
        XCTAssertFalse(row.label.contains("食費"), "古いカテゴリーが残っています: \(row.label)")
        XCTAssertTrue(row.label.contains("-1,000円"), "金額が変わっています: \(row.label)")
    }
    
    func testChangePaymentMethodUpdatesList() throws {
        saveExpenseAndOpenRecords()
        openOverwriteScreen()
        
        changePaymentMethod(to: "メインカード")
        saveOverwrite()
        
        let row = recordRows.firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        XCTAssertTrue(row.label.contains("メインカード"), "支払方法が変わっていません: \(row.label)")
        XCTAssertFalse(row.label.contains("現金"), "古い支払方法が残っています: \(row.label)")
        XCTAssertTrue(row.label.contains("食費"), "カテゴリーが変わっています: \(row.label)")
    }
    
    func testChangeTypeCategoryAndPaymentMethodAtOnce() throws {
        saveExpenseAndOpenRecords()
        openOverwriteScreen()
        
        changeType(to: "収入")
        changeCategory(to: "交通費")
        changePaymentMethod(to: "メインカード")
        saveOverwrite()
        
        let row = recordRows.firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        XCTAssertTrue(row.label.contains("+1,000円"), "種類が違います: \(row.label)")
        XCTAssertTrue(row.label.contains("交通費"), "カテゴリーが違います: \(row.label)")
        XCTAssertTrue(row.label.contains("メインカード"), "支払方法が違います: \(row.label)")
        XCTAssertEqual(recordRows.count, 1)
    }
    
    // MARK: - 日付(日をまたぐ移動)
    
    func testChangeDateMovesRecordToOtherDay() throws {
        saveExpenseAndOpenRecords()
        openOverwriteScreen()
        
        changeDate(toDay: otherDay)
        expectDateButtonShows(day: otherDay)
        saveOverwrite()
        
        // 今日は空になり、移動先の日に記録が出る
        XCTAssertTrue(emptyMessage.waitForExistence(timeout: 5), "元の日に、記録が残っています")
        XCTAssertEqual(recordRows.count, 0)
        XCTAssertFalse(cellAmounts(today).contains("1000"), "元の日のセルに金額が残っています: \(dayCell(today).label)")
        XCTAssertTrue(cellAmounts(otherDay).contains("1000"), "移動先のセルに金額が出ません: \(dayCell(otherDay).label)")
        
        dayCell(otherDay).tap()
        XCTAssertTrue(recordRows.firstMatch.waitForExistence(timeout: 5), "移動先の日に、記録が表示されません")
        XCTAssertEqual(recordRows.count, 1)
    }
    
    func testEditRecordOnOtherDayAndMoveToToday() throws {
        saveOnOtherDayAndOpenRecords()
        XCTAssertTrue(cellAmounts(otherDay).contains("1000"), "別の日のセルに、金額が出ていません: \(dayCell(otherDay).label)")
        openOverwriteScreen()
        
        changeDate(toDay: today)
        expectDateButtonShows(day: today)
        saveOverwrite()
        
        // 元の別の日は空になり、今日に記録が出る
        XCTAssertTrue(emptyMessage.waitForExistence(timeout: 5), "元の日に、記録が残っています")
        XCTAssertFalse(cellAmounts(otherDay).contains("1000"), "元の日のセルに金額が残っています: \(dayCell(otherDay).label)")
        XCTAssertTrue(cellAmounts(today).contains("1000"), "今日のセルに金額が出ません: \(dayCell(today).label)")
        
        dayCell(today).tap()
        XCTAssertTrue(recordRows.firstMatch.waitForExistence(timeout: 5), "今日に、記録が表示されません")
        XCTAssertEqual(recordRows.count, 1)
    }
    
    func testChangeDateAndAmountAtOnce() throws {
        saveExpenseAndOpenRecords()
        openOverwriteScreen()
        
        changeDate(toDay: otherDay)
        clearOverwriteAmount()
        app.textFields["overwrite.amountField"].typeText("2500")
        saveOverwrite()
        
        XCTAssertTrue(cellAmounts(otherDay).contains("2500"), "移動先のセルの金額が違います: \(dayCell(otherDay).label)")
        XCTAssertFalse(cellAmounts(today).contains("1000"), "元の日のセルに、古い金額が残っています: \(dayCell(today).label)")
    }
}
