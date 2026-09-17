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

The program prints the environment (macOS build, chip, TextRecognition.framework version, system languages), renders the samples into `images/`, and prints every result for each configuration plus a summary. Please include the full output when reporting results from another machine. Use `xcrun swiftc` so the compiler matches the Xcode SDK.

## Results on this machine

### Environment

- macOS: Version 27.2 (Build 26B5086k)
- Chip: Apple M1 Pro
- Model: MacBookPro18,3
- TextRecognition.framework: 157 (source 446013101000000)
- AppleLanguages: ["en-US", "zh-Hans-US"]
- AppleLocale: en_US
- VNRecognizeTextRequest revision: 3, supported: [1, 2, 3]
- Default recognitionLanguages: ["en_US"]
- Supported languages (accurate): ["en-US", "fr-FR", "it-IT", "de-DE", "es-ES", "pt-BR", "zh-Hans", "zh-Hant", "yue-Hans", "yue-Hant", "ko-KR", "ja-JP", "ru-RU", "uk-UA", "th-TH", "vi-VT", "ar-SA", "ars-SA", "tr-TR", "id-ID", "cs-CZ", "da-DK", "nl-NL", "no-NO", "nn-NO", "nb-NO", "ms-MY", "pl-PL", "ro-RO", "sv-SE", "fi-FI", "hi-IN", "mr-IN"]

### Results

#### Hello World 你好，世界 (28pt)

- ❌ auto-detect [0.24s]: Hello World 1527, ШF
- ❌ default (no languages set) [0.08s]: Hello World 1527, ШF
- ❌ [en-US, zh-Hans] [0.08s]: Hello World 1527, ШF
- ✅ [zh-Hans, en-US] [0.24s]: Hello World 你好，世界
- ✅ [zh-Hans] [0.14s]: Hello World 你好，世界
- ✅ auto-detect + [zh-Hans, en-US] [0.14s]: Hello World 你好，世界
- ❌ auto-detect, CPU only [0.08s]: Hello World 1527, ШF
- ❌ auto-detect, GPU only [0.10s]: Hello World 1527, ШF
- ❌ auto-detect, Neural Engine only [0.07s]: Hello World 1527, ШF
- ❌ [en-US, zh-Hans], fast [0.03s]: Hello World IiJil},

#### Hello World 你好，世界 (48pt)

- ❌ auto-detect [0.10s]: Hello World 1527, 5
- ❌ default (no languages set) [0.09s]: Hello World 1527, 5
- ❌ [en-US, zh-Hans] [0.09s]: Hello World 1527, 5
- ✅ [zh-Hans, en-US] [0.15s]: Hello World 你好，世界
- ✅ [zh-Hans] [0.10s]: Hello World 你好，世界
- ✅ auto-detect + [zh-Hans, en-US] [0.11s]: Hello World 你好，世界
- ❌ auto-detect, CPU only [0.11s]: Hello World 1527, 5
- ❌ auto-detect, GPU only [0.09s]: Hello World 1527, 5
- ❌ auto-detect, Neural Engine only [0.09s]: Hello World 1527, 5
- ❌ [en-US, zh-Hans], fast [0.02s]: Hello World IiJil},

#### The quick brown fox 敏捷的棕色狐狸 (28pt)

- ❌ auto-detect [0.11s]: The quick brown fox EFE
- ❌ default (no languages set) [0.09s]: The quick brown fox EFE
- ❌ [en-US, zh-Hans] [0.09s]: The quick brown fox EFE
- ✅ [zh-Hans, en-US] [0.16s]: The quick brown fox 敏捷的棕色狐狸
- ✅ [zh-Hans] [0.12s]: The quick brown fox 敏捷的棕色狐狸
- ✅ auto-detect + [zh-Hans, en-US] [0.12s]: The quick brown fox 敏捷的棕色狐狸
- ❌ auto-detect, CPU only [0.09s]: The quick brown fox EFE
- ❌ auto-detect, GPU only [0.09s]: The quick brown fox EFE
- ❌ auto-detect, Neural Engine only [0.09s]: The quick brown fox EFE
- ❌ [en-US, zh-Hans], fast [0.02s]: The quick brown fox *lllt*,ÈaJLt

#### The quick brown fox 敏捷的棕色狐狸 (48pt)

- ❌ auto-detect [0.08s]: The quick brown fox FE
- ❌ default (no languages set) [0.09s]: The quick brown fox FE
- ❌ [en-US, zh-Hans] [0.09s]: The quick brown fox FE
- ✅ [zh-Hans, en-US] [0.16s]: The quick brown fox 敏捷的棕色狐狸
- ✅ [zh-Hans] [0.12s]: The quick brown fox 敏捷的棕色狐狸
- ✅ auto-detect + [zh-Hans, en-US] [0.12s]: The quick brown fox 敏捷的棕色狐狸
- ❌ auto-detect, CPU only [0.08s]: The quick brown fox FE
- ❌ auto-detect, GPU only [0.08s]: The quick brown fox FE
- ❌ auto-detect, Neural Engine only [0.09s]: The quick brown fox FE
- ❌ [en-US, zh-Hans], fast [0.01s]: The quick brown fox *l%Att,",ÈILtI

