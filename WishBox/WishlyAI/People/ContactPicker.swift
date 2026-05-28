import SwiftUI
import ContactsUI

// MARK: - CNContactPickerViewController wrapper
// Uses the out-of-process picker — no Contacts permission prompt required.

struct ContactPicker: UIViewControllerRepresentable {
    /// Called with (name, day, month) — day and month are nil if the contact has no birthday.
    var onSelect: (_ name: String, _ day: Int?, _ month: Int?) -> Void
    var onCancel: () -> Void = {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onSelect: onSelect, onCancel: onCancel)
    }

    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let vc = CNContactPickerViewController()
        // We want name + birthday date component
        vc.displayedPropertyKeys = [
            CNContactGivenNameKey,
            CNContactFamilyNameKey,
            CNContactBirthdayKey
        ]
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ vc: CNContactPickerViewController, context: Context) {}

    // MARK: - Coordinator
    final class Coordinator: NSObject, CNContactPickerDelegate {
        let onSelect: (_ name: String, _ day: Int?, _ month: Int?) -> Void
        let onCancel: () -> Void

        init(onSelect: @escaping (_ name: String, _ day: Int?, _ month: Int?) -> Void,
             onCancel: @escaping () -> Void) {
            self.onSelect = onSelect
            self.onCancel = onCancel
        }

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            let given  = contact.givenName
            let family = contact.familyName
            var name   = [given, family].filter { !$0.isEmpty }.joined(separator: " ")
            if name.isEmpty { name = "Unknown" }

            var day: Int?
            var month: Int?
            if let bday = contact.birthday {
                day   = bday.day
                month = bday.month
            }
            DispatchQueue.main.async { self.onSelect(name, day, month) }
        }

        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            DispatchQueue.main.async { self.onCancel() }
        }
    }
}
