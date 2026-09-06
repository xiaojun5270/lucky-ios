import SwiftUI

/// `app/(tabs)/monitor.tsx` — the 总览 tab.
///
/// Three feeds run at once: the status socket pushes a frame a second, the Docker overview is
/// refetched every 60 s, and the reverse-proxy rule list every 30 s. All three are gated on
/// `dockerActive = isFocused && appIsActive`, so a backgrounded app holds no socket and issues no
/// requests. The socket is the shared reference-counted stream, so leaving the tab drops the
/// connection but keeps the last frame on screen instead of blanking the charts.

/// `webRuleText(rule, keys, fallback)`: the first key holding a string or a number, as a string.
/// Deliberately not `JSONUnwrap.pick`, which also accepts arrays and would render a list-valued
/// field as `"a, b"` where the original falls back.
private func webRuleText(_ rule: JSONValue, _ keys: [String], _ fallback: String) -> String {
    for key in keys {
        guard let value = rule[key] else { continue }
        if case .string(let text) = value { return text }
        if case .number(let number) = value { return JSONSerializer.numberString(number) }
    }
    return fallback
}

/// `webSubRules(rule)`: `ProxyList` under any of its three spellings, keeping only the object
/// elements. The first non-null spelling wins even when it is not an array, which is what `??`
/// followed by `Array.isArray` does.
private func webSubRules(_ rule: JSONValue) -> [JSONValue] {
    for key in ["ProxyList", "proxyList", "proxies"] {
        guard let value = rule[key], !value.isNull else { continue }
        return value.arrayValue?.filter(\.isRecord) ?? []
    }
    return []
}

/// `asEnabled(rule.Enable ?? rule.enable)`, spelled out as a loop: JavaScript's `??` falls through
/// on `null`, which is a value here rather than an absence, while an empty string must *not* fall
/// through — it has to reach `asEnabled` and take the fallback there.
private func webRuleFlag(_ rule: JSONValue, _ keys: [String], fallback: Bool = true) -> Bool {
    for key in keys {
        guard let value = rule[key], !value.isNull else { continue }
        return Format.asEnabled(value, fallback: fallback)
    }
    return fallback
}

/// `<Legend>`: an 8pt dot and a caption. Takes a tone rather than a colour so a dot and the line it
/// explains cannot drift apart.
private struct DashboardLegend: View {
    var label: String
    var tone: LuckyTone

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(tone.tint)
                .frame(width: 8, height: 8)
            Text(label)
                .font(LuckyTheme.Text.caption)
                .foregroundStyle(LuckyTheme.textTertiary)
                .lineLimit(1)
        }
    }
}

/// Both `Pressable`s in the reverse-proxy header dim to 0.62 while held.
private struct DashboardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.opacity(configuration.isPressed ? 0.62 : 1)
    }
}

/// `<ReverseProxyOverview>` — the one non-Docker card on the dashboard: three counts, the first two
/// enabled rules, and a local eye toggle that masks listen ports.
private struct ReverseProxyCard: View {
    var rules: [LuckyListItem]
    /// `ready = Boolean(data)`. react-query keeps the last payload through a later failure, so once
    /// the list has arrived the counts stay up even while the request is failing.
    var ready: Bool
    var loading: Bool
    var failure: String
    var open: () -> Void

    /// The original's `useState(false)`: masking is for the moment someone is looking over your
    /// shoulder, so it is deliberately not persisted.
    @State private var portsMasked = false

    private var enabledRules: [JSONValue] {
        rules.filter { webRuleFlag($0, ["Enable", "enable"]) }
    }

    private var subRules: [JSONValue] { rules.flatMap { webSubRules($0) } }

    private var enabledSubRules: [JSONValue] {
        subRules.filter { webRuleFlag($0, ["Enable", "enable"]) }
    }

    private var tlsRules: [JSONValue] {
        enabledRules.filter { webRuleFlag($0, ["EnableTLS", "enableTLS", "TLS"], fallback: false) }
    }

    private var preview: [JSONValue] { Array(enabledRules.prefix(2)) }

    private var subtitle: String {
        if !failure.isEmpty { return "规则状态暂时无法读取" }
        if loading, !ready { return "正在同步规则状态" }
        return "域名、监听、后端与 TLS 规则"
    }