#### iPhone 17 发布会 (28pt)

- ❌ auto-detect [0.09s]: ¡Phone 17
- ❌ default (no languages set) [0.07s]: ¡Phone 17
- ❌ [en-US, zh-Hans] [0.07s]: ¡Phone 17
- ✅ [zh-Hans, en-US] [0.13s]: iPhone 17 发布会
- ✅ [zh-Hans] [0.08s]: iPhone 17 发布会
- ✅ auto-detect + [zh-Hans, en-US] [0.08s]: iPhone 17 发布会
- ❌ auto-detect, CPU only [0.08s]: ¡Phone 17
- ❌ auto-detect, GPU only [0.08s]: ¡Phone 17
- ❌ auto-detect, Neural Engine only [0.08s]: ¡Phone 17
- ❌ [en-US, zh-Hans], fast [0.01s]: iPhone 17

#### iPhone 17 发布会 (48pt)

- ❌ auto-detect [0.07s]: (empty)
- ❌ default (no languages set) [0.07s]: (empty)
- ❌ [en-US, zh-Hans] [0.07s]: (empty)
- ✅ [zh-Hans, en-US] [0.13s]: iPhone 17 发布会
- ✅ [zh-Hans] [0.09s]: iPhone 17 发布会
- ✅ auto-detect + [zh-Hans, en-US] [0.09s]: iPhone 17 发布会
- ❌ auto-detect, CPU only [0.07s]: (empty)
- ❌ auto-detect, GPU only [0.08s]: (empty)
- ❌ auto-detect, Neural Engine only [0.08s]: (empty)
- ❌ [en-US, zh-Hans], fast [0.01s]: iPhone 17

#### macOS 系统更新 (28pt)

- ✅ auto-detect [0.13s]: macOS 系统更新
- ❌ default (no languages set) [0.06s]: (empty)
- ❌ [en-US, zh-Hans] [0.06s]: (empty)
- ✅ [zh-Hans, en-US] [0.07s]: macOS 系统更新
- ✅ [zh-Hans] [0.08s]: macOS 系统更新
- ✅ auto-detect + [zh-Hans, en-US] [0.08s]: macOS 系统更新
- ✅ auto-detect, CPU only [0.13s]: macOS 系统更新
- ✅ auto-detect, GPU only [0.12s]: macOS 系统更新
- ✅ auto-detect, Neural Engine only [0.09s]: macOS 系统更新
- ❌ [en-US, zh-Hans], fast [0.01s]: macos ¥1*4

#### macOS 系统更新 (48pt)

- ❌ auto-detect [0.09s]: macoS 系统更新
- ❌ default (no languages set) [0.08s]: (empty)
- ❌ [en-US, zh-Hans] [0.07s]: (empty)
- ❌ [zh-Hans, en-US] [0.08s]: macoS 系统更新
- ❌ [zh-Hans] [0.08s]: macoS 系统更新
- ❌ auto-detect + [zh-Hans, en-US] [0.09s]: macoS 系统更新
- ❌ auto-detect, CPU only [0.09s]: macoS 系统更新
- ❌ auto-detect, GPU only [0.09s]: macoS 系统更新
- ❌ auto-detect, Neural Engine only [0.07s]: macoS 系统更新
- ❌ [en-US, zh-Hans], fast [0.01s]: macos .*.**,￿*

#### 你好 Hello World (28pt)

- ❌ auto-detect [0.05s]: 1547 Hello World
- ❌ default (no languages set) [0.03s]: 1547 Hello World
- ❌ [en-US, zh-Hans] [0.04s]: 1547 Hello World
- ✅ [zh-Hans, en-US] [0.06s]: 你好 Hello World
- ✅ [zh-Hans] [0.05s]: 你好 Hello World
- ❌ auto-detect + [zh-Hans, en-US] [0.05s]: 1547 Hello World
- ❌ auto-detect, CPU only [0.04s]: 1547 Hello World
- ❌ auto-detect, GPU only [0.04s]: 1547 Hello World
- ❌ auto-detect, Neural Engine only [0.04s]: 1547 Hello World
- ❌ [en-US, zh-Hans], fast [0.01s]: IiJ,11 Hello World

#### 你好 Hello World (48pt)

