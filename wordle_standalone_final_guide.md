# Wördle — Standalone Web Setup Guide

This is the execution-ready guide for extracting Wördle from the TicTacZwo project and
deploying it as a standalone web game at `studio10200.dev/wordle/`.

**What you are building:** A thin new Flutter project that wraps the existing Wördle feature
code, replaces the Supabase/Hive data pipeline with a local CSV + shared_preferences approach,
stubs out audio and haptics for web, and deploys via the established GitHub Pages strategy.

**The main TicTacToe project is never modified.**

### Project Structure

This standalone uses simplified feature-based architecture. Since there is only one feature,
the `features/game/` nesting is dropped. The top-level `lib/game/` folder holds all three
layers — `ui/`, `data/`, and `logic/` — keeping separation of concerns without unnecessary
nesting.

```
lib/
 game/
    ui/
      screens/
        wordle_game_screen.dart      ← copied from main project
      widgets/
        *.dart                       ← copied from main project
    data/
      repositories/
        wordle_word_repo.dart        ← REPLACED (new CSV-based implementation)
      services/
        wordle_coins_service.dart    ← REPLACED (new shared_preferences implementation)
    logic/
      wordle_logic.dart              ← copied from main project
      *.dart                         ← copied from main project
  config/
    game_config/
      constants.dart                 ← copied from main project
  core/
    ui/
      widgets/
        glassmorphic_dialog.dart     ← copied from main project
        dual_progress_indicator.dart ← copied from main project
  settings/
    logic/
      audio_manager.dart             ← STUB (new no-op implementation)
      haptics_manager.dart           ← STUB (new no-op implementation)
  navigation/
    routes/
      route_names.dart               ← REPLACED (minimal standalone routing)
  main.dart                          ← NEW
```

---

## Confirmed Decisions

| Decision | Value |
| :--- | :--- |
| Repo / URL subpath | `wordle` → `studio10200.dev/wordle/` |
| Platforms | Web only |
| Data storage | `shared_preferences` (replaces Hive entirely) |
| Word source | `german_nouns.csv` — column index 1 (`noun`), filtered to 5-letter nouns at runtime |
| Coin persistence | Full persistence via `shared_preferences` |
| Audio | Stubbed (no-op) for web |
| Haptics | Stubbed (no-op) for web |
| Home navigation | Game restart (no external route needed) |
| Theme | No ThemeData — bare `MaterialApp` with dark scaffold background, game screen owns its styling |
| Layout | Adaptive — centred, max-width constrained for web |
| Loading screen | Custom CSS box-flip animation with Wördle colours |

---

## Part 1: Scaffold the New Project


Update `pubspec.yaml` name and description:
```yaml
name: wordle
description: Wördle — guess the German noun in six tries.
version: 1.0.0+1
```

Update `web/index.html` — title, meta, and confirm modern loader:
```html
<title>Wördle</title>
<meta name="description" content="Wördle — guess the German noun in six tries.">
<meta name="apple-mobile-web-app-title" content="Wördle">
```

Ensure the script block uses the modern loader (remove any legacy block if present):
```html
<script src="flutter_bootstrap.js" async></script>
```

Update `web/manifest.json`:
```json
{
  "name": "Wördle",
  "short_name": "Wördle",
  "description": "Guess the German noun in six tries."
}
```

---

## Part 2: Transplant the Feature Code

### Step 1 — Copy the Wördle feature folder

The main project has the feature at `lib/features/game/wordle/`. In the standalone it lives
at `lib/game/`. Copy and rename in one step:

```bash
mkdir -p lib/game
cp -r ../tic_tac_zwo/lib/features/game/wordle/ui    lib/game/ui
cp -r ../tic_tac_zwo/lib/features/game/wordle/data  lib/game/data
cp -r ../tic_tac_zwo/lib/features/game/wordle/logic lib/game/logic
```

After copying, do a find-and-replace across all files in `lib/game/` to update internal
import paths. Any import previously referencing `features/game/wordle/` needs to be updated
to reflect the new `wordle/` root. Use a global search in your IDE for
`features/game/wordle` within `lib/game/` and replace with the correct relative paths.

### Step 2 — Copy the shared external files

