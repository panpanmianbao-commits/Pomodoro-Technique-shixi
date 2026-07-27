import SwiftUI

// MARK: - 排名视图
/// 展示用户排行榜，待后续实现具体数据加载
struct RankingView: View {
    @EnvironmentObject var vm: ShixiViewModel

    var body: some View {
        VStack(spacing: 16) {
            // 标题
            Text("专注排行榜")
                .font(.system(size: 28, weight: .bold, design: .serif))
                .padding(.top)

            // 占位内容
            if let user = vm.currentUser {
                Text("欢迎，\(user.username)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "trophy")
                .font(.system(size: 80))
                .foregroundColor(.yellow.opacity(0.6))

            Text("排行榜功能即将上线")
                .font(.title3)
                .foregroundColor(.secondary)

            Text("在这里你可以看到所有用户的专注时长排名")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(vm.currentTheme.bgColor.ignoresSafeArea())
        .navigationTitle("排名")
        .navigationBarTitleDisplayMode(.inline)
    }
}
