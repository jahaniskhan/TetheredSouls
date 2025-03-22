import SwiftUI
import Foundation
import Combine
import CoreGraphics
import CoreFoundation

// Add a global feature flag enum to control which gesture system is active
enum GestureMode {
    case blockDragging // For grid and block interactions
    case catInteraction // For cat eye and heart gestures
    
    static var current: GestureMode = .blockDragging
}

protocol DragStateResettable {
    func resetDragStates()
}

struct ContentView: View {
    private let columns: Int = 10
    private let rows: Int = 10
    
    @State private var grid: [[Bool]] = Array(repeating: Array(repeating: false, count: 10), count: 10)
    @State private var score: Int = 0
    @State private var currentStreak: Int = 0
    @State private var isLoading = true
    @State private var selectedBlock: Block?
    @State private var isDragging = false
    @State private var blockPosition: CGPoint?
    @State private var eyePosition: CGPoint = .zero
    @State private var showedFirstCat = false
    @State private var lastDragActivityTime: Date?
    @State private var dragResetTimer: Timer?
    
    @State private var availableBlocks: [Block] = []
    
    @StateObject private var streakManager = StreakManager()
    
    @State private var gridGeometry = GridGeometry(frame: .zero, cellSize: 30)
    
    @State private var hasTriedOverride = false
    
    // Add new state to track the active gesture mode
    @State private var gestureMode: GestureMode = .blockDragging
    
    private var backgroundDoodles: some View {
        GeometryReader { geometry in
            ZStack {
                // Extract each layer into separate views
                BaseDoodleLayer(geometry: geometry, currentStreak: currentStreak)
                MiddleDoodleLayer(geometry: geometry, currentStreak: currentStreak)
                BottomDoodleLayer(geometry: geometry, currentStreak: currentStreak)
            }
        }
    }
    
    var decorativeElements: some View {
        ZStack {
            // Static elements only
            ForEach(0..<12) { i in
                let items = ["✧", "⋆", "❀", "♠", "♣", "♥", "♦", "★", "☆"]
                Text(items[i % items.count])
                    .font(.system(size: CGFloat.random(in: 14...24)))
                    .foregroundColor(Color(hue: Double.random(in: 0...1),
                                           saturation: 0.7,
                                           brightness: 0.8)
                                    .opacity(0.4))
                    .rotationEffect(.degrees(Double.random(in: 0...360)))
                    .position(
                        x: CGFloat.random(in: 50...UIScreen.main.bounds.width-50),
                        y: CGFloat.random(in: 100...UIScreen.main.bounds.height-100)
                    )
            }
        }
    }
    
    private var blockSize: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        return (screenWidth - (2 * Theme.Layout.padding)) / 4 // Adjust divisor based on your layout needs
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(hex: "FFF9F2")
                    .ignoresSafeArea()
                
                // Add background doodles behind main content
                backgroundDoodles
                
                // Main game content
                ZStack {
                    // Background doodles tied to streak
                    GeometryReader { geometry in
                        if currentStreak > 0 {
                            ForEach(0..<min(currentStreak, 4), id: \.self) { i in
                                let streakDoodleId = "streak-doodle-\(i)-\(currentStreak)"
                                
                                // Mix of different doodle types for streak visualization
                                let type = DoodleType.allCases.randomElement()!
                                
                                DoodleElement(
                                    type: type,
                                    rotation: Double.random(in: type.rotationRange),
                                    streak: min(currentStreak, 4)
                                )
                                .frame(width: CGFloat.random(in: 18...32))
                                .position(
                                    DoodlePositionManager.shared.getPosition(
                                        for: streakDoodleId,
                                        defaultX: CGFloat.random(in: 0...geometry.size.width),
                                        defaultY: CGFloat.random(in: geometry.size.height * 0.15...geometry.size.height * 0.95)
                                    )
                                )
                                .opacity(Double.random(in: 0.5...0.8))
                                // This animation only triggers when currentStreak changes
                                .animation(
                                    .easeInOut(duration: 6.0) // Increased from 3.0 to 6.0 seconds
                                        .delay(Double(i) * 0.2) // Increased delay
                                        .speed(0.1), // Extremely slow speed
                                    value: currentStreak
                                )
                            }
                        }
                    }
                    
                    decorativeElements
                    
                    VStack(spacing: 24) {
                        GamePanel(
                            score: score,
                            selectedBlock: selectedBlock
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 20)
                        
                        GridView(grid: $grid, selectedBlock: $selectedBlock, blockPosition: $blockPosition, isDragging: $isDragging)
                            .padding(.horizontal, 20)
                        
                        BlockSelectionView(
                            availableBlocks: $availableBlocks,
                            selectedBlock: $selectedBlock,
                            blockPosition: $blockPosition,
                            isDragging: $isDragging,
                            gridGeometry: $gridGeometry
                        )
                            .frame(height: 180)
                            .padding(.horizontal, 20)
                    }
                    .padding(.vertical, 16)
                }
                .coordinateSpace(name: "gameArea")
                