Create the required folder structure first:
```bash
mkdir -p lib/config/game_config
mkdir -p lib/core/ui/widgets
```

Copy each file:
```bash
cp ../tic_tac_zwo/lib/config/game_config/constants.dart \
   lib/config/game_config/constants.dart

cp ../tic_tac_zwo/lib/features/game/core/ui/widgets/glassmorphic_dialog.dart \
   lib/core/ui/widgets/glassmorphic_dialog.dart

cp ../tic_tac_zwo/lib/features/game/core/ui/widgets/dual_progress_indicator.dart \
   lib/core/ui/widgets/dual_progress_indicator.dart
```

After copying, update any import inside `glassmorphic_dialog.dart` or
`dual_progress_indicator.dart` that references the old `features/game/core/` path —
replace with `core/ui/widgets/`.

> [!NOTE]
> You are intentionally NOT copying `data_initialization_service.dart`,
> `german_noun_hive.dart`, `audio_manager.dart`, `haptics_manager.dart`, or
> `route_names.dart`. These are all being replaced in the steps below.

### Step 3 — Add the noun dataset and copy the coin asset

# confirm the german_nouns.csv is in assets/data/


```bash
mkdir -p assets/images
cp ../tic_tac_zwo/assets/images/coins.svg assets/images/coins.svg
```


> [!IMPORTANT]
> The CSV must follow this exact column format with a header row:
> ```
> article,noun,plural,english
> die,Kapelle,Kapellen,Chapel
> ```
> The parser reads column index 1 (`noun`) and skips the header row. Any deviation
> from this format requires a corresponding change to `WordleWordRepo`.

---

## Part 3: Replace the Data Pipeline

The original pipeline (Supabase → Hive) is replaced with a simple local loader:
CSV asset → filter 5-letter nouns → cache in `shared_preferences`.

### Step 1 — Replace the word repository

The file was copied in Part 2 but its contents must be fully replaced.
Overwrite `lib/game/data/repositories/wordle_word_repo.dart`:

```dart
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WordleWordRepo {
  static const _cacheKey = 'wordle_five_letter_nouns';
  static const _assetPath = 'assets/data/german_nouns.csv';

  /// Returns a list of 5-letter German nouns.
  /// On first call, loads and filters the CSV and caches the result.
  /// Subsequent calls return instantly from the cache.
  ///
  /// CSV format: article,noun,plural,english
  /// Noun is at column index 1. Header row is skipped.
  Future<List<String>> getFiveLetterNouns() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getStringList(_cacheKey);
    if (cached != null && cached.isNotEmpty) return cached;

    final raw = await rootBundle.loadString(_assetPath);
    final lines = raw.split('\n');

    // Skip header row (article,noun,plural,english)
    final nouns = lines
        .skip(1)
        .map((line) => line.split(','))
        .where((parts) => parts.length > 1)
        .map((parts) => parts[1].trim())
        .where((noun) => noun.length == 5)
        .toList();

    await prefs.setStringList(_cacheKey, nouns);
    return nouns;
  }
}
```

> [!NOTE]
> On first run, add a temporary `print('Loaded ${nouns.length} five-letter nouns');`
> after the filter to confirm the list is populated correctly, then remove it before
> the production build.

### Step 2 — Replace the coin service

The file was copied in Part 2 but its contents must be fully replaced.
Overwrite `lib/game/data/services/wordle_coins_service.dart`:

```dart
import 'package:shared_preferences/shared_preferences.dart';

class WordleCoinsService {
  static const _coinsKey = 'wordle_coins';
  static const _initialCoins = 100; // set your starting balance here

  Future<int> getCoins() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_coinsKey) ?? _initialCoins;
  }

  Future<void> setCoins(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_coinsKey, amount);
  }

  Future<void> deductCoins(int amount) async {
    final current = await getCoins();
    await setCoins((current - amount).clamp(0, double.maxFinite.toInt()));
  }
}
```

---

## Part 4: Create Stubs for Audio and Haptics

These are brand new files — do not copy from the main project.
They have identical method signatures to the originals but all methods are no-ops.

### AudioManager stub

Create `lib/settings/logic/audio_manager.dart`:

