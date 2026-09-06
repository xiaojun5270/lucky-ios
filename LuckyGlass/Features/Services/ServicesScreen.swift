import SwiftUI

/// `app/(tabs)/manage.tsx`.
///
/// Two sections of tiles, plus a third the port adds: `/modules/[module]` and `/endpoints/[id]`
/// exist in the original but nothing links to them — expo-router reaches them by URL only, and a
/// native app has no URL bar. The 45-module browser is part of the app, so it gets a door.
struct ServicesScreen: View {
    @Environment(\.luckyNavigator) private var navigator

    var body: some View {
        LuckyPage {
            LuckySectionHeader(title: "常用服务", symbol: "star.fill")
            LuckyTileGrid {
                ServiceTile(symbol: "globe.asia.australia", label: "反向代理",
                            detail: "域名、后端与 TLS 规则", tone: .brand) {
                    navigator.push(.webservice)
                }
                ServiceTile(symbol: "arrow.triangle.2.circlepath", label: "动态域名",
                            detail: "DDNS 任务与手动同步", tone: .info) {
                    navigator.push(.service(.ddns))
                }
                ServiceTile(symbol: "shippingbox", label: "Docker",
                            detail: "容器状态与启停操作", tone: .warning) {
                    navigator.push(.docker())
                }
                ServiceTile(symbol: "checkmark.shield", label: "SSL 证书",
                            detail: "证书状态与手动同步", tone: .ok) {
                    navigator.push(.service(.ssl))
                }
            }
            LuckySectionHeader(title: "内网穿透", symbol: "point.3.connected.trianglepath.dotted")
            LuckyTileGrid {
                ForEach(TunnelKind.allCases) { kind in
                    ServiceTile(symbol: kind.symbol, label: kind.title, detail: kind.detail,
                                tone: kind.tone) {
                        navigator.push(.tunnel(kind))
                    }
                }
            }
            LuckySectionHeader(title: "开发工具", symbol: "curlybraces")
            LuckyTileGrid {
                ServiceTile(symbol: LuckySymbol.debugger, label: "接口调试",
                            detail: endpointDetail, tone: .brand) {
                    navigator.push(.moduleIndex)
                }
            }
        }
        .luckyTitle("服务")
    }

    private var endpointDetail: String {
        let modules = LuckyEndpointRegistry.modules.count
        let endpoints = LuckyEndpointRegistry.endpoints.count
        return "\(modules) 个模块 · \(endpoints) 个端点"
    }
}

/// `<ServiceButton>`: `flexBasis: 150`, `minHeight: 124`, icon tile and chevron on one line, then
/// the label and a two-line detail.
private struct ServiceTile: View {
    var symbol: String
    var label: String
    var detail: String
    var tone: LuckyTone
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: LuckyTheme.Space.s) {
                HStack {
                    LuckyIconTile(symbol: symbol, size: 42, glyph: 21, tone: tone)
                    Spacer(minLength: LuckyTheme.Space.s)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(LuckyTheme.textTertiary)
                        .frame(width: 28, height: 28)
                        .background(ConcentricRectangle().fill(LuckyTheme.surfaceRaised))
                }
                Text(label)
                    .font(LuckyTheme.Text.cardTitle)
                    .foregroundStyle(LuckyTheme.textPrimary)
                Text(detail)
                    .font(LuckyTheme.Text.caption)
                    .foregroundStyle(LuckyTheme.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(minHeight: 124, alignment: .top)
        }
        .buttonStyle(LuckyCardButtonStyle())
    }
}
