import Foundation

// MARK: - Language layer
//
// Design: Spanish is the SOURCE OF TRUTH. The database, the Obsidian importer and the
// enum rawValues all keep using their Spanish values, so stored data never changes when
// you switch language. Only DISPLAYED text is translated. `L10n.t(_:)` looks up an English
// string in the table below; if the current language is Spanish, or a translation is missing,
// it returns the Spanish input unchanged (graceful fallback — the app never breaks).

enum AppLanguage: String, CaseIterable, Codable {
    case es
    case en
    
    /// Language name shown in its own language (proper noun, not translated).
    var label: String {
        switch self {
        case .es: return "Español"
        case .en: return "English"
        }
    }
}

enum L10n {
    static let defaultsKey = "appLanguage"
    
    static var lang: AppLanguage {
        get {
            if let raw = UserDefaults.standard.string(forKey: defaultsKey),
               let v = AppLanguage(rawValue: raw) { return v }
            // First launch: follow the system language, default to Spanish.
            let sys = Locale.current.language.languageCode?.identifier ?? "es"
            return sys.hasPrefix("en") ? .en : .es
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: defaultsKey) }
    }
    
    /// Translate a Spanish source string to the active language (with Spanish fallback).
    static func t(_ es: String) -> String {
        guard lang == .en else { return es }
        return en[es] ?? es
    }
    
    /// Translate with a "%d"/"%@" placeholder filled in (still Spanish-fallback safe).
    static func fmt(_ es: String, _ args: CVarArg...) -> String {
        String(format: t(es), arguments: args)
    }
}

/// Global convenience used across all views.
@inline(__always) func loc(_ s: String) -> String { L10n.t(s) }

// MARK: - English table (key = exact Spanish source string)