```dart
/// Web stub for AudioManager.
/// All methods are no-ops. Add web audio implementation here if needed later.
class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  Future<void> playBackgroundMusic() async {}
  Future<void> pauseBackgroundMusic() async {}
  Future<void> resumeBackgroundMusic() async {}
  Future<void> playCorrectSound() async {}
  Future<void> playIncorrectSound() async {}
  Future<void> dispose() async {}
}
```

> [!NOTE]
> Open `lib/game/ui/screens/wordle_game_screen.dart` and
> `lib/game/logic/wordle_logic.dart` and find every call made on `AudioManager`.
> Ensure every method called exists in the stub above. Add any missing methods as
> additional no-op entries.

### HapticsManager stub

Create `lib/settings/logic/haptics_manager.dart`:

```dart
/// Web stub for HapticsManager.
/// Haptics are not supported on web — all methods are no-ops.
class HapticsManager {
  static Future<void> light() async {}
  static Future<void> medium() async {}
  static Future<void> heavy() async {}
}
```

---

## Part 5: Replace Navigation

Create `lib/navigation/routes/route_names.dart`:

```dart
class RouteNames {
  // In the standalone, both routes point to '/'.
  // Navigating "home" simply restarts WordleGameScreen.
  static const String wordle = '/';
  static const String home = '/';
}
```

No changes are needed inside the Wördle feature files — the navigation calls work
correctly with both constants mapped to `'/'`.

---

## Part 6: Write main.dart

Replace `lib/main.dart` entirely. There is no `ThemeData` — the game screen owns its own
styling. The `MaterialApp` is kept minimal: dark scaffold background, routing, no debug
banner. The `AdaptiveGameShell` centres and constrains the game to a mobile-width viewport
on wide screens.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'wordle/ui/screens/wordle_game_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferences.getInstance();
  runApp(
    const ProviderScope(
      child: WordleApp(),
    ),
  );
}

class WordleApp extends StatelessWidget {
  const WordleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wördle',
      debugShowCheckedModeBanner: false,
      // No full ThemeData — WordleGameScreen owns its own styling.
      // Dark scaffold background prevents any white flash between the
      // loading screen and the first Flutter frame.
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.black,
        brightness: Brightness.dark,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AdaptiveGameShell(child: WordleGameScreen()),
      },
    );
  }
}

/// Centres the game and constrains it to a mobile-width viewport on wide screens.
/// On a phone this wrapper is invisible — the game fills the screen as normal.
/// On a desktop browser this prevents the layout from stretching awkwardly.
class AdaptiveGameShell extends StatelessWidget {
  final Widget child;
  const AdaptiveGameShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: child,
        ),
      ),
    );
  }
}
```

> [!NOTE]
> The `maxWidth: 480` matches a standard mobile viewport. Adjust during local testing
> if the game looks better at a different width. The game screen retains all its own
> layout logic — this shell only prevents it from expanding beyond the constraint.

---

## Part 7: Configure pubspec.yaml

Replace the dependencies and assets sections:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.6.1
  flutter_animate: ^4.5.2
  flutter_svg: ^2.0.16
  shared_preferences: ^2.x.x   # check pub.dev for latest stable

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_launcher_icons: ^0.14.4

flutter_launcher_icons:
  android: "ic_launcher"
  ios: true
  image_path: "assets/icons/icon_full.png"
  adaptive_icon_background: "#FFFFFF"
  adaptive_icon_foreground: "assets/icons/icon_foreground.png"
  web:
    generate: true
    image_path: "assets/icons/icon_full.png"
    background_color: "#FFFFFF"
    theme_color: "#FFFFFF"

flutter:
  uses-material-design: true
  assets:
    - assets/data/
    - assets/images/
    - assets/icons/
```

> [!NOTE]
> `hive_ce`, `hive_ce_flutter`, `hive_ce_generator`, `build_runner`, `audioplayers`,
> `vibration`, `supabase_flutter`, and `flutter_dotenv` are intentionally absent.

```bash
flutter pub get
```

---

## Part 8: Test Locally

### Step 1 — First run

```bash
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
```

Get your Mac IP in a second terminal:
```bash
ipconfig getifaddr en0
```

Open `http://YOUR_MAC_IP:8080` in Chrome on your Pixel 5.

