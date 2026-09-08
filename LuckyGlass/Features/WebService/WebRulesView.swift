import SwiftUI

/// The eleven verbs a rule row can perform, bundled so `WebRulesView` takes one parameter and not
/// eleven. In the original every one of these is a closure written inline in `renderItem`, closing
/// over the screen's state; `private` being file-scoped in Swift, they have to be handed over.
struct WebRuleActions {
    var expand: (String) -> Void
    var move: (Int, Int) -> Void
    var setEnabled: (String, Bool) -> Void
    /// `(key, copy)` — 编辑 and 复制规则 open the same form.
    var edit: (String, Bool) -> Void
    var remove: (String, String) -> Void
    var order: (WebOrderRequest) -> Void
    var tools: (WebToolsTarget) -> Void
    /// A `nil` sub-key is 添加子规则.
    var editSub: (String, String?) -> Void
    var setSubEnabled: (String, String, Bool) -> Void
    var removeSub: (String, String, String) -> Void
    var copyURL: (LuckyListItem, LuckyListItem) -> Void
}

/// §12 — 规则. The reverse-proxy rules, each expanding to its own sub-rules.
struct WebRulesView: View {
    var items: [LuckyListItem]
    var expanded: String
    var loading: Bool
    var busy: Bool
    var refresh: @Sendable () async -> Void
    var actions: WebRuleActions

    var body: some View {
        WebPaneScroll(refresh: refresh) {
            LuckySectionHeader(title: WebPane.rules.title, symbol: WebPane.rules.symbol,
                               iconRole: WebPane.rules.iconRole) {
                LuckyChip(text: "\(items.count) 项", tone: .idle)
            }
            if loading {
                LuckyLoadingView(text: "正在读取 Web 服务规则")
            } else if items.isEmpty {
                LuckyEmptyState(symbol: WebPane.rules.symbol, title: "暂无 Web 服务规则")
                    .padding(.vertical, LuckyTheme.Space.xl)
            } else {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    WebRuleCard(item: item, index: index, total: items.count, expanded: expanded,
                                busy: busy, actions: actions)
                }
            }
        }
    }
}

// MARK: - 规则卡片

/// One rule panel: disclosure header, enable state and the primary edit action. Less frequent
/// commands live in a menu so the card does not become a toolbar.
private struct WebRuleCard: View {
    var item: LuckyListItem
    var index: Int
    var total: Int
    var expanded: String
    var busy: Bool
    var actions: WebRuleActions

    private var key: String { WebRecord.key(item, index) }
    private var name: String { WebRecord.pick(item, ["RuleName", "Name"], "未命名规则") }
    private var subs: [LuckyListItem] { WebRecord.array(item, ["ProxyList"]) }
    private var enabled: Bool { WebRecord.isEnabled(item) }
    private var isOpen: Bool { expanded == key }

    /// `${Network|tcp} · ${ListenIP|*}:${ListenPort|--} · ${n} 个子规则` — verbatim, port and all.
    /// There is no masking anywhere on this screen.
    private var summary: String {
        let network = WebRecord.pick(item, ["Network"], "tcp")
        let ip = WebRecord.pick(item, ["ListenIP"], "*")
        let port = WebRecord.pick(item, ["ListenPort"], "--")
        return "\(network) · \(ip):\(port) · \(subs.count) 个子规则"
    }

    var body: some View {
        LuckyCard(spacing: 14) {
            header
            status
            if isOpen { expansion }
        }
    }
}

