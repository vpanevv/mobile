import SwiftUI

struct PrimaryActionButton: View {
    let title: String
    let systemImage: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(title)
                if let systemImage {
                    Image(systemName: systemImage)
                }
            }
        }
        .buttonStyle(TimeMapPrimaryButtonStyle())
    }
}
