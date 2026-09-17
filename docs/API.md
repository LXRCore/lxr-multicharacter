# 🐺 lxr-multicharacter — API

## Server exports

```lua
-- Max character slots for a player (config default / licence override / ace bonus)
exports['lxr-multicharacter']:GetMaxCharacters(src) --> integer

-- Full trait record from metadata (nil if none). See TRAITS.md → Storage format
exports['lxr-multicharacter']:GetTraits(src) --> table|nil

-- true when the loaded character has that advantage or disadvantage locked
exports['lxr-multicharacter']:HasTrait(src, 'frail_build') --> boolean

-- Summed modifier; `default` is returned when the player has no traits or the key is absent
exports['lxr-multicharacter']:GetModifier(src, 'craft_speed_mult', 1.0) --> number|boolean

-- Localised definitions, rules, presets and skills — what the NUI receives
exports['lxr-multicharacter']:GetTraitDefinitions() --> table
```

## Client exports

```lua
exports['lxr-multicharacter']:GetTraits()                         --> { perks, flaws, mods } | nil
exports['lxr-multicharacter']:HasTrait('light_step')              --> boolean
exports['lxr-multicharacter']:GetModifier('aim_sway_mult', 1.0)   --> value | default
```

## State bag

After a character loads, the server sets a **replicated** player state bag:

```lua
Player(src).state.traits   -- server side
LocalPlayer.state.traits   -- client side: { perks = {...}, flaws = {...}, mods = {...} } or nil
```

Any client resource can react with `AddStateBagChangeHandler('traits', nil, fn)`.

## Events

### Server → listen

| Event | Args | When |
|---|---|---|
| `lxr-multicharacter:server:traitsLocked` | `src, citizenid, record` | Traits were locked (creation, legacy prompt, retrait) |

### Client → listen

| Event | Args | When |
|---|---|---|
| `lxr-multicharacter:client:traitsApplied` | `mods, perks, flaws` | Modifiers are (re)applied on this client; `mods = nil` on unload / reset |
| `lxr-multicharacter:client:traitsLocked` | `perks, flaws, mods` | Right after locking |
| `lxr-multicharacter:client:traitsReset` | — | After `/resettraits` or `/retrait` |
| `Config.Integrations.afterSelect / afterCreate` | `cData, isNew` | Hand-off (default `lxr-spawn:client:setupSpawnUI`); `cData.traits` carries the record |

### Client → trigger

| Event | Purpose |
|---|---|
| `lxr-multicharacter:client:open` | Open the selection scene (used by `/logout`) |
| `lxr-multicharacter:client:closeUI` | Force-close the scene |
| `lxr-multicharacter:client:openTraits` (`traitsPayload, localeBundle`) | Open the standalone trait screen — normally triggered by the server |

### Net events the NUI flow uses (server side, rate limited)

`lxr-multicharacter:server:select` · `:create` · `:delete` · `:disconnect` · `:lockTraits`
Callbacks: `lxr-multicharacter:server:characters` · `:appearance`

All of them validate ownership / rules server-side; a client can not select or delete a character it does not own, lock traits twice, exceed the budget, or bypass conflicts.

## Legacy names still honoured

`lxr-multicharacter:client:chooseChar` (= open) · `lxr-multicharacter:client:closeNUI` (= closeUI)

---
© 2026 iBoss21 / LXRCore · lxrcore.com · 🐺 wolves.land
