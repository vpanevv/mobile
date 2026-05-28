import SwiftUI
import ContactsUI
import Contacts

struct ContactPicker: UIViewControllerRepresentable {
    var onSelect: (_ name: String, _ day: Int?, _ month: Int?) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onSelect: onSelect)
    }

    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}

    // MARK: - Coordinator (retained by SwiftUI — delegate is never deallocated)

    final class Coordinator: NSObject, CNContactPickerDelegate {
        let onSelect: (_ name: String, _ day: Int?, _ month: Int?) -> Void

        init(onSelect: @escaping (_ name: String, _ day: Int?, _ month: Int?) -> Void) {
            self.onSelect = onSelect
        }

        // Single-contact selection — fires on a normal row tap
        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            let given  = contact.givenName.trimmingCharacters(in: .whitespaces)
            let family = contact.familyName.trimmingCharacters(in: .whitespaces)
            let full   = [given, family].filter { !$0.isEmpty }.joined(separator: " ")
            let name   = full.isEmpty ? "Unknown" : full

            var day: Int?   = nil
            var month: Int? = nil
            if let bday = contact.birthday {
                day   = bday.day
                month = bday.month
            }

            DispatchQueue.main.async {
                self.onSelect(name, day, month)
            }
        }

        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            // Sheet is dismissed automatically; no action needed
        }
    }
}