**Work through this checklist before continuing:**
- [ ] App launches without a red error screen
- [ ] `WordleGameScreen` loads (no "No MaterialApp found" error)
- [ ] Black background is showing — no white flash or grey scaffold
- [ ] On a wide browser window, game is centred and constrained to ~480px, not stretched
- [ ] Word loads correctly on game start (confirms CSV parsing works)
- [ ] Keyboard input works
- [ ] Win and loss states trigger correctly
- [ ] Result dialog appears and restart works
- [ ] Coin balance displays and persists across page refreshes
- [ ] Hint deduction works correctly
- [ ] Instructions dialog opens
- [ ] No errors in Chrome DevTools console

### Step 2 — Fix "No MaterialApp found" if it appears

`WordleGameScreen` is reaching for a `MaterialApp` or `Navigator` above it. Confirm
`AdaptiveGameShell` wraps `WordleGameScreen` in the routes map in `main.dart`.

### Step 3 — Test with HTML renderer

```bash
flutter run -d web-server --web-renderer html --web-hostname 0.0.0.0 --web-port 8080
```

Compare visually. If it looks correct, the production build uses HTML renderer.

### Step 4 — Code cleanliness

```bash
grep -r "print(" lib/
grep -r "debugPrint(" lib/
```

Both must return zero results.

---

## Part 9: Add the Loading Screen to web/index.html

> [!IMPORTANT]
> **When reusing this loading screen in other projects, change ONLY
> the `:root` variables block — nothing else in the CSS ever needs to touch:**
> - `--loading-bg` — the project's scaffold background colour
> - `--color-1` through `--color-5` — the project's colour palette as a gradient
> - `--shadow-rgb` — the RGB channels of `--color-3` as a comma-separated string
>   e.g. if `--color-3` is `#e53935`, then `--shadow-rgb: 229, 57, 53`
>   (use any hex-to-rgb converter — the three numbers go directly in)
> - The `.label` text — the project name
>
> Every other rule — layout, animation assignments, shadow keyframes, timing keyframes —
> is fully driven by variables and identical across all projects.

Edit `web/index.html`. Add the following inside `<body>`, before the
`<script src="flutter_bootstrap.js">` tag:

