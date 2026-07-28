# Feedback log

Append-only, value-free correction records. Supersede or retire an entry by appending a new record that references its ID.

- 2026-07-28 | communication/name-frequency | Douglas asked agents to stop beginning every message with his name. Use his name sparingly, when it adds clarity or warmth; routine updates should begin with the result or action.
- 2026-07-28 | process-safety/codex-renderers | An agent stopped low-memory `ChatGPT.exe` renderer children under the active `OpenAI.Codex` host, which closed the app. Renderer IDs and resource use do not identify task ownership. Never terminate individual renderer or utility children in the active Codex tree; limit cleanup to proven detached CLI/helpers, and require explicit confirmation before a whole-app restart.
