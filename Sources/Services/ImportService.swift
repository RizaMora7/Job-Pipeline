import Foundation

// MARK: - Import from Obsidian vault (parse YAML frontmatter from .md files)

final class ImportService {

    struct Result {
        var imported = 0
        var duplicates = 0
        var failed = 0
    }

    /// Reads and parses every application note under the vault. Touches no app state,
    /// so it is safe to call off the main thread.
    func parseVault(path: String) -> [Application] {
        let fm = FileManager.default
        var parsed: [Application] = []

        // Look for Applications/ subfolder
        let appsPath = (path as NSString).appendingPathComponent("Applications")
        let searchPath = fm.fileExists(atPath: appsPath) ? appsPath : path
        
        guard let enumerator = fm.enumerator(at: URL(fileURLWithPath: searchPath),
                                              includingPropertiesForKeys: [.isRegularFileKey],
                                              options: [.skipsHiddenFiles]) else { return [] }
        
        for case let fileURL as URL in enumerator {
            guard fileURL.pathExtension == "md" else { continue }
            let name = fileURL.deletingPathExtension().lastPathComponent
            if name.hasPrefix("_") { continue } // skip templates
            
            guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else { continue }
            // parseFrontmatter already falls back to today when `capturada` is missing.
            guard let app = parseFrontmatter(content: content) else { continue }
            parsed.append(app)
        }
        return parsed
    }

    /// Saves parsed applications, skipping any that already exist (same URL, or same
    /// company + role when there is no URL) so re-importing the vault is idempotent.
    /// Must run on the main thread: it mutates the store's published state.
    func save(_ apps: [Application], into store: AppStore) -> Result {
        dispatchPrecondition(condition: .onQueue(.main))
        var result = Result()
        var seen = Set(store.applications.map(Self.dedupKey))
        for app in apps {
            let key = Self.dedupKey(app)
            if seen.contains(key) { result.duplicates += 1; continue }
            if store.save(app) {
                seen.insert(key)
                result.imported += 1
            } else {
                result.failed += 1
            }
        }
        return result
    }

    static func dedupKey(_ app: Application) -> String {
        func norm(_ s: String) -> String { s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
        let url = norm(app.url)
        return url.isEmpty ? "ec:\(norm(app.empresa))|\(norm(app.cargo))" : "url:\(url)"
    }
    
    private func parseFrontmatter(content: String) -> Application? {
        // Extract YAML between --- markers
        let lines = content.components(separatedBy: "\n")
        guard lines.first?.trimmingCharacters(in: .whitespaces) == "---" else { return nil }
        
        var yamlLines: [String] = []
        var inYaml = false
        for line in lines {
            if line.trimmingCharacters(in: .whitespaces) == "---" {
                if inYaml { break }
                inYaml = true
                continue
            }
            if inYaml { yamlLines.append(line) }
        }
        
        let dict = parseSimpleYAML(yamlLines)
        
        // Only import if it has tipo: aplicacion
        guard dict["tipo"] == "aplicacion" else { return nil }
        
        var app = Application()
        app.empresa = dict["empresa"] ?? ""
        app.cargo = dict["cargo"] ?? ""
        app.url = dict["url"] ?? ""
        app.plataforma = dict["plataforma"] ?? "Otra"
        app.pais = dict["pais"] ?? "Chile"
        app.modalidad = Modalidad(rawValue: dict["modalidad"] ?? "") ?? .remoto
        app.seniority = dict["seniority"] ?? ""
        
        if let nota = Double(dict["job_fit_nota"] ?? "") { app.jobFitNota = nota }
        if let fit = Int(dict["job_fit"] ?? "") { app.jobFit = fit }
        app.requisitoExcluyente = dict["requisito_excluyente"] ?? ""
        
        let estadoStr = dict["estado"] ?? "por_evaluar"
        app.estado = mapEstado(estadoStr)
        
        app.siguienteAccion = dict["siguiente_accion"] ?? ""
        app.cvUsado = dict["cv_usado"] ?? ""
        app.coverUsada = dict["cover_usada"] ?? ""
        
        if let res = dict["resultado"], !res.isEmpty {
            app.resultado = mapResultado(res)
        }
        app.motivo = dict["motivo"] ?? ""
        app.tags = dict["tags"] ?? ""
        
        app.capturada = parseDate(dict["capturada"]) ?? Date()
        app.publicada = parseDate(dict["publicada"])
        app.aplicadaEn = parseDate(dict["aplicada_en"])
        app.cerradoEn = parseDate(dict["cerrado_en"])
        app.proximoSeguimiento = parseDate(dict["proximo_seguimiento"])
        
        return app
    }
    
    private func parseSimpleYAML(_ lines: [String]) -> [String: String] {
        var dict: [String: String] = [:]
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("#") || trimmed.isEmpty { continue }
            if let colonIdx = trimmed.firstIndex(of: ":") {
                let key = String(trimmed[trimmed.startIndex..<colonIdx]).trimmingCharacters(in: .whitespaces)
                var val = String(trimmed[trimmed.index(after: colonIdx)...]).trimmingCharacters(in: .whitespaces)
                // Obsidian often quotes values (url: "https://…"); drop one matching pair.
                if val.count >= 2, let q = val.first, q == "\"" || q == "'", val.last == q {
                    val = String(val.dropFirst().dropLast())
                }
                dict[key] = val
            }
        }
        return dict
    }
    
    private func parseDate(_ str: String?) -> Date? {
        guard let s = str, !s.isEmpty else { return nil }
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.locale = Locale(identifier: "en_US_POSIX")
        return fmt.date(from: s)
    }
    
    private func mapEstado(_ raw: String) -> PipelineColumn {
        switch raw.lowercased() {
        case "por_evaluar", "por evaluar": return .porEvaluar
        case "lista", "lista para aplicar": return .listaParaAplicar
        case "aplicada", "aplicar": return .aplicada
        case "en_proceso", "en proceso": return .enProceso
        case "cerrada": return .cerrada
        default: return .porEvaluar
        }
    }
    
    private func mapResultado(_ raw: String) -> Resultado? {
        switch raw.lowercased() {
        case "oferta": return .oferta
        case "rechazo": return .rechazo
        case "silencio": return .silencio
        case "descartada_evaluada", "descartada": return .descartadaEvaluada
        default: return nil
        }
    }
}