```html
<!-- ─────────────────────────────────────────────────────────
     WÖRDLE LOADING SCREEN
     To reuse for another project, change ONLY:
       • --loading-bg
       • The 5 background-color hex values on nth-child(2-5):after
       • The slide/color-change keyframe start/end hex values
       • The .label text
     Everything else stays identical across all projects.
     ───────────────────────────────────────────────────────── -->
<style>
  /* =====================================================
     THEME VARIABLES — only this block changes per project
     ===================================================== */
  :root {
    /* Background — must match the Flutter scaffold colour exactly */
    --loading-bg: #000000;       /* Wördle: pure black — CHANGE PER PROJECT */

    /* Box colour palette — gradient from darkest to lightest */
    --color-1: #388e3c;          /* Colors.green[700] — CHANGE PER PROJECT */
    --color-2: #43a047;          /* Colors.green[600] — CHANGE PER PROJECT */
    --color-3: #4caf50;          /* Colors.green      — CHANGE PER PROJECT */
    --color-4: #66bb6a;          /* Colors.green[400] — CHANGE PER PROJECT */
    --color-5: #81c784;          /* Colors.green[300] — CHANGE PER PROJECT */

    /* Shadow — RGB channels of --color-3, used as rgba(var(--shadow-rgb), opacity) */
    --shadow-rgb: 76, 175, 80;   /* #4caf50 = rgb(76,175,80) — CHANGE PER PROJECT */

    /* Animation internals — DO NOT CHANGE for any project */
    --duration: 3s;
    --container-size: 250px;
    --box-size: 33px;
    --box-border-radius: 15%;
  }

  /* Loading screen wrapper */
  #flutter-loading {
    position: fixed;
    inset: 0;
    display: flex;
    flex-direction: column;
    justify-content: center;
    align-items: center;
    background-color: var(--loading-bg);
    gap: 32px;
    z-index: 9999;
  }

  #flutter-loading .label {
    color: #ffffff;
    font-family: sans-serif;
    font-size: 1rem;
    letter-spacing: 0.3em;
    opacity: 0.8;
  }

  /* Box container */
  .box-container {
    width: var(--container-size);
    display: flex;
    justify-content: space-between;
    align-items: center;
    position: relative;
  }

  /* Individual boxes */
  .box {
    width: var(--box-size);
    height: var(--box-size);
    position: relative;
    display: block;
    transform-origin: -50% center;
    border-radius: var(--box-border-radius);
    --anim: none;
    animation: var(--anim) var(--duration) ease-in-out infinite alternate;
  }

  .box:after {
    content: "";
    width: 100%;
    height: 100%;
    position: absolute;
    top: 0;
    right: 0;
    background-color: var(--color-3);
    border-radius: var(--box-border-radius);
    --after-anim: none;
    --shadow-logic: shadow-pulse; /* Default for flipping boxes */
    animation:
      var(--after-anim) var(--duration) ease-in-out infinite alternate,
      var(--shadow-logic) var(--duration) ease-in-out infinite alternate;
  }

  /* Animation assignments — DO NOT CHANGE */
  .box:nth-child(1) { --anim: slide; }
  .box:nth-child(1):after {
    --after-anim: color-change;
    --shadow-logic: shadow-slide; /* Linear shadow for the sliding box */
  }

  .box:nth-child(2) { --anim: flip-1; }
  .box:nth-child(2):after { --after-anim: squidge-1; background-color: var(--color-2); }

  .box:nth-child(3) { --anim: flip-2; }
  .box:nth-child(3):after { --after-anim: squidge-2; background-color: var(--color-3); }

  .box:nth-child(4) { --anim: flip-3; }
  .box:nth-child(4):after { --after-anim: squidge-3; background-color: var(--color-4); }

  .box:nth-child(5) { --anim: flip-4; }
  .box:nth-child(5):after { --after-anim: squidge-4; background-color: var(--color-5); }

  /* Colour keyframes — reference variables only, no hardcoded colours */
  @keyframes slide {
    0%   { transform: translateX(0vw); }
    100% { transform: translateX(calc(var(--container-size) - (var(--box-size) * 1.25))); }
  }
  @keyframes color-change {
    0%   { background-color: var(--color-1); }
    100% { background-color: var(--color-5); }
  }

  /* Shadow keyframes — rgba() uses --shadow-rgb, no hardcoded colours here */
  @keyframes shadow-slide {
    /* Shadow shifts direction as the box travels left to right */
    0% {
      box-shadow:
        -8px 10px 15px rgba(var(--shadow-rgb), 0.2),
        0 2px 4px rgba(255, 255, 255, 0.1) inset;
    }
    100% {
      box-shadow:
        8px 10px 15px rgba(var(--shadow-rgb), 0.2),
        0 2px 4px rgba(255, 255, 255, 0.1) inset;
    }
  }
  @keyframes shadow-pulse {
    /* Flipping boxes: elevation feel on squidge */
    0% {
      box-shadow:
        8px 12px 18px rgba(var(--shadow-rgb), 0.15),
        0 2px 4px rgba(255, 255, 255, 0.15) inset;
      transform: translateY(-3px);
    }
    100% {
      box-shadow:
        4px 4px 10px rgba(var(--shadow-rgb), 0.3),
        0 1px 2px rgba(255, 255, 255, 0.05) inset;
      transform: translateY(0px);
    }
  }

  /* ── Timing keyframes — DO NOT CHANGE for any project ── */
  @keyframes flip-1 {
    0%, 15%   { transform: rotate(0); }
    35%, 100% { transform: rotate(-180deg); }
  }
  @keyframes squidge-1 {
    5%        { transform-origin: center bottom; transform: scale(1,1); }
    15%       { transform-origin: center bottom; transform: scale(1.3,0.7); }
    20%, 25%  { transform-origin: center bottom; transform: scale(0.8,1.4); }
    40%       { transform-origin: center top;    transform: scale(1.3,0.7); }
    55%, 100% { transform-origin: center top;    transform: scale(1,1); }
  }
  @keyframes flip-2 {
    0%, 30%   { transform: rotate(0); }
    50%, 100% { transform: rotate(-180deg); }
  }
  @keyframes squidge-2 {
    20%       { transform-origin: center bottom; transform: scale(1,1); }
    30%       { transform-origin: center bottom; transform: scale(1.3,0.7); }
    35%, 40%  { transform-origin: center bottom; transform: scale(0.8,1.4); }
    55%       { transform-origin: center top;    transform: scale(1.3,0.7); }
    70%, 100% { transform-origin: center top;    transform: scale(1,1); }
  }
  @keyframes flip-3 {
    0%, 45%   { transform: rotate(0); }
    65%, 100% { transform: rotate(-180deg); }
  }
  @keyframes squidge-3 {
    35%       { transform-origin: center bottom; transform: scale(1,1); }
    45%       { transform-origin: center bottom; transform: scale(1.3,0.7); }
    50%, 55%  { transform-origin: center bottom; transform: scale(0.8,1.4); }
    70%       { transform-origin: center top;    transform: scale(1.3,0.7); }
    85%, 100% { transform-origin: center top;    transform: scale(1,1); }
  }
  @keyframes flip-4 {
    0%, 60%   { transform: rotate(0); }
    80%, 100% { transform: rotate(-180deg); }
  }
  @keyframes squidge-4 {
    50%        { transform-origin: center bottom; transform: scale(1,1); }
    60%        { transform-origin: center bottom; transform: scale(1.3,0.7); }
    65%, 70%   { transform-origin: center bottom; transform: scale(0.8,1.4); }
    85%        { transform-origin: center top;    transform: scale(1.3,0.7); }
    100%       { transform-origin: center top;    transform: scale(1,1); }
  }
</style>

<div id="flutter-loading">
  <div class="box-container">
    <div class="box"></div>
    <div class="box"></div>
    <div class="box"></div>
    <div class="box"></div>
    <div class="box"></div>
  </div>
  <div class="label">WÖRDLE</div>  <!-- CHANGE PER PROJECT -->
</div>

  /* Loading screen wrapper */
  #flutter-loading {
    position: fixed;
    inset: 0;
    display: flex;
    flex-direction: column;
    justify-content: center;
    align-items: center;
    background-color: var(--loading-bg);
    gap: 32px;
    z-index: 9999;
  }

  #flutter-loading .label {
    color: #ffffff;
    font-family: sans-serif;
    font-size: 1rem;
    letter-spacing: 0.3em;
    opacity: 0.8;
  }

  /* Box container */
  .box-container {
    width: var(--container-size);
    display: flex;
    justify-content: space-between;
    align-items: center;
    position: relative;
  }

  /* Individual boxes */
  .box {
    width: var(--box-size);
    height: var(--box-size);
    position: relative;
    display: block;
    transform-origin: -50% center;
    border-radius: var(--box-border-radius);
    --anim: none;
    animation: var(--anim) var(--duration) ease-in-out infinite alternate;
  }

  .box:after {
    content: "";
    width: 100%;
    height: 100%;
    position: absolute;
    top: 0;
    right: 0;
    background-color: var(--color-3);
    border-radius: var(--box-border-radius);
    box-shadow: 0px 0px 10px 0px var(--glow);
    --after-anim: none;
    animation: var(--after-anim) var(--duration) ease-in-out infinite alternate;
  }

  /* Animation assignments — DO NOT CHANGE */
  .box:nth-child(1) { --anim: slide; }
  .box:nth-child(1):after { --after-anim: color-change; }

  .box:nth-child(2) { --anim: flip-1; }
  .box:nth-child(2):after { --after-anim: squidge-1; background-color: var(--color-2); }

  .box:nth-child(3) { --anim: flip-2; }
  .box:nth-child(3):after { --after-anim: squidge-2; background-color: var(--color-3); }

  .box:nth-child(4) { --anim: flip-3; }
  .box:nth-child(4):after { --after-anim: squidge-3; background-color: var(--color-4); }

  .box:nth-child(5) { --anim: flip-4; }
  .box:nth-child(5):after { --after-anim: squidge-4; background-color: var(--color-5); }

  /* Colour keyframes — reference variables, no hardcoded colours here */
  @keyframes slide {
    0%   { background-color: var(--color-1); transform: translatex(0vw); }
    100% { background-color: var(--color-5);
           transform: translatex(calc(var(--container-size) - (var(--box-size) * 1.25))); }
  }
  @keyframes color-change {
    0%   { background-color: var(--color-1); }
    100% { background-color: var(--color-5); }
  }

  /* ── Timing keyframes — DO NOT CHANGE for any project ── */
  @keyframes flip-1 {
    0%, 15%   { transform: rotate(0); }
    35%, 100% { transform: rotate(-180deg); }
  }
  @keyframes squidge-1 {
    5%        { transform-origin: center bottom; transform: scalex(1) scaley(1); }
    15%       { transform-origin: center bottom; transform: scalex(1.3) scaley(0.7); }
    20%, 25%  { transform-origin: center bottom; transform: scalex(0.8) scaley(1.4); }
    40%       { transform-origin: center top;    transform: scalex(1.3) scaley(0.7); }
    55%, 100% { transform-origin: center top;    transform: scalex(1) scaley(1); }
  }
  @keyframes flip-2 {
    0%, 30%   { transform: rotate(0); }
    50%, 100% { transform: rotate(-180deg); }
  }
  @keyframes squidge-2 {
    20%       { transform-origin: center bottom; transform: scalex(1) scaley(1); }
    30%       { transform-origin: center bottom; transform: scalex(1.3) scaley(0.7); }
    35%, 40%  { transform-origin: center bottom; transform: scalex(0.8) scaley(1.4); }
    55%       { transform-origin: center top;    transform: scalex(1.3) scaley(0.7); }
    70%, 100% { transform-origin: center top;    transform: scalex(1) scaley(1); }
  }
  @keyframes flip-3 {
    0%, 45%   { transform: rotate(0); }
    65%, 100% { transform: rotate(-180deg); }
  }
  @keyframes squidge-3 {
    35%       { transform-origin: center bottom; transform: scalex(1) scaley(1); }
    45%       { transform-origin: center bottom; transform: scalex(1.3) scaley(0.7); }
    50%, 55%  { transform-origin: center bottom; transform: scalex(0.8) scaley(1.4); }
    70%       { transform-origin: center top;    transform: scalex(1.3) scaley(0.7); }
    85%, 100% { transform-origin: center top;    transform: scalex(1) scaley(1); }
  }
  @keyframes flip-4 {
    0%, 60%   { transform: rotate(0); }
    80%, 100% { transform: rotate(-180deg); }
  }
  @keyframes squidge-4 {
    50%        { transform-origin: center bottom; transform: scalex(1) scaley(1); }
    60%        { transform-origin: center bottom; transform: scalex(1.3) scaley(0.7); }
    65%, 70%   { transform-origin: center bottom; transform: scalex(0.8) scaley(1.4); }
    85%        { transform-origin: center top;    transform: scalex(1.3) scaley(0.7); }
    100%       { transform-origin: center top;    transform: scalex(1) scaley(1); }
  }
</style>

<div id="flutter-loading">
  <div class="box-container">
    <div class="box"></div>
    <div class="box"></div>
    <div class="box"></div>
    <div class="box"></div>
    <div class="box"></div>
  </div>
  <div class="label">WÖRDLE</div>  <!-- CHANGE PER PROJECT -->
</div>

<script>
  window.addEventListener('flutter-first-frame', function () {
    const loader = document.getElementById('flutter-loading');
    if (loader) {
      loader.style.transition = 'opacity 0.3s ease';
      loader.style.opacity = '0';
      setTimeout(() => loader.remove(), 300);
    }
  });
</script>
```

