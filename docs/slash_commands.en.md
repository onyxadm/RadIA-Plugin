# Rad IA Slash Commands

Rad IA supports quick command shortcuts directly in the chat interface, enabling developers to run common tasks without typing long prompts or using the mouse.

---

## How to Use

Simply type the `/` character in the chat input area. A floating popup menu will appear below the input field, allowing you to select a command using the `↑`/`↓` arrow keys and press `Enter` to insert it.

---

## Available Commands

| Command | Description | Automatic IDE Context |
| :--- | :--- | :--- |
| `/explain` | Analyzes and explains the logic of the selected code block in the editor. | Sends the selected code snippet. |
| `/refactor` | Optimizes performance, readability, and applies SOLID/Clean Code best practices. | Sends the selected code snippet. |
| `/bugs` | Scans selected code for memory leaks, unhandled exceptions, and logic bugs. | Sends the selected code snippet. |
| `/doc` | Generates Delphi-compliant XML help documentation tags (`/// <summary>`) above methods. | Sends the selected method signature. |
| `/template` | Opens the quick prompt template library selector. | — |
| `/stacktrace` | Analyzes exception logs (MadExcept, EurekaLog, or RTL) and points to the root cause. | Sends the active unit file from the editor as context for the error line number. |
| `/review` | Runs a comprehensive static analysis of the active unit looking for leaks and anti-patterns. | Sends the full source code of the active editor file. |
| `/sqloptimize` | Analyzes and optimizes the selected SQL query, suggesting indexes, syntax corrections, and performance improvements. | Sends the selected SQL query string. |
| `/createproject` | Generates a complete vanilla Delphi project on disk and loads it in the IDE based on text specs. | — |
| `/createprojectarch` | Generates a Clean Architecture (SOLID) Delphi project on disk and loads it in the IDE. | — |

---

## Customization and Command Backups

Rad IA allows you to edit, delete, or add new commands and prompt templates directly from the plugin options inside the IDE (`Tools -> Options -> Rad IA -> Templates`).

Each template registry can define:
- **Slash Command**: The command string that triggers the template in chat (e.g., `/explain`).
- **Is Project Generator**: A boolean marking if the template produces executable files on disk.
- **Import/Export**: Export your templates to JSON files and import them on other machines transactionally, with options to Merge with existing templates or completely Overwrite them.

