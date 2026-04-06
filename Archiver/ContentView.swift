import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {

  // array of dragged files / folders
  @State private var droppedItems: [URL] = []

  @State private var isTargeted: Bool = false
  
  var body: some View {
    VStack(spacing: 20) {
      Text("Archiver")
        .font(.largeTitle)
        .fontWeight(.bold)
      
      // --- AREA DRAG & DROP ---
      ZStack {
        RoundedRectangle(cornerRadius: 15)
          .fill(
            isTargeted ? Color.accentColor.opacity(0.2) : Color(nsColor: .controlBackgroundColor)
          )
          .overlay(
            RoundedRectangle(cornerRadius: 15)
              .stroke(style: StrokeStyle(lineWidth: 2, dash: [10]))
              .foregroundColor(isTargeted ? .accentColor : .gray.opacity(0.5))
          )
        
        if droppedItems.isEmpty {
          VStack(spacing: 10) {
            Image(systemName: "arrow.down.doc.fill")
              .font(.system(size: 50))
              .foregroundColor(.secondary)
            Text("Drag files or folders here")
              .foregroundColor(.secondary)
          }
        } else {
          ScrollView {
            VStack(alignment: .leading, spacing: 8) {
              ForEach(droppedItems, id: \.self) { item in
                HStack {
                  Image(systemName: iconForItem(item))
                    .foregroundColor(.blue)
                  Text(item.lastPathComponent)
                    .lineLimit(1)
                    .truncationMode(.middle)
                  Spacer()
                }
                .padding(.horizontal)
              }
            }
            .padding(.vertical)
          }
        }
      }
      .frame(minWidth: 400, minHeight: 250)
      .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
        handleDrop(providers: providers)
      }
      
      Button("Сжать всё в ZIP") {
        processDroppedItems()
      }
      .buttonStyle(.borderedProminent)
      .disabled(droppedItems.isEmpty)
    }
    .padding(30)
    .frame(minWidth: 500, minHeight: 400)
  }
  
  // MARK: - Обработка перетаскивания
  
  private func handleDrop(providers: [NSItemProvider]) -> Bool {
    var foundItems: [URL] = []
    
    // group for waiting as async
    let group = DispatchGroup()
    
    for provider in providers {
      group.enter()
      provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { data, error in
        if let data = data as? Data,
           let path = NSString(data: data, encoding: String.Encoding.utf8.rawValue) as String?,
           let url = URL(string: path) {
          foundItems.append(url)
        }
        group.leave()
      }
    }
    
    group.notify(queue: .main) {
      if !foundItems.isEmpty {
        self.droppedItems = foundItems
        print("✅ Dropped elements: \(foundItems.count)")
      }
    }
    
    return true
  }
  
  // MARK: - Вспомогательные методы
  
  // file or folder
  private func iconForItem(_ url: URL) -> String {
    var isDir: ObjCBool = false
    if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) {
      return isDir.boolValue ? "folder.fill" : "doc.fill"
    }
    return "questionmark.diamond"
  }
  
  private func processDroppedItems() {
    print("🚀 Zipping files:")
    for item in droppedItems {
      if let accessibleURL = resolveBookmark(for: item) {
        print(" - \(accessibleURL.lastPathComponent) (Got access)")
      } else {
        print(" - Failed to get access for \(item.lastPathComponent)")
      }
    }
  }
  // check
  private func resolveBookmark(for url: URL) -> URL? {
    return url.startAccessingSecurityScopedResource() ? url : url
  }
}
