import SwiftUI

/// Post-reflection rest state. Confirms the day is closed and shows the future
/// action so the user goes to bed knowing tomorrow's seed.
struct CompletedTodayView: View {
    let entry: DailyEntry

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle")
                .font(.system(size: 56, weight: .ultraLight))
                .foregroundStyle(.tint)

            VStack(spacing: 6) {
                Text("오늘은 마감되었어요.")
                    .font(.title2.weight(.medium))
                Text("노트에 한 조각 더 쌓였어요.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let future = entry.futureAction {
                VStack(alignment: .leading, spacing: 6) {
                    Text("내일의 씨앗")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(future)
                        .font(.callout)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 20)
            }

            Spacer()
        }
        .padding()
    }
}
