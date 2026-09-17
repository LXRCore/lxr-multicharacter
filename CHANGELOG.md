# Changelog — lxr-multicharacter

## [2.0.0] — 2026-09-17

Rewrite for LXRCore v3.

### Added
- Server-side validation of every creation field, blocked-word list, create cooldown, slot limits (default / per-license / ACE bonus).
- Ownership checks before select and delete; exploit attempts logged through lxr-core.
- Appearance preview through lxr-clothing exports with default-model fallback.
- Georgian locale, NUI locale bundle, `GetMaxCharacters` export.

### Changed
- Uses the core object (`GetCoreObject`, `LXRCore.Callback`, `LXRCore.Player.GetCharacters`) instead of raw SQL.
- NUI rewritten in vanilla HTML/CSS/JS with LXRCore design tokens (previous UI posted to `qbr-multicharacter` and loaded jQuery/Materialize from CDNs).
- No per-frame loop after the scene closes.

### Removed
- Housing / apartment hooks, `houselocations` query, dead code from the QBR fork.
