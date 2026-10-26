import SwiftUI
import AppKit

// MARK: - Card Detail (sheet with all fields)

struct CardDetailView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss
    @State var app: Application
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Identificación
                    GroupBox(loc("Identificación")) {
                        VStack(alignment: .leading, spacing: 8) {
                            fieldRow(loc("Empresa"), text: $app.empresa)
                                .help(loc("Nombre de la empresa o contratista. Obligatorio."))
                            fieldRow(loc("Cargo"), text: $app.cargo)
                                .help(loc("Título exacto de la vacante tal como aparece en el aviso. Obligatorio."))
                            fieldRow(loc("URL"), text: $app.url)
                                .help(loc("Enlace directo a la oferta para re-visitarla."))
                            hFieldRow(loc("Plataforma")) {
                                Picker("", selection: $app.plataforma) {
                                    ForEach(store.platforms, id: \.self) { Text($0).tag($0) }
                                }.labelsHidden().frame(width: 160)
                            }
                            .help(loc("Dónde encontraste la oferta. Editable en Settings → Plataformas."))
                            hFieldRow(loc("Modalidad")) {
                                Picker("", selection: $app.modalidad) {
                                    ForEach(Modalidad.allCases, id: \.self) { Text($0.displayName).tag($0) }
                                }.labelsHidden().frame(width: 120)
                            }
                            .help(loc("Remoto / Híbrido / Presencial. Filtro clave para tu búsqueda."))
                            fieldRow(loc("País"), text: $app.pais)
                                .help(loc("Relevante para requisitos de visa y zona horaria."))
                            fieldRow(loc("Seniority"), text: $app.seniority)
                                .help(loc("Junior / Mid / Senior / Lead / Manager, según el aviso."))
                        }.padding(8)
                    }
                    
                    // Evaluación
                    GroupBox(loc("Evaluación (JobFit)")) {
                        VStack(alignment: .leading, spacing: 8) {
                            hFieldRow(loc("Nota (1-10)")) {
                                TextField("—", value: $app.jobFitNota, format: .number)
                                    .frame(width: 60).multilineTextAlignment(.trailing)
                            }
                            .help(loc("Puntaje de jobfit.fyi modo Normal. Umbral: ≥6 aplica, <6 descarta."))
                            hFieldRow(loc("Job Fit %")) {
                                TextField("—", value: $app.jobFit, format: .number)
                                    .frame(width: 60).multilineTextAlignment(.trailing)
                            }
                            .help(loc("Nota × 10. Comparable con tu umbral del 70% del Manual."))
                            fieldRow(loc("Requisito excluyente"), text: $app.requisitoExcluyente)
                                .help(loc("Visa, certificación, residencia. Si no lo cumples, anula el score y descarta."))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(loc("Fortalezas")).font(.caption).foregroundColor(.secondary)
                                TextEditor(text: $app.fortalezas).frame(height: 50)
                                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.secondary.opacity(0.2)))
                            }
                            .help(loc("Qué te hace destacar para este rol. Del output de JobFit Normal."))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(loc("Brechas")).font(.caption).foregroundColor(.secondary)
                                TextEditor(text: $app.brechas).frame(height: 50)
                                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.secondary.opacity(0.2)))
                            }
                            .help(loc("Qué te falta o es débil. Del output de JobFit + modo Brutal."))
                        }.padding(8)
                    }
                    
                    // Estado y Fechas
                    GroupBox(loc("Estado y Fechas")) {
                        VStack(alignment: .leading, spacing: 8) {
                            hFieldRow(loc("Columna")) {
                                Picker("", selection: $app.estado) {
                                    ForEach(PipelineColumn.allCases) { Text($0.displayName).tag($0) }
                                }.labelsHidden().frame(width: 150)
                            }
                            hFieldRow(loc("Capturada")) {
                                DatePicker("", selection: $app.capturada, displayedComponents: .date)
                                    .labelsHidden()
                            }
                            hFieldRow(loc("Aplicada")) {
                                DatePicker("", selection: optionalDateBinding($app.aplicadaEn), displayedComponents: .date)
                                    .labelsHidden()
                            }
                            hFieldRow(loc("Próx. seguimiento")) {
                                DatePicker("", selection: optionalDateBinding($app.proximoSeguimiento), displayedComponents: .date)
                                    .labelsHidden()
                            }
                            fieldRow(loc("Siguiente acción"), text: $app.siguienteAccion)
                        }.padding(8)
                    }
                    
                    // Documentos
                    GroupBox(loc("Documentos (rutas locales)")) {
                        VStack(alignment: .leading, spacing: 6) {
                            fileRow(loc("CV usado"), path: $app.cvUsado)
                            fileRow(loc("Cover usada"), path: $app.coverUsada)
                            fileRow(loc("Captura oferta"), path: $app.capturaOferta)
                        }.padding(8)
                    }
                    
                    // Resultado
                    GroupBox(loc("Resultado")) {
                        VStack(alignment: .leading, spacing: 8) {
                            hFieldRow(loc("Resultado")) {
                                Picker("", selection: $app.resultado) {
                                    Text("—").tag(Resultado?.none)
                                    ForEach(Resultado.allCases, id: \.self) { Text($0.displayName).tag(Resultado?.some($0)) }
                                }.labelsHidden().frame(width: 160)
                            }
                            fieldRow(loc("Motivo"), text: $app.motivo)
                            hFieldRow(loc("Cerrado")) {
                                DatePicker("", selection: optionalDateBinding($app.cerradoEn), displayedComponents: .date)
                                    .labelsHidden()
                            }
                        }.padding(8)
                    }
                    
                    fieldRow(loc("Tags (coma)"), text: $app.tags)
                }
                .padding()
            }
            .navigationTitle("\(app.empresa) · \(app.cargo)")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(loc("Cancelar")) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button(loc("Guardar")) { store.save(app); dismiss() } }
                ToolbarItem(placement: .destructiveAction) {
                    Button(loc("Eliminar"), role: .destructive) { store.delete(app); dismiss() }
                }
            }
        }
        .frame(width: 620, height: 680)
    }
    
    private func fieldRow(_ label: String, text: Binding<String>) -> some View {
        HStack {
            Text(label).frame(width: 130, alignment: .leading).foregroundColor(.secondary).font(.callout)
            TextField("", text: text).textFieldStyle(.roundedBorder)
        }
    }
    
    private func hFieldRow(_ label: String, @ViewBuilder content: () -> some View) -> some View {
        HStack {
            Text(label).frame(width: 130, alignment: .leading).foregroundColor(.secondary).font(.callout)
            content()
            Spacer()
        }
    }
    
    private func fileRow(_ label: String, path: Binding<String>) -> some View {
        HStack {
            Text(label).frame(width: 130, alignment: .leading).foregroundColor(.secondary).font(.callout)
            if path.wrappedValue.isEmpty {
                Button(loc("Seleccionar…")) { pickFile(binding: path) }.font(.caption)
            } else {
                Text((path.wrappedValue as NSString).lastPathComponent)
                    .font(.caption).foregroundColor(.accentColor)
                    .onTapGesture { openFile(path.wrappedValue) }
                Button("✕") { path.wrappedValue = "" }.font(.caption).foregroundColor(.secondary)
            }
            Spacer()
        }
    }
    
    private func pickFile(binding: Binding<String>) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url { binding.wrappedValue = url.path }
    }
    
    private func openFile(_ path: String) {
        NSWorkspace.shared.open(URL(fileURLWithPath: path))
    }
}

