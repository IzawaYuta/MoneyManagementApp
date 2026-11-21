
import XCTest

@MainActor
final class HomeRecordingUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        // テスト用の起動設定 + 表示を日本語・日本のロケールに固定(金額の表記を揃えるため)
        app.launchArguments = ["-uiTesting", "-AppleLanguages", "(ja)", "-AppleLocale", "ja_JP"]
        app.launch()
    }

    // MARK: - Helper

    /// 金額表示のテキスト(識別子で探す。見つからなければ、画面の中身を出して失敗させる)
    private func amountText() -> XCUIElement {
        let text = app.staticTexts["home.amountText"]
        if !text.waitForExistence(timeout: 5) {
            XCTFail("金額表示が見つかりません\n\(app.debugDescription)")
        }
        return text
    }
    
    /// 金額表示の数字だけ(通貨記号やカンマはロケールで変わるため、数字だけで比べる)
    private func amountDigits() -> String {
        amountText().label.filter(\.isNumber)
    }
    
    /// カレンダーの記録の行(「円」を含む部品を探す。ボタン以外として認識されていても拾う)
    private func firstRecordRow() -> XCUIElement {
        let row = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS '円'"))
            .firstMatch
        
        if !row.waitForExistence(timeout: 5) {
            // 失敗時の診断: スクリーンショットと、画面上の部品の一覧を残す
            let attachment = XCTAttachment(screenshot: app.screenshot())
            attachment.name = "記録タブの画面"
            attachment.lifetime = .keepAlways
            add(attachment)
            
            let buttons = app.buttons.allElementsBoundByIndex
                .map { "Button id=[\($0.identifier)] label=[\($0.label)]" }
            let texts = app.staticTexts.allElementsBoundByIndex
                .map { "Text id=[\($0.identifier)] label=[\($0.label)]" }
            XCTFail("記録の行が表示されませんでした\n--- Buttons ---\n\(buttons.joined(separator: "\n"))\n--- Texts ---\n\(texts.joined(separator: "\n"))")
        }
        return row
    }
    
    /// 「確定」を押し、チェックマークのアニメーションが終わる(ボタンが再び押せる)まで待つ
    private func confirmAndWait() {
        let confirm = app.buttons["home.confirmButton"]
        confirm.tap()
        let enabled = expectation(for: NSPredicate(format: "isEnabled == true"), evaluatedWith: confirm)
        wait(for: [enabled], timeout: 5)
    }
    
    private func tapQuick(_ amount: Int) {
        app.buttons["home.quickAmount.\(amount)"].tap()
    }

    private func openRecordsTab() {
        // キーボードが開いていると、タブバーが覆われて押せないので、先に閉じる
        let keyboard = app.keyboards.firstMatch
        if keyboard.exists {
            let returnKey = keyboard.buttons["Return"]
            if returnKey.exists { returnKey.tap() }
            let closed = expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: keyboard)
            wait(for: [closed], timeout: 3)
        }
        app.tabBars.buttons["記録"].tap()
    }
    
    // MARK: - 初期状態

    func testInitialState() throws {
        let text = amountText()
        XCTAssertEqual(amountDigits(), "0", "金額表示のラベル: [\(text.label)]")
        XCTAssertTrue(app.buttons["home.categoryCard"].label.contains("食費"))
        XCTAssertTrue(app.buttons["home.paymentCard"].label.contains("現金"))
    }
    // MARK: - 金額の入力

    func testQuickAmountButtoHelpernsAccumulate() throws {
        tapQuick(100)
        tapQuick(500)
        tapQuick(1000)
        tapQuick(5000)

        XCTAssertEqual(amountDigits(), "6600")
    }

    func testClearResetsAmount() throws {
        tapQuick(500)
        XCTAssertEqual(amountDigits(), "500")

        app.buttons["home.clearButton"].tap()

        XCTAssertEqual(amountDigits(), "0")
    }

    // MARK: - 保存

    func testSaveClearsAmount() throws {
        tapQuick(1000)

        confirmAndWait()

        XCTAssertEqual(amountDigits(), "0")
    }

    func testSavedExpenseAppearsInRecords() throws {
        tapQuick(1000)

        confirmAndWait()
        openRecordsTab()

        let row = firstRecordRow()
        XCTAssertTrue(row.label.contains("-1,000円"), "金額が違います: \(row.label)")
        XCTAssertTrue(row.label.contains("食費"), "カテゴリーが違います: \(row.label)")
        XCTAssertTrue(row.label.contains("現金"), "支払方法が違います: \(row.label)")
    }

    func testSavedIncomeAppearsAsPlus() throws {
        app.segmentedControls.buttons["収入"].tap()
        tapQuick(5000)

        confirmAndWait()
        openRecordsTab()

        let row = firstRecordRow()
        XCTAssertTrue(row.label.contains("+5,000円"), "金額が違います: \(row.label)")
    }

    func testSavedMemoAppearsInRecords() throws {
        tapQuick(500)
        let memo = app.textFields["home.memoField"]
        memo.tap()
        memo.typeText("lunch")

        confirmAndWait()
        openRecordsTab()

        let row = firstRecordRow()
        XCTAssertTrue(row.label.contains("lunch"), "メモが違います: \(row.label)")
    }
}
