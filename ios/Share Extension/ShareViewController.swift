import AVFoundation
import MobileCoreServices
import Photos
import Social
import UIKit
import UniformTypeIdentifiers

private let schemePrefix = "ShareMedia"
private let userDefaultsKey = "ShareKey"
private let userDefaultsMessageKey = "ShareMessageKey"
private let appGroupIdKey = "AppGroupId"

final class ShareViewController: SLComposeServiceViewController {
  private var hostAppBundleIdentifier = ""
  private var appGroupId = ""
  private var sharedMedia: [SharedMediaFile] = []

  override func isContentValid() -> Bool {
    true
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    loadIds()
  }

  override func didSelectPost() {
    saveAndRedirect(message: contentText)
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    loadSharedItems()
  }

  override func presentationAnimationDidFinish() {
    super.presentationAnimationDidFinish()
    navigationController?.navigationBar.topItem?.rightBarButtonItem?.title = "Save"
  }

  override func configurationItems() -> [Any]! {
    []
  }

  private func loadIds() {
    let shareExtensionBundleIdentifier = Bundle.main.bundleIdentifier ?? ""
    if let lastDot = shareExtensionBundleIdentifier.lastIndex(of: ".") {
      hostAppBundleIdentifier = String(shareExtensionBundleIdentifier[..<lastDot])
    }
    let defaultAppGroupId = "group.\(hostAppBundleIdentifier)"
    let customAppGroupId = Bundle.main.object(forInfoDictionaryKey: appGroupIdKey) as? String
    appGroupId = customAppGroupId ?? defaultAppGroupId
  }

  private func loadSharedItems() {
    guard
      let extensionContext,
      let content = extensionContext.inputItems.first as? NSExtensionItem,
      let attachments = content.attachments
    else {
      saveAndRedirect()
      return
    }

    if attachments.isEmpty {
      saveAndRedirect(message: contentText)
      return
    }

    for (index, attachment) in attachments.enumerated() {
      for type in SharedMediaType.allCases {
        if attachment.hasItemConformingToTypeIdentifier(type.toUTTypeIdentifier) {
          attachment.loadItem(forTypeIdentifier: type.toUTTypeIdentifier) { [weak self] data, error in
            guard let self, error == nil else {
              self?.dismissWithError()
              return
            }

            switch type {
            case .text:
              if let text = data as? String {
                self.handleLiteral(text, type: type, index: index, content: content)
              }
            case .url:
              if let url = data as? URL {
                self.handleLiteral(url.absoluteString, type: type, index: index, content: content)
              } else if let text = data as? String {
                self.handleLiteral(text, type: type, index: index, content: content)
              }
            case .image, .video, .file:
              if let url = data as? URL {
                self.handleFile(url, type: type, index: index, content: content)
              } else if let image = data as? UIImage {
                self.handleImage(image, type: type, index: index, content: content)
              }
            }
          }
          break
        }
      }
    }
  }

  private func handleLiteral(
    _ item: String,
    type: SharedMediaType,
    index: Int,
    content: NSExtensionItem
  ) {
    sharedMedia.append(
      SharedMediaFile(path: item, mimeType: type == .text ? "text/plain" : nil, type: type)
    )
    finishIfNeeded(index: index, content: content)
  }

