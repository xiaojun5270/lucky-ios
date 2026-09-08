import SwiftUI

/// `app/(tabs)/manage.tsx`.
///
/// The seven service entry points, grouped by direct management and tunnelling.
struct ServicesScreen: View {
    @Environment(\.luckyNavigator) private var navigator

    var body: some View {
        LuckyPage(spacing: LuckyTheme.Space.section) {
            VStack(alignment: .leading, spacing: LuckyTheme.Space.m) {
                LuckySectionHeader(title: "服务管理", subtitle: "网络、容器与自动化",
                                   symbol: "square.grid.2x2.fill", iconRole: .neutral)
                LuckyTileGrid(minimum: 145, spacing: LuckyTheme.Space.m) {
                    ServiceCompactTile(symbol: "globe.asia.australia", label: "反向代理",
                                       detail: "代理与 TLS",
                                       iconRole: LuckyServiceKind.webservice.iconRole) {
                        navigator.push(.webservice)
                    }
                    ServiceCompactTile(symbol: "shippingbox", label: "Docker",
                                       detail: "容器与镜像",
                                       iconRole: LuckyServiceKind.docker.iconRole) {
                        navigator.push(.docker())
                    }
                    ServiceCompactTile(symbol: "arrow.triangle.2.circlepath", label: "动态域名",
                                       detail: "域名解析",
                                       iconRole: LuckyServiceKind.ddns.iconRole) {
                        navigator.push(.service(.ddns))
                    }
                    ServiceCompactTile(symbol: "checkmark.shield", label: "SSL 证书",
                                       detail: "证书续期",
                                       iconRole: LuckyServiceKind.ssl.iconRole) {
                        navigator.push(.service(.ssl))
                    }
                }
            }

            VStack(alignment: .leading, spacing: LuckyTheme.Space.m) {
                LuckySectionHeader(title: "内网穿透", subtitle: "隧道与代理",
                                   symbol: "point.3.connected.trianglepath.dotted", iconRole: .tunnels)
                LuckyCard(padding: 0, spacing: 0) {
                    ForEach(Array(TunnelKind.allCases.enumerated()), id: \.offset) { index, kind in
                        if index > 0 {
                            LuckyHairline()
                                .padding(.leading, LuckyTheme.Space.cardInset + 38 + LuckyTheme.Space.m)
                        }
                        ServiceListRow(symbol: kind.symbol, label: kind.title, detail: kind.detail,
                                       iconRole: kind.iconRole) {
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
    var iconRole: LuckyIconRole
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: LuckyTheme.Space.m) {
                HStack {
                    LuckyIconTile(symbol: symbol, size: 40, glyph: 18, role: iconRole)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(LuckyTheme.textTertiary)
                        .accessibilityHidden(true)
                }
                VStack(alignment: .leading, spacing: LuckyTheme.Space.xs) {
                    Text(label)
                        .font(LuckyTheme.Text.cardTitle)
                        .foregroundStyle(LuckyTheme.textPrimary)
                    Text(detail)
                        .font(LuckyTheme.Text.caption)
                        .foregroundStyle(LuckyTheme.textTertiary)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 100, alignment: .topLeading)
        }
        .buttonStyle(LuckyCardButtonStyle(radius: LuckyTheme.Radius.card))
    }
}

private struct ServiceListRow: View {
    var symbol: String
    var label: String
    var detail: String
    var iconRole: LuckyIconRole
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: LuckyTheme.Space.m) {
                LuckyIconTile(symbol: symbol, size: 38, glyph: 17, role: iconRole)
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
            .padding(.horizontal, LuckyTheme.Space.cardInset)
            .padding(.vertical, LuckyTheme.Space.m)
            .frame(minHeight: 68)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
