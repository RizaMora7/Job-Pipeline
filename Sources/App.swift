import SwiftUI
import AppKit

@main
struct JobPipelineApp: App {
    @StateObject private var store = AppStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .frame(minWidth: 1100, minHeight: 700)
                .preferredColorScheme(colorScheme(for: store.appearance))
        }
        .commands {
            CommandGroup(after: .newItem) {
                Button(loc("Nueva Aplicación")) { store.newApplication() }
                    .keyboardShortcut("n", modifiers: [.command, .shift])
                Divider()
                Button(loc("Importar desde Obsidian")) { store.showImport = true }
            }
            CommandGroup(replacing: .help) {
                Button(loc("Guía del Pipeline")) { store.showHelp = true }
                    .keyboardShortcut("?", modifiers: [.command])
            }
        }
        
        Settings {
            SettingsView()
                .environmentObject(store)
        }
    }
    
    private func colorScheme(for appearance: AppStore.AppAppearance) -> ColorScheme? {
        switch appearance {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// MARK: - App Store (Observable state)

final class AppStore: ObservableObject {
    @Published var applications: [Application] = []
    @Published var selectedApp: Application?
    @Published var showNewApp = false
    @Published var showImport = false
    @Published var showDetail = false
    @Published var showHelp = false
    @Published var newAppCounter = 0
    @Published var viewMode: ViewMode = .board
    @Published var platforms: [String] = ["LinkedIn", "SEEK", "Indeed", "Get on Board", "Mercado Laboral UC", "Referido", "PitchBook", "Otra"]
    @Published var appearance: AppAppearance = .system
    @Published var language: AppLanguage = L10n.lang
    @Published var dueSoonDays: Int = 2
    
    enum ViewMode { case board, review }
    enum AppAppearance: String, CaseIterable {
        case system = "Automático", light = "Claro", dark = "Oscuro"
        var displayName: String { loc(rawValue) }
    }
    
    private let db = DatabaseService.shared
    
    init() {
        load()
        loadPlatforms()
        loadAppearance()
        loadDueSoonDays()
        DispatchQueue.main.async { [weak self] in
            self?.applyDockIcon()
            self?.observeSystemTheme()
        }
    }
    
    private func observeSystemTheme() {
        DistributedNotificationCenter.default().addObserver(
            self, selector: #selector(systemThemeChanged),
            name: NSNotification.Name("AppleInterfaceThemeChangedNotification"),
            object: nil, suspensionBehavior: .deliverImmediately
        )
    }
    
    @objc private func systemThemeChanged() {
        if appearance == .system { applyDockIcon() }
    }
    
    func load() {
        applications = db.fetchAll()
    }
    
    private func loadPlatforms() {
        if let json = db.getSetting("platforms"), let data = json.data(using: .utf8),
           let list = try? JSONDecoder().decode([String].self, from: data), !list.isEmpty {
            platforms = list
        }
    }
    
    func savePlatforms(_ list: [String]) {
        platforms = list
        if let data = try? JSONEncoder().encode(list), let json = String(data: data, encoding: .utf8) {
            db.setSetting("platforms", json)
        }
    }
    
    private func loadAppearance() {
        if let val = db.getSetting("appearance"), let a = AppAppearance(rawValue: val) {
            appearance = a
        }
    }
    
    func setAppearance(_ a: AppAppearance) {
        appearance = a
        db.setSetting("appearance", a.rawValue)
        applyDockIcon()
    }
    
    private func loadDueSoonDays() {
        if let val = db.getSetting("dueSoonDays"), let n = Int(val) { dueSoonDays = max(1, n) }
    }
    
    func setDueSoonDays(_ n: Int) {
        dueSoonDays = max(1, n)
        db.setSetting("dueSoonDays", String(dueSoonDays))
    }
    
    func setLanguage(_ l: AppLanguage) {
        L10n.lang = l
        language = l
        objectWillChange.send()   // re-render the whole tree so every loc() call re-reads the language
    }
    
    /// Sets the Dock icon to match the selected appearance mode (works on Ventura, unlike the system auto-switch).
    func applyDockIcon() {
        let useDark: Bool
        switch appearance {
        case .dark: useDark = true
        case .light: useDark = false
        case .system:
            let match = NSApp.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua])
            useDark = (match == .darkAqua)
        }
        let name = useDark ? "AppIcon-dark" : "AppIcon-light"
        if let url = Bundle.main.url(forResource: name, withExtension: "icns"),
           let img = NSImage(contentsOf: url) {
            NSApp.applicationIconImage = img
        }
    }
    
    /// Persists the card and mirrors it in memory only if the database accepted it.
    @discardableResult
    func save(_ app: Application) -> Bool {
        var updated = app
        updated.updatedAt = Date()
        if app.id == 0 {
            let newId = db.insert(updated)
            guard newId > 0 else { return false }   // insert failed → don't create a duplicate id=0 card
            updated.id = newId
            applications.append(updated)
        } else {
            guard db.update(updated) else { return false }
            if let idx = applications.firstIndex(where: { $0.id == updated.id }) {
                applications[idx] = updated
            }
        }
        return true
    }
    
    func newApplication() {
        newAppCounter += 1
        showNewApp = true
    }
    
    func delete(_ app: Application) {
        guard app.id > 0 else { return }
        guard db.delete(id: app.id) else { return }
        applications.removeAll { $0.id == app.id }
        if selectedApp?.id == app.id { selectedApp = nil }
    }
    
    func move(app: Application, to column: PipelineColumn) {
        var updated = app
        updated.estado = column
        updated.updatedAt = Date()
        if column == .aplicada && updated.aplicadaEn == nil {
            updated.aplicadaEn = Date()
        }
        // Auto-program follow-up (+7 days from application) only when empty, so a manual date is never overwritten.
        if column == .aplicada, updated.proximoSeguimiento == nil, let applied = updated.aplicadaEn {
            updated.proximoSeguimiento = applied.addingTimeInterval(7 * 86400)
        }
        if column == .cerrada && updated.cerradoEn == nil {
            updated.cerradoEn = Date()
        }
        guard db.update(updated) else { return }
        if let idx = applications.firstIndex(where: { $0.id == updated.id }) {
            applications[idx] = updated
        }
    }
    
    func apps(in column: PipelineColumn) -> [Application] {
        applications.filter { $0.estado == column }
    }
    
    // Weekly review helpers
    var overdueFollowUps: [Application] {
        let now = Date()
        return applications.filter {
            $0.estado != .cerrada &&
            $0.proximoSeguimiento != nil &&
            $0.proximoSeguimiento! <= now
        }
    }
    
    /// Follow-ups that are still in the future but due within the configured due-soon window.
    var dueSoonFollowUps: [Application] {
        let now = Date()
        let limit = now.addingTimeInterval(Double(dueSoonDays) * 86400)
        return applications.filter {
            $0.estado != .cerrada &&
            $0.proximoSeguimiento != nil &&
            $0.proximoSeguimiento! > now &&
            $0.proximoSeguimiento! <= limit
        }
    }
    
    enum FollowUpStatus { case none, overdue, dueSoon }
    
    func followUpStatus(for app: Application) -> FollowUpStatus {
        guard app.estado != .cerrada, let seg = app.proximoSeguimiento else { return .none }
        let now = Date()
        if seg <= now { return .overdue }
        if seg <= now.addingTimeInterval(Double(dueSoonDays) * 86400) { return .dueSoon }
        return .none
    }
    
    var silenceAlerts: [Application] {
        let threshold = Date().addingTimeInterval(-30 * 86400)
        return applications.filter {
            $0.estado == .aplicada &&
            $0.aplicadaEn != nil &&
            $0.aplicadaEn! <= threshold
        }
    }
    
    var funnelCounts: [(PipelineColumn, Int)] {
        PipelineColumn.allCases.map { ($0, apps(in: $0).count) }
    }
    
    var conversionRate: Double {
        let applied = applications.filter { $0.aplicadaEn != nil }.count
        let responded = applications.filter { $0.estado == .enProceso || $0.resultado == .oferta }.count
        return applied > 0 ? Double(responded) / Double(applied) * 100 : 0
    }
}
