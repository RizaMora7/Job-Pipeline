import Foundation
import SQLite3

// SQLite copies the string when we pass SQLITE_TRANSIENT; passing nil (SQLITE_STATIC)
// keeps a dangling pointer because Swift's bridged UTF-8 buffer is freed after the call.
let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

// MARK: - Database Service (SQLite3, zero external deps)

final class DatabaseService {
    static let shared = DatabaseService()
    private var db: OpaquePointer?
    private let dbPath: String
    
    private init() {
        let appSupport = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first!
        let folder = (appSupport as NSString).appendingPathComponent("JobPipeline")
        try? FileManager.default.createDirectory(atPath: folder, withIntermediateDirectories: true)
        dbPath = (folder as NSString).appendingPathComponent("pipeline.sqlite")
        open()
        createTables()
    }
    
    deinit { sqlite3_close(db) }
    
    private func open() {
        if sqlite3_open(dbPath, &db) != SQLITE_OK {
            fatalError("Cannot open database: \(String(cString: sqlite3_errmsg(db)))")
        }
        sqlite3_exec(db, "PRAGMA journal_mode=WAL;", nil, nil, nil)
    }
    
    private func createTables() {
        let sql = """
        CREATE TABLE IF NOT EXISTS applications (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            empresa TEXT NOT NULL DEFAULT '',
            cargo TEXT NOT NULL DEFAULT '',
            url TEXT DEFAULT '',
            plataforma TEXT DEFAULT 'LinkedIn',
            pais TEXT DEFAULT 'Chile',
            modalidad TEXT DEFAULT 'Remoto',
            seniority TEXT DEFAULT '',
            capturada REAL NOT NULL,
            publicada REAL,
            aplicada_en REAL,
            cerrado_en REAL,
            proximo_seguimiento REAL,
            job_fit_nota REAL,
            job_fit INTEGER,
            requisito_excluyente TEXT DEFAULT '',
            fortalezas TEXT DEFAULT '',
            brechas TEXT DEFAULT '',
            estado TEXT DEFAULT 'Por evaluar',
            siguiente_accion TEXT DEFAULT '',
            cv_usado TEXT DEFAULT '',
            cover_usada TEXT DEFAULT '',
            captura_oferta TEXT DEFAULT '',
            contactos_json TEXT DEFAULT '[]',
            resultado TEXT,
            motivo TEXT DEFAULT '',
            tags TEXT DEFAULT '',
            created_at REAL NOT NULL,
            updated_at REAL NOT NULL
        );
        CREATE TABLE IF NOT EXISTS settings (
            key TEXT PRIMARY KEY,
            value TEXT
        );
        """
        sqlite3_exec(db, sql, nil, nil, nil)
    }
    
    // MARK: - CRUD
    
