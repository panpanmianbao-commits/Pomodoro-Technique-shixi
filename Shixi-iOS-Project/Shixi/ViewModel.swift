import Combine
import SwiftUI
import AVFoundation

class ShixiViewModel: ObservableObject {

    // MARK: - 自习室同步
    @Published var roomManager: StudyRoomManager?

    // MARK: - 计时核心
    @Published var remainingSeconds: Int = 0
    @Published var totalSeconds: Int = 0
    @Published var isRunning: Bool = false
    @Published var isPaused: Bool = false
    @Published var progress: Double = 0.0
    @Published var timerMode: TimerMode = .normal
    @Published var pomoPhase: PomodoroPhase = .work

    // MARK: - 番茄钟设置
    @Published var pomoWorkMinutes: Int = 25
    @Published var pomoBreakMinutes: Int = 5
    @Published var pomoCycles: Int = 4
    @Published var currentCycle: Int = 0

    // MARK: - 时间输入
    @Published var timeInput: String = ""

    // MARK: - 主题 & 动画
    @Published var currentTheme: AppTheme = .bee
    @Published var pomoTheme: AppTheme = .bee
    @Published var currentFrame: String = ""
    @Published var currentStatus: String = ""
    @Published var showDoneMessage: Bool = false
    @Published var doneMessage: String = ""

    // MARK: - 音乐 & 电台
    @Published var currentStationIndex: Int = 0
    @Published var isMusicPlaying: Bool = false
    @Published var volume: Double = 1.0
    @Published var autoSwitch: Bool = false
    @Published var musicStatus: String = "准备就绪"

    // MARK: - 成就 & 商店
    @Published var achievements: [AchievementItem] = [
        AchievementItem(id: "1", name: "初来乍到", description: "完成第一次计时", isUnlocked: false),
        AchievementItem(id: "2", name: "番茄新手", description: "完成一次番茄钟", isUnlocked: false),
        AchievementItem(id: "3", name: "音乐爱好者", description: "收听音乐超过10分钟", isUnlocked: false),
    ]
    @Published var autumnLeaves: Int = 0
    @Published var coins: Int = 100
    @Published var unlockedThemeIDs: Set<String> = ["bee", "rocket", "fish", "cook"]

    // MARK: - 用户
    @Published var currentUser: AppUser? = nil
    @Published var isShowingAuth: Bool = false
    @Published var authMode: AuthMode = .login

    // MARK: - 内部
    private var timer: Timer?
    private var audioPlayer: AVAudioPlayer?
    private let stations: [RadioStation] = RadioStation.allStations
    private var frameIndex: Int = 0
    private var statusIndex: Int = 0
    private var lastSecondUpdate: TimeInterval = 0   // 用于主题动画帧切换

    var currentStation: RadioStation {
        guard stations.indices.contains(currentStationIndex) else { return stations[0] }
        return stations[currentStationIndex]
    }

    enum AuthMode: String { case login, register }

    // MARK: - 初始化
    init() {}

    // MARK: - 计时控制 ⭐️ 核心实现
    func togglePlayPause() {
        if isRunning && !isPaused {
            // 运行中 → 暂停
            isPaused = true
            timer?.invalidate()
        } else if isPaused {
            // 已暂停 → 继续
            isPaused = false
            startTimerTick()
        } else {
            // 未开始 → 开始新计时
            if timerMode == .normal {
                let seconds = parseTimeInput(timeInput)
                guard seconds > 0 else { return }
                startNormalTimer(seconds: seconds)
            } else {
                startPomodoroTimer()
            }
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        isPaused = false
        remainingSeconds = 0
        totalSeconds = 0
        progress = 0
        showDoneMessage = false
        currentCycle = 0
        pomoPhase = .work
        // 重置动画状态
        frameIndex = 0
        statusIndex = 0
        currentFrame = ""
        currentStatus = ""
    }

    // MARK: - 普通计时器
    private func startNormalTimer(seconds: Int) {
        remainingSeconds = seconds
        totalSeconds = seconds
        isRunning = true
        isPaused = false
        progress = 0
        showDoneMessage = false
        updateAnimationFrame()
        startTimerTick()
    }

    // MARK: - 番茄钟启动
    private func startPomodoroTimer() {
        // 每次启动重新计算，若不希望重置请自行调整
        currentCycle = 0
        pomoPhase = .work
        remainingSeconds = pomoWorkMinutes * 60
        totalSeconds = remainingSeconds
        isRunning = true
        isPaused = false
        progress = 0
        showDoneMessage = false
        updateAnimationFrame()
        startTimerTick()
    }

    // MARK: - 每秒 tick
    private func startTimerTick() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] t in
            guard let self = self else { t.invalidate(); return }
            self.remainingSeconds -= 1
            self.progress = self.totalSeconds > 0 ? 1.0 - Double(self.remainingSeconds) / Double(self.totalSeconds) : 1.0

            // 动画帧切换
            if Date().timeIntervalSince1970 - self.lastSecondUpdate > 0.2 {
                self.lastSecondUpdate = Date().timeIntervalSince1970
                self.updateAnimationFrame()
            }

            // 播放音乐（如果有）
            // 这里省略具体播放逻辑，可自行补充

