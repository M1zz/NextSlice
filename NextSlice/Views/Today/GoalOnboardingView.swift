import SwiftUI

/// Shown in place of MorningModeView when the user has never created a goal.
/// Hard gate: the morning intent doesn't get asked until at least one goal has
/// passed through the wizard. After that, the gate doesn't re-fire even if the
/// user archives or deletes all goals — autonomy stands once experienced.
struct GoalOnboardingView: View {
    @State private var showWizard = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "flag.checkered.circle")
                .font(.system(size: 60, weight: .light))
                .foregroundStyle(.tint)

            VStack(spacing: 10) {
                Text("먼저 목표 하나만 잡고 가요")
                    .font(.title2.weight(.semibold))
                    .multilineTextAlignment(.center)
                Text("오늘 한 발을 어디로 디딜지 정해야\n매일의 한 조각이 의미가 생겨요.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            VStack(alignment: .leading, spacing: 10) {
                bullet("큰 목표 하나를 적어요")
                bullet("이번 주말까지 끝낼 작은 한 발을 같이 정해요")
                bullet("이게 끝나면 오늘부터 매일의 한 조각을 쌓아요")
            }
            .padding(.horizontal, 28)
            .padding(.top, 4)

            Spacer()

            Button {
                showWizard = true
            } label: {
                Text("목표 만들기")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                    .fontWeight(.semibold)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .padding(.top, 20)
        .sheet(isPresented: $showWizard) {
            GoalCreationWizardView()
        }
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Circle()
                .fill(Color.accentColor.opacity(0.7))
                .frame(width: 6, height: 6)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary.opacity(0.85))
            Spacer()
        }
    }
}