---

## Part 10: Icon Generation

Place your icon files:
- `assets/icons/icon_full.png` — full square icon
- `assets/icons/icon_foreground.png` — foreground layer for adaptive icon

```bash
flutter pub get && dart run flutter_launcher_icons
```

---

## Part 11: Git Setup

On GitHub, create a new **public** repo named `wordle` under `3llips3s`.
Do not initialise with a README.

```bash
git init
git remote add origin https://github.com/3llips3s/wordle.git
```

Append to the default Flutter `.gitignore`:
```gitignore
# Internal IDE / AI docs
*.antigravity*
brain/
*_prd.md
*_progress.md
*_setup_guide.md

# Environment
.env*
```

Create `LICENSE`:
```
MIT License
Copyright (c) 2026 3llips3s
```

Create `README.md` with: About, How to Play, Tech Stack, License.

```bash
git add .
git commit -m "feat: initial Wördle standalone project"
git push -u origin main
```

---

## Part 12: GitHub Actions (CI/CD)

Create `.github/workflows/deploy.yml`:
```yaml
name: Deploy to GitHub Pages

on:
  push:
    branches:
      - main

permissions:
  contents: write

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          channel: 'stable'
          flutter-version: '3.29.0'

      - name: Install dependencies
        run: flutter pub get

      - name: Build Web
        run: flutter build web --release --web-renderer html --base-href "/wordle/"

      - name: Deploy to GitHub Pages
        uses: JamesIves/github-pages-deploy-action@v4
        with:
          folder: build/web
          branch: gh-pages
```

