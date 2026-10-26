import SwiftUI

// MARK: - Weekly Review (Friday dashboard)

struct WeeklyReviewView: View {
    @EnvironmentObject var store: AppStore
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Funnel
                GroupBox(loc("Embudo del pipeline")) {
                    HStack(alignment: .top, spacing: 20) {
                        ForEach(store.funnelCounts, id: \.0) { col, count in
                            VStack {
                                Text("\(count)").font(.title).bold().foregroundColor(columnColor(col))
                                Text(col.displayName).font(.caption).foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }.frame(width: 80)
                        }
                    }.padding()
                }
                
                // Conversion
                GroupBox(loc("Conversión")) {
                    HStack(spacing: 30) {
                        statBlock(loc("Tasa respuesta"), String(format: "%.0f%%", store.conversionRate))
                        statBlock(loc("Total aplicadas"), "\(store.applications.filter { $0.aplicadaEn != nil }.count)")
                        statBlock(loc("En proceso"), "\(store.apps(in: .enProceso).count)")
                        statBlock(loc("Ofertas"), "\(store.applications.filter { $0.resultado == .oferta }.count)")
                    }.padding()
                }
                
                // Overdue follow-ups
                GroupBox(loc("Seguimientos vencidos")) {
                    if store.overdueFollowUps.isEmpty {
                        Text(loc("Nada pendiente")).foregroundColor(.secondary).padding()
                    } else {
                        ForEach(store.overdueFollowUps) { app in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(app.empresa) · \(app.cargo)").font(.subheadline)
                                    Text("\(loc("Vencido")): \(app.proximoSeguimiento?.formatted(date: .abbreviated, time: .omitted) ?? "—")")
                                        .font(.caption).foregroundColor(.red)
                                }
                                Spacer()
                                Text(app.siguienteAccion).font(.caption).foregroundColor(.secondary)
                                Button(loc("Cerrada")) { store.move(app: app, to: .cerrada) }
                                    .font(.caption).buttonStyle(.bordered)
                            }.padding(.horizontal, 10).padding(.vertical, 6)
                            Divider()
                        }
                    }
                }
                
                // Due-soon follow-ups (<2 days)
                GroupBox("\(loc("Próximos a vencer")) (<\(store.dueSoonDays) \(loc("días")))") {
                    if store.dueSoonFollowUps.isEmpty {
                        Text(loc("Nada próximo")).foregroundColor(.secondary).padding()
                    } else {
                        ForEach(store.dueSoonFollowUps) { app in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(app.empresa) · \(app.cargo)").font(.subheadline)
                                    Text("\(loc("Vence")): \(app.proximoSeguimiento?.formatted(date: .abbreviated, time: .omitted) ?? "—")")
                                        .font(.caption).foregroundColor(.yellow)
                                }
                                Spacer()
                                Text(app.siguienteAccion).font(.caption).foregroundColor(.secondary)
                                Button(loc("Hoy")) {
                                    var u = app; u.proximoSeguimiento = Date(); store.save(u)
                                }
                                .font(.caption).buttonStyle(.bordered)
                            }.padding(.horizontal, 10).padding(.vertical, 6)
                            Divider()
                        }
                    }
                }
                
                // Silence alerts
                GroupBox(loc("Silencios (>30 días)")) {
                    if store.silenceAlerts.isEmpty {
                        Text(loc("Ninguno")).foregroundColor(.secondary).padding()
                    } else {
                        ForEach(store.silenceAlerts) { app in
                            HStack {
                                Text("\(app.empresa) · \(app.cargo)").font(.subheadline)
                                Spacer()
                                Text("\(loc("Aplicada")): \(app.aplicadaEn?.formatted(date: .abbreviated, time: .omitted) ?? "—")")
                                    .font(.caption).foregroundColor(.orange)
                                Button(loc("Cerrar")) {
                                    var u = app; u.resultado = .silencio; u.motivo = loc("Sin respuesta >30 días")
                                    u.estado = .cerrada; u.cerradoEn = Date(); store.save(u)
                                }.font(.caption).buttonStyle(.bordered)
                            }.padding(.horizontal, 10).padding(.vertical, 6)
                            Divider()
                        }
                    }
                }
                
                // Discard reasons
                GroupBox(loc("Motivos de descarte (recientes)")) {
                    let recent = store.applications.filter { $0.estado == .cerrada && !$0.motivo.isEmpty }
                        .sorted { ($0.cerradoEn ?? .distantPast) > ($1.cerradoEn ?? .distantPast) }.prefix(10)
                    if recent.isEmpty {
                        Text(loc("Sin motivos registrados")).foregroundColor(.secondary).padding()
                    } else {
                        ForEach(Array(recent), id: \.id) { app in
                            HStack {
                                Text(app.empresa).font(.caption).bold()
                                Text("→").foregroundColor(.secondary)
                                Text(app.motivo).font(.caption)
                                Spacer()
                                Text(app.resultado?.displayName ?? "").font(.caption2).foregroundColor(.secondary)
                            }.padding(.horizontal, 10).padding(.vertical, 4)
                        }
                    }
                }
            }.padding()
        }
        .navigationTitle(loc("Revisión Semanal"))
    }
    
    private func statBlock(_ label: String, _ value: String) -> some View {
        VStack { Text(value).font(.title2).bold(); Text(label).font(.caption).foregroundColor(.secondary) }
    }
    
    private func columnColor(_ col: PipelineColumn) -> Color {
        switch col {
        case .porEvaluar: return .gray
        case .listaParaAplicar: return .blue
        case .aplicada: return .orange
        case .enProceso: return .purple
        case .cerrada: return .green
        }
    }
}

