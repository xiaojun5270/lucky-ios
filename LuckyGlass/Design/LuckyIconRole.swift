import SwiftUI

/// Function identity is independent of status and action emphasis (`LuckyTone`).
/// Pass a role for shared glyphs such as `network` and `globe.asia.australia`.
enum LuckyIconRole: String, CaseIterable, Sendable {
    case web, docker, ddns, security, tunnels, cloudflared, frp
    case system, server, network, storage, automation, media, settings, logs, account, tools, neutral
    case create, start, edit

    /// Opaque plates keep white symbols legible in both appearances. These are deliberately
    /// darker than the text accents, which become lighter in dark mode.
    var color: Color {
        switch self {
        case .web: Self.purple
        case .docker: Self.blue
        case .ddns, .network: Self.teal
        case .security, .create, .start: Self.green
        case .tunnels: Self.grape
        case .cloudflared, .automation, .edit: Self.orange
        case .frp, .account: Self.berry
        case .system: Self.amber
        case .storage: Self.brown
        case .media: Self.magenta
        case .tools: Self.purple
        case .server, .settings, .logs, .neutral: Self.graphite
        }
    }

    private static let purple = LuckyTheme.dynamic(light: 0x7950BC, dark: 0x8055C2)
    private static let blue = LuckyTheme.dynamic(light: 0x2563BD, dark: 0x2C68C2)
    private static let teal = LuckyTheme.dynamic(light: 0x16766D, dark: 0x197B72)
    private static let green = LuckyTheme.dynamic(light: 0x247B4F, dark: 0x298056)
    private static let grape = LuckyTheme.dynamic(light: 0x8A4AA3, dark: 0x9151AB)
    private static let orange = LuckyTheme.dynamic(light: 0xB65F20, dark: 0xB65F20)
    private static let berry = LuckyTheme.dynamic(light: 0xA14370, dark: 0xA84A78)
    private static let amber = LuckyTheme.dynamic(light: 0x956619, dark: 0x9A6B20)
    private static let brown = LuckyTheme.dynamic(light: 0x88633B, dark: 0x906B43)
    private static let magenta = LuckyTheme.dynamic(light: 0x9B4790, dark: 0xA24F97)
    private static let graphite = LuckyTheme.dynamic(light: 0x586273, dark: 0x626D7F)

    /// Defaults for unambiguous utility glyphs. A new symbol gets a neutral plate until its
    /// feature supplies a role, rather than silently adding another blue icon.
    static func symbol(_ symbol: String) -> LuckyIconRole {
        switch symbol {
        case "cpu", "memorychip", "waveform.path.ecg", "speedometer", "gauge": .system
        case "server.rack": .server
        case "network", "wifi", "cable.connector", "link", "arrow.left.arrow.right": .network
        case "internaldrive", "internaldrive.fill", "externaldrive", "folder",
             "folder.fill", "folder.badge.person.crop", "externaldrive.badge.icloud": .storage
        case "lock", "lock.fill", "lock.shield", "lock.shield.fill", "checkmark.shield",
             "shield.lefthalf.filled", "key", "key.fill", "person.badge.key": .security
        case "point.3.connected.trianglepath.dotted", "point.3.filled.connected.trianglepath.dotted",
             "antenna.radiowaves.left.and.right", "dot.radiowaves.left.and.right": .tunnels
        case "cloud": .cloudflared
        case "cube.transparent", "shippingbox": .docker
        case "point.topleft.down.to.point.bottomright.curvepath", "arrow.triangle.branch": .web
        case "photo.on.rectangle.angled": .media
        case "flowchart", "clock.arrow.circlepath", "clock", "bolt.fill": .automation
        case "gearshape", "gearshape.2", "slider.horizontal.3": .settings
        case "text.alignleft", "doc.text", "terminal": .logs
        case "person", "person.fill", "person.crop.circle", "person.2", "person.2.wave.2": .account
        case "curlybraces", "curlybraces.square", "testtube.2", "wrench.and.screwdriver": .tools
        case "plus": .create
        case "play.fill": .start
        case "square.and.pencil", "pencil": .edit
        default: .neutral
        }
    }

    static func module(_ key: String) -> LuckyIconRole {
        switch key {
        case "webservice": .web
        case "docker": .docker
        case "ddns", "ddnstasklist": .ddns
        case "ssl", "coraza", "twofapassword": .security
        case "stun", "stunrule", "stunrulelist", "stunrulelist_lite": .tunnels
        case "cloudflared": .cloudflared
        case "frp": .frp
        case "info": .server
        case "status": .system
        default: symbol(LuckySymbol.module(key))
        }
    }
}

extension LuckyServiceKind {
    var iconRole: LuckyIconRole {
        switch self {
        case .webservice: .web
        case .docker: .docker
        case .ddns: .ddns
        case .ssl: .security
        }
    }
}

extension TunnelKind {
    var iconRole: LuckyIconRole {
        switch self {
        case .stun: .tunnels
        case .cloudflared: .cloudflared
        case .frp: .frp
        }
    }
}
