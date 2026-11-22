---
name: adobe-jsx
description: Create or edit Adobe ExtendScript JSX scripts for Photoshop, Illustrator, or After Effects. Ask for a save folder once per app, remember it, and save future scripts there, including directly into the Adobe Scripts folder when chosen.
---

# Adobe JSX

Write the requested Adobe `.jsx` and save it to the user's preferred location. Keep the interaction simple: app + desired behavior, then a single location question on first use for that app. Do not introduce a connector, background service, or script runner.

## First use and remembered folders

1. Identify Photoshop/PS, Illustrator/AI, or After Effects/AE from the request or conversation. Ask which app only if unclear. JSX here means Adobe ExtendScript, not React.
2. Read the remembered destinations with `scripts/save-script.ps1 -ShowSettings`. Settings belong to the current user, outside this shareable skill folder. Never use the package author's personal paths as defaults.
3. If this app has no saved destination, ask exactly one location question: **"Where should I save your [app] scripts? Give me a folder path, or choose the app's Scripts folder to have them appear in its menu."** Offer a folder inside the current writable workspace as the recommended custom location. Discover installed menu folders using `scripts/adobe-scripts.ps1 -List`; list concrete candidates when several versions/locales exist. Do not choose an app version or locale arbitrarily when the user is choosing the destination.
4. Build and check the requested script in a writable staging folder while waiting if useful. Once the user selects a destination, pass that exact folder to `save-script.ps1 -App <app> -Source <file> -Destination <folder>`. The helper creates the folder if needed, backs up changed existing JSX, copies and checks its hash, then remembers the folder only after successful saving.
5. On later requests, omit `-Destination`. Do not ask again. If the user asks to change location, pass the new destination explicitly. If a remembered folder is missing, recreate that same folder when possible. If unavailable or denied, retain the finished staging copy and report the failure; ask for a replacement destination only when needed to resolve that failure. Never silently switch destinations.

Use `AfterEffects` as the helper's app identifier. The config defaults to `$CODEX_HOME/adobe-jsx/settings.json`, or `~/.codex/adobe-jsx/settings.json` if CODEX_HOME is unset. `-SettingsPath` exists for isolated tests. Folder consent does not bypass filesystem tool permissions or Windows administrator requirements. Use normal tool escalation where required. If Windows still denies a protected destination, give the staged file and exact manual-copy destination; do not change ACLs or claim installation succeeded. Saving does not authorize running the script on open documents.

## Authoring

- Use host-compatible ExtendScript, normally ES3 (`var`, functions, loops), and the correct `#target` directive. Use the selected app's actual APIs, not browser, Node, React, or UXP APIs. Verify unfamiliar APIs against Adobe documentation.
- Use a descriptive filename. Keep ordinary scripts scoped in a function; clean up temporary globals if the host needs them for history callbacks.
- Validate required documents, layers/selections, and input files. Handle cancellation. Restore temporary app preferences and visibility in `finally`; group undo where appropriate. Preserve artwork and existing masks unless the requested operation requires changing them.
- Check syntax when possible, excluding ExtendScript directives from ordinary JS parsers. State that a syntax check is not an in-app execution test. Never run a script against the user's document merely to validate it without authorization.
- For After Effects dockable panels, use `Scripts/ScriptUI Panels` only when a panel is requested. Ordinary scripts belong directly in Scripts. Other Adobe apps need their own verified runtime and installation workflow.

## Save and deliver

```powershell
# First save: the user's chosen absolute directory
& '<skill>/scripts/save-script.ps1' -App Photoshop -Source '<staging>/Rename_Layers.jsx' -Destination '<chosen folder>'
# Following saves use the remembered folder
& '<skill>/scripts/save-script.ps1' -App Photoshop -Source '<staging>/Another_Script.jsx'
# Inspect destinations without modifying anything
& '<skill>/scripts/save-script.ps1' -ShowSettings
```

Keep the response short: what the script does, a clickable absolute path, and how to run it. If the chosen directory is an actual Adobe menu folder, say it is installed there, with a restart possibly needed for menu discovery. For custom folders, say **saved**, not **installed in the menu**:

| App | Run a file from any folder |
| --- | --- |
| Photoshop | File > Scripts > Browse |
| Illustrator | File > Scripts > Other Script |
| After Effects | File > Scripts > Run Script File |

Examples live in `samples/`; read only the relevant sample when useful. They are starting points, not a reason to change the user's requested task. `samples/photoshop/Mask_Subjects_Selected_Layers.jsx` implements Select Subject followed by a layer mask on each selected image layer. `samples/photoshop/Hello_Photoshop.jsx` is a check that does not alter documents. Illustrator's palette and After Effects' title samples create new editable content without saving or exporting files.