> [!IMPORTANT]
> `/wordle/` must exactly match the GitHub repo name.

```bash
git add .github/workflows/deploy.yml
git commit -m "ci: add GitHub Pages deploy workflow"
git push
```

---

## Part 13: Activate GitHub Pages

After the first successful Action run:
1. Go to `wordle` repo → **Settings → Pages**
2. Set Branch: `gh-pages`, Folder: `/(root)`
3. Click **Save**

Live at `https://3llips3s.github.io/wordle/` within ~60 seconds.
Available at `https://studio10200.dev/wordle/` once the portfolio repo is live.

---

## Part 14: Update the Project Registry

Update `replication_guide.md`:

| Game | Repo | Web? | Android? | URL |
| :--- | :--- | :---: | :---: | :--- |
| Hangmensch | `hangmensch` | ✅ | ✅ | `studio10200.dev/hangmensch/` |
| Wördle | `wordle` | ✅ | ❌ | `studio10200.dev/wordle/` |
| [TicTacToe] | `[repo-name]` | ❌ | ✅ | APK download only |
| Portfolio | `3llips3s.github.io` | ✅ | ❌ | `studio10200.dev/` |

---

## Appendix: Common Issues

**Red screen — "No MaterialApp found"**
`WordleGameScreen` is reaching for a `MaterialApp` or `Navigator` above it. Confirm
`AdaptiveGameShell` wraps `WordleGameScreen` in the routes map in `main.dart`.

