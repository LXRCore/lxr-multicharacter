# Changelog — lxr-multicharacter

## 3.0.0 — 2026-09-17

### Added
- **Character & life experience** step in character creation: advantages / disadvantages with a
  point balance (start at 0, disadvantages give, advantages spend), 2–4 advantages, ≤ 12 traits,
  conflicts, linked disadvantages, ready-made fates with flavour text, intro rules modal.
- **Skills & experience** tab: leftover balance becomes starting skill levels (XP via lxr-core).
- `config_traits.lua` — 16 advantages, 16 disadvantages, 7 presets, all data-driven.
- Shared trait engine (`shared/traits.lua`) used by the server for validation and modifier folding.
- Persistence in `players.metadata.traits`; inventory slots / weight and starting XP applied on lock.
- Replicated `traits` state bag + server/client exports (`GetTraits`, `HasTrait`, `GetModifier`).
- Client effects module: `move_rate` applied natively; `traitsApplied` event for other resources.
- Standalone trait prompt for characters created before this resource; `/traits`, `/retrait`, `/resettraits`.
- Trait chips on the character card; preview-ped rotation arrows on the trait screen.
- Georgian locale on the kit's Noto Sans Georgian, never uppercased or tracked.

### Changed
- Creation payload is now `{ identity, traits }`; identity **and** traits are validated before `Player.Login`.
- NUI rebuilt around the "personal file" flow on the LXR UI Kit (inks, single blood accent, radius 0, Fraunces / Inter / JetBrains Mono / Noto Sans Georgian shipped locally).

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
