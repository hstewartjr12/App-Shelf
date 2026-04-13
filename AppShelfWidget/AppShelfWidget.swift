import WidgetKit
import SwiftUI

@main
struct AppShelfWidgetBundle: WidgetBundle {
    var body: some Widget {
        CurrentlyTrackingWidget()
    }
}

struct CurrentlyTrackingWidget: Widget {
    let kind = "CurrentlyTrackingWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: SelectShelfIntent.self,
            provider: CurrentlyTrackingProvider()
        ) { entry in
            CurrentlyTrackingWidgetView(entry: entry)
        }
        .configurationDisplayName("My Shelf")
        .description("See what's on your shelf at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}
