# Adobe Script Creator

Describe an Adobe script in chat. Choose a save folder the first time you use each app. Future scripts for that app go to the same folder.

## Install the skill

1. Download this repository using **Code > Download ZIP**, then extract it to a normal folder. You can also clone the repository with Git.
2. Copy the entire `adobe-jsx` folder into your personal Codex `skills` folder. The usual Windows location is `%USERPROFILE%\.codex\skills\adobe-jsx`. If you use a custom `CODEX_HOME`, use its `skills` folder. If an older copy exists, back it up before replacing it.
3. Open a new chat in Codex and invoke `$adobe-jsx`. If the skill is not listed, restart Codex and try a new chat.

This package includes a Codex skill and Windows PowerShell helpers, not an Adobe plug-in. Photoshop, Illustrator, or After Effects must be installed to run the corresponding JSX. Other AI tools can read the instructions, but automatic skill discovery and filesystem access depend on that tool.

## What's included

```text
adobe-jsx/
  SKILL.md                 Instructions for the AI assistant
  agents/openai.yaml       Skill name and starter prompt
  scripts/save-script.ps1  Save, verify, back up, and remember locations
  scripts/adobe-scripts.ps1  Discover Adobe script folders / install JSX
  samples/                 Photoshop, Illustrator, and After Effects examples
```

The PowerShell helpers use built-in Windows functionality and do not require installing additional packages. Keep the whole skill folder together when installing it.

## First script

Example prompt:

> $adobe-jsx Photoshop: create a script that runs Select Subject and adds a mask to every selected image layer.

You will be asked where to save Photoshop scripts. Reply with either a full folder path or **"Use Photoshop's Scripts folder."** Choose a folder inside your chat's workspace for the easiest file access.

- **Your folder:** find the JSX there and run it using the app's Browse/Run Script File command.
- **Adobe's Scripts folder:** the file is placed in the app's menu folder. Windows may require administrator permission. A restart may be necessary before a new menu entry appears.

The helper remembers the location separately for each app in `$CODEX_HOME/adobe-jsx/settings.json`, normally `%USERPROFILE%\.codex\adobe-jsx\settings.json`. Personal settings are not included in this ZIP. Filesystem permissions can still require approval; remembering a folder does not grant additional permissions.

To change a destination later, say: **"Use [new full folder path] for my Photoshop scripts from now on."**

## Try the included samples

| Sample | Result |
| --- | --- |
| `samples/photoshop/Hello_Photoshop.jsx` | Displays the version and document count; changes nothing. Start here to check file execution. |
| `samples/photoshop/Mask_Subjects_Selected_Layers.jsx` | Select Subject + layer mask for each selected image layer/Smart Object. Skips existing masks, locked layers, and non-image layers. |
| `samples/illustrator/Create_Color_Palette.jsx` | Creates a new document with five editable color swatches. |
| `samples/after-effects/Create_Animated_Title.jsx` | Creates a five-second portrait composition with an editable animated title. |

Sample paths are relative to the `adobe-jsx` folder. Run them directly or ask the skill to copy a sample to your chosen save folder. The samples are supplied as code examples; verify their output in your installed Adobe version before using them in production. Creating or saving a script does not automatically run it on your document.

| App | Run a JSX from any folder |
| --- | --- |
| Photoshop | File > Scripts > Browse |
| Illustrator | File > Scripts > Other Script |
| After Effects | File > Scripts > Run Script File |

## More example requests

> $adobe-jsx Photoshop: rename selected layers with a prefix I enter.

> $adobe-jsx Illustrator: create an editable five-color palette in a new document.

> $adobe-jsx After Effects: create a vertical title animation with editable text.

## If a file cannot be saved

The assistant should keep the completed JSX in its staging folder and give you the exact path. You can run that file directly, manually copy it to Adobe's Scripts folder, or choose another destination. Do not change Windows folder permissions or disable security settings just to install a script.

The workflow was checked for saved-location reuse, per-app destinations, backups, and file verification. Adobe sample execution must be checked in the actual apps; a syntax check alone does not establish compatibility.
