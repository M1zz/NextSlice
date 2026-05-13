import WidgetKit
import SwiftUI

struct TodayWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: TodayWidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:
            smallBody
        case .accessoryRectangular:
            rectBody
        case .accessoryInline:
            inlineBody
        case .accessoryCircular:
            circularBody
        default:
            smallBody
        }
    }

    private var smallBody: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("DAY \(entry.dayNumber)")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                if entry.isReflectionPending {
                    Circle()
                        .fill(.red)
                        .frame(width: 6, height: 6)
                }
            }
            Spacer()
            Text(entry.intent)
                .font(.system(size: 13, weight: .medium))
                .lineLimit(4)
                .multilineTextAlignment(.leading)
            Spacer()
            Text("Today's slice")
                .font(.system(size: 9, weight: .regular))
                .foregroundStyle(.tertiary)
        }
    }

    private var rectBody: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "sun.max")
                    .font(.system(size: 10, weight: .semibold))
                Text("Today's slice")
                    .font(.system(size: 10, weight: .semibold))
                if entry.isReflectionPending {
                    Spacer()
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 10))
                }
            }
            Text(entry.intent)
                .font(.system(size: 13, weight: .medium))
                .lineLimit(2)
        }
        .widgetAccentable()
    }

    private var inlineBody: some View {
        Text("\(Image(systemName: "sun.max")) \(entry.intent)")
            .lineLimit(1)
    }

    private var circularBody: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 0) {
                Text("D\(entry.dayNumber)")
                    .font(.system(size: 12, weight: .semibold))
                Text("slice")
                    .font(.system(size: 9))
            }
        }
    }
}