- ❌ auto-detect [0.08s]: 15$7 Hello World
- ❌ default (no languages set) [0.07s]: 15$7 Hello World
- ❌ [en-US, zh-Hans] [0.08s]: 15$7 Hello World
- ✅ [zh-Hans, en-US] [0.13s]: 你好 Hello World
- ✅ [zh-Hans] [0.09s]: 你好 Hello World
- ✅ auto-detect + [zh-Hans, en-US] [0.09s]: 你好 Hello World
- ❌ auto-detect, CPU only [0.07s]: 15$7 Hello World
- ❌ auto-detect, GPU only [0.08s]: 15$7 Hello World
- ❌ auto-detect, Neural Engine only [0.08s]: 15$7 Hello World
- ❌ [en-US, zh-Hans], fast [0.01s]: IiJ,11 Hello World

#### Open Settings 打开设置 (28pt)

- ❌ auto-detect [0.09s]: Open Settings FAiE
- ❌ default (no languages set) [0.08s]: Open Settings FAiE
- ❌ [en-US, zh-Hans] [0.07s]: Open Settings FAiE
- ✅ [zh-Hans, en-US] [0.14s]: Open Settings 打开设置
- ✅ [zh-Hans] [0.10s]: Open Settings 打开设置
- ✅ auto-detect + [zh-Hans, en-US] [0.09s]: Open Settings 打开设置
- ❌ auto-detect, CPU only [0.07s]: Open Settings FAiE
- ❌ auto-detect, GPU only [0.08s]: Open Settings FAiE
- ❌ auto-detect, Neural Engine only [0.08s]: Open Settings FAiE
- ❌ [en-US, zh-Hans], fast [0.01s]: Open Settings *JFFi

#### Open Settings 打开设置 (48pt)

- ❌ auto-detect [0.09s]: Open Settings $JHiE
- ❌ default (no languages set) [0.09s]: Open Settings $JHiE
- ❌ [en-US, zh-Hans] [0.09s]: Open Settings $JHiE
- ✅ [zh-Hans, en-US] [0.15s]: Open Settings 打开设置
- ✅ [zh-Hans] [0.10s]: Open Settings 打开设置
- ✅ auto-detect + [zh-Hans, en-US] [0.11s]: Open Settings 打开设置
- ❌ auto-detect, CPU only [0.10s]: Open Settings $JHiE
- ❌ auto-detect, GPU only [0.10s]: Open Settings $JHiE
- ❌ auto-detect, Neural Engine only [0.09s]: Open Settings $JHiE
- ❌ [en-US, zh-Hans], fast [0.01s]: Open Settings *JfFi

#### 今天天气很好，我们一起去公园散步吧。 (28pt)

- ✅ auto-detect [0.12s]: 今天天气很好，我们一起去公园散步吧。
- ❌ default (no languages set) [0.11s]: (empty)
- ❌ [en-US, zh-Hans] [0.09s]: (empty)
- ✅ [zh-Hans, en-US] [0.11s]: 今天天气很好，我们一起去公园散步吧。
- ✅ [zh-Hans] [0.11s]: 今天天气很好，我们一起去公园散步吧。
- ✅ auto-detect + [zh-Hans, en-US] [0.12s]: 今天天气很好，我们一起去公园散步吧。
- ✅ auto-detect, CPU only [0.11s]: 今天天气很好，我们一起去公园散步吧。
- ✅ auto-detect, GPU only [0.11s]: 今天天气很好，我们一起去公园散步吧。
- ✅ auto-detect, Neural Engine only [0.10s]: 今天天气很好，我们一起去公园散步吧。
- ❌ [en-US, zh-Hans], fast [0.01s]: (empty)

#### 今天天气很好，我们一起去公园散步吧。 (48pt)

- ✅ auto-detect [0.10s]: 今天天气很好，我们一起去公园散步吧。
- ❌ default (no languages set) [0.09s]: (empty)
- ❌ [en-US, zh-Hans] [0.09s]: (empty)
- ✅ [zh-Hans, en-US] [0.12s]: 今天天气很好，我们一起去公园散步吧。
- ✅ [zh-Hans] [0.12s]: 今天天气很好，我们一起去公园散步吧。
- ✅ auto-detect + [zh-Hans, en-US] [0.12s]: 今天天气很好，我们一起去公园散步吧。
- ✅ auto-detect, CPU only [0.12s]: 今天天气很好，我们一起去公园散步吧。
- ✅ auto-detect, GPU only [0.12s]: 今天天气很好，我们一起去公园散步吧。
- ✅ auto-detect, Neural Engine only [0.12s]: 今天天气很好，我们一起去公园散步吧。
- ❌ [en-US, zh-Hans], fast [0.01s]: (empty)

### Summary (exact match, ignoring spaces)

- auto-detect: 3/14
- default (no languages set): 0/14
- [en-US, zh-Hans]: 0/14
- [zh-Hans, en-US]: 13/14
- [zh-Hans]: 13/14
- auto-detect + [zh-Hans, en-US]: 12/14
- auto-detect, CPU only: 3/14
- auto-detect, GPU only: 3/14
- auto-detect, Neural Engine only: 3/14
- [en-US, zh-Hans], fast: 0/14