extension WebRuleCard {
    /// The whole header is the disclosure control. The glyph never varies — a rule is a rule,
    /// whatever it proxies.
    private var header: some View {
        Button {
            actions.expand(key)
        } label: {
            HStack(spacing: LuckyTheme.Space.m) {
                LuckyIconTile(symbol: LuckySymbol.network, size: 36, glyph: 16, role: .web)
                VStack(alignment: .leading, spacing: 3) {
                    Text(name)
                        .font(LuckyTheme.Text.cardTitle)
                        .foregroundStyle(LuckyTheme.textPrimary)
                        .lineLimit(1)
                    Text(summary)
                        .font(LuckyTheme.Text.caption)
                        .foregroundStyle(LuckyTheme.textSecondary)
                        .lineLimit(2)
                }
                Spacer(minLength: 0)
                Image(systemName: isOpen ? "chevron.up" : "chevron.down")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .frame(width: 24, height: 24)
                    .background(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(LuckyTheme.idle)
                    )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityHint(isOpen ? "收起子规则" : "展开子规则")
    }

    /// The switch and its sentence are the entire status derivation — no pill, no TLS badge, no
    /// protocol badge.
    private var status: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: LuckyTheme.Space.m) {
                statusControl
                Spacer(minLength: LuckyTheme.Space.m)
                primaryActions
            }
            VStack(alignment: .leading, spacing: LuckyTheme.Space.s) {
                statusControl
                HStack {
                    Spacer(minLength: 0)
                    primaryActions
                }
            }
        }
        .padding(LuckyTheme.Space.s)
        .background(LuckyTheme.surfaceRaised,
                    in: .rect(cornerRadius: LuckyTheme.Radius.row))
    }

    private var statusControl: some View {
        HStack(spacing: LuckyTheme.Space.s) {
            WebEnableSwitch(isOn: enabled, disabled: busy, name: "启用规则") { on in
                actions.setEnabled(key, on)
            }
            .fixedSize()
            Text(enabled ? "已启用" : "已停用")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(LuckyTheme.textSecondary)
        }
        .fixedSize()
    }

    private var primaryActions: some View {
        HStack(spacing: LuckyTheme.Space.s) {
            WebInlineActionButton(title: "编辑", symbol: "pencil", prominent: true) {
                actions.edit(key, false)
            }
            moreMenu
        }
        .fixedSize()
    }

    private var moreMenu: some View {
        Menu {
            Section("顺序") {
                Button {
                    actions.move(index, -1)
                } label: {
                    Label("上移", systemImage: "arrow.up")
                }
                .disabled(busy || index == 0)
                Button {
                    actions.move(index, 1)
                } label: {
                    Label("下移", systemImage: "arrow.down")
                }
                .disabled(busy || index == total - 1)
                Button {
                    actions.order(WebOrderRequest(key: key, name: name, keys: subKeys))
                } label: {
                    Label("子规则排序", systemImage: "list.number")
                }
                .disabled(busy || subs.count < 2)
            }
            Section("规则") {
                Button {
                    actions.edit(key, true)
                } label: {
                    Label("复制规则", systemImage: LuckySymbol.copy)
                }
                Button {
                    actions.tools(WebToolsTarget(ruleKey: key, ruleName: name))
                } label: {
                    Label("更多操作", systemImage: "wrench.and.screwdriver")
                }
                Button(role: .destructive) {
                    actions.remove(key, name)
                } label: {
                    Label("删除规则", systemImage: LuckySymbol.delete)
                }
                .disabled(busy)
            }
        } label: {
            LuckyIconTile(symbol: "ellipsis", size: 36, glyph: 15, tone: .idle)
                .frame(width: LuckyTheme.Space.touchTarget, height: LuckyTheme.Space.touchTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("规则更多操作")
    }

    /// The 排序 payload. `keyOf` again, so a sub-rule with no key of its own is ordered by the
    /// position it currently holds — which is what the sheet then shows.
    private var subKeys: [String] { subs.enumerated().map { WebRecord.key($1, $0) } }
}

extension WebRuleCard {
    /// §12.2 — only for the open rule.
    private var expansion: some View {
        VStack(alignment: .leading, spacing: LuckyTheme.Space.s) {
            LuckyHairline()
            ServiceActionButton(title: "添加子规则", symbol: LuckySymbol.add, tone: .brand,
                                fill: .tinted, height: 40,
                                radius: LuckyTheme.Radius.row) {
                actions.editSub(key, nil)
            }
            if subs.isEmpty {
                Text("暂无子规则")
                    .font(LuckyTheme.Text.caption)
                    .foregroundStyle(LuckyTheme.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, LuckyTheme.Space.m)
            } else {
                ForEach(Array(subs.enumerated()), id: \.offset) { subIndex, sub in
                    WebSubRuleCard(rule: item, sub: sub, index: subIndex, parentKey: key,
                                   parentName: name, busy: busy, actions: actions)
                }
            }
        }
        .padding(.top, LuckyTheme.Space.hair)
    }
}

// MARK: - 子规则卡片

/// §12.3 — a sub-rule inside its parent's card. The shield's tint is the only enabled/disabled
/// indicator here, and unlike the rule's switch this one carries no track colour of its own.
private struct WebSubRuleCard: View {
    var rule: LuckyListItem
    var sub: LuckyListItem
    var index: Int
    var parentKey: String
    var parentName: String
    var busy: Bool
    var actions: WebRuleActions

    private var key: String { WebRecord.key(sub, index) }
    private var enabled: Bool { WebRecord.isEnabled(sub) }

    /// `Array.isArray(sub.Domains) ? sub.Domains.join(", ") : ""` — a string `Domains` yields
    /// nothing here, which is why the row can read `reverseproxy · --` while the URL builder still
    /// finds an address.
    private var domains: String {
        guard let list = sub["Domains"]?.arrayValue else { return "" }
        return list.map(\.asDisplayString).joined(separator: ", ")
    }

    /// `pick(sub, ["Remark"], domains || `子规则 ${index + 1}`)`. A `Remark` of `""` is still a
    /// string, so it wins over the fallback and the card shows no title at all.
    private var name: String {
        WebRecord.pick(sub, ["Remark"], domains.isEmpty ? "子规则 \(index + 1)" : domains)
    }

    /// `type` for the file-service test carries a `""` fallback, while the line printed below
    /// carries `"reverseproxy"` — and `pick` only reaches a fallback when the key is absent or
    /// holds something other than a string or a number. So `WebServiceType: ""` shows as nothing
    /// here and still is not a file service.
    private var type: String { WebRecord.pick(sub, ["WebServiceType"]) }

    private var fileService: Bool { type.lowercased().contains("file") }

    private var summary: String {
        let printed = WebRecord.pick(sub, ["WebServiceType"], "reverseproxy")
        return "\(printed) · \(domains.isEmpty ? "--" : domains)"
    }

    var body: some View {
        LuckyInset(padding: LuckyTheme.Space.m, spacing: LuckyTheme.Space.s) {
            header
            verbs
        }
    }
}

extension WebSubRuleCard {
    private var header: some View {
        HStack(alignment: .center, spacing: LuckyTheme.Space.s) {
            LuckyFunctionIcon(symbol: "checkmark.shield", size: 28, glyph: 12,
                              color: enabled ? LuckyTheme.success : LuckyTheme.idle)
            VStack(alignment: .leading, spacing: 3) {
                Text(name)
                    .font(LuckyTheme.Text.captionMedium)
                    .foregroundStyle(LuckyTheme.textPrimary)
                    .lineLimit(1)
                Text(summary)
                    .font(LuckyTheme.Text.codeSmall)
                    .foregroundStyle(LuckyTheme.textSecondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
            WebEnableSwitch(isOn: enabled, disabled: busy, name: "启用子规则") { on in
                actions.setSubEnabled(parentKey, key, on)
            }
            .fixedSize()
        }
    }

    private var verbs: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: LuckyTheme.Space.s) {
                copyAction
                Spacer(minLength: 0)
                editActions
            }
            VStack(alignment: .leading, spacing: LuckyTheme.Space.s) {
                copyAction
                HStack {
                    Spacer(minLength: 0)
                    editActions
                }
            }
        }
    }

    private var copyAction: some View {
        WebInlineActionButton(title: "复制网址", symbol: LuckySymbol.copy) {
            actions.copyURL(rule, sub)
        }
        .fixedSize()
    }

    private var editActions: some View {
        HStack(spacing: LuckyTheme.Space.s) {
            WebInlineActionButton(title: "编辑", symbol: "pencil", prominent: true) {
                actions.editSub(parentKey, key)
            }
            Menu {
                Button {
                    actions.tools(WebToolsTarget(ruleKey: parentKey, ruleName: parentName,
                                                 subKey: key, subName: name,
                                                 fileService: fileService))
                } label: {
                    Label("更多操作", systemImage: "wrench.and.screwdriver")
                }
                Button(role: .destructive) {
                    actions.removeSub(parentKey, key, name)
                } label: {
                    Label("删除子规则", systemImage: LuckySymbol.delete)
                }
                .disabled(busy)
            } label: {
                LuckyIconTile(symbol: "ellipsis", size: 34, glyph: 14, tone: .idle)
                    .frame(width: LuckyTheme.Space.touchTarget, height: LuckyTheme.Space.touchTarget)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("子规则更多操作")
        }
        .fixedSize()
    }
}
