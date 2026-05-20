import SwiftUI
import SwiftData

@Observable
final class SettingsViewModel {
    var selectedModel: String {
        didSet { UserDefaults.standard.set(selectedModel, forKey: "selectedModel") }
    }

    var vadAutoStop: Bool {
        didSet { UserDefaults.standard.set(vadAutoStop, forKey: "vadAutoStop") }
    }

    var iCloudSyncEnabled: Bool {
        didSet { UserDefaults.standard.set(iCloudSyncEnabled, forKey: "iCloudSyncEnabled") }
    }

    var recordingsStorage: String = "Calculating..."
    var modelsStorage: String = "Calculating..."

    private let modelManager = ModelManager()

    init() {
        self.selectedModel = UserDefaults.standard.string(forKey: "selectedModel") ?? "openai_whisper-large-v3-turbo"
        self.vadAutoStop = UserDefaults.standard.bool(forKey: "vadAutoStop")
        self.iCloudSyncEnabled = UserDefaults.standard.bool(forKey: "iCloudSyncEnabled")
        updateStorageInfo()
    }

    func updateStorageInfo() {
        recordingsStorage = modelManager.formatStorage(modelManager.recordingsStorageSize())
        modelsStorage = modelManager.formatStorage(modelManager.totalStorageUsed())
    }

    var availableModels: [String] {
        TranscriptionEngine.shared.getAvailableModels()
    }

    func modelDisplayName(_ model: String) -> String {
        model.replacingOccurrences(of: "openai_whisper-", with: "")
    }

    func modelSize(_ model: String) -> String {
        TranscriptionEngine.shared.modelSize(for: model)
    }

    func isModelDownloaded(_ model: String) -> Bool {
        modelManager.isModelDownloaded(model)
    }

    func deleteModel(_ model: String) {
        try? modelManager.deleteModel(model)
        updateStorageInfo()
    }
}
