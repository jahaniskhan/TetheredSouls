.onAppear {
    setupGame()
    
    // Add observer for block placement attempts
    NotificationCenter.default.addObserver(
        forName: .init("AttemptBlockPlacement"),
        object: nil,
        queue: .main
    ) { notification in
        if let userInfo = notification.userInfo,
           let row = userInfo["row"] as? Int,
           let column = userInfo["column"] as? Int,
           let block = self.selectedBlock {
            
            self.placeBlock(block, at: row, column: column)
        }
    }
} 