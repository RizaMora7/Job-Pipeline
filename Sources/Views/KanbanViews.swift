import SwiftUI
import UniformTypeIdentifiers

// MARK: - ContentView

struct ContentView: View {
    @EnvironmentObject var store: AppStore
    
    var body: some View {
        NavigationSplitView {
            SidebarView()
        } detail: {
            Group {
                switch store.viewMode {
                case .board: KanbanBoardView()
                case .review: WeeklyReviewView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Menu {
                        Picker(selection: Binding(
                            get: { store.appearance },
                            set: { store.setAppearance($0) }
                        )) {
                            ForEach(AppStore.AppAppearance.allCases, id: \.self) { a in
                                Label(a.displayName, systemImage: symbolFor(a)).tag(a)
                            }
                        } label: {
                            Text(loc("Modo"))
                        }
                    } label: {
                        Image(systemName: appearanceSymbol)
                    }
                    .help(loc("Modo de apariencia: Automático / Claro / Oscuro"))
                }
                ToolbarItem(placement: .automatic) {
                    HStack(spacing: 6) {
                        if !store.overdueFollowUps.isEmpty {
                            followUpBadge(store.overdueFollowUps.count, color: .red,
                                          label: loc("seguimiento(s) vencido(s)"))
                        }
                        if !store.dueSoonFollowUps.isEmpty {
                            followUpBadge(store.dueSoonFollowUps.count, color: .yellow,
                                          label: loc("seguimiento(s) por vencer pronto"))
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $store.showNewApp) {
            NewApplicationView().id("newApp-\(store.newAppCounter)")
        }
        .sheet(isPresented: $store.showImport) { ImportView() }
        .sheet(isPresented: $store.showHelp) { HelpView() }
        .sheet(item: $store.selectedApp) { app in
            CardDetailView(app: app).id("detail-\(app.id)")
        }
    }
    
    private func followUpBadge(_ count: Int, color: Color, label: String) -> some View {
        Button(action: { store.viewMode = .review }) {
            HStack(spacing: 3) {
                Image(systemName: "bell.fill").font(.system(size: 9))
                Text("\(count)").font(.caption2).bold()
            }
            .foregroundColor(color == .yellow ? .black : .white)
            .padding(.horizontal, 6).padding(.vertical, 3)
            .background(Capsule().fill(color))
        }
        .buttonStyle(.plain)
        .help("\(count) \(label)")
    }
    
    private var appearanceSymbol: String {
        switch store.appearance {
        case .system: return "circle.righthalf.filled"
        case .light: return "sun.max"
        case .dark: return "moon"
        }
    }
    
    private func symbolFor(_ a: AppStore.AppAppearance) -> String {
        switch a {
        case .system: return "circle.righthalf.filled"
        case .light: return "sun.max"
        case .dark: return "moon"
        }
    }
}

// MARK: - Sidebar

struct SidebarView: View {
    @EnvironmentObject var store: AppStore
    
    var body: some View {
        List(selection: Binding(
            get: { store.viewMode },
            set: { store.viewMode = $0 }
        )) {
            Label(loc("Pipeline"), systemImage: "rectangle.split.3x1")
                .tag(AppStore.ViewMode.board)
            Label(loc("Revisión Semanal"), systemImage: "chart.bar.xaxis")
                .tag(AppStore.ViewMode.review)
            Divider()
            Section(header: Text(loc("Columnas"))) {
                ForEach(PipelineColumn.allCases) { col in
                    HStack {
                        Circle().fill(accentColor(col)).frame(width: 8, height: 8)
                        Text(col.displayName)
                        Spacer()
                        Text("\(store.apps(in: col).count)")
                            .foregroundColor(.secondary).font(.caption)
                    }
                }
            }
            Divider()
            Button(action: { store.showHelp = true }) {
                Label(loc("Guía del Pipeline"), systemImage: "questionmark.circle")
            }
        }
        .navigationTitle("Job Pipeline")
        .frame(minWidth: 180)
    }
    
    private func accentColor(_ col: PipelineColumn) -> Color {
        switch col {
        case .porEvaluar: return .gray
        case .listaParaAplicar: return .blue
        case .aplicada: return .orange
        case .enProceso: return .purple
        case .cerrada: return .green
        }
    }
}

// MARK: - Kanban Board

struct KanbanBoardView: View {
    @EnvironmentObject var store: AppStore
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            HStack(alignment: .top, spacing: 12) {
                ForEach(PipelineColumn.allCases) { col in
                    ColumnView(column: col).frame(width: 250)
                }
            }
            .padding()
        }
        .background(Color(NSColor.controlBackgroundColor))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { store.newApplication() }) {
                    Label(loc("Nueva"), systemImage: "plus")
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
            }
        }
    }
}