                if let block = selectedBlock {
                    DraggableBlock(
                        selectedBlock: $selectedBlock,
                        isDragging: $isDragging,
                        blockPosition: $blockPosition,
                        grid: $grid,
                        projectedCells: Binding<[(row: Int, column: Int)]>(
                            get: { GridProjectionCoordinator.shared.projectedCells },
                            set: { GridProjectionCoordinator.shared.projectedCells = $0 }
                        ),
                        block: block,
                        gridGeometry: gridGeometry
                    )
                    .zIndex(2)
                }
                
                // Add emergency reset tap gesture area that covers part of the screen
                // but doesn't interfere with normal gameplay
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        
                        // Visual indicator of drag state with emergency reset button
                        if isDragging {
                            Text("RESET DRAG")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.red.opacity(0.7))
                                .cornerRadius(8)
                                .onTapGesture {
                                    forceResetAllDragStates()
                                }
                        }
                    }
                    .padding()
                }
                .allowsHitTesting(isDragging) // Only allow interaction when actually stuck in drag mode
                
                if isLoading {
                    LoadingView()
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    isLoading = false
                                }
                            }
                        }
                }
                
                // Inside the ZStack, after GamePanel but before DraggableBlock
                ForEach(BackgroundEffectCoordinator.shared.activeEffects) { effect in
                    Group {
                        switch effect.type {
                        case .symbol(let name):
                            Image(systemName: name)
                                .font(.system(size: 24))
                                .foregroundColor(Theme.textSecondary.opacity(0.3))
                        case .image(let name):
                            Image(name)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40)
                        }
                    }
                    .position(effect.position)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.1)),
                        removal: .opacity.combined(with: .scale(scale: 3.0))
                    ))
                    .animation(.easeOut(duration: 0.8), value: effect.position)
                }
                
                if score >= 100 && !showedFirstCat {
                    CatAchievementCard()
                        .transition(.scale.combined(with: .opacity))
                        .onAppear {
                            withAnimation {
                                showedFirstCat = true
                            }
                        }
                }
            }
            .coordinateSpace(name: "gameArea")
            .environment(\.isDraggingBlock, gestureMode == .blockDragging && isDragging)
            
            // Keep only the essential reset gesture
            .simultaneousGesture(
                TapGesture()
                    .onEnded {
                        if isDragging {
                            forceResetAllDragStates()
                        }
                    }
            )
            
            // Debug indicator showing both state and environment values
            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        if isDragging {
                            Text("DRAG STATE: ON")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(4)
                                .background(Color.red.opacity(0.7))
                                .cornerRadius(4)
                        }
                        
                        // Show when override is active
                        if DragStateOverride.shared.forceDisableDragState {
                            Text("BYPASS ACTIVE")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(4)
                                .background(Color.orange.opacity(0.7))
                                .cornerRadius(4)
                        }
                        
                        // Add mode indicator
                        Text("MODE: \(gestureMode == .blockDragging ? "BLOCKS" : "CAT")")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(4)
                            .background(gestureMode == .blockDragging ? Color.blue.opacity(0.7) : Color.purple.opacity(0.7))
                            .cornerRadius(4)
                    }
                    Spacer()
                    
                    // Add a dedicated mode switch button
                    Button(action: {
                        toggleGestureMode()
                    }) {
                        Image(systemName: gestureMode == .blockDragging ? "square.on.square" : "heart")
                            .font(.system(size: 22))
                            .foregroundColor(gestureMode == .blockDragging ? .blue.opacity(0.8) : .purple.opacity(0.8))
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    
                    // Nuclear option - always visible emergency reset button
                    Button(action: {
                        forceResetAllDragStates()
                    }) {
                        Image(systemName: "arrow.counterclockwise.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(isDragging ? .red.opacity(0.8) : .gray.opacity(0.5))
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .padding(.leading, 8)
                }
                Spacer()
            }
            .padding(8)
            .allowsHitTesting(true)
            
            .onChange(of: blockPosition) { oldValue, newValue in
                if newValue != nil {
                    // Update drag activity timestamp when position changes
                    lastDragActivityTime = Date()
                }
                
                if newValue == nil {
                    withAnimation(.spring()) {
                        eyePosition = CGPoint(x: UIScreen.main.bounds.width/2, y: UIScreen.main.bounds.height/2)
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .init("BlockPlaced"))) { notification in
                if let points = notification.userInfo?["points"] as? Int {
                    score += points
                }
            }
            .onPreferenceChange(GridGeometryKey.self) { geometry in
                #if DEBUG
                print("GridGeometry updated: \(geometry.frame)")
                #endif
                self.gridGeometry = geometry
                
                // Ensure GridProjectionCoordinator knows about grid geometry
                GridProjectionCoordinator.shared.gridFrame = geometry.frame
                GridProjectionCoordinator.shared.cellSize = geometry.cellSize
            }
            .onChange(of: isDragging) { oldValue, newValue in
                if newValue {
                    // Start drag activity monitoring
                    lastDragActivityTime = Date()
                    startDragMonitoring()
                } else {
                    resetDragStates()
                }
            }
            .onDisappear {
                // Clean up timer when view disappears
                dragResetTimer?.invalidate()
                dragResetTimer = nil
            }
            .onChange(of: gestureMode) { oldValue, newValue in
                // When switching to cat mode, force reset any drag state
                if newValue == .catInteraction {
                    resetDragStates()
                    
                    // Update the global state
                    GestureMode.current = .catInteraction
                    
                    // Force enable gestures in NotionFace
                    NotificationCenter.default.post(name: .init("ForceEnableNotionFaceGestures"), object: nil)
                } else {
                    // Update the global state
                    GestureMode.current = .blockDragging
                }
            }
        }
        .onAppear {
            setupGame()
            
            // Update initial gesture mode
            gestureMode = .blockDragging
            GestureMode.current = .blockDragging
            
            // Listen for GestureModeChanged notifications
            NotificationCenter.default.addObserver(
                forName: .init("GestureModeChanged"),
                object: nil,
                queue: .main
            ) { notification in
                if let newMode = notification.object as? GestureMode {
                    self.gestureMode = newMode
                    // Also update global state
                    GestureMode.current = newMode
                }
            }
        }
    }
    
    private func startDragMonitoring() {
        // Cancel any existing timer
        dragResetTimer?.invalidate()
        
        // Set up a new timer to check for drag timeout (3 seconds of inactivity)
        dragResetTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            guard self.isDragging else { return }
            
            if let lastActivity = self.lastDragActivityTime, 
               Date().timeIntervalSince(lastActivity) > 3.0 {
                #if DEBUG
                print("Drag timeout detected - force resetting drag state")
                #endif
                
                // Force reset drag state after timeout
                DispatchQueue.main.async {
                    self.resetDragStates()
                }
            }
        }
    }
    
    private func activateGlobalDragOverride() {
        // Toggle the override state
        DragStateOverride.shared.forceDisableDragState = !DragStateOverride.shared.forceDisableDragState
        
        print("🛑 GLOBAL DRAG OVERRIDE: \(DragStateOverride.shared.forceDisableDragState ? "ACTIVATED" : "DEACTIVATED")")
        
        // If we're activating the override, also do a complete reset
        if DragStateOverride.shared.forceDisableDragState {
            // Force reset all state
            isDragging = false
            selectedBlock = nil
            blockPosition = nil
            GridProjectionCoordinator.shared.projectedCells = []
            
            // Send all notifications
            NotificationCenter.default.post(name: .init("ForceDragReset"), object: nil)
            NotificationCenter.default.post(name: .init("ForceEnableNotionFaceGestures"), object: nil)
            NotificationCenter.default.post(name: .init("DragStateReset"), object: nil)
            NotificationCenter.default.post(name: .init("FinalDragReset"), object: nil)
            
            // Set our tracking variable
            hasTriedOverride = true
        }
    }
    
    private func forceResetAllDragStates() {
        print("🚨 EMERGENCY: FORCE RESETTING ALL DRAG STATES")
        
        // First cancel any active timers
        dragResetTimer?.invalidate()
        dragResetTimer = nil
        
        // Immediate reset all coordination values
        GridProjectionCoordinator.shared.projectedCells = []
        
        // If we've already tried regular reset and it didn't work, activate the override
        if hasTriedOverride && isDragging {
            activateGlobalDragOverride()
            return
        }
        
        // Force reset everything in exact order
        blockPosition = nil
        selectedBlock = nil
        
        // Post notification to inform other components immediately
        NotificationCenter.default.post(name: .init("ForceDragReset"), object: nil)
        
        // Direct notification to NotionFace to force-enable gestures
        NotificationCenter.default.post(name: .init("ForceEnableNotionFaceGestures"), object: nil)
        
        // Wait a tiny bit before changing isDragging to ensure other state is cleared first
        // This prevents animation conflicts
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.isDragging = false
            
            // Post another notification after isDragging is reset
            NotificationCenter.default.post(name: .init("DragStateReset"), object: nil)
            
            // Reset any stray state after a brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                // Make a second reset pass to catch any lingering state
                self.isDragging = false
                self.blockPosition = nil
                self.selectedBlock = nil
                GridProjectionCoordinator.shared.projectedCells = []
                
                // Final notification that confirms everything has been reset
                NotificationCenter.default.post(name: .init("FinalDragReset"), object: nil)
                
                // Second direct notification to NotionFace with a delay
                NotificationCenter.default.post(name: .init("ForceEnableNotionFaceGestures"), object: nil)
                
                // Set our tracking variable
                self.hasTriedOverride = true
            }
        }
    }
    
    // Add a function to toggle between gesture modes
    private func toggleGestureMode() {
        // First cancel any ongoing drag operations
        if isDragging {
            forceResetAllDragStates()
        }
        
        // Disable animations during the mode switch
        var transaction = Transaction(animation: nil)
        transaction.disablesAnimations = true
        
        withTransaction(transaction) {
            gestureMode = gestureMode == .blockDragging ? .catInteraction : .blockDragging
            GestureMode.current = gestureMode
        }
        
        print("🔄 Gesture mode switched to: \(gestureMode == .blockDragging ? "BLOCKS" : "CAT")")
        
        // Force all relevant states based on the new mode
        if gestureMode == .catInteraction {
            // When switching to cat mode, ensure dragging is impossible
            isDragging = false
            selectedBlock = nil
            blockPosition = nil
            DragStateOverride.shared.forceDisableDragState = true
            
            // Force enable NotionFace gestures
            NotificationCenter.default.post(name: .init("ForceEnableNotionFaceGestures"), object: nil)
            
            // Cancel all animations to avoid conflicts
            NotificationCenter.default.post(name: .init("CancelAllAnimations"), object: nil)
        } else {
            // When switching to block mode, allow dragging again
            DragStateOverride.shared.forceDisableDragState = false
        }
        
        // Broadcast mode change after states are updated
        NotificationCenter.default.post(
            name: .init("GestureModeChanged"),
            object: gestureMode
        )
    }
    
    // Add the setupGame function to initialize the game state
    private func setupGame() {
        // Initialize the grid with empty cells
        grid = Array(repeating: Array(repeating: false, count: columns), count: rows)
        
        // Initialize score
        score = 0
        
        // Initialize available blocks
        availableBlocks = generateInitialBlocks()
        
        // Set initial mode
        gestureMode = .blockDragging
        GestureMode.current = .blockDragging
        
        // Reset any lingering drag states
        isDragging = false
        selectedBlock = nil
        blockPosition = nil
        
        // Ensure drag state override is reset
        DragStateOverride.shared.forceDisableDragState = false
        
        print("🎮 Game initialized successfully")
    }
    
    // Helper function to generate initial blocks
    private func generateInitialBlocks() -> [Block] {
        // Create a variety of blocks with different shapes and colors
        return [
            Block.createRandom(),
            Block.createRandom(),
            Block.createRandom(),
            Block.createRandom()
        ]
    }
}

