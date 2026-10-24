
import SwiftUI
import MessageUI

struct MailView: UIViewControllerRepresentable {
    let recipients: [String]
    let subject: String
    
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let viewController = MFMailComposeViewController()
        viewController.setToRecipients(recipients)
        viewController.setSubject(subject)
        viewController.mailComposeDelegate = context.coordinator
        return viewController
    }
    
    func updateUIViewController(
        _ uiViewController: MFMailComposeViewController,
        context: Context
    ) {
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(dismiss: dismiss)
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let dismiss: DismissAction
        
        init(dismiss: DismissAction) {
            self.dismiss = dismiss
        }
        
        func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: Error?
        ) {
            dismiss()
        }
    }
}
