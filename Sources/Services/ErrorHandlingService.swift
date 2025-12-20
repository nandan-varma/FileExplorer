import Foundation

class ErrorHandlingService: ObservableObject {
    @Published var errorMessage: String? = nil
    @Published var showErrorAlert: Bool = false

    func showError(_ message: String) {
        errorMessage = message
        showErrorAlert = true
    }

    func clearError() {
        errorMessage = nil
        showErrorAlert = false
    }

    func handleFileSystemError(_ error: Error, operation: String) {
        var errorMsg = "Unable to \(operation)."

        if let nsError = error as? NSError {
            switch nsError.domain {
            case NSCocoaErrorDomain:
                switch nsError.code {
                case NSFileReadNoPermissionError:
                    errorMsg = "Permission denied. Please grant full disk access in System Settings > Privacy & Security."
                case NSFileReadNoSuchFileError:
                    errorMsg = "The folder no longer exists."
                case NSFileReadInvalidFileNameError:
                    errorMsg = "Invalid folder path."
                default:
                    errorMsg = "File system error during \(operation): \(error.localizedDescription)"
                }
            default:
                errorMsg = "Error during \(operation): \(error.localizedDescription)"
            }
        }

        showError(errorMsg)
    }
}