private let en: [String: String] = [
    // Product / navigation
    "Job Pipeline": "Job Pipeline",
    "Pipeline": "Pipeline",
    "Revisión Semanal": "Weekly Review",
    "Columnas": "Columns",
    "Guía del Pipeline": "Pipeline Guide",
    "Nueva Aplicación": "New Application",
    "Importar desde Obsidian": "Import from Obsidian",
    
    // Toolbar / buttons
    "Nueva": "New",
    "Mover a": "Move to",
    "Abrir": "Open",
    "Eliminar": "Delete",
    "Cancelar": "Cancel",
    "Guardar": "Save",
    "Crear": "Create",
    "Cerrar": "Close",
    "Cerrada": "Closed",
    "Hoy": "Today",
    "Elegir…": "Choose…",
    "Importar": "Import",
    "Importando…": "Importing…",
    "Seleccionar…": "Select…",
    "Agregar": "Add",
    "✕": "✕",
    
    // Follow-up badges / help
    "Seguimiento vencido": "Overdue follow-up",
    "Por vencer pronto": "Due soon",
    "seguimiento(s) vencido(s)": "overdue follow-up(s)",
    "seguimiento(s) por vencer pronto": "follow-up(s) due soon",
    "días": "days",
    
    // Appearance
    "Modo": "Mode",
    "Automático": "Automatic",
    "Claro": "Light",
    "Oscuro": "Dark",
    "Modo de apariencia: Automático / Claro / Oscuro": "Appearance mode: Automatic / Light / Dark",
    
    // Columns
    "Por evaluar": "To evaluate",
    "Lista para aplicar": "Ready to apply",
    "Aplicada": "Applied",
    "En proceso": "In progress",
    
    // Modalidad
    "Remoto": "Remote",
    "Híbrido": "Hybrid",
    "Presencial": "On-site",
    
    // Resultado
    "Oferta": "Offer",
    "Rechazo": "Rejected",
    "Silencio": "Ghosted",
    "Descartada evaluada": "Evaluated & dropped",
    
    // Weekly review
    "Embudo del pipeline": "Pipeline funnel",
    "Conversión": "Conversion",
    "Tasa respuesta": "Response rate",
    "Total aplicadas": "Total applied",
    "Ofertas": "Offers",
    "Seguimientos vencidos": "Overdue follow-ups",
    "Nada pendiente": "Nothing pending",
    "Vencido": "Overdue",
    "Próximos a vencer": "Coming due",
    "Nada próximo": "Nothing coming up",
    "Vence": "Due",
    "Silencios (>30 días)": "Ghosting (>30 days)",
    "Ninguno": "None",
    "Sin respuesta >30 días": "No response >30 days",
    "Motivos de descarte (recientes)": "Discard reasons (recent)",
    "Sin motivos registrados": "No reasons recorded",
    
    // Settings
    "Apariencia": "Appearance",
    "Idioma": "Language",
    "Idioma de la interfaz": "Interface language",
    "Sigue el idioma del sistema": "Follows system language",
    "Umbral JobFit (descartar bajo)": "JobFit threshold (drop below)",
    "Días para avisar seguimiento pronto": "Days to flag a follow-up as due soon",
    "Días de silencio antes de cerrar": "Ghosting days before closing",
    "%d días": "%d days",
    "General": "General",
    "Plataformas": "Platforms",
    "Plataformas de búsqueda": "Search platforms",
    "Nueva plataforma…": "New platform…",
    
    // Detail sections
    "Identificación": "Identification",
    "Evaluación (JobFit)": "Evaluation (JobFit)",
    "Estado y Fechas": "Status & Dates",
    "Documentos (rutas locales)": "Documents (local paths)",
    "Resultado": "Result",
    
    // Detail field labels
    "Empresa": "Company",
    "Cargo": "Role",
    "URL": "URL",
    "Plataforma": "Platform",
    "Modalidad": "Work mode",
    "País": "Country",
    "Seniority": "Seniority",
    "Nombre de la empresa/contratista": "Company / contractor name",
    "Título exacto de la vacante": "Exact job title",
    "Enlace directo a la oferta": "Direct link to the posting",
    "Dónde la encontraste": "Where you found it",
    "Remoto / Híbrido / Presencial": "Remote / Hybrid / On-site",
    "Junior / Mid / Senior / Lead / Manager": "Junior / Mid / Senior / Lead / Manager",
    "Nota (1-10)": "Score (1-10)",
    "Job Fit %": "Job Fit %",
    "Requisito excluyente": "Must-have requirement",
    "Fortalezas": "Strengths",
    "Brechas": "Gaps",
    "Columna": "Column",
    "Capturada": "Captured",
    "Próx. seguimiento": "Next follow-up",
    "Siguiente acción": "Next action",
    "CV usado": "CV used",
    "Cover usada": "Cover used",
    "Captura oferta": "Offer screenshot",
    "Motivo": "Reason",
    "Cerrado": "Closed",
    "Tags (coma)": "Tags (comma)",
    "Empresa *": "Company *",
    "Cargo *": "Role *",
    
    // Detail tooltips
    "Nombre de la empresa o contratista. Obligatorio.": "Company or contractor name. Required.",
    "Título exacto de la vacante tal como aparece en el aviso. Obligatorio.": "Exact job title as shown in the posting. Required.",
    "Enlace directo a la oferta para re-visitarla.": "Direct link to the posting to revisit it.",
    "Dónde encontraste la oferta. Editable en Settings → Plataformas.": "Where you found the posting. Editable in Settings → Platforms.",
    "Remoto / Híbrido / Presencial. Filtro clave para tu búsqueda.": "Remote / Hybrid / On-site. Key filter for your search.",
    "Relevante para requisitos de visa y zona horaria.": "Relevant for visa requirements and time zone.",
    "Junior / Mid / Senior / Lead / Manager, según el aviso.": "Junior / Mid / Senior / Lead / Manager, per the posting.",
    "Puntaje de jobfit.fyi modo Normal. Umbral: ≥6 aplica, <6 descarta.": "jobfit.fyi Normal-mode score. Threshold: ≥6 apply, <6 drop.",
    "Nota × 10. Comparable con tu umbral del 70% del Manual.": "Score × 10. Comparable with your 70% Manual threshold.",
    "Visa, certificación, residencia. Si no lo cumples, anula el score y descarta.": "Visa, certification, residency. If you don't meet it, it voids the score — drop.",
    "Qué te hace destacar para este rol. Del output de JobFit Normal.": "What makes you stand out for this role. From JobFit Normal output.",
    "Qué te falta o es débil. Del output de JobFit + modo Brutal.": "What you lack or is weak. From JobFit + Brutal mode output.",
    
    // New / Import views
    "Escanea las notas .md en la carpeta Applications/ del vault, parsea el frontmatter YAML y carga las aplicaciones a la base de datos local.": "Scans the .md notes in the vault's Applications/ folder, parses the YAML frontmatter and loads the applications into the local database.",
    "Ruta del vault": "Vault path",
    "Importadas %d aplicaciones.": "Imported %d applications.",
    
    // Help — sections
    "Las 5 columnas": "The 5 columns",
    "Entra:": "Entry:",
    "Sale:": "Exit:",
    "Transiciones (T1-T10)": "Transitions (T1-T10)",
    "Campos de la tarjeta": "Card fields",
    "Reglas de oro": "Golden rules",
    
    // Help — column entry/exit
    "Encontraste una oferta en LinkedIn/SEEK/Indeed/Get on Board/Mercado UC y la registraste. Sin nota JobFit todavía.": "You found a posting on LinkedIn/SEEK/Indeed/Get on Board/Mercado UC and logged it. No JobFit score yet.",
    "JobFit te dio ≥6/10, no hay requisito excluyente, y adaptaste CV/cover a la vacante.": "JobFit gave you ≥6/10, there's no must-have blocker, and you tailored CV/cover to the role.",
    "Pulsaste 'Enviar' en la plataforma. Corriste modo Brutal de JobFit antes.": "You hit 'Submit' on the platform. You ran JobFit Brutal mode first.",
    "Un recruiter respondió, hay screening agendado, o estás en rondas de entrevista.": "A recruiter replied, a screening is booked, or you're in interview rounds.",
    "Oferta recibida, rechazo, 30+ días de silencio, o descartada tras evaluar.": "Offer received, rejection, 30+ days of silence, or dropped after evaluation.",
    "Le pusiste nota JobFit y decidiste: ≥6 → 'Lista para aplicar'; <6 → 'Cerrada'.": "You set a JobFit score and decided: ≥6 → 'Ready to apply'; <6 → 'Closed'.",
    "Enviaste la postulación → 'Aplicada'.": "You submitted the application → 'Applied'.",
    "Respuesta positiva → 'En proceso'. Rechazo o silencio → 'Cerrada'.": "Positive reply → 'In progress'. Rejection or silence → 'Closed'.",
    "Oferta o rechazo final → 'Cerrada'.": "Offer or final rejection → 'Closed'.",
    "No sale. Se archiva con `cerrado_en`.": "It doesn't move. Archived with `cerrado_en`.",
    
    // Help — weekly review bullets
    "Embudo: cuántas tarjetas hay en cada columna → detecta dónde se atasca.": "Funnel: how many cards sit in each column → spots where things stall.",
    "Conversión: % de aplicaciones que generaron respuesta. Meta: >25%.": "Conversion: % of applications that generated a reply. Target: >25%.",
    "Seguimientos vencidos: tarjetas con proximo_seguimiento ≤ hoy → contactar o cerrar.": "Overdue follow-ups: cards with proximo_seguimiento ≤ today → reach out or close.",
    "Próximos a vencer: punto amarillo en la tarjeta; anticipa el contacto hoy.": "Coming due: yellow dot on the card; make the contact today.",
    "Alertas en la barra: cápsula roja = vencidos, amarilla = por vencer. Clic → Revisión Semanal.": "Toolbar alerts: red pill = overdue, yellow = due soon. Click → Weekly Review.",
    "Silencios >30 días: cerradas en lote con resultado=silencio.": "Ghosting >30 days: closed in bulk with resultado=silencio.",
    "Motivos de descarte: patrones (p.ej. 'todos piden SCADA' → capacitar o filtrar antes).": "Discard reasons: patterns (e.g. 'all ask for SCADA' → train up or filter earlier).",
    "Próxima semana: tarjetas en 'Lista para aplicar' aún no enviadas → priorizar lunes.": "Next week: cards still in 'Ready to apply' not yet sent → prioritize Monday.",
    
    // Help — rules
    "JobFit antes de mover de 'Por evaluar'.": "JobFit before moving out of 'To evaluate'.",
    "Brutal antes de pulsar 'Enviar'.": "Brutal before hitting 'Submit'.",
    "Requisito excluyente anula el score.": "A must-have requirement voids the score.",
    "No borrar tarjetas cerradas — alimentan métricas.": "Don't delete closed cards — they feed the metrics.",
    "proximo_seguimiento se respeta: si vence, actúas.": "proximo_seguimiento is honored: when it's due, act.",
    "3 apps excelentes > 10 mediocres.": "3 excellent apps > 10 mediocre ones.",
    "Una oferta = una tarjeta. Múltiples cargos en misma empresa = tarjetas separadas.": "One posting = one card. Multiple roles at the same company = separate cards.",
    
    // Help — transitions (trigger column + fixed words)
    "Capturas oferta": "Capture posting",
    "JobFit >=6/10": "JobFit >=6/10",
    "JobFit <6 o excluyente": "JobFit <6 or must-have",
    "Enviaste postulación": "You applied",
    "Respuesta positiva": "Positive reply",
    "30 días silencio": "30 days silence",
    "Rechazo temprano": "Early rejection",
    "Rechazo en entrevista": "Rejected in interview",
    "Solo acuse, no avanza": "Acknowledged only, no progress",
    "→ Por evaluar": "→ To evaluate",
    "Por evaluar → Lista": "To evaluate → Ready",
    "Por evaluar → Cerrada": "To evaluate → Closed",
    "Lista → Aplicada": "Ready → Applied",
    "Aplicada → En proceso": "Applied → In progress",
    "Aplicada → Cerrada": "Applied → Closed",
    "En proceso → Cerrada": "In progress → Closed",
    "En proceso → Aplicada": "In progress → Applied",
    
    // Help — field notes
    "Obligatorio": "Required",
    "Para re-visitar la vacante": "To revisit the posting",
    "Configurable en Settings → Plataformas": "Configurable in Settings → Platforms",
    "Chile / NZ / otro": "Chile / NZ / other",
    "Relevante para requisitos de visa": "Relevant for visa requirements",
    "Filtro clave para tu búsqueda": "Key filter for your search",
    "Del aviso original": "From the original posting",
    "Fecha en que la registraste": "Date you logged it",
    "Automática al crear": "Automatic on create",
    "Fecha del aviso": "Posting date",
    "Prioriza recientes": "Prefer recent ones",
    "Puntaje JobFit.fyi (1-10)": "JobFit.fyi score (1-10)",
    "Umbral: >=6 aplica, <6 descarta": "Threshold: >=6 apply, <6 drop",
    "Nota x 10 (0-100)": "Score x 10 (0-100)",
    "Comparable con tu umbral del 70%": "Comparable with your 70% threshold",
    "Visa, certificacion, residencia": "Visa, certification, residency",
    "Anula el score si no lo cumples": "Voids the score if you don't meet it",
    "Que te hace destacar para este rol": "What makes you stand out for this role",
    "Del output de JobFit": "From JobFit output",
    "Que te falta o es debil": "What you lack or is weak",
    "Del output de JobFit + modo Brutal": "From JobFit + Brutal mode output",
    "Columna actual": "Current column",
    "Se mueve con drag-drop": "Moves with drag-drop",
    "Que toca hacer ahora": "What to do next",
    "Ej: contactar recruiter, preparar entrevista": "E.g. contact recruiter, prep for interview",
    "Fecha de envio": "Submission date",
    "Auto al mover a Aplicada": "Auto when moving to Applied",
    "Cuando revisar si hay respuesta": "When to check for a reply",
    "Default: aplicada_en + 7 dias": "Default: aplicada_en + 7 days",
    "Ruta al PDF del CV enviado": "Path to the submitted CV PDF",
    "Snapshot, no el master": "Snapshot, not the master",
    "Ruta al PDF de la cover": "Path to the cover PDF",
    "Snapshot": "Snapshot",
    "Ruta a la imagen de la oferta": "Path to the posting image",
    "Captura de pantalla": "Screenshot",
    "Personas contactadas (recruiter, HM)": "People contacted (recruiter, HM)",
    "Con rol, canal y fecha": "With role, channel and date",
    "oferta / rechazo / silencio / descartada": "offer / rejected / ghosted / dropped",
    "Obligatorio al cerrar": "Required when closing",
    "Por que cerro": "Why it closed",
    "Para detectar patrones": "To spot patterns",
    "Fecha de cierre": "Close date",
    "Auto al mover a Cerrada": "Auto when moving to Closed",
    "Sectores: energia, epc, contratos": "Sectors: energy, epc, contracts",
    "Separados por coma": "Comma-separated",
]

// MARK: - Localized display names (storage keeps the Spanish rawValue)

extension PipelineColumn { var displayName: String { loc(rawValue) } }
extension Modalidad { var displayName: String { loc(rawValue) } }
extension Resultado { var displayName: String { loc(rawValue) } }
