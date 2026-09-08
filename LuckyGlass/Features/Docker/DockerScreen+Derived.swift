import SwiftUI

/// One row of the 镜像 list, pre-read. §3 builds these once per payload rather than per row because
/// `searchText` stringifies the whole record and the filter runs on every keystroke.
struct DockerImageEntry: Identifiable, Hashable {
    var item: LuckyListItem
    var id: String
    var references: [String]
    var searchText: String
}

/// The payload and its derived index change together, only after a successful image-list read.
/// Search, selection and unrelated state updates can then reuse the expensive JSON search text.
struct DockerImageSnapshot {
    let items: [LuckyListItem]
    let entries: [DockerImageEntry]
    let ids: Set<String>

    init(items: [LuckyListItem] = []) {
        let entries = items.enumerated().map { index, item in
            DockerImageEntry(
                item: item,
                id: DockerRecord.keyOf(item, index),
                references: DockerRecord.imageReferences(item),
                searchText: DockerRecord.searchText(item)
            )
        }
        self.items = items
        self.entries = entries
        self.ids = Set(entries.map(\.id))
    }
}

// MARK: - 当前视图

extension DockerScreen {
    /// §2's `active` — the query whose loading and error state the chrome reads. 设置 has three
    /// queries and `config` is the one the original picks, which is why its 维护状态 failure needs
    /// the separate card §17.3 draws.
    var activeQuery: DockerQuery { DockerScreen.query(of: view) }

    /// The same mapping against a view that is not necessarily the current one — a load that began
    /// before a tab switch still has to file its outcome under the query it was reading.
    static func query(of view: DockerView) -> DockerQuery {
        switch view {
        case .containers: .containers
        case .images: .images
        case .compose: .compose
        case .networks: .networks
        case .volumes: .volumes
        case .tasks: .tasks
        case .logs: .logs
        case .settings: .config
        }
    }

    /// The six searchable list payloads; settings and logs render their own sources.
    var source: [LuckyListItem] {
        switch view {
        case .containers: containers
        case .images: imageSnapshot.items
        case .compose: projects
        case .networks: networks
        case .volumes: volumes
        case .tasks: tasks
        case .settings, .logs: []
        }
    }

    /// `deferredSearch.trim().toLowerCase()`. `useDeferredValue` has no SwiftUI counterpart, so the
    /// filter runs on the keystroke rather than one frame behind it.
    var searchWord: String { search.jsTrimmed.lowercased() }

    /// §3's `filtered` — a substring test against the whole record stringified, which is why the
    /// box finds a container by a label value or a mount path just as readily as by its name.
    var filtered: [LuckyListItem] {
        let word = searchWord
        guard !word.isEmpty else { return source }
        return source.filter { DockerRecord.searchText($0).contains(word) }
    }
}

// MARK: - 镜像

extension DockerScreen {
    /// §3's `imageEntries`, prepared when the payload changes rather than on every body read.
    var imageEntries: [DockerImageEntry] { imageSnapshot.entries }

    /// The same word, matched against the entry's own cached text rather than re-stringified.
    var visibleImageEntries: [DockerImageEntry] {
        let word = searchWord
        guard !word.isEmpty else { return imageEntries }
        return imageEntries.filter { $0.searchText.contains(word) }
    }

    var imageIdSet: Set<String> { imageSnapshot.ids }

    /// `selectedImageIds.filter(id => imageIdSet.has(id))` — the pruning effect keeps the array in
    /// step with the payload, but a selection made against a list that has since been refetched is
    /// filtered here too, so a stale id can never reach a delete.
    var validSelectedImageIds: [String] {
        let ids = imageIdSet
        return selectedImageIds.filter { ids.contains($0) }
    }

    var selectedImageSet: Set<String> { Set(validSelectedImageIds) }

    var visibleImageIds: [String] { visibleImageEntries.map(\.id) }

    /// `length > 0 && every(...)` — an empty visible list is *not* "all selected", which is what
    /// keeps the 全选 label from reading 取消全选 over an empty search result.
    var allVisibleImagesSelected: Bool {
        let selected = selectedImageSet
        let visible = visibleImageIds
        return !visible.isEmpty && visible.allSatisfy { selected.contains($0) }
    }

    /// `mutation.isPending || unusedImageScanChecking` — what dims the checkboxes.
    var imageSelectionBusy: Bool { pending || unusedScanChecking }

