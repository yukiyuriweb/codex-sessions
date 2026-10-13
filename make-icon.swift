// アプリアイコンの元画像 (1024x1024 PNG) を描く。使い方: swift make-icon.swift <出力.png>
import AppKit

let size: CGFloat = 1024
let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { _ in
    // macOS アイコングリッド: 1024 キャンバスに 824 角の角丸四角形
    let body = NSRect(x: 100, y: 100, width: 824, height: 824)
    let shape = NSBezierPath(roundedRect: body, xRadius: 185, yRadius: 185)

    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.35)
    shadow.shadowBlurRadius = 24
    shadow.shadowOffset = NSSize(width: 0, height: -10)
    shadow.set()
    NSColor.black.setFill()
    shape.fill()
    NSGraphicsContext.restoreGraphicsState()

    NSGradient(colors: [
        NSColor(red: 0.13, green: 0.16, blue: 0.32, alpha: 1),
        NSColor(red: 0.05, green: 0.06, blue: 0.12, alpha: 1),
    ])!.draw(in: shape, angle: -90)

    // セッション一覧を表すカード 3 枚（下ほど薄い）
    let accent = NSColor(red: 0.36, green: 0.85, blue: 0.75, alpha: 1)
    let cardX: CGFloat = 200, cardW: CGFloat = 624, cardH: CGFloat = 150
    for (i, y) in [CGFloat(600), 410, 220].enumerated() {
        let card = NSBezierPath(roundedRect: NSRect(x: cardX, y: y, width: cardW, height: cardH), xRadius: 40, yRadius: 40)
        NSColor.white.withAlphaComponent([0.95, 0.28, 0.14][i]).setFill()
        card.fill()
        if i > 0 {
            // タイトル行を模した線
            let line = NSBezierPath(roundedRect: NSRect(x: cardX + 60, y: y + 60, width: [380, 280][i - 1], height: 30), xRadius: 15, yRadius: 15)
            NSColor.white.withAlphaComponent(0.35).setFill()
            line.fill()
        }
    }

    // 一番上のカードに ">_" プロンプト
    let font = NSFont.monospacedSystemFont(ofSize: 120, weight: .heavy)
    let prompt = NSAttributedString(string: ">_", attributes: [
        .font: font,
        .foregroundColor: NSColor(red: 0.09, green: 0.11, blue: 0.22, alpha: 1),
    ])
    let ps = prompt.size()
    prompt.draw(at: NSPoint(x: cardX + 60, y: 600 + (cardH - ps.height) / 2))

    // 右端のコピーを示すアクセントの丸
    let dot = NSBezierPath(ovalIn: NSRect(x: cardX + cardW - 60 - 70, y: 600 + (cardH - 70) / 2, width: 70, height: 70))
    accent.setFill()
    dot.fill()
    return true
}

let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size), bitsPerSample: 8,
                           samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
image.draw(in: NSRect(x: 0, y: 0, width: size, height: size))
NSGraphicsContext.restoreGraphicsState()
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
