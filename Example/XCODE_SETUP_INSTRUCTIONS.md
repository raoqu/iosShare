# Xcode Project Setup Instructions

## Quick Setup Checklist

After the code files have been created, you need to configure the Xcode project to use Swift alongside Objective-C.

### Step 1: Add Swift Files to Xcode Project

1. Open `XExtensionItemExample.xcworkspace` in Xcode
2. In the Project Navigator, right-click on the `App` folder
3. Select "Add Files to XExtensionItemExample..."
4. Navigate to the App folder and select these files:
   - `ContentItem.swift`
   - `ContentItemCell.swift`
   - `ContentViewController.swift`
   - `XExtensionItemExample-Bridging-Header.h`
5. Make sure "Copy items if needed" is UNCHECKED (files are already in place)
6. Ensure "XExtensionItemExample" target is checked
7. Click "Add"

### Step 2: Configure Bridging Header

1. Select the project in Project Navigator (top-level blue icon)
2. Select the "XExtensionItemExample" target
3. Click on "Build Settings" tab
4. In the search bar, type "bridging"
5. Find "Objective-C Bridging Header"
6. Double-click the field and enter:
   ```
   App/XExtensionItemExample-Bridging-Header.h
   ```
   or
   ```
   $(SRCROOT)/App/XExtensionItemExample-Bridging-Header.h
   ```

### Step 3: Set Swift Language Version

1. Still in Build Settings
2. Search for "Swift Language Version"
3. Set it to "Swift 5"

### Step 4: Verify Target Membership

For each Swift file:
1. Select the file in Project Navigator
2. Open File Inspector (right panel, first tab)
3. Under "Target Membership", ensure "XExtensionItemExample" is checked

### Step 5: Clean and Build

1. Clean build folder: **Cmd + Shift + K**
2. Build project: **Cmd + B**
3. Fix any errors (usually related to file paths)
4. Run on simulator: **Cmd + R**

## Expected Result

When you run the app, you should see:

```
┌─────────────────────────────────┐
│  Share Content                  │
├─────────────────────────────────┤
│                                 │
│  Available Content              │
│                                 │
│  ┌───┐  Product Image           │
│  │📷 │  High-resolution...      │
│  └───┘                      >   │
│                                 │
│  ┌───┐  Technical Documentation │
│  │📄 │  User manual and...      │
│  └───┘                      >   │
│                                 │
│  ┌───┐  Sales Report Q4 2024    │
│  │📊 │  Quarterly financial...  │
│  └───┘                      >   │
│                                 │
│  ┌───┐  Project Proposal        │
│  │📝 │  Detailed project...     │
│  └───┘                      >   │
│                                 │
│  ┌───┐  Apple iPad Air 2        │
│  │🔗 │  http://apple.com...     │
│  └───┘                      >   │
│                                 │
│  Tap any item to share via...   │
└─────────────────────────────────┘
```

## Troubleshooting

### Error: "No such module 'XExtensionItem'"
**Solution:** Make sure Pods are installed:
```bash
cd Example
pod install
```
Then open the `.xcworkspace` file, not `.xcodeproj`

### Error: "Bridging header not found"
**Solution:** 
- Check the bridging header path is correct
- Verify the file exists at `Example/App/XExtensionItemExample-Bridging-Header.h`
- Try using absolute path: `$(SRCROOT)/App/XExtensionItemExample-Bridging-Header.h`

### Error: "Use of undeclared type 'ContentViewController'"
**Solution:**
- Make sure Swift files are added to the target
- Clean build folder and rebuild
- Check that ContentViewController.swift has `@objc` or `@objcMembers` if needed

### Error: Build succeeds but app crashes
**Solution:**
- Check console for error messages
- Verify AppDelegate.m imports "XExtensionItemExample-Swift.h"
- Make sure ContentViewController is properly initialized

### Files appear red in Xcode
**Solution:**
- Right-click the file and choose "Show in Finder"
- Verify the file exists
- If not, the path is wrong - re-add the file

## Build Settings Reference

### Critical Settings for Swift/ObjC Interop

| Setting | Value |
|---------|-------|
| Swift Language Version | Swift 5 |
| Objective-C Bridging Header | App/XExtensionItemExample-Bridging-Header.h |
| Defines Module | YES |
| Always Embed Swift Standard Libraries | YES |

## Alternative: Command Line Verification

Run these commands to verify setup:

```bash
# Navigate to Example directory
cd /Users/raoqu/mylab/iosShare/Example

# Check if Swift files exist
ls -la App/*.swift

# Check if bridging header exists
ls -la App/*Bridging*.h

# Check if Pods are installed
ls -la Pods/

# Open workspace
open XExtensionItemExample.xcworkspace
```

## Next Steps After Setup

1. **Test Basic Functionality**
   - Run the app
   - Verify the table view displays
   - Tap each item type
   - Test sharing to different destinations

2. **Customize Content**
   - Edit `ContentViewController.swift`
   - Modify the `loadSampleData()` method
   - Add your own content items

3. **Style Customization**
   - Modify colors in `ContentItem.swift`
   - Adjust cell layout in `ContentItemCell.swift`
   - Update icons (SF Symbols)

## Important Notes

- **Do not** delete the workspace file - always use `.xcworkspace`
- **Do not** commit `Pods/` directory to git
- **Always** clean build folder when switching between Obj-C and Swift changes
- The bridging header allows Swift to import Objective-C headers
- The auto-generated `-Swift.h` header allows Objective-C to import Swift classes

## Support

If you encounter issues:
1. Check Xcode console for detailed error messages
2. Verify all file paths are correct
3. Clean derived data: `rm -rf ~/Library/Developer/Xcode/DerivedData/*`
4. Restart Xcode
5. Check the Swift Migration Guide for more details
