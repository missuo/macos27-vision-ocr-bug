// Reproduces broken mixed CJK + Latin text recognition in Vision on macOS 27.
// Usage: xcrun swiftc -O repro.swift -o repro && ./repro
import AppKit
import CoreML
import Vision

let samples = [
    "Hello World 你好，世界",
    "The quick brown fox 敏捷的棕色狐狸",
    "iPhone 17 发布会",
    "macOS 系统更新",
    "你好 Hello World",
    "Open Settings 打开设置",
    "今天天气很好，我们一起去公园散步吧。",
]
let sizes: [CGFloat] = [28, 48]

struct Config {
    let name: String
    var level: VNRequestTextRecognitionLevel = .accurate
    var autoDetect = false
    var languages: [String]? = nil
    var device: String? = nil
}

let configs = [
    Config(name: "auto-detect", autoDetect: true),
    Config(name: "default (no languages set)"),
    Config(name: "[en-US, zh-Hans]", languages: ["en-US", "zh-Hans"]),
    Config(name: "[zh-Hans, en-US]", languages: ["zh-Hans", "en-US"]),
    Config(name: "[zh-Hans]", languages: ["zh-Hans"]),
    Config(name: "auto-detect + [zh-Hans, en-US]", autoDetect: true, languages: ["zh-Hans", "en-US"]),
    Config(name: "auto-detect, CPU only", autoDetect: true, device: "cpu"),
    Config(name: "auto-detect, GPU only", autoDetect: true, device: "gpu"),
    Config(name: "auto-detect, Neural Engine only", autoDetect: true, device: "ane"),
    Config(name: "[en-US, zh-Hans], fast", level: .fast, languages: ["en-US", "zh-Hans"]),
]

func shell(_ command: String) -> String {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/bin/sh")
    process.arguments = ["-c", command]
    let pipe = Pipe()
    process.standardOutput = pipe
    try? process.run()
    process.waitUntilExit()
    return String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
        .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
}

func printEnvironment() {
    let textRecognition = "/System/Library/PrivateFrameworks/TextRecognition.framework/Versions/A/Resources/version.plist"
    let plist = NSDictionary(contentsOfFile: textRecognition)
    let probe = VNRecognizeTextRequest()
    print("## Environment\n")
    print("- macOS: \(ProcessInfo.processInfo.operatingSystemVersionString)")
    print("- Chip: \(shell("sysctl -n machdep.cpu.brand_string"))")
    print("- Model: \(shell("sysctl -n hw.model"))")
    print("- TextRecognition.framework: \(plist?["CFBundleVersion"] ?? "?") (source \(plist?["SourceVersion"] ?? "?"))")
    print("- AppleLanguages: \(UserDefaults.standard.stringArray(forKey: "AppleLanguages") ?? [])")
    print("- AppleLocale: \(Locale.current.identifier)")
    print("- VNRecognizeTextRequest revision: \(probe.revision), supported: \(Array(VNRecognizeTextRequest.supportedRevisions))")
    print("- Default recognitionLanguages: \(probe.recognitionLanguages)")
    print("- Supported languages (accurate): \((try? probe.supportedRecognitionLanguages()) ?? [])")
    print()
}

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

func pin(_ request: VNRecognizeTextRequest, to device: String) {
    guard let stages = try? request.supportedComputeStageDevices else { return }
    for (stage, devices) in stages {
        let match = devices.first { d in
            switch d {
            case .cpu: return device == "cpu"
            case .gpu: return device == "gpu"
            case .neuralEngine: return device == "ane"
            @unknown default: return false
            }
        }
        if let match { request.setComputeDevice(match, for: stage) }
    }
}

func recognize(_ image: CGImage, _ config: Config) -> (String, Double) {
    let request = VNRecognizeTextRequest()
    request.recognitionLevel = config.level
    request.automaticallyDetectsLanguage = config.autoDetect
    if let languages = config.languages { request.recognitionLanguages = languages }
    if let device = config.device { pin(request, to: device) }
    let start = Date()
    do {
        try VNImageRequestHandler(cgImage: image).perform([request])
    } catch {
        return ("ERROR: \(error)", 0)
    }
    let text = (request.results ?? []).map { $0.topCandidates(1)[0].string }.joined(separator: " / ")
    return (text.isEmpty ? "(empty)" : text, Date().timeIntervalSince(start))
}

try? FileManager.default.createDirectory(atPath: "images", withIntermediateDirectories: true)
printEnvironment()

var summary: [String: (pass: Int, total: Int)] = [:]
print("## Results\n")
for (i, text) in samples.enumerated() {
    for size in sizes {
        let image = render(text, size)
        save(image, "sample\(i + 1)-\(Int(size))pt")
        print("### \(text) (\(Int(size))pt)\n")
        for config in configs {
            let (result, time) = recognize(image, config)
            let ok = result.replacingOccurrences(of: " ", with: "") == text.replacingOccurrences(of: " ", with: "")
            summary[config.name, default: (0, 0)].total += 1
            if ok { summary[config.name]!.pass += 1 }
            print("- \(ok ? "✅" : "❌") \(config.name) [\(String(format: "%.2f", time))s]: \(result)")
        }
        print()
    }
}

print("## Summary (exact match, ignoring spaces)\n")
for config in configs {
    let s = summary[config.name]!
    print("- \(config.name): \(s.pass)/\(s.total)")
}
