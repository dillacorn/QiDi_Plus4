# Repository instructions for QiDi Plus4

Applies to the printer configuration, documentation, scripts, test G-code, and Orca Slicer profiles in this repository.

## Printer and configuration safety

- The repository holds QiDi Plus4-specific Orca Slicer profiles, QiDi Box/AMS workflows, Fluidd/Klipper printer and macro adjustments, sample print files, and optional host tuning. These are repository files, **not proof of the currently running printer firmware or live configuration**.
- Inspect the applicable files and current printer/firmware state before proposing machine-specific commands. Preserve user-tuned offsets, bed calibration, hardware assumptions, temperature/current limits, and installed configuration. Do not copy a documented calibration value to another machine as if it were universally correct.
- Preserve the distinct `AMS MANAGED`, `AMS DIRECT`, and `EXTERNAL SPOOL` filament flows. Never bypass the documented external-spool/QiDi Box synchronized-slot guard or assume pulling filament from the extruder has reset the Box state.
- Changes to heaters, motors, G-code safety checks, startup/shutdown macros, filament loading/unloading, or Z-offset can affect physical hardware. Clearly separate source edits, offline validation, printer configuration deployment, and executing live motions/heating. Confirm safety and obtain explicit approval for live or potentially damaging actions.
- `plus4-optional-tuning.sh` must retain reversible user-chosen changes. Do not disable the stock screen stack, Obico, webcam functions, Klipper/Moonraker, or unrelated host services merely to optimize performance; keep Obico available and prefer tuning/capping optional load where needed.
- Never publish secrets, Moonraker API tokens, Wi-Fi credentials, private device addresses, or complete private printer configuration dumps.

## Merge and release authorization

Operate autonomously within the user's approved scope. Do not add unnecessary repeat-approval checkpoints.

- Investigating, implementing, fixing, testing, committing scoped work to a feature branch, or preparing an ordinary review PR does **not** by itself authorize merging to the default branch, creating a tag, publishing a GitHub Release, distributing a build, or deploying to devices.
- An explicit instruction to merge, apply directly to `main`, tag, or release authorizes that named operation for the specified work. An approved release includes the necessary scoped merge unless the user specifies another target or restriction. Do not demand another approval for already-authorized steps.
- Authorization for an **unfinished** merge or release survives related small fixes, revisions, and testing pauses. If the user interrupts an approved release to correct something, "good to go", "working, continue", or a similarly clear signal may resume that same pending release without asking for the original approval again.
- Respect "wait", "hold off", and cancellations. A pause stops delivery until the user clearly resumes; cancellation withdraws approval. Materially different work, a changed release target, or an altered version beyond what was authorized requires renewed authorization.
- Approval is **single-use**: after the authorized merge/release finishes, it does not authorize another merge or release, including a follow-up patch. Positive feedback alone ("perfect", "that works") cannot start a new delivery operation when none is pending.
- The user may approve a merge or release without personally testing it. Run the available relevant static/automated checks, report meaningful failures, and distinguish automated validation from unperformed real-device/runtime tests. Do not impose user testing as an extra requirement if the user explicitly elects to proceed.
- Drafting release notes, suggesting a version, or preparing a branch/PR is not publication. Publishing workflows, temporary GitHub Actions release bridges, Git tags, Releases, uploads, and external release artifacts require the active authorization for that exact publication.
- Never equate approval for a GitHub Release with approval for unrelated distribution, production deployment, hardware changes, destructive data operations, credential exposure, or external-provider settings.

## Validation and delivery

- Validate Bash scripts with `bash -n` (and ShellCheck if available), review G-code/Klipper macro syntax and the matching printer/firmware semantics, and check that slicer profile references agree with documented source modes.
- Offline checks cannot establish that a print, tool change, purge, or physical calibration is safe on a live Plus4. State required controlled hardware tests honestly.
- A GitHub commit or release does not update the printer's Fluidd files, slicer configuration, or firmware. Treat actual deployment as separate from publication.
