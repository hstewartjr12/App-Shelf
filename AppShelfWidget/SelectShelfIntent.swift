import AppIntents
import WidgetKit

struct SelectShelfIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Select Shelf"
    static var description = IntentDescription("Choose which shelf to display in the widget.")

    @Parameter(title: "Shelf", default: nil)
    var shelf: ShelfEntity?
}
