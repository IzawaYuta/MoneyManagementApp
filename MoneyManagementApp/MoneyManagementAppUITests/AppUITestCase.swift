import XCTest

/// UIテスト共通の土台(テスト用の起動設定と、よく使う操作)
@MainActor
class AppUITestCase: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-AppleLanguages", "(ja)", "-AppleLocale", "ja_JP"]
        app.launch()
    }
    
    // MARK: - 日付
    
    var today: Int { Calendar.current.component(.day, from: Date()) }
    
    /// 今日と同じ月の、今日以外の日(月初なら2日、それ以外は前日)
    var otherDay: Int { today == 1 ? 2 : today - 1 }
    
    // MARK: - ホームの操作
    
    func tapQuick(_ amount: Int) {
        app.buttons["home.quickAmount.\(amount)"].tap()
    }
    
    /// 金額表示の数字だけ
    func amountDigits() -> String {
        app.staticTexts["home.amountText"].label.filter(\.isNumber)
    }
    
    /// 「確定」を押し、チェックマークのアニメーションが終わる(ボタンが再び押せる)まで待つ
    func confirmAndWait() {
        let confirm = app.buttons["home.confirmButton"]
        confirm.tap()
        let enabled = expectation(for: NSPredicate(format: "isEnabled == true"), evaluatedWith: confirm)
        wait(for: [enabled], timeout: 5)
    }
    
    func openRecordsTab() {
        app.tabBars.buttons["記録"].tap()
    }
    
    func openInputTab() {
        app.tabBars.buttons["入力"].tap()
    }
    
    /// 今日の日付で、支出を保存する(既定のカテゴリー「食費」・支払方法「現金」)
    func saveExpense(_ amount: Int) {
        tapQuick(amount)
        confirmAndWait()
    }
    
    /// 今日の日付で、収入を保存する(保存後は支出に戻す)
    func saveIncome(_ amount: Int) {
        app.segmentedControls.buttons["収入"].tap()
        tapQuick(amount)
        confirmAndWait()
        app.segmentedControls.buttons["支出"].tap()
    }
    
    /// 1000円の支出を保存して、記録タブを開く
    func saveExpenseAndOpenRecords() {
        saveExpense(1000)
        openRecordsTab()
        XCTAssertTrue(recordRows.firstMatch.waitForExistence(timeout: 5), "記録の行が表示されませんでした")
    }
    
    // MARK: - 記録タブの部品
    
    /// 「円」を含む記録の行(カレンダー下の一覧)
    var recordRows: XCUIElementQuery {
        app.buttons.matching(NSPredicate(format: "label CONTAINS '円'"))
    }
    
    func dayCell(_ day: Int) -> XCUIElement {
        app.buttons["calendar.day.\(day)"]
    }
    
    var emptyMessage: XCUIElement {
        app.staticTexts["この日の記録はありません"]
    }
    
    /// ラベルを「, 」で区切り、それぞれの数字だけを取り出す(例: "24, 5,000, 1,000" → ["24", "5000", "1000"])
    func numbers(in label: String) -> [String] {
        label.components(separatedBy: ", ").map { $0.filter(\.isNumber) }
    }
    
    /// その日のセルに出ている金額(数字だけ)。先頭の日付は含まない
    func cellAmounts(_ day: Int) -> [String] {
        Array(numbers(in: dayCell(day).label).dropFirst())
    }
    
    // MARK: - 上書き画面の操作
    
    /// 記録の行をタップして、上書き画面を開く
    func openOverwriteScreen() {
        recordRows.firstMatch.tap()
        XCTAssertTrue(app.navigationBars["上書き"].waitForExistence(timeout: 5), "上書き画面が開きませんでした")
    }
    
    /// 「上書きする」を押して、上書き画面が閉じるまで待つ
    func saveOverwrite() {
        app.buttons["上書きする"].tap()
        waitUntilGone(app.navigationBars["上書き"])
    }
    
    /// 上書き画面の金額を、すべて消す(カーソルを末尾に置き、空になるまで1文字ずつ削除する)
    func clearOverwriteAmount() {
        let field = app.textFields["overwrite.amountField"]
        XCTAssertTrue(field.waitForExistence(timeout: 5), "金額欄が見つかりません")
        field.coordinate(withNormalizedOffset: CGVector(dx: 0.98, dy: 0.5)).tap()
        
        func isEmpty() -> Bool {
            let text = (field.value as? String) ?? ""
            return text.isEmpty || text == field.placeholderValue
        }
        
        var tries = 0
        while !isEmpty() && tries < 15 {
            field.typeText(XCUIKeyboardKey.delete.rawValue)
            tries += 1
        }
        XCTAssertTrue(isEmpty(), "金額を消しきれませんでした: [\(field.value as? String ?? "")]")
    }
    
    // MARK: - 日付ピッカー
    
    /// 日付ピッカー内の「今月の◯日」のボタン(英語表記 "…, November 22" と、日本語表記 "11月22日" のどちらでも探す)
    func pickerDayButton(_ picker: XCUIElement, day: Int) -> XCUIElement {
        let calendar = Calendar.current
        var comps = calendar.dateComponents([.year, .month], from: Date())
        comps.day = day
        let date = calendar.date(from: comps)!
        
        let en = DateFormatter()
        en.locale = Locale(identifier: "en_US_POSIX")
        en.dateFormat = "MMMM d"          // 例: November 22
        let month = comps.month ?? 0
        
        let predicate = NSPredicate(
            format: "label ENDSWITH %@ OR label CONTAINS %@",
            en.string(from: date), "\(month)月\(day)日"
        )
        return picker.buttons.matching(predicate).firstMatch
    }
    
    /// ホームの日付を、下の「日付」行のシートで「今月の◯日」に変える(日を選ぶとシートが閉じる)
    func changeHomeDate(toDay day: Int) {
        let month = Calendar.current.component(.month, from: Date())
        
        let dateButton = app.buttons["home.dateButton"]
        XCTAssertTrue(dateButton.waitForExistence(timeout: 5), "ホームの日付行が見つかりません\n\(buttonSummary())")
        dateButton.tap()
        
        let picker = app.datePickers.firstMatch
        if !picker.waitForExistence(timeout: 5) {
            attachScreenshot("日付シートが開かなかったホーム")
            XCTFail("日付ピッカーが開きませんでした(ホーム)\n\(buttonSummary())")
            return
        }
        
        let cell = pickerDayButton(picker, day: day)
        if !cell.waitForExistence(timeout: 3) {
            let labels = picker.buttons.allElementsBoundByIndex.map { "[\($0.label)]" }
            XCTFail("\(day)日のボタンが見つかりません。ピッカー内のボタン:\n\(labels.joined(separator: "\n"))")
            return
        }
        cell.tap()
        waitUntilGone(app.datePickers.firstMatch)
        
        // 日付行の中の文字(「2026年11月23日」)が、選んだ日になる
        let shown = app.buttons["home.dateButton"].staticTexts
            .matching(NSPredicate(format: "label CONTAINS %@", "\(month)月\(day)日")).firstMatch
        if !shown.waitForExistence(timeout: 5) {
            attachScreenshot("日付を選んだあとのホーム")
            XCTFail("ホームの日付が\(month)月\(day)日になっていません\n\(buttonSummary())")
        }
    }
    
    // MARK: - 待つ・診断
    
    func waitUntilGone(_ element: XCUIElement, timeout: TimeInterval = 5) {
        let gone = expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: element)
        wait(for: [gone], timeout: timeout)
    }
    
    /// 画面上のボタンの一覧(失敗メッセージ用)
    func buttonSummary() -> String {
        app.buttons.allElementsBoundByIndex
            .map { "Button id=[\($0.identifier)] label=[\($0.label)]" }
            .joined(separator: "\n")
    }
    
    /// スクリーンショットを残す(失敗の診断用)
    func attachScreenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
