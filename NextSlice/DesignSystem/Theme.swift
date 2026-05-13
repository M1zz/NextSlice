import SwiftUI

/// Single source of truth for design tokens. Inject via `.environment(\.theme, …)`
/// once SwiftUI Environment is the chosen pattern (Today's Finding from 5/13).
enum Theme {
    enum Spacing {
        static let xs: CGFloat = 4
        static let s:  CGFloat = 8
        static let m:  CGFloat = 12
        static let l:  CGFloat = 20
        static let xl: CGFloat = 28
    }

    enum Radius {
        static let s: CGFloat = 8
        static let m: CGFloat = 10
        static let l: CGFloat = 12
        static let xl: CGFloat = 16
    }

    enum Limits {
        /// Hard cap on the morning intent. Enforces "one line, one slice".
        static let intentCharacters = 80
    }
}