**Word list is empty on game start**
CSV parsing returned zero 5-letter results. Temporarily add
`print('Loaded ${nouns.length} nouns');` in `WordleWordRepo` to check. Confirm the
CSV header row is being skipped and column index 1 contains the noun.

**Coins not persisting across refreshes**
Confirm `SharedPreferences.getInstance()` is awaited in `main()` before `runApp`.
Confirm `WordleCoinsService` reads and writes using the key `wordle_coins`.

**Assets not loading (404)**
Confirm every asset folder in `pubspec.yaml` ends with a trailing slash and the physical
file exists at exactly the declared relative path.

**Audio / haptics compile errors**
The stubs must expose every method the Wördle feature calls. Open
`lib/game/ui/screens/wordle_game_screen.dart` and `lib/game/logic/wordle_logic.dart`,
find every call on `AudioManager` and `HapticsManager`, and ensure each method exists in
the stub classes.

**Game stretches full width on desktop browser**
Confirm `WordleGameScreen` is wrapped inside `AdaptiveGameShell` in the routes map.
If the game screen has its own `Scaffold`, the shell's `ConstrainedBox` still applies —
the scaffold simply fills the constrained width.

**Black background not showing — white flash on load**
Confirm both `ThemeData(scaffoldBackgroundColor: Colors.black)` in `MaterialApp` and
`backgroundColor: Colors.black` in `AdaptiveGameShell`'s `Scaffold` are set. Both are
needed — the outer scaffold covers the area outside the 480px constraint on wide screens,
and the theme covers the inner area before the game screen renders.

**`RouteNames.home` navigates away unexpectedly**
Both `'/'` and `RouteNames.home` are mapped to `WordleGameScreen`. Pressing home restarts
the game in place. If it behaves unexpectedly, check whether the Wördle code uses
`pushNamed` or `pushNamedAndRemoveUntil` — both work correctly with this setup.
