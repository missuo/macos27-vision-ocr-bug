# macOS 27 Vision OCR bug: mixed Chinese + English text

On macOS 27 (still present in 27.2 Beta 1), `VNRecognizeTextRequest` fails on lines that mix Chinese and Latin text:

- With `automaticallyDetectsLanguage = true`, the Chinese part comes back as garbage (`你好，世界` → `1527, ШF`) or is dropped.
- With `recognitionLanguages = ["en-US", "zh-Hans"]`, only the first language seems to be used. Chinese is garbled, and even `macOS 系统更新` returns nothing.
- Only `["zh-Hans", "en-US"]` works.

This breaks apps that use the system OCR engine, such as Bob. Workaround: pick Simplified Chinese as the OCR language instead of auto-detect.

## Reproduce

```sh
xcrun swiftc -O repro.swift -o repro && ./repro
```

The program renders the samples into `images/` and prints the table below. Use `xcrun swiftc` so the compiler matches the Xcode SDK.

## Results

| Input | Size | automaticallyDetectsLanguage | [en-US, zh-Hans] | [zh-Hans, en-US] |
|---|---|---|---|---|
| Hello World 你好，世界 | 28pt | `Hello World 1527, ШF` | `Hello World 1527, ШF` | `Hello World 你好，世界` |
| Hello World 你好，世界 | 48pt | `Hello World 1527, 5` | `Hello World 1527, 5` | `Hello World 你好，世界` |
| The quick brown fox 敏捷的棕色狐狸 | 28pt | `The quick brown fox EFE` | `The quick brown fox EFE` | `The quick brown fox 敏捷的棕色狐狸` |
| The quick brown fox 敏捷的棕色狐狸 | 48pt | `The quick brown fox FE` | `The quick brown fox FE` | `The quick brown fox 敏捷的棕色狐狸` |
| iPhone 17 发布会 | 28pt | `¡Phone 17` | `¡Phone 17` | `iPhone 17 发布会` |
| iPhone 17 发布会 | 48pt | *(empty)* | *(empty)* | `iPhone 17 发布会` |
| macOS 系统更新 | 28pt | `macOS 系统更新` | *(empty)* | `macOS 系统更新` |
| macOS 系统更新 | 48pt | `macoS 系统更新` | *(empty)* | `macoS 系统更新` |
| 你好 Hello World | 28pt | `1547 Hello World` | `1547 Hello World` | `你好 Hello World` |
| 你好 Hello World | 48pt | `15$7 Hello World` | `15$7 Hello World` | `你好 Hello World` |
| Open Settings 打开设置 | 28pt | `Open Settings FAiE` | `Open Settings FAiE` | `Open Settings 打开设置` |
| Open Settings 打开设置 | 48pt | `Open Settings $JHiE` | `Open Settings $JHiE` | `Open Settings 打开设置` |
