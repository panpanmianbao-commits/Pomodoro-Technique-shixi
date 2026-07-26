import SwiftUI

// MARK: - 商店视图
/// 展示所有主题，支持金币购买和解锁
struct ShopView: View {
    @EnvironmentObject var vm: ShixiViewModel

    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(AppTheme.allThemes) { theme in
                        ThemeShopCard(theme: theme)
                    }
                }
                .padding(16)
            }
            .background(vm.currentTheme.bgColor.ignoresSafeArea())
            .navigationTitle("主题商店")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - 单个主题卡片
struct ThemeShopCard: View {
    let theme: AppTheme
    @EnvironmentObject var vm: ShixiViewModel

    /// 是否已解锁
    private var isUnlocked: Bool {
        vm.unlockedThemeIDs.contains(theme.id)
    }

    /// 是否可以购买
    private var canAfford: Bool {
        vm.coins >= theme.cost
    }

    var body: some View {
        VStack(spacing: 10) {
            // 主题图标
            if let icon = UIImage(named: theme.iconName) {
                Image(uiImage: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48, height: 48)
            } else {
                Image(systemName: "paintpalette")
                    .font(.system(size: 32))
                    .foregroundColor(theme.primaryColor)
            }

            // 主题名称
            Text(theme.name)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary)

            // 分组标签
            Text(theme.group.rawValue)
                .font(.system(size: 11))
                .foregroundColor(.secondary)

            Spacer()
                .frame(height: 4)

            // 状态按钮
            if isUnlocked {
                Text("已解锁")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
            } else if theme.cost > 0 {
                Button {
                    if vm.purchaseTheme(theme) {
                        // 购买成功后自动刷新 UI
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "bitcoinsign.circle.fill")
                            .font(.system(size: 12))
                        Text("\(theme.cost)")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(canAfford ? .white : .gray)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(canAfford ? Color.orange : Color.gray.opacity(0.3))
                    .cornerRadius(8)
                }
                .disabled(!canAfford)
                .buttonStyle(.plain)
            } else {
                Text("免费")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(theme.borderColor, lineWidth: 1.5)
        )
    }
}
