# NOW - Working Memory

> Current focus / active sprint. Always describes what we're doing right now.
> Keep to 5–12 active items; move stable decisions into PROJECT_CONTEXT.md, and closed-out sessions into SESSION_NOTES.md.

<!-- SUMMARY_START -->
**Current Focus:**
- Added `GameSoundPlayer` (synthesized, no bundled assets): distinct per-tile tone for Colour Patterns, plus a shared success/failure chime across all 6 modes. Fixed a bug where the Pattern sequence demo played silently (only taps had sound).
- Added Marathon rules onboarding: a new `MarathonIntroOverlay` before the first mode, and rules text + a "miss and the run ends" warning added to the existing between-mode `HandoffOverlay` — in response to beta tester confusion about Marathon's rules.
- Headless-harness-verified a full marathon lap (all 6 modes, no mistakes): every overlay's copy is correct and reads well — mode-cleared text, run total, up-next name+rules, fail warning (correctly absent for Card Match), and the lap-complete line on the 6th→1st wrap. Not yet checked: `RunOverOverlay` copy (the loss screen) in context — no mistake was made in the test run.
- `xcodebuild` (iphonesimulator) green after all of the above; nothing has been manually played on-screen (UI taps can't be automated here — see [[pairflip-verification]] in Claude's memory) — all verification so far is build + headless harness.
- `MemoryFlip.xcodeproj/project.pbxproj` still carries an unexplained modification from before this session's work — needs review before next commit.
<!-- SUMMARY_END -->

---

## Active Branch

- `ios-app`

---

## What We Are Working On Right Now

- [x] Add per-tile tones to Colour Patterns mode (`GameSoundPlayer.playTile`), fix silent sequence-demo bug.
- [x] Add shared success/failure feedback chimes to the other 5 modes.
- [x] Add Marathon intro overlay (rules + concept) and extend the handoff overlay with per-mode rules text.
- [x] Headless-verify a full marathon lap's overlay copy (see summary above) — copy reads correctly.
- [ ] Check `RunOverOverlay` copy on an actual loss (deliberately fail a round) — not yet reviewed.
- [ ] Have the user physically play a Marathon run on device/simulator to confirm the sounds feel right and the copy/pacing feels good in real use, not just on paper.
- [ ] Review the pre-existing uncommitted change to `MemoryFlip.xcodeproj/project.pbxproj` (present at session start, separate from the pbxproj edits made to register `GameSoundPlayer.swift`).

---

## Next Small Deliverables

- Get user feedback on the sound feel (frequencies/durations are first-pass guesses, easy to retune in `GameSoundPlayer.swift`).
- Get user feedback on the Marathon intro/handoff wording — consider whether repeat players will want a "skip intro" option if it becomes annoying on every run.
- Decide if the original pbxproj diff (pre-dating this session) is intentional or should be reverted.

---

## Notes / Scratchpad

- If this file grows past ~12 items, move finished details into SESSION_NOTES.md and keep only what's active here.
