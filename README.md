# Right Click → Add to Calendar

Select any text, right-click, and add it to your Apple Calendar. Uses Gemini Flash to parse event details automatically.

![macOS](https://img.shields.io/badge/macOS-13%2B-blue)

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

## How it works

1. You select text like *"Dinner at Nobu on Saturday at 7:30pm"*
2. Right-click → Services → Add to Calendar
3. Gemini Flash parses the event details
4. A preview popup lets you review/edit before adding
5. Event is added to your default Apple Calendar

## Requirements

- macOS 13+
- Xcode 15+
- Gemini API key
