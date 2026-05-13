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
        .configurationDisplayName("오늘의 한 조각")
        .description("당신의 한 가지를 언제나.")
        .supportedFamilies([
            .systemSmall,
            .accessoryRectangular,
            .accessoryInline,
            .accessoryCircular
        ])
    }
}
