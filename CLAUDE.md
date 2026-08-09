# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & test

`xcode-select` on this machine points at the Command Line Tools, so `xcodebuild` fails unless you override the developer dir:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -scheme Interval -destination 'platform=macOS' build
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -scheme Interval -destination 'platform=macOS' test
```

Single test (Swift Testing, so target the test's identifier):

```bash
DEVELOPER_DIR=... xcodebuild -scheme Interval -destination 'platform=macOS' \
  -only-testing:IntervalTests/IntervalTests/restCompletionRestartsWorkCounter test
```

Targets: `Interval` (app), `IntervalTests` (unit, Swift Testing), `IntervalUITests` (XCUITest). macOS 26.5 deployment target, sandboxed, `SWIFT_APPROACHABLE_CONCURRENCY = YES`.

Tests drive real wall-clock time (`Task.sleep`) rather than a injected clock, so keep durations in test settings to a few seconds — `IntervalSettings` has a public memberwise `init` specifically so tests can construct sub-minute intervals (`workMinutes: 2 / 60`).

## Architecture

A menu-bar-only Pomodoro-style app. The app launches as `.accessory` (no Dock icon) and only becomes `.regular` while a titled window is open — see `AppDelegate.showInDock()` and the `windowWillClose` observer that drops back to accessory when the last one closes. Every menu action that opens a window calls `showInDock()` first.

**`IntervalManager`** is the single source of truth and the only stateful component. It is `@MainActor @Observable` and owns a `Phase` state machine (`idle → working → resting → working …`) driven by a 1 s `Timer` on the main run loop. Key invariants that are easy to break:

- Time is **accumulated**, not counted down from a deadline. Each tick adds `min(maxElapsedPerTick, elapsed)` to `workAccumulatedSeconds` / `restAccumulatedSeconds`. The per-tick cap exists so a sleep or screen-lock gap doesn't dump minutes of phantom work time in on resume. `displayRemaining` is always derived (`target - accumulated`), never decremented directly.
- Ticks are skipped (paused, not stopped) when the screen is locked or the user is idle past `idleThresholdSeconds` during work; and during **rest** when the user is still typing (`pauseRestOnActivity`, `restInteractionThreshold`). `isPaused` + `pauseReason` are purely presentational output of this.
- `suppressIdleResetAfterRest` guards a subtle interaction: after a rest completes the user has legitimately been idle for the whole rest, so the "away longer than a full rest → reset the work session" check would fire immediately. The flag suppresses that check until fresh input actually arrives.
- Sleep/wake is handled separately via `NSWorkspace` observers: a sleep gap longer than a full rest is treated as a completed rest and the focus session restarts.

**Idle detection** goes through the `ActivityMonitoring` protocol (`isScreenLocked`, `secondsSinceLastInput`) so tests can substitute a stub. The real `ActivityMonitor` uses `CGEventSource.secondsSinceLastEventType(.combinedSessionState, …)`, which works inside the App Sandbox without Input Monitoring permission — don't replace it with an event tap. Screen lock comes from the undocumented `com.apple.screenIsLocked` / `screenIsUnlocked` distributed notifications.

**Rest UI** is `RestWindowController`: borderless `.screenSaver`-level `NSWindow`s, one per screen when `restOnAllScreens`. Two ordering quirks are load-bearing and commented in place — each window needs an explicit `setFrame` (the `screen:` init arg is only a backing-scale hint), and only the *first* window may `makeKeyAndOrderFront`; the rest use `orderFrontRegardless` or they cancel each other out. A `RestPalette` is chosen once per rest so all displays match.

**Stats** are a two-layer write path. `IntervalManager` calls `stats?.addWork/addRest` every tick, but `StatsRecorder` only buffers those in memory and writes to SwiftData on phase transitions, rest completion, day rollover, Statistics-window open, and app termination (`AppDelegate.onWillTerminate → manager.flushStats()`). Anything that *reads* stats must `flush()` first or it will miss the current session — `snapshot(for:)` and `allTimeTotals()` already do. Days are keyed by a `yyyy-MM-dd` local-time string (`DayKey`) with a `@Attribute(.unique)` constraint, and `rolloverIfNeeded()` flushes pending deltas to the *previous* day before switching keys at midnight.

**Settings** (`IntervalSettings.shared`) is `@Observable` over `UserDefaults`, with defaults supplied via `register(defaults:)` and persisted in each property's `didSet`.

## Conventions

- `@MainActor` is applied at the type level throughout; notification/timer callbacks re-enter it with `MainActor.assumeIsolated { }`. Stored properties read from a `deinit` (which is nonisolated) need `nonisolated(unsafe)`.
- `MenuBarContent` deliberately does not read `manager.displayRemaining` — that changes every second and would rebuild the dropdown on every tick, making it flicker and swallow clicks. Only `MenuBarLabel` reads it. Keep new menu items free of per-tick state.
- Comments in this codebase explain *why* a non-obvious workaround exists (AppKit ordering bugs, sandbox constraints, timing edge cases). Match that: skip narration of what the code plainly does.
