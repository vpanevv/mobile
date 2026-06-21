import SwiftUI
import WidgetKit

@main
struct GarageWidgetBundle: WidgetBundle {
    var body: some Widget {
        NextServiceWidget()
        SpendWidget()
        ServiceLiveActivity()
    }
}