            if self.remainingSeconds <= 0 {
                self.handleTimerFinish()
            }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    // MARK: - 计时结束
    private func handleTimerFinish() {
        timer?.invalidate()
        timer = nil

        if timerMode == .pomodoro {
            // 番茄钟阶段切换
            if pomoPhase == .work {
                // 完成一个工作段，进入休息
                pomoPhase = .rest
                remainingSeconds = pomoBreakMinutes * 60
                totalSeconds = remainingSeconds
                progress = 0
                startTimerTick()
                // 解锁成就（示例）
                if !achievements[1].isUnlocked {
                    achievements[1].isUnlocked = true
                }
            } else {
                // 休息结束
                currentCycle += 1
                if currentCycle < pomoCycles {
                    pomoPhase = .work
                    remainingSeconds = pomoWorkMinutes * 60
                    totalSeconds = remainingSeconds
                    progress = 0
                    startTimerTick()
                } else {
                    // 所有循环结束
                    finishTiming()
                }
            }
        } else {
            finishTiming()
        }
    }

    private func finishTiming() {
        isRunning = false
        isPaused = false
        showDoneMessage = true
        doneMessage = currentTheme.doneMessage

        // 收集红叶（示例）
        autumnLeaves += 1
        // 解锁成就（第一次完成）
        if !achievements[0].isUnlocked {
            achievements[0].isUnlocked = true
        }

        // 3秒后自动隐藏完成消息
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.showDoneMessage = false
        }

        // 本地通知（需要请求授权）
        sendLocalNotification()
    }

    // MARK: - 动画帧更新
    private func updateAnimationFrame() {
        guard isRunning, !isPaused else { return }
        let theme = timerMode == .pomodoro ? pomoTheme : currentTheme

        if !theme.frames.isEmpty {
            currentFrame = theme.frames[frameIndex % theme.frames.count]
            frameIndex += 1
        }
        if !theme.statuses.isEmpty {
            currentStatus = theme.statuses[statusIndex % theme.statuses.count]
            statusIndex += 1
        }
    }

    // MARK: - 时间输入解析
    private func parseTimeInput(_ input: String) -> Int {
        let lower = input.lowercased().trimmingCharacters(in: .whitespaces)
        if lower.hasSuffix("min") {
            let digits = lower.replacingOccurrences(of: "min", with: "")
            if let minutes = Int(digits) {
                return minutes * 60
            }
        } else if lower.hasSuffix("s") {
            let digits = lower.replacingOccurrences(of: "s", with: "")
            if let seconds = Int(digits) {
                return seconds
            }
        } else {
            // 纯数字当作分钟
            if let minutes = Int(lower) {
                return minutes * 60
            }
        }
        return 0
    }

    // MARK: - 音乐控制
    func toggleMusic() { isMusicPlaying.toggle() }
    func nextStation() { if currentStationIndex < stations.count - 1 { currentStationIndex += 1 } }
    func prevStation() { if currentStationIndex > 0 { currentStationIndex -= 1 } }
    func setVolume(_ v: Double) { volume = v }

    // MARK: - 用户
    func login(username: String, password: String) -> Bool { return true }
    func logout() { currentUser = nil }
    func register(username: String, email: String, password: String, avatarData: Data?) -> Bool {
        currentUser = AppUser(username: username, email: email, avatarData: avatarData, password: password)
        return true
    }
    func updateAvatar(_ data: Data) { currentUser?.avatarData = data }

    // MARK: - 商店
    func purchaseTheme(_ theme: AppTheme) -> Bool {
        guard !unlockedThemeIDs.contains(theme.id), coins >= theme.cost else { return false }
        coins -= theme.cost
        unlockedThemeIDs.insert(theme.id)
        return true
    }

    // MARK: - 本地通知
    private func sendLocalNotification() {
        let content = UNMutableNotificationContent()
        content.title = "⏳ 计时完成"
        content.body = currentTheme.doneMessage
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - 数据持久化（占位）
    func loadSavedData() {}

    // MARK: - 自习室同步
    func broadcastCurrentState() {
        guard let rm = roomManager else { return }
        let payload = Message.StatePayload(
            remainingSeconds: remainingSeconds,
            totalSeconds: totalSeconds,
            isRunning: isRunning,
            isPaused: isPaused,
            timerMode: timerMode.rawValue,
            pomoPhase: pomoPhase.rawValue,
            currentStationIndex: currentStationIndex,
            isMusicPlaying: isMusicPlaying,
            volume: volume
        )
        rm.sendMessage(.stateUpdate(payload))
    }

    func applySyncPayload(_ payload: Message.StatePayload) {
        remainingSeconds = payload.remainingSeconds
        totalSeconds = payload.totalSeconds
        isRunning = payload.isRunning
        isPaused = payload.isPaused
        timerMode = TimerMode(rawValue: payload.timerMode) ?? .normal
        if let phaseStr = payload.pomoPhase {
            pomoPhase = PomodoroPhase(rawValue: phaseStr) ?? .work
        }
        currentStationIndex = payload.currentStationIndex
        isMusicPlaying = payload.isMusicPlaying
        volume = payload.volume
    }
}
