import SwiftUI

/// `app/(tabs)/settings.tsx`.
struct SettingsScreen: View {
    @State private var session = LuckySession.shared
    @State private var busy = false
    @State private var confirming = false

    var body: some View {
        LuckyPage {
            connection
            security
            logout
        }
        .luckyTitle("设置", "当前 Lucky 连接")
        // `Alert.alert('退出登录', '确定结束当前 Lucky 会话吗？', …)` — a decision, so it stays an
        // alert rather than becoming a toast.
        .alert("退出登录", isPresented: $confirming) {
            Button("取消", role: .cancel) {}
            Button("退出", role: .destructive) { leave() }
        } message: {
            Text("确定结束当前 Lucky 会话吗？")
        }
    }

    private var connection: some View {
        LuckyCard {
            HStack(spacing: LuckyTheme.Space.m) {
                LuckyIconTile(symbol: "server.rack", size: 46, glyph: 22)
                VStack(alignment: .leading, spacing: LuckyTheme.Space.xs) {
                    Text(session.account.isEmpty ? "管理员" : session.account)
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundStyle(LuckyTheme.textPrimary)
                    Text(session.baseUrl)
                        .font(LuckyTheme.Text.caption)
                        .foregroundStyle(LuckyTheme.textSecondary)
                        .lineLimit(2)
                        .textSelection(.enabled)
                }
                Spacer(minLength: LuckyTheme.Space.s)
                LuckyStatusDot(tone: .ok, size: 9)
            }
            LuckyHairline()
            VStack(alignment: .leading, spacing: LuckyTheme.Space.s) {
                note("person", "账号已保存")
                note("key", "凭据由设备安全存储保护")
            }
        }
    }

    private func note(_ symbol: String, _ text: String) -> some View {
        HStack(spacing: 9) {
            LuckyIconTile(symbol: symbol, size: 28, glyph: 14, tone: .idle)
            Text(text)
                .font(LuckyTheme.Text.caption)
                .foregroundStyle(LuckyTheme.textSecondary)
        }
    }

    private var security: some View {
        LuckyCard {
            HStack(spacing: 9) {
                LuckyIconTile(symbol: "checkmark.shield", tone: .ok)
                Text("连接安全")
                    .font(LuckyTheme.Text.cardTitle)
                    .foregroundStyle(LuckyTheme.textPrimary)
            }
            Text("公网访问时应在 Lucky 前配置 HTTPS 与访问控制。管理 Token 不会写入 Web 的持久存储。")
                .font(LuckyTheme.Text.body)
                .foregroundStyle(LuckyTheme.textSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var logout: some View {
        let shape = RoundedRectangle(cornerRadius: LuckyTheme.Radius.row, style: .continuous)
        return Button {
            confirming = true
        } label: {
            HStack(spacing: LuckyTheme.Space.s) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 15, weight: .semibold))
                Text(busy ? "正在退出" : "退出登录")
                    .font(LuckyTheme.Text.button)
            }
            .foregroundStyle(LuckyTheme.danger)
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(shape.fill(LuckyTheme.surface))
            .overlay(shape.strokeBorder(LuckyTheme.danger, lineWidth: LuckyTheme.strokeWidth))
        }
        .buttonStyle(.plain)
        .disabled(busy)
    }

    /// `leave()`: tell the server, then drop the local session whatever the server said — a failed
    /// `/api/logout` must not trap the user in a session they asked to end. The root view swaps to
    /// the login screen as soon as the token clears, which is `router.replace('/login')`.
    private func leave() {
        guard !busy else { return }
        busy = true
        Task {
            do { _ = try await LuckyService.logout() } catch {}
            await session.end()
            busy = false
        }
    }
}
