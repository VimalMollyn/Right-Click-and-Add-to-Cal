# Right Click → Add to Calendar

Select any text, right-click, and add it to your Apple Calendar. Parses event details automatically using either Gemini Flash or Apple's on-device Foundation Models. Made with Claude Code when I was bored in class.

![Right-click Services menu showing "Add to Calendar"](addtocal_herofig.png)

## Setup

1. Pick a model provider:
   - **Gemini** (default, works on macOS 13+): grab a free [Gemini API key](https://aistudio.google.com/apikey).
   - **Apple Foundation Models** (on-device, no API key, no network): requires macOS 26 with Apple Intelligence enabled.

2. Clone and configure:
   ```
   git clone https://github.com/paan/RightClickAddToCalendar.git
   cd RightClickAddToCalendar
   cp RightClickAddToCalendar/.env.example RightClickAddToCalendar/.env
   ```
   Edit `RightClickAddToCalendar/.env`:
   - For Gemini: paste your key into `GEMINI_API_KEY`.
   - `MODEL_PROVIDER` in `.env` is the initial default; you can switch live from the menu bar after launch.

3. Build and install:
   ```
   xcodebuild -scheme RightClickAddToCalendar -configuration Release build
   ```
   Or open `RightClickAddToCalendar.xcodeproj` in Xcode and hit Run.

4. Copy the built app to Applications:
   ```
   cp -R ~/Library/Developer/Xcode/DerivedData/RightClickAddToCalendar-*/Build/Products/Release/RightClickAddToCalendar.app /Applications/
   ```

5. Open the app. It runs in the background (no dock icon). To start it automatically on login, add it in **System Settings → General → Login Items**.

6. Select any text → right-click → **Services** → **Add to Calendar**.

7. Switch models any time from the menu bar icon (📅): **Model → Gemini / Apple Foundation Models**. The choice is saved across launches. The Apple option is greyed out unless you're on macOS 26 with Apple Intelligence enabled.

> If the service doesn't appear, go to **System Settings → Keyboard → Keyboard Shortcuts → Services** and enable "Add to Calendar". You may need to log out and back in.
