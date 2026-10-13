// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "CodexSessions",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "CodexSessions",
            linkerSettings: [.linkedLibrary("sqlite3")]
        )
    ]
)
