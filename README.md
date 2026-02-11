# Right Click → Add to Calendar

Select any text, right-click, and add it to your Apple Calendar. Uses Gemini Flash to parse event details automatically. Made with Claude Code when I was bored in class.

![Right-click Services menu showing "Add to Calendar"](addtocal_herofig.png)

## Setup

1. Get a [Gemini API key](https://aistudio.google.com/apikey) (free)

2. Clone and add your key:
   ```
   git clone https://github.com/paan/RightClickAddToCalendar.git
   cd RightClickAddToCalendar
   cp RightClickAddToCalendar/.env.example RightClickAddToCalendar/.env
   ```
   Edit `RightClickAddToCalendar/.env` and paste your API key.

3. Build and run:
   ```
   xcodebuild -scheme RightClickAddToCalendar -configuration Release build
   ```
   Or open `RightClickAddToCalendar.xcodeproj` in Xcode and hit Run.

4. The app runs in the background (no dock icon). Select any text → right-click → **Services** → **Add to Calendar**.

> If the service doesn't appear, go to **System Settings → Keyboard → Keyboard Shortcuts → Services** and enable "Add to Calendar". You may need to log out and back in.
