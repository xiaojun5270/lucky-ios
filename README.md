# LuckyGlass for iOS

Lucky 管理控制台的原生 SwiftUI 客户端，面向 iOS 26。

## 本地构建

需要 Xcode 26。打开 `LuckyGlass.xcodeproj`，选择 `LuckyGlass` Scheme 和模拟器后运行。

真机调试需要在 Xcode 的 Signing & Capabilities 中选择自己的开发团队。

## 无证书 IPA

推送到 `main` 分支或在 GitHub Actions 中手动运行 **Build Unsigned iOS IPA**。构建完成后，在该次运行的 Artifacts 中下载 `lucky-ios-unsigned-ipa`。

无证书 IPA 不能直接通过 App Store 安装，需要使用支持自签名的安装工具重新签名。