// MARK: - New Application (compact)

struct NewApplicationView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss
    @State private var app = Application()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(loc("Nueva Aplicación")).font(.headline)
            
            fieldRow(loc("Empresa *"), text: $app.empresa)
            fieldRow(loc("Cargo *"), text: $app.cargo)
            fieldRow(loc("URL"), text: $app.url)
            hFieldRow(loc("Plataforma")) {
                Picker("", selection: $app.plataforma) {
                    ForEach(store.platforms, id: \.self) { Text($0).tag($0) }
                }.labelsHidden().frame(width: 160)
            }
            fieldRow(loc("País"), text: $app.pais)
            hFieldRow(loc("Modalidad")) {
                Picker("", selection: $app.modalidad) {
                    ForEach(Modalidad.allCases, id: \.self) { Text($0.displayName).tag($0) }
                }.labelsHidden().frame(width: 120)
            }
            
            HStack {
                Spacer()
                Button(loc("Cancelar")) { dismiss() }
                Button(loc("Crear")) {
                    app.capturada = Date()
                    app.estado = .porEvaluar
                    store.save(app)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(app.empresa.isEmpty || app.cargo.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 420)
    }
    
    private func fieldRow(_ label: String, text: Binding<String>) -> some View {
        HStack {
            Text(label).frame(width: 90, alignment: .leading).font(.callout).foregroundColor(.secondary)
            TextField("", text: text).textFieldStyle(.roundedBorder)
        }
    }
    
    private func hFieldRow(_ label: String, @ViewBuilder content: () -> some View) -> some View {
        HStack {
            Text(label).frame(width: 90, alignment: .leading).font(.callout).foregroundColor(.secondary)
            content()
            Spacer()
        }
    }
}

// MARK: - Import View

struct ImportView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss
    @State private var vaultPath = ""
    @State private var status = ""
    @State private var importing = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(loc("Importar desde Obsidian")).font(.headline)
            Text(loc("Escanea las notas .md en la carpeta Applications/ del vault, parsea el frontmatter YAML y carga las aplicaciones a la base de datos local."))
                .font(.caption).foregroundColor(.secondary)
            HStack {
                TextField(loc("Ruta del vault"), text: $vaultPath).textFieldStyle(.roundedBorder)
                Button(loc("Elegir…")) { pickVault() }
            }
            Button(importing ? loc("Importando…") : loc("Importar")) { startImport() }
                .disabled(vaultPath.isEmpty || importing)
            if !status.isEmpty { Text(status).font(.caption).foregroundColor(.secondary) }
            HStack { Spacer(); Button(loc("Cerrar")) { dismiss() } }
        }
        .padding(20).frame(width: 500)
    }
    
    private func pickVault() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true; panel.canChooseFiles = false
        if panel.runModal() == .OK, let url = panel.url { vaultPath = url.path }
    }
    
    private func startImport() {
        importing = true
        DispatchQueue.global().async {
            let importer = ImportService()
            let count = importer.importFromVault(path: vaultPath, store: store)
            DispatchQueue.main.async { status = L10n.fmt("Importadas %d aplicaciones.", count); importing = false }
        }
    }
}

// MARK: - Helpers

func optionalDateBinding(_ value: Binding<Date?>) -> Binding<Date> {
    Binding(get: { value.wrappedValue ?? Date() }, set: { value.wrappedValue = $0 })
}
