import SwiftUI

// MARK: - Help Window (full reference)

struct HelpView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    columnsSection
                    transitionsSection
                    fieldsSection
                    weeklyReviewSection
                    rulesSection
                }
                .padding(24)
                .frame(maxWidth: 700)
            }
            .navigationTitle(loc("Guía del Pipeline"))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(loc("Cerrar")) { dismiss() }
                }
            }
        }
    }
    
    // MARK: Columns
    
    private var columnsSection: some View {
        GroupBox(loc("Las 5 columnas")) {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(PipelineColumn.allCases) { col in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(col.displayName).font(.headline)
                        HStack(alignment: .top, spacing: 8) {
                            Text(loc("Entra:")).bold().frame(width: 50, alignment: .leading)
                            Text(loc(entryFor(col))).font(.callout)
                        }
                        HStack(alignment: .top, spacing: 8) {
                            Text(loc("Sale:")).bold().frame(width: 50, alignment: .leading)
                            Text(loc(exitFor(col))).font(.callout)
                        }
                    }
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 6).fill(accentColor(col).opacity(0.08)))
                    if col != .cerrada { Divider() }
                }
            }.padding(8)
        }
    }
    
    private func entryFor(_ col: PipelineColumn) -> String {
        switch col {
        case .porEvaluar: return "Encontraste una oferta en LinkedIn/SEEK/Indeed/Get on Board/Mercado UC y la registraste. Sin nota JobFit todavía."
        case .listaParaAplicar: return "JobFit te dio ≥6/10, no hay requisito excluyente, y adaptaste CV/cover a la vacante."
        case .aplicada: return "Pulsaste 'Enviar' en la plataforma. Corriste modo Brutal de JobFit antes."
        case .enProceso: return "Un recruiter respondió, hay screening agendado, o estás en rondas de entrevista."
        case .cerrada: return "Oferta recibida, rechazo, 30+ días de silencio, o descartada tras evaluar."
        }
    }
    
    private func exitFor(_ col: PipelineColumn) -> String {
        switch col {
        case .porEvaluar: return "Le pusiste nota JobFit y decidiste: ≥6 → 'Lista para aplicar'; <6 → 'Cerrada'."
        case .listaParaAplicar: return "Enviaste la postulación → 'Aplicada'."
        case .aplicada: return "Respuesta positiva → 'En proceso'. Rechazo o silencio → 'Cerrada'."
        case .enProceso: return "Oferta o rechazo final → 'Cerrada'."
        case .cerrada: return "No sale. Se archiva con `cerrado_en`."
        }
    }
    
    // MARK: Transitions
    
    private var transitionsSection: some View {
        GroupBox(loc("Transiciones (T1-T10)")) {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(transData, id: \.0) { id, from, trigger, fields in
                    transRow(id, from, trigger, fields)
                }
            }.padding(8)
        }
    }
    
    private var transData: [(String, String, String, String)] {
        [
            ("T1", "→ Por evaluar", "Capturas oferta", "Set: empresa, cargo, url, plataforma, estado=por_evaluar"),
            ("T2", "Por evaluar → Lista", "JobFit >=6/10", "Set: job_fit_nota, job_fit, estado=lista"),
            ("T3", "Por evaluar → Cerrada", "JobFit <6 o excluyente", "Set: resultado=descartada, motivo, cerrado_en"),
            ("T4", "Lista → Aplicada", "Enviaste postulación", "Set: aplicada_en, cv_usado, cover_usada, proximo_seguimiento=+7d"),
            ("T5", "Aplicada → En proceso", "Respuesta positiva", "Set: contactos[], siguiente_accion"),
            ("T6", "Aplicada → Cerrada", "30 días silencio", "Set: resultado=silencio, cerrado_en"),
            ("T7", "Aplicada → Cerrada", "Rechazo temprano", "Set: resultado=rechazo, motivo"),
            ("T8", "En proceso → Cerrada", "Oferta", "Set: resultado=oferta, motivo"),
            ("T9", "En proceso → Cerrada", "Rechazo en entrevista", "Set: resultado=rechazo, motivo"),
            ("T10", "En proceso → Aplicada", "Solo acuse, no avanza", "Set: proximo_seguimiento=+7d"),
        ]
    }
    
    private func transRow(_ id: String, _ from: String, _ trigger: String, _ fields: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(id).font(.caption).bold().frame(width: 28)
            Text(loc(from)).font(.caption).frame(width: 140, alignment: .leading)
            Text(loc(trigger)).font(.caption).foregroundColor(.secondary).frame(width: 130, alignment: .leading)
            Text(loc(fields)).font(.caption2).foregroundColor(.blue)
            Spacer()
        }
    }
    
    // MARK: Fields
    
    private var fieldsSection: some View {
        GroupBox(loc("Campos de la tarjeta")) {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(fieldData, id: \.0) { name, desc, note in
                    fieldInfo(name, desc, note)
                }
            }.padding(8)
        }
    }
    
    private var fieldData: [(String, String, String)] {
        [
            ("empresa", "Nombre de la empresa/contratista", "Obligatorio"),
            ("cargo", "Título exacto de la vacante", "Obligatorio"),
            ("url", "Enlace directo a la oferta", "Para re-visitar la vacante"),
            ("plataforma", "Dónde la encontraste", "Configurable en Settings → Plataformas"),
            ("pais", "Chile / NZ / otro", "Relevante para requisitos de visa"),
            ("modalidad", "Remoto / Híbrido / Presencial", "Filtro clave para tu búsqueda"),
            ("seniority", "Junior / Mid / Senior / Lead / Manager", "Del aviso original"),
            ("capturada", "Fecha en que la registraste", "Automática al crear"),
            ("publicada", "Fecha del aviso", "Prioriza recientes"),
            ("job_fit_nota", "Puntaje JobFit.fyi (1-10)", "Umbral: >=6 aplica, <6 descarta"),
            ("job_fit", "Nota x 10 (0-100)", "Comparable con tu umbral del 70%"),
            ("requisito_excluyente", "Visa, certificacion, residencia", "Anula el score si no lo cumples"),
            ("fortalezas", "Que te hace destacar para este rol", "Del output de JobFit"),
            ("brechas", "Que te falta o es debil", "Del output de JobFit + modo Brutal"),
            ("estado", "Columna actual", "Se mueve con drag-drop"),
            ("siguiente_accion", "Que toca hacer ahora", "Ej: contactar recruiter, preparar entrevista"),
            ("aplicada_en", "Fecha de envio", "Auto al mover a Aplicada"),
            ("proximo_seguimiento", "Cuando revisar si hay respuesta", "Default: aplicada_en + 7 dias"),
            ("cv_usado", "Ruta al PDF del CV enviado", "Snapshot, no el master"),
            ("cover_usada", "Ruta al PDF de la cover", "Snapshot"),
            ("captura_oferta", "Ruta a la imagen de la oferta", "Captura de pantalla"),
            ("contactos", "Personas contactadas (recruiter, HM)", "Con rol, canal y fecha"),
            ("resultado", "oferta / rechazo / silencio / descartada", "Obligatorio al cerrar"),
            ("motivo", "Por que cerro", "Para detectar patrones"),
            ("cerrado_en", "Fecha de cierre", "Auto al mover a Cerrada"),
            ("tags", "Sectores: energia, epc, contratos", "Separados por coma"),
        ]
    }
    
    private func fieldInfo(_ name: String, _ desc: String, _ note: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(name).font(.system(.caption, design: .monospaced)).frame(width: 130, alignment: .leading)
            Text(loc(desc)).font(.caption).frame(width: 200, alignment: .leading)
            Text(loc(note)).font(.caption2).foregroundColor(.secondary)
            Spacer()
        }
    }
    
    // MARK: Weekly Review
    
    private var weeklyReviewSection: some View {
        GroupBox(loc("Revisión Semanal (viernes, 30 min)")) {
            VStack(alignment: .leading, spacing: 8) {
                bullet("Embudo: cuántas tarjetas hay en cada columna → detecta dónde se atasca.")
                bullet("Conversión: % de aplicaciones que generaron respuesta. Meta: >25%.")
                bullet("Seguimientos vencidos: tarjetas con proximo_seguimiento ≤ hoy → contactar o cerrar.")
                bullet("Próximos a vencer: punto amarillo en la tarjeta; anticipa el contacto hoy.")
                bullet("Alertas en la barra: cápsula roja = vencidos, amarilla = por vencer. Clic → Revisión Semanal.")
                bullet("Silencios >30 días: cerradas en lote con resultado=silencio.")
                bullet("Motivos de descarte: patrones (p.ej. 'todos piden SCADA' → capacitar o filtrar antes).")
                bullet("Próxima semana: tarjetas en 'Lista para aplicar' aún no enviadas → priorizar lunes.")
            }.padding(8)
        }
    }
    
    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text("•").bold()
            Text(loc(text)).font(.callout)
        }
    }
    
    // MARK: Rules
    
    private var rulesSection: some View {
        GroupBox(loc("Reglas de oro")) {
            VStack(alignment: .leading, spacing: 6) {
                rule("JobFit antes de mover de 'Por evaluar'.")
                rule("Brutal antes de pulsar 'Enviar'.")
                rule("Requisito excluyente anula el score.")
                rule("No borrar tarjetas cerradas — alimentan métricas.")
                rule("proximo_seguimiento se respeta: si vence, actúas.")
                rule("3 apps excelentes > 10 mediocres.")
                rule("Una oferta = una tarjeta. Múltiples cargos en misma empresa = tarjetas separadas.")
            }.padding(8)
        }
    }
    
    private func rule(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: "checkmark.circle.fill").foregroundColor(.green).font(.caption)
            Text(loc(text)).font(.callout)
        }
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
