
import SwiftUI

struct SettingListView: View {
    
    @State private var showMailView = false
    
    let privacyPolicyURL: String = "https://wooded-starburst-67e.notion.site/3e3e36f7a27180b6b7fef0d8dbcca9ec?source=copy_link"
    
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
                        Button("お問い合わせ") {
                            showMailView = true
                        }
                        .foregroundColor(Color.black)
                        .sheet(isPresented: $showMailView) {
                            MailView(
                                recipients: ["example@example.com"],
                                subject: "お問い合わせ"
                            )
                        }
                        
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