    /// The selection busy flag plus the upgrade check, which leaves the checkboxes alone but stops
    /// every button in the header.
    var imageActionBusy: Bool { imageSelectionBusy || imageUpgradeChecking }
}

// MARK: - 容器统计

extension DockerScreen {
    var statsContainerItems: [LuckyListItem] { containers }

    /// §25.2 — `paused` counts as running, so a paused container still expects a stats row and its
    /// absence still triggers the live sweep.
    var runningContainerCount: Int {
        statsContainerItems.filter { item in
            let state = DockerStats.containerState(item)
            return state == .running || state == .paused
        }
        .count
    }

    /// `dockerStatRows(containerStats.data, …)` — the five-second cached sweep on its own.
    var cachedStatRows: [DockerStatRow] {
        DockerStats.rows(stats, containers: statsContainerItems)
    }

    /// §2's gate on the expensive per-container sweep: the cheap bulk endpoint either failed, or
    /// succeeded while reporting fewer rows than there are containers expected to have one.
    var liveStatsNeeded: Bool {
        guard statsActive else { return false }
        if statsFailed { return true }
        return statsSucceeded && runningContainerCount > cachedStatRows.count
    }

    /// The statistics payload normalized to an array. The live branch carries partial results
    /// while the fallback sweep is still running.
    var statsSource: JSONValue {
        let payloads = liveStatsNeeded
            ? [stats, liveStats, progressiveStats]
            : [stats]
        return .array(payloads.compactMap { $0 })
    }

    /// The cached rows are reused verbatim when the live sweep is not needed — recomputing them
    /// from `statsSource` would give the same answer, and the original's memo split is what keeps
    /// the five-second tick from re-walking the payload three times.
    var containerStatRows: [DockerStatRow] {
        guard liveStatsNeeded else { return cachedStatRows }
        return DockerStats.rows(statsSource, containers: statsContainerItems)
    }

    /// §25.1 — every row is inserted **twice**, under its key and under its name, because the
    /// container list and the statistics endpoint rarely agree on which of the two they print. A
    /// row whose key and name collide with another's wins the later write, exactly as `Map` does.
    var containerStatsByKey: [String: DockerStatRow] {
        var result: [String: DockerStatRow] = [:]
        for row in containerStatRows {
            result[row.key] = row
            result[row.name] = row
        }
        return result
    }
}

// MARK: - 轮询门控

extension DockerScreen {
    /// `isScreenFocused` is `.task`'s own cancellation — a popped screen tears its tasks down — so
    /// only the scene phase is left to test.
    var statsActive: Bool { view == .containers && phase == .active }

    var logsActive: Bool { view == .logs && phase == .active }

    /// `.task(id:)` restarts a loop when its id changes and cancels it when the view goes away.
    /// A `String` rather than the flag itself so the three ids read alike.
    var statsTaskID: String { "\(statsActive)" }

    var liveStatsTaskID: String { "\(liveStatsNeeded)" }

    /// Paging the daemon log restarts the fifteen-second refetch, as changing the query key does.
    var logsTaskID: String { "\(logsActive)|\(logPage)" }
}

// MARK: - 页面状态

extension DockerScreen {
    /// `getDockerLogs(200, page)` — a full page is exactly this many lines, which is how §18's
    /// pager knows it has reached the end without a total.
    static let logPageSize = 200

    /// `lines(logs.data)` — docker's own flattener, not `LuckyLog.lines`.
    var logLines: [String] { DockerRecord.lines(logPayload) }

    /// `active.isFetching || (view === "settings" && maintenance.isFetching)` — 设置 refreshes three
    /// endpoints and the toolbar button must stay disabled until the slowest of them lands.
    var pageRefreshing: Bool { fetching || (view == .settings && maintenanceFetching) }

    /// `mutation.isPending`.
    var pending: Bool { running != nil }

    /// `active.isLoading` — fetching, and nothing cached to draw underneath.
    var loading: Bool { fetching && !loaded.contains(activeQuery) }

    /// `.alert(isPresented:)` wants a `Bool`; the request itself is the state.
    var confirming: Binding<Bool> {
        Binding(get: { confirmation != nil }, set: { shown in
            if !shown { confirmation = nil }
        })
    }
}
