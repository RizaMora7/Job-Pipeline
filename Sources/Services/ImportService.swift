import Foundation

// MARK: - Import from Obsidian vault (parse YAML frontmatter from .md files)

final class ImportService {
    
    func importFromVault(path: String, store: AppStore) -> Int {
        let fm = FileManager.default
        var count = 0
        
        // Look for Applications/ subfolder
        let appsPath = (path as NSString).appendingPathComponent("Applications")
        let searchPath = fm.fileExists(atPath: appsPath) ? appsPath : path
        
        guard let enumerator = fm.enumerator(at: URL(fileURLWithPath: searchPath),
                                              includingPropertiesForKeys: [.isRegularFileKey],
                                              options: [.skipsHiddenFiles]) else { return 0 }
        
        for case let fileURL as URL in enumerator {
            guard fileURL.pathExtension == "md" else { continue }
            let name = fileURL.deletingPathExtension().lastPathComponent
            if name.hasPrefix("_") { continue } // skip templates
            
            guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else { continue }
            guard let app = parseFrontmatter(content: content) else { continue }
            
            var newApp = app
            newApp.capturada = Date() // default if not parseable
            store.save(newApp)
            count += 1
        }
        return count
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
                let val = String(trimmed[trimmed.index(after: colonIdx)...]).trimmingCharacters(in: .whitespaces)
                dict[key] = val.isEmpty ? "" : val
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
