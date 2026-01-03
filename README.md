# woodbine

Desktop dice rolling app that solves a couple of problems with all the die rolling apps I was able to find out there.

- Offline
- Roll any number of dice
- Dice can have any sides
- See a history of rolls
- Re-roll button on history let's you roll a new one like that
- No ads
- No weird interface - just push the button and clearly see the results

## Development Setup

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- [Node.js](https://nodejs.org/) (for build scripts)

### Initial Setup
1. Clone the repository
2. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```
3. Install build script dependencies:
   ```bash
   npm install
   ```

## Building

### Automated Build (Recommended)

The automated build script handles building, packaging, and creating a distributable zip file:

```bash
npm run build
```

or directly:

```bash
node build.js
```

This will:
1. Build the Flutter Windows app in release mode
2. Copy the build output to `deploy/Woodbine vX.X.X/` (version from pubspec.yaml)
3. Create a zip file `deploy/Woodbine vX.X.X.zip` ready for distribution

### Manual Build

To build manually without the automated script:

```bash
flutter build windows --release
```

The built executable will be located at:
```
build/windows/x64/runner/Release/woodbine.exe
```

You can run it directly from there, or manually copy the entire `Release` folder to distribute the app (it contains required DLLs and data files).

