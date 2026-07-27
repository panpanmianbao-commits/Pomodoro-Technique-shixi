import SwiftUI

// MARK: - 主标签栏视图
/// 应用的主标签栏，包含「主页」和「排名」两个标签
struct MainTabView: View {
    @EnvironmentObject var vm: ShixiViewModel

    var body: some View {
        TabView {
            // 主页标签 - 包含原有计时器等功能
            NavigationStack {
                ContentView()
            }
            .tabItem {
                Image(systemName: "house.fill")
                Text("主页")
            }

            // 排名标签 - 显示用户排行榜
            NavigationStack {
                RankingView()
            }
            .tabItem {
                Image(systemName: "trophy.fill")
                Text("排名")
            }
        }
        // 使用 iOS 14+ 默认的 TabView 风格，底部标签栏
        // 如需 iOS 17+ 的风格可改为 .tabViewStyle(.sidebar) 等，但这里保持标准底部标签
    }
}