#Preview {
    ContentView()
}

/// Handles core game loop mechanics:
/// 1. Drag gestures create temporary DraggableBlock instances
/// 2. Grid position calculated using gameArea coordinate space
/// 3. Placement validated against grid state
/// 4. Successful placement updates grid and clears transient state
/// 5. Eye tracking integrates with gesture system for hybrid input

class StreakManager: ObservableObject {
    @Published var currentStreak: Int = 0
    private var streakTimer: Timer?
    
    func addPoints(_ points: Int) {
        currentStreak += points
        resetTimer()
    }
    
    private func resetTimer() {
        streakTimer?.invalidate()
        streakTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
            self.currentStreak = 0
        }
    }
}

// Add state reset protocol
extension ContentView: DragStateResettable {
    func resetDragStates() {
        // Create a controlled sequence of state updates to avoid animation conflicts
        
        // First clear projected cells to avoid UI artifacts
        GridProjectionCoordinator.shared.projectedCells = []
        
        // Use a controlled animation sequence
        withAnimation(.easeOut(duration: 0.1)) {
            // Reset block position first
            blockPosition = nil
        }
        
        // Slight delay before changing selection and drag state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            // Then reset selection
            withAnimation(.easeOut(duration: 0.1)) {
                selectedBlock = nil
            }
            
            // Finally, reset drag state
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                self.isDragging = false
            }
        }
    }
}

