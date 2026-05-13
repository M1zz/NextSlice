# Xcode setup

For a 10-year iOS dev, the short version:

1. **Create Xcode project**
   - `File → New → Project → iOS App`
   - Product name: `NextSlice`
   - Interface: SwiftUI, Language: Swift, Storage: **SwiftData**
   - Minimum deployment: iOS 17.0

2. **Drop in the source files**
   - Drag the contents of `NextSlice/` into the new app target (keep folder refs).
   - The `Models/`, `Services/`, `Views/`, `DesignSystem/` groups should mirror the directory layout.
   - Replace the generated `ContentView.swift` and `NextSliceApp.swift` with the ones here.

3. **Add the widget extension**
   - `File → New → Target → Widget Extension`
   - Product name: `NextSliceWidget`
   - Uncheck "Include Configuration Intent" (we use StaticConfiguration).
   - Replace generated files with the contents of `NextSliceWidget/`.

4. **Configure App Group (required for widget data access)**
   - On **both** the `NextSlice` app target and the `NextSliceWidget` target:
     - Signing & Capabilities → `+ Capability` → App Groups
     - Add group: `group.com.devkoan.NextSlice` (or your own — must match Apple Developer portal)
   - Update `AppGroup.identifier` in **two places** if you chose a different group:
     - `NextSlice/NextSliceApp.swift`
     - `NextSliceWidget/TodayProvider.swift`
   - (They're duplicated by necessity — separate compile units can't share a single source file unless you give the widget access. If you'd rather, drag a single `AppGroup.swift` into both target memberships.)

5. **Share model files with the widget target**
   - In Xcode, select each file in `Models/` and tick the `NextSliceWidget` checkbox in
     File Inspector → Target Membership.
   - Same for `Services/Date+Helpers.swift` if you reference it from the provider.

6. **Build & run**
   - On first launch, a `UserStage` is auto-created (Day 1, Soft).
   - The widget surfaces "Open NextSlice to start" until the first intent is saved.

## Things deliberately left as TODOs

- **`WeekView.exportCard()`** — wire up a `ShareLink` rendering the WeeklyPattern + Findings
  to a UIImage via `ImageRenderer`. Look-and-Say style: one finding per row, header with
  pattern text. Probably an SVG-like layout in SwiftUI then snapshot.
- **Notifications** — schedule a daily evening reminder ("close today's slice") and a
  Sunday morning one ("time for your weekly retro"). UserNotifications, no special infra.
- **Onboarding** — one-screen intro explaining the 80-char rule and the gauge gradient.
- **Time-of-day boundary** — currently hardcoded at 18:00 (`TodayView.mode`). Make
  this user-adjustable in Settings if needed.

## SwiftData gotchas to watch

- `@Model` enums need raw-string storage with a computed accessor (already done on
  `UserStage.manualOverride`).
- `#Predicate` doesn't accept computed properties — filter in-memory after fetch
  (already done in `EnforcementService.unfinishedYesterday`).
- The `Bindable` wrapper is required when binding TextField to `@Model` properties
  (see `DayActiveView`, `EveningModeView`).

## After v0.1

Once you've shipped, the natural next moves:

1. Widget interaction (iOS 17+) — let the user tap the widget intent to mark
   the morning entry started, or jump straight to the evening 4F.
2. CloudKit sync — `ModelConfiguration` accepts a `cloudKitDatabase` parameter.
3. The CBL / Academy layer you parked: re-add `Challenge` as an opt-in model
   without disturbing v0.1 storage.