    func fetchAll() -> [Application] {
        let sql = "SELECT * FROM applications ORDER BY estado, capturada DESC;"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        defer { sqlite3_finalize(stmt) }
        
        var results: [Application] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            results.append(rowToApp(stmt))
        }
        return results
    }
    
    func fetch(byColumn col: PipelineColumn) -> [Application] {
        fetchAll().filter { $0.estado == col }
    }
    
    func insert(_ app: Application) -> Int {
        let sql = """
        INSERT INTO applications (empresa, cargo, url, plataforma, pais, modalidad, seniority,
            capturada, publicada, aplicada_en, cerrado_en, proximo_seguimiento,
            job_fit_nota, job_fit, requisito_excluyente, fortalezas, brechas,
            estado, siguiente_accion, cv_usado, cover_usada, captura_oferta,
            contactos_json, resultado, motivo, tags, created_at, updated_at)
        VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?);
        """
        var stmt: OpaquePointer?
        sqlite3_prepare_v2(db, sql, -1, &stmt, nil)
        defer { sqlite3_finalize(stmt) }
        
        bindApp(stmt, app, offset: 1)
        sqlite3_step(stmt)
        return Int(sqlite3_last_insert_rowid(db))
    }
    
    func update(_ app: Application) {
        let sql = """
        UPDATE applications SET empresa=?, cargo=?, url=?, plataforma=?, pais=?, modalidad=?, seniority=?,
            capturada=?, publicada=?, aplicada_en=?, cerrado_en=?, proximo_seguimiento=?,
            job_fit_nota=?, job_fit=?, requisito_excluyente=?, fortalezas=?, brechas=?,
            estado=?, siguiente_accion=?, cv_usado=?, cover_usada=?, captura_oferta=?,
            contactos_json=?, resultado=?, motivo=?, tags=?, created_at=?, updated_at=?
        WHERE id=?;
        """
        var stmt: OpaquePointer?
        sqlite3_prepare_v2(db, sql, -1, &stmt, nil)
        defer { sqlite3_finalize(stmt) }
        
        bindApp(stmt, app, offset: 1)
        sqlite3_bind_int64(stmt, 29, Int64(app.id))
        sqlite3_step(stmt)
    }
    
    func delete(id: Int) {
        let sql = "DELETE FROM applications WHERE id=?;"
        var stmt: OpaquePointer?
        sqlite3_prepare_v2(db, sql, -1, &stmt, nil)
        sqlite3_bind_int64(stmt, 1, Int64(id))
        sqlite3_step(stmt)
        sqlite3_finalize(stmt)
    }
    
    func count(byColumn col: PipelineColumn) -> Int {
        let sql = "SELECT COUNT(*) FROM applications WHERE estado=?;"
        var stmt: OpaquePointer?
        sqlite3_prepare_v2(db, sql, -1, &stmt, nil)
        sqlite3_bind_text(stmt, 1, col.rawValue, -1, SQLITE_TRANSIENT)
        let count = sqlite3_step(stmt) == SQLITE_ROW ? Int(sqlite3_column_int(stmt, 0)) : 0
        sqlite3_finalize(stmt)
        return count
    }
    
    func getSetting(_ key: String) -> String? {
        let sql = "SELECT value FROM settings WHERE key=?;"
        var stmt: OpaquePointer?
        sqlite3_prepare_v2(db, sql, -1, &stmt, nil)
        sqlite3_bind_text(stmt, 1, key, -1, SQLITE_TRANSIENT)
        let val = sqlite3_step(stmt) == SQLITE_ROW ? String(cString: sqlite3_column_text(stmt, 0)) : nil
        sqlite3_finalize(stmt)
        return val
    }
    
    func setSetting(_ key: String, _ value: String) {
        let sql = "INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?);"
        var stmt: OpaquePointer?
        sqlite3_prepare_v2(db, sql, -1, &stmt, nil)
        sqlite3_bind_text(stmt, 1, key, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 2, value, -1, SQLITE_TRANSIENT)
        sqlite3_step(stmt)
        sqlite3_finalize(stmt)
    }
    
    // MARK: - Helpers
    
    private func bindApp(_ stmt: OpaquePointer?, _ app: Application, offset: Int32) {
        var i = offset
        sqlite3_bind_text(stmt, i, app.empresa, -1, SQLITE_TRANSIENT); i += 1
        sqlite3_bind_text(stmt, i, app.cargo, -1, SQLITE_TRANSIENT); i += 1
        sqlite3_bind_text(stmt, i, app.url, -1, SQLITE_TRANSIENT); i += 1
        sqlite3_bind_text(stmt, i, app.plataforma, -1, SQLITE_TRANSIENT); i += 1
        sqlite3_bind_text(stmt, i, app.pais, -1, SQLITE_TRANSIENT); i += 1
        sqlite3_bind_text(stmt, i, app.modalidad.rawValue, -1, SQLITE_TRANSIENT); i += 1
        sqlite3_bind_text(stmt, i, app.seniority, -1, SQLITE_TRANSIENT); i += 1
        sqlite3_bind_double(stmt, i, app.capturada.timeIntervalSince1970); i += 1
        bindOptionalDate(stmt, i, app.publicada); i += 1
        bindOptionalDate(stmt, i, app.aplicadaEn); i += 1
        bindOptionalDate(stmt, i, app.cerradoEn); i += 1
        bindOptionalDate(stmt, i, app.proximoSeguimiento); i += 1
        bindOptionalDouble(stmt, i, app.jobFitNota); i += 1
        bindOptionalInt(stmt, i, app.jobFit); i += 1
        sqlite3_bind_text(stmt, i, app.requisitoExcluyente, -1, SQLITE_TRANSIENT); i += 1
        sqlite3_bind_text(stmt, i, app.fortalezas, -1, SQLITE_TRANSIENT); i += 1
        sqlite3_bind_text(stmt, i, app.brechas, -1, SQLITE_TRANSIENT); i += 1
        sqlite3_bind_text(stmt, i, app.estado.rawValue, -1, SQLITE_TRANSIENT); i += 1
        sqlite3_bind_text(stmt, i, app.siguienteAccion, -1, SQLITE_TRANSIENT); i += 1
        sqlite3_bind_text(stmt, i, app.cvUsado, -1, SQLITE_TRANSIENT); i += 1
        sqlite3_bind_text(stmt, i, app.coverUsada, -1, SQLITE_TRANSIENT); i += 1
        sqlite3_bind_text(stmt, i, app.capturaOferta, -1, SQLITE_TRANSIENT); i += 1
        let json = (try? JSONEncoder().encode(app.contactos)).flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
        sqlite3_bind_text(stmt, i, json, -1, SQLITE_TRANSIENT); i += 1
        if let r = app.resultado { sqlite3_bind_text(stmt, i, r.rawValue, -1, SQLITE_TRANSIENT) } else { sqlite3_bind_null(stmt, i) }
        i += 1
        sqlite3_bind_text(stmt, i, app.motivo, -1, SQLITE_TRANSIENT); i += 1
        sqlite3_bind_text(stmt, i, app.tags, -1, SQLITE_TRANSIENT); i += 1
        sqlite3_bind_double(stmt, i, app.createdAt.timeIntervalSince1970); i += 1
        sqlite3_bind_double(stmt, i, app.updatedAt.timeIntervalSince1970)
    }
    
    private func bindOptionalDate(_ stmt: OpaquePointer?, _ idx: Int32, _ val: Date?) {
        if let v = val { sqlite3_bind_double(stmt, idx, v.timeIntervalSince1970) }
        else { sqlite3_bind_null(stmt, idx) }
    }
    
    private func bindOptionalDouble(_ stmt: OpaquePointer?, _ idx: Int32, _ val: Double?) {
        if let v = val { sqlite3_bind_double(stmt, idx, v) }
        else { sqlite3_bind_null(stmt, idx) }
    }
    
    private func bindOptionalInt(_ stmt: OpaquePointer?, _ idx: Int32, _ val: Int?) {
        if let v = val { sqlite3_bind_int(stmt, idx, Int32(v)) }
        else { sqlite3_bind_null(stmt, idx) }
    }
    
    private func rowToApp(_ stmt: OpaquePointer?) -> Application {
        var app = Application()
        app.id = Int(sqlite3_column_int64(stmt, 0))
        app.empresa = str(stmt, 1)
        app.cargo = str(stmt, 2)
        app.url = str(stmt, 3)
        app.plataforma = str(stmt, 4)
        app.pais = str(stmt, 5)
        app.modalidad = Modalidad(rawValue: str(stmt, 6)) ?? .remoto
        app.seniority = str(stmt, 7)
        app.capturada = Date(timeIntervalSince1970: sqlite3_column_double(stmt, 8))
        app.publicada = optDate(stmt, 9)
        app.aplicadaEn = optDate(stmt, 10)
        app.cerradoEn = optDate(stmt, 11)
        app.proximoSeguimiento = optDate(stmt, 12)
        app.jobFitNota = optDouble(stmt, 13)
        app.jobFit = sqlite3_column_type(stmt, 14) == SQLITE_NULL ? nil : Int(sqlite3_column_int(stmt, 14))
        app.requisitoExcluyente = str(stmt, 15)
        app.fortalezas = str(stmt, 16)
        app.brechas = str(stmt, 17)
        app.estado = PipelineColumn(rawValue: str(stmt, 18)) ?? .porEvaluar
        app.siguienteAccion = str(stmt, 19)
        app.cvUsado = str(stmt, 20)
        app.coverUsada = str(stmt, 21)
        app.capturaOferta = str(stmt, 22)
        if let data = str(stmt, 23).data(using: .utf8) {
            app.contactos = (try? JSONDecoder().decode([Contacto].self, from: data)) ?? []
        }
        app.resultado = Resultado(rawValue: str(stmt, 24))
        app.motivo = str(stmt, 25)
        app.tags = str(stmt, 26)
        app.createdAt = Date(timeIntervalSince1970: sqlite3_column_double(stmt, 27))
        app.updatedAt = Date(timeIntervalSince1970: sqlite3_column_double(stmt, 28))
        return app
    }
    
    private func str(_ stmt: OpaquePointer?, _ idx: Int32) -> String {
        guard let c = sqlite3_column_text(stmt, idx) else { return "" }
        return String(cString: c)
    }
    
    private func optDate(_ stmt: OpaquePointer?, _ idx: Int32) -> Date? {
        sqlite3_column_type(stmt, idx) == SQLITE_NULL ? nil : Date(timeIntervalSince1970: sqlite3_column_double(stmt, idx))
    }
    
    private func optDouble(_ stmt: OpaquePointer?, _ idx: Int32) -> Double? {
        sqlite3_column_type(stmt, idx) == SQLITE_NULL ? nil : sqlite3_column_double(stmt, idx)
    }
}