// Create these new structs at the bottom of the ContentView.swift file:
private struct BaseDoodleLayer: View {
    let geometry: GeometryProxy
    let currentStreak: Int
    
    var body: some View {
        // Base layer - evenly distributed across the screen
        ForEach(0..<20) { i in
            let allTypes = DoodleType.allCases
            
            // Increase the frequency of twentyEight and xSmile doodles
            let type = i % 4 == 0 ? DoodleType.twentyEight : 
                      (i % 5 == 0 ? DoodleType.xSmile : 
                       allTypes[i % (allTypes.count - 1)])
            
            // Divide the screen into a grid and position doodles evenly
            let column = i % 5
            let row = i / 5
            let xPos = CGFloat(column) * geometry.size.width / 5 + CGFloat.random(in: -30...30)
            let yPos = CGFloat(row) * geometry.size.height / 8 + CGFloat.random(in: -30...30)
            
            // Generate a unique ID for this doodle
            let doodleId = "doodle-\(i)-\(type.rawValue)"
            
            DoodleElement(
                type: type,
                rotation: Double.random(in: -25...25),
                streak: 3
            )
            .opacity(0.6)
            .scaleEffect(0.7)
            .position(
                DoodlePositionManager.shared.getPosition(
                    for: doodleId, 
                    defaultX: xPos, 
                    defaultY: yPos
                )
            )
            .animation(
                Animation.easeInOut(duration: 5.0).speed(0.1),
                value: currentStreak
            )
            .offset(
                DoodlePositionManager.shared.getOffset(
                    for: doodleId,
                    defaultOffset: CGSize(
                        width: currentStreak > 0 ? CGFloat.random(in: -20...20) : 0,
                        height: currentStreak > 0 ? CGFloat.random(in: -20...20) : 0
                    )
                )
            )
            .rotationEffect(
                .degrees(
                    DoodlePositionManager.shared.getRotation(
                        for: doodleId,
                        defaultRotation: Double.random(in: -5...5)
                    )
                )
            )
        }
    }
}