    var body: some View {
        LuckyCard {
            header
            statsStrip
            if !preview.isEmpty {
                VStack(alignment: .leading, spacing: LuckyTheme.Space.s) {
                    ForEach(preview.indices, id: \.self) { index in
                        previewRow(index, preview[index])
                    }
                }
            } else if ready, failure.isEmpty {
                Text("暂无启用中的反向代理规则")
                    .font(LuckyTheme.Text.caption)
                    .foregroundStyle(LuckyTheme.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    private var header: some View {
        HStack(spacing: LuckyTheme.Space.s) {
            Button(action: open) {
                HStack(spacing: 10) {
                    LuckyIconTile(symbol: "globe.asia.australia", size: 42, glyph: 21)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("反向代理")
                            .font(LuckyTheme.Text.cardTitle)
                            .foregroundStyle(LuckyTheme.textPrimary)
                        Text(subtitle)
                            .font(LuckyTheme.Text.caption)
                            .foregroundStyle(LuckyTheme.textTertiary)
                            .lineLimit(1)
                    }
                    Spacer(minLength: LuckyTheme.Space.xs)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(LuckyTheme.textTertiary)
                        .frame(width: 30, height: 30)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(LuckyTheme.surfaceRaised)
                        )
                }
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(DashboardPressStyle())
            .accessibilityLabel("打开反向代理规则")
            maskToggle
        }
    }

    private var maskToggle: some View {
        Button {
            portsMasked.toggle()
        } label: {
            Image(systemName: portsMasked ? "eye" : "eye.slash")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(portsMasked ? LuckyTheme.accent : LuckyTheme.textTertiary)
                .frame(width: 40, height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(portsMasked ? LuckyTheme.accentSoft : LuckyTheme.surfaceRaised)
                )
        }
        .buttonStyle(DashboardPressStyle())
        .accessibilityLabel(portsMasked ? "显示端口信息" : "隐藏端口信息")
        .accessibilityAddTraits(portsMasked ? [.isSelected] : [])
    }

    /// Three equal columns divided by hairlines. `--` until the first payload arrives, so an empty
    /// server and an unreached one never read the same.
    private var statsStrip: some View {
        HStack(spacing: 0) {
            statColumn("启用规则", ready ? "\(enabledRules.count)/\(rules.count)" : "--",
                       tint: LuckyTheme.accent, divided: false)
            statColumn("启用子规则", ready ? "\(enabledSubRules.count)/\(subRules.count)" : "--",
                       tint: LuckyTheme.success, divided: true)
            statColumn("TLS 监听", ready ? String(tlsRules.count) : "--",
                       tint: LuckyTheme.warning, divided: true)
        }
        .frame(minHeight: 66)
        .background(ConcentricRectangle().fill(LuckyTheme.surfaceRaised))
    }

    private func statColumn(_ label: String, _ value: String, tint: Color,
                            divided: Bool) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(LuckyTheme.Text.metricSmall)
                .foregroundStyle(tint)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .contentTransition(.numericText())
            Text(label)
                .font(LuckyTheme.Text.caption)
                .foregroundStyle(LuckyTheme.textTertiary)
                .lineLimit(1)
        }
        .padding(.horizontal, LuckyTheme.Space.s)
        .frame(maxWidth: .infinity, minHeight: 42)
        .overlay(alignment: .leading) {
            if divided {
                Rectangle()
                    .fill(LuckyTheme.hairline)
                    .frame(width: LuckyTheme.strokeWidth)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label) \(value)")
    }

    /// One preview row: `${network} · ${host}:${visiblePort}` under the rule's name, with its
    /// sub-rule count on the right. A TLS listener is amber and carries a lock instead of a route.
    private func previewRow(_ index: Int, _ rule: JSONValue) -> some View {
        let name = webRuleText(rule, ["RuleName", "Name"], "规则 \(index + 1)")
        let network = webRuleText(rule, ["Network"], "tcp")
        let listen = webRuleText(rule, ["ListenIP"], "*")
        let host = listen.isEmpty ? "*" : listen
        let port = webRuleText(rule, ["ListenPort"], "--")
        let visiblePort = portsMasked && port != "--" ? "••••" : port
        let tls = webRuleFlag(rule, ["EnableTLS", "enableTLS", "TLS"], fallback: false)
        return HStack(spacing: 9) {
            LuckyIconTile(symbol: tls ? "lock.fill" : "arrow.triangle.branch", size: 28,
                          glyph: 14, tone: tls ? .warning : .brand)
            VStack(alignment: .leading, spacing: 1) {
                Text(name)
                    .font(LuckyTheme.Text.captionMedium)
                    .foregroundStyle(LuckyTheme.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text("\(network) · \(host):\(visiblePort)")
                    .font(LuckyTheme.Text.caption)
                    .foregroundStyle(LuckyTheme.textTertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Text("\(webSubRules(rule).count) 个子规则")
                .font(LuckyTheme.Text.caption)
                .foregroundStyle(LuckyTheme.textTertiary)
                .lineLimit(1)
        }
        .frame(minHeight: 34)
        .accessibilityElement(children: .combine)
    }
}

/// The 总览 tab root.
struct DashboardScreen: View {
    @Environment(\.luckyNavigator) private var navigator
    @Environment(\.scenePhase) private var phase

    @State private var overview: DockerOverview?
    @State private var overviewFailure = ""
    /// `isFetching`, kept as a re-entrancy guard. SwiftUI owns the refresh spinner, so the
    /// original's `refreshing` flag — which only fed the `RefreshControl` and blocked a second
    /// pull — has nothing else left to drive.
    @State private var overviewFetching = false
    @State private var rules: [LuckyListItem] = []
    @State private var rulesReady = false
    @State private var rulesFailure = ""
    @State private var rulesFetching = false

    private var live: LuckyStatusStore { .shared }

    /// `dockerActive = isFocused && appIsActive`.
    private var active: Bool { navigator.selection == .dashboard && phase == .active }

    var body: some View {
        LuckyPage(refresh: { await refreshAll() }) {
            if !live.error.isEmpty, live.data == nil {
                LuckyErrorCard(message: live.error)
            }
            if !overviewFailure.isEmpty {
                LuckyErrorCard(message: "Docker 总览：\(overviewFailure)") {
                    Task { await loadOverview() }
                }
            }
            DockerOverviewDashboard(
                data: overview,
                active: active,
                live: live,
                showHeader: false,
                showDockerSummary: false,
                showContainerInsights: false,
                onSelectView: { navigator.push(.docker(view: $0.rawValue)) },
                onSelectContainer: { navigator.push(.docker(view: "containers", search: $0)) }
            )
            ReverseProxyCard(rules: rules, ready: rulesReady, loading: rulesFetching,
                             failure: rulesFailure) {
                navigator.push(.webservice)
            }
            if let status = live.data {
                systemPanel(status)
                networkPanel(status)
                serverPanel(status)
            }
        }
        .luckyTitle("总览", "实时资源与服务状态")
        .task(id: active) { await holdStatus() }
        .task(id: active) { await pollOverview() }
        .task(id: active) { await pollRules() }
    }

    /// 系统资源 — `TrendChart maxValue={100}` over the socket's 90-sample history. The original
    /// draws bare polylines; area-filling the primary line is the one visual liberty taken here.
    private func systemPanel(_ status: LuckyLiveStatus) -> some View {
        let memory = Format.percent(status.usedMem, status.totalMem)
        return VStack(alignment: .leading, spacing: LuckyTheme.Space.s) {
            LuckySectionHeader(title: "系统资源", symbol: LuckySymbol.cpu) {
                LuckyChip(text: "内存 \(JSCompat.toFixed(memory, 1))%", tone: .idle)
            }
            LuckyCard {
                LuckyWrap(spacing: LuckyTheme.Space.m, lineSpacing: 6) {
                    DashboardLegend(label: "系统 CPU", tone: .brand)
                    DashboardLegend(label: "进程 CPU", tone: .danger)
                    DashboardLegend(label: "系统内存", tone: .ok)
                }
                LuckySparkline(series: systemSeries(status.history), height: 128, ceiling: 100)
            }
        }
    }

    /// Memory is charted as a percentage of the total reported in the same sample, not of the
    /// latest total — a host that grows its RAM mid-history keeps a truthful curve either way.
    private func systemSeries(_ history: [LuckyStatusSample]) -> [LuckySparkSeries] {
        [
            LuckySparkSeries(id: "system-cpu", values: history.map(\.systemCpuPercent),
                             tone: .brand, filled: true),
            LuckySparkSeries(id: "process-cpu", values: history.map(\.processCpuPercent),
                             tone: .danger),
            LuckySparkSeries(id: "system-memory",
                             values: history.map { Format.percent($0.usedMem, $0.totalMem) },
                             tone: .ok),
        ]
    }

    /// 网络趋势 — in and out share one scale (`LuckySparkline` takes its ceiling from the largest
    /// sample across every series), so the two speeds stay comparable.
    private func networkPanel(_ status: LuckyLiveStatus) -> some View {
        let inSpeed = Format.bytes(status.lastNetInSpeed, speed: true)
        let outSpeed = Format.bytes(status.lastNetOutSpeed, speed: true)
        return VStack(alignment: .leading, spacing: LuckyTheme.Space.s) {
            LuckySectionHeader(title: "网络趋势", symbol: LuckySymbol.network)
            LuckyCard {
                LuckyWrap(spacing: LuckyTheme.Space.m, lineSpacing: 6) {
                    DashboardLegend(label: "下载 \(inSpeed)", tone: .info)
                    DashboardLegend(label: "上传 \(outSpeed)", tone: .warning)
                }
                LuckySparkline(series: networkSeries(status.history), height: 128)
                HStack(spacing: 10) {
                    totalColumn("接收总量", Format.bytes(status.netIn),
                                symbol: LuckySymbol.download, tone: .info)
                    totalColumn("发送总量", Format.bytes(status.netOut),
                                symbol: LuckySymbol.upload, tone: .warning)
                }
            }
        }
    }

    private func networkSeries(_ history: [LuckyStatusSample]) -> [LuckySparkSeries] {
        [
            LuckySparkSeries(id: "net-in", values: history.map(\.netInSpeed),
                             tone: .info, filled: true),
            LuckySparkSeries(id: "net-out", values: history.map(\.netOutSpeed), tone: .warning),
        ]
    }

    private func totalColumn(_ label: String, _ value: String, symbol: String,
                             tone: LuckyTone) -> some View {
        HStack(spacing: 7) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(tone.tint)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(LuckyTheme.Text.caption)
                    .foregroundStyle(LuckyTheme.textTertiary)
                    .lineLimit(1)
                Text(value)
                    .font(LuckyTheme.Text.captionMedium)
                    .foregroundStyle(LuckyTheme.textPrimary)
                    .monospacedDigit()
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    /// 服务器信息 — the socket's non-charted fields, in the original's order. `String(value)` on a
    /// JavaScript number is `JSONSerializer.numberString`, which is why these stay `Double`s
    /// instead of being rounded to `Int` for display.
    private func serverPanel(_ status: LuckyLiveStatus) -> some View {
        LuckySection(title: "服务器信息", symbol: LuckySymbol.disk) {
            LuckyRow("进程启动时间", status.runTime.isEmpty ? "--" : status.runTime)
            LuckyRow("查询时间", status.queryTime.isEmpty ? "--" : status.queryTime)
            LuckyRow("进程已打开句柄数", JSONSerializer.numberString(status.handleCount))
            LuckyRow("协程数", JSONSerializer.numberString(status.goroutine))
            LuckyRow("进程占用内存", Format.bytes(status.processUsedMem), mono: true)
            LuckyHairline()
            LuckyRow("GC 总次数", JSONSerializer.numberString(status.numGc))
            LuckyRow("堆占用内存", Format.bytes(status.heapInuse), mono: true)
        }
    }

    /// `Promise.all([dockerOverview.refetch(), webServiceOverview.refetch()])`.
    private func refreshAll() async {
        async let overviewDone: Void = loadOverview()
        async let rulesDone: Void = loadRules()
        _ = await (overviewDone, rulesDone)
    }

    /// The socket lives exactly as long as the tab is showing and the app is foregrounded. The
    /// sleep loop is only a parking spot — `retain()` happens on entry and `release()` in the
    /// `defer` when `.task(id: active)` cancels this on the way out.
    private func holdStatus() async {
        guard active else { return }
        live.retain()
        defer { live.release() }
        while !Task.isCancelled { try? await Task.sleep(for: .seconds(60)) }
    }

    /// `staleTime: 30_000, refetchInterval: 60_000`. `staleTime` has no equivalent here: coming
    /// back to the tab inside 30 s refetches, where react-query would have served its cache.
    private func pollOverview() async {
        guard active else { return }
        while !Task.isCancelled {
            await loadOverview()
            try? await Task.sleep(for: .seconds(60))
        }
    }

    /// `staleTime: 15_000, refetchInterval: 30_000`.
    private func pollRules() async {
        guard active else { return }
        while !Task.isCancelled {
            await loadRules()
            try? await Task.sleep(for: .seconds(30))
        }
    }

    /// A failure keeps the previous payload on screen — react-query's `data` survives a later
    /// error, and the error card above the charts is what reports it.
    private func loadOverview() async {
        guard !overviewFetching else { return }
        overviewFetching = true
        defer { overviewFetching = false }
        do {
            overview = try await DockerService.overview()
            overviewFailure = ""
        } catch {
            guard !error.isCancellation else { return }
            overviewFailure = error.luckyMessage()
        }
    }

    /// `getWebServiceRules(false)` — the full list, not the lite one, because the preview rows
    /// count sub-rules and the lite endpoint omits them.
    private func loadRules() async {
        guard !rulesFetching else { return }
        rulesFetching = true
        defer { rulesFetching = false }
        do {
            rules = try await WebService.rules().items
            rulesReady = true
            rulesFailure = ""
        } catch {
            guard !error.isCancellation else { return }
            rulesFailure = error.luckyMessage()
        }
    }
}
