# BotFlow Builder 📱

A Flutter port of the Bot Flow Builder visual scenario editor.  
Dark theme, dot-grid canvas, glass UI, draggable FAB — designed to match the HTML prototype 1:1.

## Features

- 🖤 Black dot-grid canvas (pannable + pinch-to-zoom)
- ✨ iOS-style liquid glass UI elements (BackdropFilter blur)
- 🔘 Draggable FAB — drag anywhere, tap to expand into action panel
  - 💬 Add Message node
  - 📝 Add Note node
- 🗂 Node cards with pop-in animation
- 🎨 Coloured node types: Start (green), Message (purple), Input (pink), Timer (orange), Note (yellow)
- 📊 Top bar with node count + auto-save indicator
- 🔲 Transparent status bar

## Run locally

```bash
flutter pub get
flutter run
```

## Build APK

```bash
flutter build apk --release
# APK → build/app/outputs/flutter-apk/app-release.apk
```

## CI/CD via GitHub Actions

Push to `main` → GitHub Actions automatically builds both release and debug APKs.  
Go to **Actions → Build APK → Artifacts** to download.

### Setup steps:
1. Create a new GitHub repository
2. Push this project folder contents to it:
   ```bash
   git init
   git add .
   git commit -m "Initial commit"
   git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git
   git push -u origin main
   ```
3. Watch the **Actions** tab — build takes ~5 minutes
4. Download the APK from **Artifacts**

## Icon design

Solar icon set — https://icon-sets.iconify.design/solar/

## Project structure

```
lib/
  main.dart               — Entry point, transparent status bar
  theme/
    app_colors.dart       — Design tokens (matches HTML :root vars)
    solar_icons.dart      — Embedded SVG icon data
  widgets/
    glass_surface.dart    — Reusable glass/backdrop widget
    grid_painter.dart     — Dot-grid CustomPainter
    top_bar.dart          — Floating top navigation
    draggable_fab.dart    — Expandable draggable FAB
  screens/
    canvas_screen.dart    — Main canvas screen
```
