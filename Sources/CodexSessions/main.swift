import AppKit
import SQLite3
import SwiftUI

struct Session: Identifiable {
    let id: String
    let title: String
    let cwd: String
    let updated: Date
}

struct Group: Identifiable {
    var id: String { cwd }
    let cwd: String
    let sessions: [Session]
}

/// Reads the unarchived, user-started sessions from ~/.codex/state_*.sqlite, read-only
func loadSessions() throws -> [Session] {
    let codexDir = FileManager.default.homeDirectoryForCurrentUser.appending(path: ".codex")
    let files = try FileManager.default.contentsOfDirectory(atPath: codexDir.path)
    // A schema update may bump state_5 to state_6 and so on, so take the highest number
    guard let dbName = files
        .filter({ $0.hasPrefix("state_") && $0.hasSuffix(".sqlite") })
        .max(by: { $0.localizedStandardCompare($1) == .orderedAscending })
    else { throw NSError(domain: "CodexSessions", code: 1, userInfo: [NSLocalizedDescriptionKey: String(localized: "No state_*.sqlite found in ~/.codex")]) }

    var db: OpaquePointer?
    guard sqlite3_open_v2(codexDir.appending(path: dbName).path, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
        let msg = String(cString: sqlite3_errmsg(db))
        sqlite3_close(db)
        throw NSError(domain: "CodexSessions", code: 2, userInfo: [NSLocalizedDescriptionKey: msg])
    }
    defer { sqlite3_close(db) }
    sqlite3_busy_timeout(db, 2000)

    let sql = """
        SELECT id, COALESCE(NULLIF(name, ''), NULLIF(title, ''), preview), cwd, recency_at_ms
        FROM threads
        WHERE archived = 0 AND preview <> '' AND source NOT LIKE '{%'
        ORDER BY recency_at_ms DESC
        """
    var stmt: OpaquePointer?
    guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
        throw NSError(domain: "CodexSessions", code: 3, userInfo: [NSLocalizedDescriptionKey: String(cString: sqlite3_errmsg(db))])
    }
    defer { sqlite3_finalize(stmt) }

    var result: [Session] = []
    while sqlite3_step(stmt) == SQLITE_ROW {
        result.append(Session(
            id: String(cString: sqlite3_column_text(stmt, 0)),
            title: String(cString: sqlite3_column_text(stmt, 1)),
            cwd: String(cString: sqlite3_column_text(stmt, 2)),
            updated: Date(timeIntervalSince1970: Double(sqlite3_column_int64(stmt, 3)) / 1000)
        ))
    }
    return result
}

@MainActor
final class Store: ObservableObject {
    @Published var groups: [Group] = []
    @Published var error: String?

    func reload() {
        do {
            let sessions = try loadSessions()
            // Sessions come newest first, so grouping in order of first appearance puts the most recently used directory first
            var order: [String] = []
            var byCwd: [String: [Session]] = [:]
            for s in sessions {
                if byCwd[s.cwd] == nil { order.append(s.cwd) }
                byCwd[s.cwd, default: []].append(s)
            }
            groups = order.map { Group(cwd: $0, sessions: byCwd[$0]!) }
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }
}

func copy(_ text: String) {
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(text, forType: .string)
}

func shellQuote(_ s: String) -> String {
    "'" + s.replacingOccurrences(of: "'", with: "'\\''") + "'"
}

func displayPath(_ path: String) -> String {
    let home = FileManager.default.homeDirectoryForCurrentUser.path
    return path.hasPrefix(home) ? "~" + path.dropFirst(home.count) : path
}

struct SessionRow: View {
    let session: Session
    @Binding var copiedID: String?

    var command: String { "codex resume \(session.id)" }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(session.title).lineLimit(1)
                Text(session.updated, format: .relative(presentation: .named))
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                copy(command)
                copiedID = session.id
            } label: {
                Label(copiedID == session.id ? "Copied" : "Copy",
                      systemImage: copiedID == session.id ? "checkmark" : "doc.on.doc")
            }
            .help(command)
        }
        .contextMenu {
            Button("Copy codex resume Command") { copy(command) }
            Button("Copy with cd") { copy("cd \(shellQuote(session.cwd)) && \(command)") }
            Button("Copy ID") { copy(session.id) }
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var store: Store
    @State private var copiedID: String?

    var body: some View {
        List {
            if let error = store.error {
                Text(error).foregroundStyle(.red)
            }
            ForEach(store.groups) { group in
                Section {
                    ForEach(group.sessions) { SessionRow(session: $0, copiedID: $copiedID) }
                } header: {
                    HStack {
                        Text(URL(fileURLWithPath: group.cwd).lastPathComponent).bold()
                        Text(displayPath(group.cwd)).foregroundStyle(.secondary).lineLimit(1).truncationMode(.middle)
                        Spacer()
                        Text("\(group.sessions.count)").foregroundStyle(.secondary)
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 420, minHeight: 300)
        .toolbar {
            Button { store.reload() } label: { Label("Reload", systemImage: "arrow.clockwise") }
                .keyboardShortcut("r")
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            store.reload()
        }
    }
}

struct CodexSessionsApp: App {
    @StateObject private var store = Store()

    var body: some Scene {
        Window("Codex Sessions", id: "main") {
            ContentView().environmentObject(store)
        }
    }
}

CodexSessionsApp.main()