private struct MiddleDoodleLayer: View {
    let geometry: GeometryProxy
    let currentStreak: Int
    
    var body: some View {
        // Additional doodles in the middle area
        ForEach(0..<8) { i in
            let type = i % 2 == 0 ? DoodleType.twentyEight : 
                      (i % 3 == 0 ? DoodleType.xSmile :
                       DoodleType.allCases.randomElement()!)
            
            // Generate a unique ID for this middle doodle
            let middleDoodleId = "middle-doodle-\(i)-\(type.rawValue)"
            
            DoodleElement(
                type: type,
                rotation: Double.random(in: -15...15),
                streak: 4
            )
            .opacity(0.65)
            .scaleEffect(0.8)
            .position(
                DoodlePositionManager.shared.getPosition(
                    for: middleDoodleId,
                    defaultX: CGFloat.random(in: geometry.size.width * 0.1...geometry.size.width * 0.9),
                    defaultY: geometry.size.height * 0.6 + CGFloat.random(in: -40...40)
                )
            )
            .animation(
                Animation.easeInOut(duration: 5.0).speed(0.1),
                value: currentStreak
            )
            .offset(
                DoodlePositionManager.shared.getOffset(
                    for: middleDoodleId,
                    defaultOffset: CGSize(
                        width: currentStreak > 0 ? CGFloat.random(in: -20...20) : 0,
                        height: currentStreak > 0 ? CGFloat.random(in: -20...20) : 0
                    )
                )
            )
            .rotationEffect(
                .degrees(
                    DoodlePositionManager.shared.getRotation(
                        for: middleDoodleId,
                        defaultRotation: Double.random(in: -5...5)
                    )
                )
            )
        }
    }
}

