import WidgetKit
import SwiftUI
import SwiftData

@main
struct NextSliceWidgetBundle: WidgetBundle {
    var body: some Widget {
        NextSliceTodayWidget()
    }
}

struct NextSliceTodayWidget: Widget {
    let kind = "NextSliceTodayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodayProvider()) { entry in
            TodayWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Today's slice")
        .description("Your one thing, always visible.")
        .supportedFamilies([
            .systemSmall,
            .accessoryRectangular,
            .accessoryInline,
            .accessoryCircular
        ])
    }
}
