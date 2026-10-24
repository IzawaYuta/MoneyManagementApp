
import SwiftUI

struct SettingListView: View {
    
    @State private var showMailView = false
    
    let privacyPolicyURL: String = "https://wooded-starburst-67e.notion.site/3e3e36f7a27180b6b7fef0d8dbcca9ec?source=copy_link"
    
    let inquiryFormURL: String = "https://docs.google.com/forms/d/e/1FAIpQLScGUQX5XLgiK9TZPl6V8-W2kNeRzTV5JXbrr0kZyJNaBN1C0w/viewform?usp=dialog"
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Link(
                            "プライバシーポリシー",
                            destination: URL(string: privacyPolicyURL)!
                        )
                        .foregroundColor(Color.black)
                        
                        Spacer()
                        
                        Image(systemName: "arrow.up.right.square")
                            .foregroundColor(Color.gray)
                    }
                    
                    HStack {
                        Link(
                            "お問い合わせ",
                            destination: URL(string: inquiryFormURL)!
                        )
                        .foregroundColor(Color.black)
                        
                        Spacer()
                        
                        Image(systemName: "envelope")
                            .foregroundColor(Color.gray)
                    }
                }
            }
            .navigationTitle("サポート")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    SettingListView()
}
