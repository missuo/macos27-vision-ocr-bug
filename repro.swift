// Reproduces broken mixed CJK + Latin text recognition in Vision on macOS 27.
// Usage: xcrun swiftc -O repro.swift -o repro && ./repro
import AppKit
import Vision

let samples = [
    "Hello World 你好，世界",
    "The quick brown fox 敏捷的棕色狐狸",
    "iPhone 17 发布会",
    "macOS 系统更新",
    "你好 Hello World",
    "Open Settings 打开设置",
]
let sizes: [CGFloat] = [28, 48]

func render(_ text: String, _ size: CGFloat) -> CGImage {
    let attrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: size), .foregroundColor: NSColor.black]
    let canvas = NSSize(width: (text as NSString).size(withAttributes: attrs).width + 40, height: size * 2)
    let image = NSImage(size: canvas)
    image.lockFocus()
    NSColor.white.setFill()
    NSRect(origin: .zero, size: canvas).fill()
    (text as NSString).draw(at: NSPoint(x: 20, y: size * 0.4), withAttributes: attrs)
    image.unlockFocus()
    return image.cgImage(forProposedRect: nil, context: nil, hints: nil)!
}

func save(_ image: CGImage, _ name: String) {
    let data = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])!
    try! data.write(to: URL(fileURLWithPath: "images/\(name).png"))
}

func recognize(_ image: CGImage, autoDetect: Bool, languages: [String]?) -> String {
    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    request.automaticallyDetectsLanguage = autoDetect
    if let languages { request.recognitionLanguages = languages }
    try! VNImageRequestHandler(cgImage: image).perform([request])
    let text = (request.results ?? []).map { $0.topCandidates(1)[0].string }.joined(separator: " / ")
    return text.isEmpty ? "*(empty)*" : "`\(text)`"
}

try? FileManager.default.createDirectory(atPath: "images", withIntermediateDirectories: true)
print("macOS \(ProcessInfo.processInfo.operatingSystemVersionString)\n")
print("| Input | Size | automaticallyDetectsLanguage | [en-US, zh-Hans] | [zh-Hans, en-US] |")
print("|---|---|---|---|---|")
for (i, text) in samples.enumerated() {
    for size in sizes {
        let image = render(text, size)
        save(image, "sample\(i + 1)-\(Int(size))pt")
        let auto = recognize(image, autoDetect: true, languages: nil)
        let enFirst = recognize(image, autoDetect: false, languages: ["en-US", "zh-Hans"])
        let zhFirst = recognize(image, autoDetect: false, languages: ["zh-Hans", "en-US"])
        print("| \(text) | \(Int(size))pt | \(auto) | \(enFirst) | \(zhFirst) |")
    }
}
