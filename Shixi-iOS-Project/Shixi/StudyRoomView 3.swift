// StudyRoomView.swift
import SwiftUI

struct StudyRoomView: View {
    @EnvironmentObject var vm: ShixiViewModel
    @StateObject private var roomManager = StudyRoomManager()
    @State private var joinCode = ""
    @State private var showCreate = false
    @State private var showJoin = false

    var body: some View {
        VStack(spacing: 20) {
            if roomManager.isConnected {
                syncContentView
            } else {
                if showCreate {
                    createRoomView
                } else if showJoin {
                    joinRoomView
                } else {
                    mainMenuView
                }
            }
        }
        .padding()
        .navigationTitle("自习室")
        .onDisappear {
            roomManager.disconnect()
        }
        .onReceive(roomManager.$isConnected) { connected in
            if !connected {
                vm.roomManager = nil
            }
        }
        .onAppear {
            vm.roomManager = roomManager

            // ✅ 修正1：捕获类实例 vm 和 roomManager 为 weak
            roomManager.onReceiveMessage = { [weak vm, weak roomManager] message in
                guard let vm = vm, let roomManager = roomManager else { return }
                switch message {
                case .stateUpdate(let payload):
                    if !roomManager.isHost {
                        vm.applySyncPayload(payload)
                    }
                }
            }

            // ✅ 修正2：只捕获 vm（如果需要广播，无需 roomManager）
            roomManager.onPeerConnected = { [weak vm] in
                vm?.broadcastCurrentState()
            }
        }
    }

    // MARK: - 主菜单
    private var mainMenuView: some View {
        VStack(spacing: 30) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 60))
                .foregroundColor(vm.currentTheme.accentColor)

            Text("连接到同一 Wi-Fi\n输入房间码同步学习")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            Button("创建自习室") {
                showCreate = true
            }
            .buttonStyle(PrimaryButtonStyle())

            Button("加入自习室") {
                showJoin = true
            }
            .buttonStyle(SecondaryButtonStyle())
        }
    }

    // MARK: - 创建房间
    private var createRoomView: some View {
        VStack(spacing: 20) {
            Text("你的房间码")
                .font(.headline)
            Text(roomManager.roomCode)
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundColor(vm.currentTheme.primaryColor)

            if roomManager.connectionError != nil {
                Text(roomManager.connectionError!)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            Button("开始广播") {
                roomManager.startHost()
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!roomManager.roomCode.isEmpty)

            Button("取消") {
                roomManager.disconnect()
                showCreate = false
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .onAppear {
            roomManager.startHost()
        }
    }

    // MARK: - 加入房间
    private var joinRoomView: some View {
        VStack(spacing: 20) {
            TextField("请输入6位房间码", text: $joinCode)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numberPad)
                .frame(maxWidth: 250)
                .multilineTextAlignment(.center)

            if roomManager.connectionError != nil {
                Text(roomManager.connectionError!)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            Button("加入") {
                guard joinCode.count == 6 else { return }
                roomManager.startClient(with: joinCode)
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(joinCode.count != 6)

            Button("取消") {
                showJoin = false
            }
            .buttonStyle(SecondaryButtonStyle())
        }
    }

    // MARK: - 同步内容视图
    private var syncContentView: some View {
        VStack(spacing: 16) {
            HStack {
                Text("已连接 \(roomManager.connectedPeerCount) 个设备")
                    .font(.caption)
                    .foregroundColor(.green)
                Spacer()
                Button("退出自习室") {
                    roomManager.disconnect()
                }
                .font(.caption)
            }
            .padding(.horizontal)

            VStack(spacing: 8) {
                Text("同步计时")
                    .font(.headline)
                HStack {
                    Text(formatTime(vm.remainingSeconds))
                        .font(.system(size: 40, weight: .medium, design: .serif))
                    if vm.isRunning {
                        Image(systemName: "play.fill")
                            .foregroundColor(.green)
                    } else if vm.isPaused {
                        Image(systemName: "pause.fill")
                            .foregroundColor(.orange)
                    }
                }
                ProgressView(value: vm.progress)
                    .tint(vm.currentTheme.progressColor)

                HStack {
                    Text(vm.currentStation.name)
                        .font(.caption)
                    if vm.isMusicPlaying {
                        Image(systemName: "speaker.wave.2.fill")
                    }
                }
                .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)

            if !roomManager.isHost {
                Text("你正以观众模式加入，计时由主机控制")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                // 主机模式不显示额外提示
            }
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        if h > 0 {
            return String(format: "%02d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }
}

// MARK: - 按钮样式
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.black)
            .foregroundColor(.white)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .fontWeight(.medium)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .foregroundColor(.primary)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4))
            )
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}
