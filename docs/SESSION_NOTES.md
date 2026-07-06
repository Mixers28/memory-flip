# Session Notes – Session Log

> Rolling log of what happened each session. Append-only — do not delete past entries.
> Roll stable decisions up into PROJECT_CONTEXT.md; roll active tasks up into NOW.md.

<!-- SUMMARY_START -->
**Latest Summary:**
- Set up docs/ session-handoff files (this repo previously had no docs/ folder).
- Adopted the doc pattern from local-mcp-context-kit (PROJECT_CONTEXT / NOW / SESSION_NOTES) without its CLI tooling — plain markdown, updated manually each session.
- Added synthesized sound feedback across all 6 game modes: per-tile tones for Colour Patterns (Simon-style), shared success/failure chimes for the rest.
- Added Marathon rules onboarding (intro overlay + rules text on handoffs) after beta tester confusion; headless-verified a full lap's overlay copy reads correctly. Nothing played live yet — this environment can't drive simulator taps.
<!-- SUMMARY_END -->

---

## Session Template (copy/paste for each new session)

### [DATE]

**Branch:**

### What we worked on
-

### Files touched
-

### Outcomes / Decisions
-

---

## Recent Sessions

### 2026-07-06

**Branch:** ios-app

### What we worked on
- Reviewed `local-mcp-context-kit` (already cloned locally under `Local Kit/`) to reuse its context-doc pattern.
- Created `docs/PROJECT_CONTEXT.md`, `docs/NOW.md`, `docs/SESSION_NOTES.md` in this repo — docs only, no handoffkit CLI, no guardrail hooks/tests from that repo.
- Seeded PROJECT_CONTEXT with the existing game-mode architecture and verification-harness constraints (previously only recorded in Claude's own memory files, not in the repo).

### Files touched
- docs/PROJECT_CONTEXT.md (new)
- docs/NOW.md (new)
- docs/SESSION_NOTES.md (new)

### Outcomes / Decisions
- These three files are maintained manually (updated at the end of a session, read at the start of the next) — no automation/hooks wired up yet.

---

### 2026-07-06 (Sound feedback)

**Branch:** ios-app

### What we worked on
- Reviewed `PatternBoardView.swift`/`GameModel.swift` for the Colour Patterns (Simon-style) mode — confirmed there was no sound anywhere in the app.
- Added `MemoryFlip/GameSoundPlayer.swift`: a single `AVAudioEngine`-backed player that synthesizes tones in-memory (no bundled audio assets) — one distinct pitch per Colour Patterns tile, plus a shared two-note success chime and a low failure buzz.
- Wired `playTile` into `GameModel.flashTile` (fires for both sequence playback and player taps).
- Wired `playSuccess`/`playFailure` into the correct/wrong-tap branches of the other 5 modes: Card Match (`flipCard`), Grid Flash (`tapFlashCell`), Number Order (`tapNumberCell`), Odd One Out (`tapOddCell` + timeout), Colour Stroop (`tapStroopOption` + timeout).
- Registered the new file in `MemoryFlip.xcodeproj/project.pbxproj` (4 manual edits: PBXBuildFile, PBXFileReference, group children, PBXSourcesBuildPhase — this project isn't using Xcode's file-system-synchronized groups).
- Confirmed `AVFoundation` needs no explicit linking here — the project has zero explicit framework entries in `PBXFrameworksBuildPhase` even for SwiftUI/Combine, and `xcodebuild` still links fine (modern SDK auto-linking via `import`).

### Files touched
- MemoryFlip/GameSoundPlayer.swift (new)
- MemoryFlip/GameModel.swift
- MemoryFlip.xcodeproj/project.pbxproj

### Outcomes / Decisions
- `xcodebuild -project MemoryFlip.xcodeproj -scheme PairFlip -sdk iphonesimulator -destination "id=<UDID>"` succeeded after each change.
- Not played live in the simulator — this environment can't drive simulator UI taps (see [[pairflip-verification]]), so the actual feel of the tones (pitch/volume/duration choices) is unverified by ear. Flagged in NOW.md as the next thing to check.
- **Bug found on user playtest:** `playBackSequence()` (the part that demos the sequence to memorise) set `litTile` directly instead of calling `flashTile()`, so the demo played silently — sound only fired when the user repeated the sequence. Fixed by calling `GameSoundPlayer.shared.playTile(tile)` alongside the `litTile` assignment in the playback loop, so tone+colour now start together on both the demo and the repeat.

---

### 2026-07-06 (Marathon rules onboarding)

**Branch:** ios-app

### What we worked on
- Beta tester feedback: unclear on the rules when playing Marathon (games rotate automatically with no explanation, and the very first mode starts with zero context).
- Added `GamePhase.rules` (one-line "how to play" per mode) — single source of truth, also swapped into `MenuView`'s practice-mode subtitles (previously hardcoded duplicate strings).
- Added `GameModel.isMarathonIntro` + `dismissMarathonIntro()`: marathon runs now hold on a new `MarathonIntroOverlay` (explains the marathon concept + first mode's rules) before `startLevel()` ever runs — added `!isMarathonIntro` guards to all 6 tap handlers plus the Odd One Out / Stroop round-timeout closures so no input/timeout can fire while it's showing.
- Extended the existing `HandoffOverlay` (shown between every subsequent mode swap) to also show the next mode's rules line, plus a "Miss and the run ends" warning for modes where `canFailRun` is true.

### Files touched
- MemoryFlip/GameModel.swift
- MemoryFlip/MenuView.swift
- MemoryFlip/WinOverlayView.swift (new `MarathonIntroOverlay`, `HandoffOverlay` rules line)
- MemoryFlip/GameBoardView.swift (renders the new overlay)

### Outcomes / Decisions
- `xcodebuild` succeeded. Verified the intro-gating logic itself with the headless harness (compiled `GameModel.swift` + a local `GameSoundPlayer` stub, since `AVAudioSession` is iOS-only and can't compile for a macOS harness binary): confirmed `isMarathonIntro` starts `true` with an empty board, a tap during intro is ignored, and `dismissMarathonIntro()` is what actually calls `startLevel()`.
- Not played live in the simulator (can't drive UI taps here) — worth a playtest to confirm the new overlay's copy/pacing feels right and doesn't slow down repeat marathon runs too much.

---

### 2026-07-06 (Full-lap headless playtest — copy review)

**Branch:** ios-app

### What we worked on
- User asked to "playtest a full marathon run and check the copy." Since simulator taps can't be driven here, extended the harness approach: wrote solver functions that play each of the 6 modes correctly using the model's own internal state (e.g. reading `patternSequence`, `flashLitCells`, `numberAtCell`, `oddIndex`, `stroopInkIndex` and tapping the right answers), pumping `RunLoop.main` to advance the same `DispatchQueue.main.asyncAfter` timers the real UI depends on (playback, reveal/hide, mid-segment re-deal delays).
- Drove a full marathon lap (all 6 modes, zero mistakes) through the real `GameModel` and printed the exact copy each overlay would show at every mode transition, using the same computed properties the SwiftUI views read (`nextMarathonMode`, `willCompleteLapNext`, `canFailRun`, `GamePhase.rules`).

### Files touched
- No app files changed this entry — harness-only (scratchpad), used to validate copy from the previous session's Marathon-onboarding work.

### Outcomes / Decisions
- Copy confirmed correct end-to-end: intro overlay, all 5 mid-lap handoffs (mode-cleared + run total + up-next name/rules + fail warning, correctly omitted for Card Match), and the "Lap 1 complete — speeding up!" line on the 6th→1st wrap.
- Not yet reviewed: `RunOverOverlay` copy in context (no mistake occurred in this perfect run) — flagged as a follow-up in NOW.md.
- This full-lap harness pattern (solver functions per mode + `RunLoop` pumping) is reusable for future gameplay-logic or copy verification — worth remembering if asked to "playtest" again.
