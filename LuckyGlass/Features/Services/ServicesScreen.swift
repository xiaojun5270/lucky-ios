import SwiftUI

/// `app/(tabs)/manage.tsx`.
///
/// Two sections of tiles, plus a third the port adds: `/modules/[module]` and `/endpoints/[id]`
/// exist in the original but nothing links to them — expo-router reaches them by URL only, and a
/// native app has no URL bar. The 45-module browser is part of the app, so it gets a door.
struct ServicesScreen: View {
    @Environment(\.luckyNavigator) private var navigator

    var body: some View {
        LuckyPage(spacing: 22) {
            LuckyWorkspaceHeader(
                eyebrow: "服务工作台",
                title: "服务",
                subtitle: "7 个服务入口 · \(LuckyEndpointRegistry.modules.count) 个接口模块"
            )

            VStack(alignment: .leading, spacing: 10) {
                LuckySectionHeader(title: "核心服务", subtitle: "常用管理入口", symbol: "star.fill")
                ServiceLaunchCard(symbol: "globe.asia.australia", label: "反向代理",
                                  detail: "域名、监听、后端与 TLS", meta: "WEB", tone: .brand) {
                    navigator.push(.webservice)
                }
                ServiceLaunchCard(symbol: "shippingbox", label: "Docker",
                                  detail: "容器、镜像、网络与存储", meta: "RUNTIME",
                                  tone: .warning) {
                    navigator.push(.docker())
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                LuckySectionHeader(title: "自动化", subtitle: "域名与证书", symbol: "bolt.fill")
                LuckyTileGrid(minimum: 145, spacing: LuckyTheme.Space.m) {
                    ServiceCompactTile(symbol: "arrow.triangle.2.circlepath", label: "动态域名",
                                       detail: "DDNS 任务", tone: .info) {
                        navigator.push(.service(.ddns))
                    }
                    ServiceCompactTile(symbol: "checkmark.shield", label: "SSL 证书",
                                       detail: "证书状态", tone: .ok) {
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

            VStack(alignment: .leading, spacing: 10) {
                LuckySectionHeader(title: "开发工具", subtitle: endpointDetail,
                                   symbol: "curlybraces")
                ServiceLaunchCard(symbol: LuckySymbol.debugger, label: "接口调试",
                                  detail: "模块索引与请求构建", meta: "API", tone: .brand) {
                    navigator.push(.moduleIndex)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var endpointDetail: String {
        let modules = LuckyEndpointRegistry.modules.count
        let endpoints = LuckyEndpointRegistry.endpoints.count
        return "\(modules) 个模块 · \(endpoints) 个端点"
    }
}

private struct ServiceLaunchCard: View {
    var symbol: String
    var label: String
    var detail: String
    var meta: String
    var tone: LuckyTone
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: LuckyTheme.Space.m) {
                LuckyIconTile(symbol: symbol, size: 52, glyph: 24, tone: tone)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: LuckyTheme.Space.s) {
                        Text(label)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(LuckyTheme.textPrimary)
                        Text(meta)
                            .font(.system(size: 9, weight: .heavy))
                            .foregroundStyle(Color.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(tone.tint, in: .rect(cornerRadius: 4))
                    }
                    Text(detail)
                        .font(LuckyTheme.Text.caption)
                        .foregroundStyle(LuckyTheme.textSecondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                Image(systemName: "arrow.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(tone.tint)
            }
            .padding(LuckyTheme.Space.l)
            .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
        }
        .buttonStyle(LuckyCardButtonStyle(radius: LuckyTheme.Radius.card, padding: 0, tone: tone))
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
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.white)
                        .frame(width: 26, height: 26)
                        .background(tone.tint, in: .rect(cornerRadius: 7))
                        .accessibilityHidden(true)
                }
                Text(label)
                    .font(LuckyTheme.Text.cardTitle)
                    .foregroundStyle(LuckyTheme.textPrimary)
                Text(detail)
                    .font(LuckyTheme.Text.caption)
                    .foregroundStyle(LuckyTheme.textTertiary)
            }
            .frame(maxWidth: .infinity, minHeight: 108, alignment: .topLeading)
        }
        .buttonStyle(LuckyCardButtonStyle(radius: LuckyTheme.Radius.card, tone: tone))
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