private struct BottomDoodleLayer: View {
    let geometry: GeometryProxy
    let currentStreak: Int
    
    var body: some View {
        // Bottom area doodles with emphasis on xSmile
        ForEach(0..<10) { i in
            // Every third doodle is xSmile, every third is 28, remainder is random
            let type = i % 3 == 0 ? DoodleType.twentyEight : 
                      (i % 3 == 1 ? DoodleType.xSmile :
                       DoodleType.allCases.randomElement()!)
            
            // Generate a unique ID for this bottom doodle
            let bottomDoodleId = "bottom-doodle-\(i)-\(type.rawValue)"
            
            DoodleElement(
                type: type,
                rotation: Double.random(in: -15...15),
                streak: 3
            )
            .opacity(0.7)
            .scaleEffect(0.85)
            .position(
                DoodlePositionManager.shared.getPosition(
                    for: bottomDoodleId,
                    defaultX: CGFloat.random(in: geometry.size.width * 0.1...geometry.size.width * 0.9),
                    defaultY: geometry.size.height * 0.9 + CGFloat.random(in: -30...30)
                )
            )
            .animation(
                Animation.easeInOut(duration: 5.0).speed(0.1),
                value: currentStreak
            )
            .offset(
                DoodlePositionManager.shared.getOffset(
                    for: bottomDoodleId,
                    defaultOffset: CGSize(
                        width: currentStreak > 0 ? CGFloat.random(in: -15...15) : 0,
                        height: currentStreak > 0 ? CGFloat.random(in: -15...15) : 0
                    )
                )
            )
            .rotationEffect(
                .degrees(
                    DoodlePositionManager.shared.getRotation(
                        for: bottomDoodleId,
                        defaultRotation: Double.random(in: -3...3)
                    )
                )
            )
        }
    }
}

