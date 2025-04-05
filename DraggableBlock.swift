NotificationCenter.default.post(
    name: .init("AttemptBlockPlacement"),
    object: nil,
    userInfo: [
        "position": position,
        "row": gridCell.row,
        "column": gridCell.column
    ]
) 