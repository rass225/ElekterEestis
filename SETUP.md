# Setup Instructions for Electricity Price Widget

This app requires some manual configuration in Xcode to enable the widget extension and background fetching.

## 1. Create Widget Extension Target

1. In Xcode, go to **File > New > Target**
2. Select **Widget Extension**
3. Name it "ElekterEestis Widget"
4. Make sure "Include Configuration Intent" is **unchecked**
5. Click **Finish**

## 2. Configure App Groups

Both the main app and widget extension need to share data via App Groups:

1. Select the **main app target** ("ElekterEestis")
2. Go to **Signing & Capabilities** tab
3. Click **+ Capability**
4. Add **App Groups**
5. Check the box for `group.tauts.ElekterEestis` (or create it if it doesn't exist)
6. Repeat steps 1-5 for the **Widget Extension target**

## 3. Share Code Between Targets

The widget extension needs access to the shared models and services:

1. Select `ElectricityPrice.swift` in the Project Navigator
2. In the File Inspector (right panel), under **Target Membership**, check both:
   - ✅ ElekterEestis
   - ✅ ElekterEestis Widget

3. Repeat for:
   - `ElectricityPriceService.swift`
   - `PriceDataStore.swift`

## 4. Replace Widget Extension Files

1. Delete the default widget files created by Xcode in the Widget Extension
2. Move the files from `ElekterEestis Widget/` folder to the Widget Extension target:
   - `ElectricityPriceWidget.swift`
   - `ElectricityPriceWidgetBundle.swift`

## 5. Background Tasks

The project is configured with `BGTaskSchedulerPermittedIdentifiers` and `UIRequiresFullScreen` in the build settings (INFOPLIST_KEY_*). No manual Info.plist configuration is needed.

## 6. Update Widget Bundle

Make sure `ElectricityPriceWidgetBundle.swift` is set as the main entry point for the Widget Extension target.

## 7. Build and Run

1. **Build the Widget Extension:**
   - Select "ElekterEestis Widget" from the scheme dropdown (next to the play button)
   - Build (⌘B) to ensure it compiles

2. **Build and Run the Main App:**
   - Select "ElekterEestis" from the scheme dropdown
   - Build and Run (⌘R) on a device or simulator

3. **Add the Widget:**

   **For Lock Screen:**
   - Long press on the lock screen
   - Tap "Customize"
   - Tap on a lock screen slot
   - Scroll to find "Electricity Prices" widget
   - Choose either Rectangular or Inline style

   **For Home Screen:**
   - Long press on the home screen
   - Tap the "+" button in the top left
   - Search for "Electricity Prices" or "ElekterEestis"
   - Select the widget
   - Choose Small or Medium size
   - Tap "Add Widget"

## Troubleshooting

If the widget doesn't appear:

1. **Verify Widget Extension is built:**
   - In Xcode, check that "ElekterEestis Widget" appears in the scheme dropdown
   - Build it separately (⌘B) to check for errors

2. **Check Target Membership:**
   - Ensure `ElectricityPriceWidget.swift` and `ElectricityPriceWidgetBundle.swift` are checked for "ElekterEestis Widget" target
   - Ensure `ElectricityPrice.swift` is checked for BOTH targets

3. **Verify App Groups:**
   - Both targets must have the same App Group: `group.tauts.ElekterEestis`
   - Check in Signing & Capabilities for both targets

4. **Clean and Rebuild:**
   - Product > Clean Build Folder (⇧⌘K)
   - Delete the app from device/simulator
   - Rebuild and reinstall

## Notes

- The app will fetch prices in the background every 15 minutes
- The widget shows prices for the next 3 hours
- Prices are stored in shared UserDefaults accessible by both the app and widget
- The widget supports:
  - **Lock Screen:** Rectangular and Inline widgets
  - **Home Screen:** Small and Medium widgets
