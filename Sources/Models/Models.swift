import Foundation

enum PipelineColumn: String, CaseIterable, Codable, Identifiable {
    case porEvaluar = "Por evaluar"
    case listaParaAplicar = "Lista para aplicar"
    case aplicada = "Aplicada"
    case enProceso = "En proceso"
    case cerrada = "Cerrada"
    
    var id: String { rawValue }
    
    var sortOrder: Int {
        switch self {
        case .porEvaluar: return 0
        case .listaParaAplicar: return 1
        case .aplicada: return 2
        case .enProceso: return 3
        case .cerrada: return 4
        }
    }
    
    var accentColor: String {
        switch self {
        case .porEvaluar: return "gray"
        case .listaParaAplicar: return "blue"
        case .aplicada: return "orange"
        case .enProceso: return "purple"
        case .cerrada: return "green"
        }
    }
}

enum Modalidad: String, CaseIterable, Codable {
    case remoto = "Remoto"
    case hibrido = "Híbrido"
    case presencial = "Presencial"
}

enum Resultado: String, CaseIterable, Codable {
    case oferta = "Oferta"
    case rechazo = "Rechazo"
    case silencio = "Silencio"
    case descartadaEvaluada = "Descartada evaluada"
}

struct Contacto: Codable, Identifiable {
    var id: UUID = UUID()
    var persona: String = ""
    var rol: String = ""
    var canal: String = ""
    var tocado: Date?
}

struct Application: Identifiable, Codable {
    var id: Int = 0
    var empresa: String = ""
    var cargo: String = ""
    var url: String = ""
    var plataforma: String = "LinkedIn"
    var pais: String = "Chile"
    var modalidad: Modalidad = .remoto
    var seniority: String = ""
    
    var capturada: Date = Date()
    var publicada: Date?
    var aplicadaEn: Date?
    var cerradoEn: Date?
    var proximoSeguimiento: Date?
    
    var jobFitNota: Double?
    var jobFit: Int?
    var requisitoExcluyente: String = ""
    var fortalezas: String = ""
    var brechas: String = ""
    
    var estado: PipelineColumn = .porEvaluar
    var siguienteAccion: String = ""
    
    var cvUsado: String = ""
    var coverUsada: String = ""
    var capturaOferta: String = ""
    
    var contactos: [Contacto] = []
    
    var resultado: Resultado?
    var motivo: String = ""
    var tags: String = ""
    
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
}
