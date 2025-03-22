import SwiftUI // Required for EnvironmentKey and EnvironmentValues

/// Environment values provide a dependency injection system for SwiftUI views
/// Key reasons we need them:
/// 1. Avoid prop drilling - prevents passing common state through multiple view layers
/// 2. Centralized state management - single source of truth for global UI state
/// 3. Cross-component communication - lets unrelated components react to shared state
/// 4. Previews/testing - easily mock environment states for different scenarios
/// 5. Performance - more efficient than ObservableObject for simple flags

// Add a global override that can bypass the environment system
// This is a last resort for fixing persistent gesture issues
class DragStateOverride {
    static let shared = DragStateOverride()
    private init() {}
    
    // When true, this forces isDraggingBlock to be false regardless of environment
    var forceDisableDragState = false
}

/// Specifically for drag state:
/// - Tracks when any block is being dragged globally
/// - Allows cat face components to pause eye tracking during drags
/// - Coordinates between grid interactions and character animations
/// - Prevents gesture conflicts between UI layers
struct DraggingBlockKey: EnvironmentKey {
    static let defaultValue = false // Default state when no value set
}

extension EnvironmentValues {
    /// Current dragging state accessible anywhere in the view hierarchy
    /// Usage: @Environment(\.isDraggingBlock) var isDragging
    var isDraggingBlock: Bool {
        get { 
            // If override is active, always return false
            if DragStateOverride.shared.forceDisableDragState {
                return false
            }
            return self[DraggingBlockKey.self] 
        }
        set { self[DraggingBlockKey.self] = newValue }
    }
}

/// Example component usage:
/// struct NotionFace: View {
///     @Environment(\.isDraggingBlock) private var isDraggingBlock
///     var body: some View {
///         CatFeatures()
///             .disabled(isDraggingBlock) // Disable interactions during drag
///     }
/// } 