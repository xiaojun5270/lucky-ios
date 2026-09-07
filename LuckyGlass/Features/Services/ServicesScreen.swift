import SwiftUI

/// `app/(tabs)/manage.tsx`.
///
/// The seven service entry points, grouped by direct management and tunnelling.
struct ServicesScreen: View {
    @Environment(\.luckyNavigator) private var navigator

    var body: some View {
        LuckyPage(spacing: 18) {
            LuckyWorkspaceHeader(
                eyebrow: "服务工作台",
                title: "服务",
                subtitle: "7 个服务入口"
            )

            VStack(alignment: .leading, spacing: 10) {
                LuckySectionHeader(title: "服务管理", subtitle: "网络、容器与自动化",
                                   symbol: "square.grid.2x2.fill")
                LuckyTileGrid(minimum: 145, spacing: LuckyTheme.Space.m) {
                    ServiceCompactTile(symbol: "globe.asia.australia", label: "反向代理",
                                       detail: "代理与 TLS", tone: .brand) {
                        navigator.push(.webservice)
                    }
                    ServiceCompactTile(symbol: "shippingbox", label: "Docker",
                                       detail: "容器与镜像", tone: .warning) {
                        navigator.push(.docker())
                    }
                    ServiceCompactTile(symbol: "arrow.triangle.2.circlepath", label: "动态域名",
                                       detail: "域名解析", tone: .info) {
                        navigator.push(.service(.ddns))
                    }
                    ServiceCompactTile(symbol: "checkmark.shield", label: "SSL 证书",
                                       detail: "证书续期", tone: .ok) {
                        navigator.push(.service(.ssl))
                    }
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                LuckySectionHeader(title: "内网穿透", subtitle: "隧道与代理",
                                   symbol: "point.3.connected.trianglepath.dotted")
                LuckyCard(padding: 0, spacing: 0) {
                    ForEach(Array(TunnelKind.allCases.enumerated()), id: \.offset) { index, kind in
                        if index > 0 { LuckyHairline().padding(.leading, 62) }
                        ServiceListRow(symbol: kind.symbol, label: kind.title, detail: kind.detail,
                                       tone: kind.tone) {
                            navigator.push(.tunnel(kind))
                        }
                    }
                }
            }

        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct ServiceCompactTile: View {
    var symbol: String
    var label: String
    var detail: String
    var tone: LuckyTone
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    LuckyIconTile(symbol: symbol, size: 40, glyph: 18, tone: tone)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(LuckyTheme.textTertiary)
                        .accessibilityHidden(true)
                }
                Text(label)
                    .font(LuckyTheme.Text.cardTitle)
                    .foregroundStyle(LuckyTheme.textPrimary)
                Text(detail)
                    .font(LuckyTheme.Text.caption)
                    .foregroundStyle(LuckyTheme.textTertiary)
            }
            .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
        }
        .buttonStyle(LuckyCardButtonStyle(radius: LuckyTheme.Radius.card))
    }
}

private struct ServiceListRow: View {
    var symbol: String
    var label: String
    var detail: String
    var tone: LuckyTone
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: LuckyTheme.Space.m) {
                LuckyIconTile(symbol: symbol, size: 38, glyph: 17, tone: tone)
                VStack(alignment: .leading, spacing: 3) {
                    Text(label).font(LuckyTheme.Text.cardTitle)
                    Text(detail)
                        .font(LuckyTheme.Text.caption)
                        .foregroundStyle(LuckyTheme.textSecondary)
                        .lineLimit(1)
                }
                .foregroundStyle(LuckyTheme.textPrimary)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(LuckyTheme.textTertiary)
            }
            .padding(.horizontal, LuckyTheme.Space.l)
            .frame(minHeight: 64)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