  private func handleImage(
    _ image: UIImage,
    type: SharedMediaType,
    index: Int,
    content: NSExtensionItem
  ) {
    guard let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) else {
      finishIfNeeded(index: index, content: content)
      return
    }
    let tempPath = container.appendingPathComponent("TempImage-\(UUID().uuidString).png")
    if writeTempImage(image, to: tempPath) {
      sharedMedia.append(
        SharedMediaFile(
          path: tempPath.absoluteString.removingPercentEncoding ?? tempPath.absoluteString,
          mimeType: "image/png",
          type: type
        )
      )
    }
    finishIfNeeded(index: index, content: content)
  }

  private func handleFile(
    _ url: URL,
    type: SharedMediaType,
    index: Int,
    content: NSExtensionItem
  ) {
    guard let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) else {
      finishIfNeeded(index: index, content: content)
      return
    }
    let newPath = container.appendingPathComponent(fileName(from: url, type: type))
    if copyFile(at: url, to: newPath) {
      let decodedPath = newPath.absoluteString.removingPercentEncoding ?? newPath.absoluteString
      if type == .video, let videoInfo = videoInfo(from: newPath) {
        sharedMedia.append(
          SharedMediaFile(
            path: decodedPath,
            mimeType: url.mimeType(),
            thumbnail: videoInfo.thumbnail?.removingPercentEncoding,
            duration: videoInfo.duration,
            type: type
          )
        )
      } else {
        sharedMedia.append(SharedMediaFile(path: decodedPath, mimeType: url.mimeType(), type: type))
      }
    }
    finishIfNeeded(index: index, content: content)
  }

  private func finishIfNeeded(index: Int, content: NSExtensionItem) {
    if index == (content.attachments?.count ?? 0) - 1 {
      saveAndRedirect(message: contentText)
    }
  }

  private func saveAndRedirect(message: String? = nil) {
    let defaults = UserDefaults(suiteName: appGroupId)
    defaults?.set(encoded(sharedMedia), forKey: userDefaultsKey)
    defaults?.set(message, forKey: userDefaultsMessageKey)
    defaults?.synchronize()
    redirectToHostApp()
  }

  private func redirectToHostApp() {
    loadIds()
    guard let url = URL(string: "\(schemePrefix)-\(hostAppBundleIdentifier):share") else {
      extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
      return
    }

    var responder = self as UIResponder?
    if #available(iOS 18.0, *) {
      while responder != nil {
        if let application = responder as? UIApplication {
          application.open(url, options: [:], completionHandler: nil)
        }
        responder = responder?.next
      }
    } else {
      let selector = sel_registerName("openURL:")
      while responder != nil {
        if responder?.responds(to: selector) == true {
          _ = responder?.perform(selector, with: url)
          break
        }
        responder = responder?.next
      }
    }
    extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
  }

  private func dismissWithError() {
    extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
  }

  private func fileName(from url: URL, type: SharedMediaType) -> String {
    if !url.lastPathComponent.isEmpty {
      return url.lastPathComponent
    }
    switch type {
    case .image:
      return "\(UUID().uuidString).png"
    case .video:
      return "\(UUID().uuidString).mp4"
    case .text:
      return "\(UUID().uuidString).txt"
    case .file, .url:
      return UUID().uuidString
    }
  }

  private func writeTempImage(_ image: UIImage, to destination: URL) -> Bool {
    do {
      if FileManager.default.fileExists(atPath: destination.path) {
        try FileManager.default.removeItem(at: destination)
      }
      try image.pngData()?.write(to: destination)
      return true
    } catch {
      return false
    }
  }

  private func copyFile(at source: URL, to destination: URL) -> Bool {
    do {
      if FileManager.default.fileExists(atPath: destination.path) {
        try FileManager.default.removeItem(at: destination)
      }
      try FileManager.default.copyItem(at: source, to: destination)
      return true
    } catch {
      return false
    }
  }

  private func videoInfo(from url: URL) -> (thumbnail: String?, duration: Double)? {
    let asset = AVAsset(url: url)
    let duration = (CMTimeGetSeconds(asset.duration) * 1000).rounded()
    let thumbnailPath = thumbnailPath(for: url)

    if FileManager.default.fileExists(atPath: thumbnailPath.path) {
      return (thumbnail: thumbnailPath.absoluteString, duration: duration)
    }

    let generator = AVAssetImageGenerator(asset: asset)
    generator.appliesPreferredTrackTransform = true
    generator.maximumSize = CGSize(width: 360, height: 360)

    do {
      let image = try generator.copyCGImage(at: CMTimeMakeWithSeconds(1, preferredTimescale: 1), actualTime: nil)
      try UIImage(cgImage: image).pngData()?.write(to: thumbnailPath)
      return (thumbnail: thumbnailPath.absoluteString, duration: duration)
    } catch {
      return nil
    }
  }

  private func thumbnailPath(for url: URL) -> URL {
    let name = Data(url.lastPathComponent.utf8)
      .base64EncodedString()
      .replacingOccurrences(of: "==", with: "")
    return FileManager.default
      .containerURL(forSecurityApplicationGroupIdentifier: appGroupId)!
      .appendingPathComponent("\(name).jpg")
  }

  private func encoded(_ data: [SharedMediaFile]) -> Data {
    (try? JSONEncoder().encode(data)) ?? Data()
  }
}

private struct SharedMediaFile: Codable {
  let path: String
  let mimeType: String?
  let thumbnail: String?
  let duration: Double?
  let message: String?
  let type: SharedMediaType

  init(
    path: String,
    mimeType: String? = nil,
    thumbnail: String? = nil,
    duration: Double? = nil,
    message: String? = nil,
    type: SharedMediaType
  ) {
    self.path = path
    self.mimeType = mimeType
    self.thumbnail = thumbnail
    self.duration = duration
    self.message = message
    self.type = type
  }
}

private enum SharedMediaType: String, Codable, CaseIterable {
  case image
  case video
  case text
  case file
  case url

  var toUTTypeIdentifier: String {
    if #available(iOS 14.0, *) {
      switch self {
      case .image:
        return UTType.image.identifier
      case .video:
        return UTType.movie.identifier
      case .text:
        return UTType.text.identifier
      case .file:
        return UTType.fileURL.identifier
      case .url:
        return UTType.url.identifier
      }
    }
    switch self {
    case .image:
      return "public.image"
    case .video:
      return "public.movie"
    case .text:
      return "public.text"
    case .file:
      return "public.file-url"
    case .url:
      return "public.url"
    }
  }
}

private extension URL {
  func mimeType() -> String {
    if #available(iOS 14.0, *) {
      if let mimeType = UTType(filenameExtension: pathExtension)?.preferredMIMEType {
        return mimeType
      }
    } else if let uti = UTTypeCreatePreferredIdentifierForTag(
      kUTTagClassFilenameExtension,
      pathExtension as NSString,
      nil
    )?.takeRetainedValue(),
      let mimeType = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue()
    {
      return mimeType as String
    }
    return "application/octet-stream"
  }
}
