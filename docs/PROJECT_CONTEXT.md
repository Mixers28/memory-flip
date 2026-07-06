# Project Context – Long-Term Memory

> High-level design, tech decisions, and constraints for this project.
> This is the source of truth for what the app *is* — session-to-session churn belongs in `NOW.md` / `SESSION_NOTES.md`.

<!-- SUMMARY_START -->
**Summary:**
- PairFlip (repo: Memory_Flip) is a card-flip memory game — a static HTML/JS web version and a native SwiftUI iOS app, both in this one repo.
- iOS app lives on the `ios-app` branch; work happens there, not `main`.
- iOS architecture: one `GameModel: ObservableObject` coordinator drives 6 game modes (`GamePhase`: cards, pattern, gridFlash, numberOrder, oddOneOut, stroop) plus a Marathon mode that rotates through all six with carried score.
- Game logic is deliberately SwiftUI-free (`GameModel.swift`) so it can be verified headlessly with a compiled harness — the simulator UI cannot be driven programmatically in this environment.
<!-- SUMMARY_END -->

---

## 1. Project Overview

- **Name:** PairFlip (originally "Memory Flip")
- **Repo:** Memory_Flip
- **Purpose:** Card-flip memory game, playable as a browser app (`memory-game.html`) and a native iOS app (`MemoryFlip.xcodeproj`).
- **Primary Stack:** Vanilla HTML/CSS/JS (web); Swift/SwiftUI (iOS, iOS 16+).
- **Branches:** `main` = mostly the web version's history; `ios-app` = active iOS development branch (current default working branch).

---

## 2. iOS Architecture Snapshot

- Single `GameModel: ObservableObject` coordinator — not separate observables per mode, to avoid manual `objectWillChange` forwarding.
- `GamePhase` enum: `cards, pattern, gridFlash, numberOrder, oddOneOut, stroop`, each with `title`/`icon`/`canFailRun`.
- Two launch styles via `GameStart`: `.practice(GamePhase)` (one mode, endless) and `.marathon` (rotates `marathonOrder` = all six modes, score carrying). `GameBoardView(start:)` builds the model.
- **The seam:** every mode's round-completion calls one private `roundCleared()`, which decides: marathon + segment target reached → `isSegmentCleared` (handoff overlay → `advanceMarathon()` → next mode, wrap = `lap++`); otherwise `continueCurrentMode()`. Practice cards uses the level-clear overlay; fail-state modes auto-advance after a short delay.
- Difficulty is per-mode and persists across marathon laps via `modeLevel: [GamePhase: Int]` (computed `level` reads the current phase's entry) — so a mode resumes harder each lap, not a flat per-lap step. `stage` is the cumulative cleared-count feeding the `bestLevel` record.
- Async safety: `transitionGeneration` is bumped on every level/run reset; all `asyncAfter` closures (playback, auto-advance, timeouts) capture and re-check it so stale closures no-op. Fail-state modes also use a per-round `solved` flag so a solve cancels its pending timeout.
- Each mode = one `GameModel+<mode>` logic block + one `<Mode>BoardView.swift`.

## 3. Verification Constraints

- Compile the real model against a throwaway harness: `swiftc MemoryFlip/GameModel.swift main.swift -o harness` (harness top-level code must live in a file named `main.swift`). Drive the model directly and pump async work with `RunLoop.main.run(until:)`.
- The harness binary has its own UserDefaults domain that *persists across runs* — reset `bestLevel`/`highScore` at the top of the harness, or `defaults delete "$(pwd)/harness"`.
- Build with `xcodebuild -project MemoryFlip.xcodeproj -scheme PairFlip -sdk iphonesimulator -destination "id=<UDID>"`. Adding a new `.swift` file requires 4 manual edits to `project.pbxproj` (explicit, non-synchronized project — not using the newer file-system-sync format).
- **Hard constraint:** the simulator UI cannot be driven programmatically here (no `cliclick`/`idb`; `osascript`/System Events blocked by assistive-access). `simctl io screenshot` works for viewing only. New mode UIs are logic-verified via the harness, not visually — to reach a deep state quickly, temporarily lower relevant caps/targets, then restore.

---

## 4. Change Log (High-Level Decisions)

- `2026-07-06` – Set up docs/ session-handoff files (this doc, NOW.md, SESSION_NOTES.md), modeled on the local-mcp-context-kit doc pattern (docs only, no CLI tooling adopted).
- Rebranded app from "Memory Flip" to "PairFlip".
- Added level progression, lives system, and scoring (gamification pass), then later removed the lives system.
- Added 5 new game modes + Marathon loop.
- Removed debug hooks; added Ko-fi support link on game-over screen.