// MARK: - Column View

struct ColumnView: View {
    @EnvironmentObject var store: AppStore
    let column: PipelineColumn
    @State private var isTargeted = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Circle().fill(accent).frame(width: 10, height: 10)
                Text(column.displayName).font(.headline)
                Spacer()
                Text("\(store.apps(in: column).count)")
                    .font(.caption).bold()
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Capsule().fill(accent.opacity(0.2)))
            }
            .padding(.horizontal, 10).padding(.vertical, 8)
            .background(accent.opacity(0.1))
            
            VStack(spacing: 8) {
                ForEach(store.apps(in: column)) { app in
                    CardView(app: app, column: column)
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .background(RoundedRectangle(cornerRadius: 8).fill(Color(NSColor.textBackgroundColor)))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(isTargeted ? accent : .clear, lineWidth: 2))
        .onDrop(of: [.text], isTargeted: $isTargeted) { providers in
            guard let provider = providers.first else { return false }
            _ = provider.loadObject(ofClass: NSString.self) { item, _ in
                if let idStr = item as? String, let id = Int(idStr),
                   let app = store.applications.first(where: { $0.id == id }) {
                    DispatchQueue.main.async { store.move(app: app, to: column) }
                }
            }
            return true
        }
    }
    
    private var accent: Color {
        switch column {
        case .porEvaluar: return .gray
        case .listaParaAplicar: return .blue
        case .aplicada: return .orange
        case .enProceso: return .purple
        case .cerrada: return .green
        }
    }
}

// MARK: - Card View (Button + contextMenu, no onTapGesture interference)

struct CardView: View {
    let app: Application
    let column: PipelineColumn
    @EnvironmentObject var store: AppStore
    
    var body: some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(accent)
                .frame(width: 4)
                .padding(.vertical, 4)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(app.empresa).font(.subheadline).bold().lineLimit(1)
                    Spacer()
                    if let nota = app.jobFitNota {
                        Text(String(format: "%.1f", nota))
                            .font(.caption2).bold()
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(Capsule().fill(notaColor(nota)))
                    }
                }
                Text(app.cargo).font(.caption).foregroundColor(.secondary).lineLimit(2)
                HStack {
                    Text(app.plataforma).font(.caption2).foregroundColor(.secondary)
                    Spacer()
                    switch store.followUpStatus(for: app) {
                    case .overdue:
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption2).foregroundColor(.red)
                            .help(loc("Seguimiento vencido"))
                    case .dueSoon:
                        Image(systemName: "circle.fill")
                            .font(.caption2).foregroundColor(.yellow)
                            .help(loc("Por vencer pronto"))
                    case .none:
                        EmptyView()
                    }
                }
            }
            .padding(.horizontal, 8).padding(.vertical, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .background(RoundedRectangle(cornerRadius: 6).fill(Color(NSColor.controlBackgroundColor)))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.12)))
        .contentShape(Rectangle())
        .onTapGesture { store.selectedApp = app }
        .onDrag { NSItemProvider(object: "\(app.id)" as NSString) }
        .contextMenu {
            Menu(loc("Mover a")) {
                ForEach(PipelineColumn.allCases.filter { $0 != column }) { target in
                    Button(target.displayName) { store.move(app: app, to: target) }
                }
            }
            Divider()
            Button(loc("Abrir")) { store.selectedApp = app }
            Button(loc("Eliminar"), role: .destructive) { store.delete(app) }
        }
    }
    
    private var accent: Color {
        switch column {
        case .porEvaluar: return .gray
        case .listaParaAplicar: return .blue
        case .aplicada: return .orange
        case .enProceso: return .purple
        case .cerrada: return .green
        }
    }
    
    private func notaColor(_ n: Double) -> Color {
        n >= 7 ? .green.opacity(0.25) : n >= 5 ? .yellow.opacity(0.25) : .red.opacity(0.25)
    }
}
