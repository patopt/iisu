import Foundation

struct Game: Identifiable, Hashable {
    /// Stable across scans: platform id + file name. Used for favourites and
    /// home-screen shortcuts, which outlive any single scan.
    let id: String
    let platformId: String
    let title: String
    let fileName: String
    let url: URL
    let fileSize: Int64
    let addedAt: Date

    init(platformId: String, url: URL, fileSize: Int64, addedAt: Date) {
        let fileName = url.lastPathComponent
        self.id = "\(platformId)/\(fileName)"
        self.platformId = platformId
        self.fileName = fileName
        self.url = url
        self.fileSize = fileSize
        self.addedAt = addedAt
        self.title = Game.displayTitle(from: url)
    }

    /// ROM sets are named `Game Name (USA) (Rev 1) [!].ext`. Strip the noise so
    /// the grid reads like a games library rather than a file listing.
    static func displayTitle(from url: URL) -> String {
        var name = url.deletingPathExtension().lastPathComponent
        name = name.replacingOccurrences(
            of: #"\s*[\(\[][^\)\]]*[\)\]]"#,
            with: "",
            options: .regularExpression
        )
        name = name.replacingOccurrences(of: "_", with: " ")
        name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? url.deletingPathExtension().lastPathComponent : name
    }

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }
}
