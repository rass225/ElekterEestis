import WidgetKit
import SwiftUI
import Charts

@main
struct ElectricityWidgetBundle: WidgetBundle {
    var body: some Widget {
        ElectricityWidget()
    }
}

struct ElectricityWidget: Widget {
    let kind: String = "ElectricityWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ElectricityWidgetProvider()) { entry in
            ElectricityWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Elekter")
        .description("Järgmiste tundide elektrihinnad.")
        .supportedFamilies([
            .accessoryInline,
            .accessoryRectangular,
            .accessoryCircular,
            .systemSmall,
            .systemMedium,
        ])
    }
}

struct ElectricityWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: ElectricityWidgetEntry

    var body: some View {
        Group {
            switch family {
            case .accessoryInline:
                LockScreenInlineView(entry: entry)
            case .accessoryRectangular:
                LockScreenRectangularView(entry: entry)
            case .accessoryCircular:
                LockScreenCircularView(entry: entry)
            case .systemSmall:
                HomeScreenSmallView(entry: entry)
            case .systemMedium:
                HomeScreenMediumView(entry: entry)
            default:
                HomeScreenSmallView(entry: entry)
            }
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }
}