// MARK: - Settings

struct SettingsView: View {
    @EnvironmentObject var store: AppStore
    @State private var newPlatform = ""
    @AppStorage("jobFitThreshold") private var jobFitThreshold = 6.0
    @AppStorage("silenceDays") private var silenceDays = 30
    
    private let labelWidth: CGFloat = 210
    
    var body: some View {
        TabView {
            generalTab
                .tabItem { Label(loc("General"), systemImage: "gear") }
            platformsTab
                .tabItem { Label(loc("Plataformas"), systemImage: "globe") }
        }
        .frame(width: 560, height: 440)
    }
    
    // MARK: General
    
    private var generalTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            GroupBox {
                VStack(alignment: .leading, spacing: 10) {
                    row(loc("Idioma de la interfaz")) {
                        Picker("", selection: Binding(
                            get: { store.language },
                            set: { store.setLanguage($0) }
                        )) {
                            ForEach(AppLanguage.allCases, id: \.self) { Text($0.label).tag($0) }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .frame(width: 140)
                    }
                }
                .padding(6)
            } label: { Text(loc("Idioma")).font(.headline) }
            
            GroupBox {
                VStack(alignment: .leading, spacing: 10) {
                    row(loc("Modo")) {
                        Picker("", selection: Binding(
                            get: { store.appearance },
                            set: { store.setAppearance($0) }
                        )) {
                            ForEach(AppStore.AppAppearance.allCases, id: \.self) { Text($0.displayName).tag($0) }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .frame(width: 140)
                    }
                }
                .padding(6)
            } label: { Text(loc("Apariencia")).font(.headline) }
            
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    row(loc("Umbral JobFit (descartar bajo)")) {
                        Slider(value: $jobFitThreshold, in: 1...10, step: 0.5)
                            .frame(width: 150)
                        Text(String(format: "%.1f", jobFitThreshold))
                            .font(.callout).frame(width: 34, alignment: .trailing)
                    }
                    row(loc("Días para avisar seguimiento pronto")) {
                        Stepper("\(store.dueSoonDays) \(loc("días"))", value: Binding(
                            get: { store.dueSoonDays },
                            set: { store.setDueSoonDays($0) }
                        ), in: 1...14)
                    }
                    row(loc("Días de silencio antes de cerrar")) {
                        Stepper("\(silenceDays) \(loc("días"))", value: $silenceDays, in: 14...60)
                    }
                }
                .padding(6)
            } label: { Text(loc("Pipeline")).font(.headline) }
            
            Spacer()
        }
        .padding(20)
    }
    
    // MARK: Platforms
    
    private var platformsTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(store.platforms, id: \.self) { p in
                        HStack {
                            Text(p)
                            Spacer()
                            Button(loc("Eliminar")) {
                                var list = store.platforms
                                list.removeAll { $0 == p }
                                store.savePlatforms(list)
                            }
                            .font(.caption).foregroundColor(.red)
                        }
                    }
                    Divider()
                    HStack {
                        TextField(loc("Nueva plataforma…"), text: $newPlatform)
                            .textFieldStyle(.roundedBorder)
                        Button(loc("Agregar")) {
                            guard !newPlatform.isEmpty else { return }
                            var list = store.platforms
                            list.append(newPlatform)
                            store.savePlatforms(list)
                            newPlatform = ""
                        }
                    }
                }
                .padding(6)
            } label: { Text(loc("Plataformas de búsqueda")).font(.headline) }
            
            Spacer()
        }
        .padding(20)
    }
    
    // MARK: Row helper
    
    private func row(_ label: String, @ViewBuilder content: () -> some View) -> some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.callout)
                .foregroundColor(.secondary)
                .frame(width: labelWidth, alignment: .leading)
            content()
            Spacer(minLength: 0)
        }
    }
}
