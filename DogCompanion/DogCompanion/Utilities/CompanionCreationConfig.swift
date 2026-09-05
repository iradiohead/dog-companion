import Foundation

enum CreationMode {
    case resourceCatalog
    case photo

    static var current: CreationMode {
        CompanionCreationConfig.useResourceCatalog ? .resourceCatalog : .photo
    }
}

enum CompanionCreationConfig {
    static let useResourceCatalog = true
}
