<!--
    lxr-multicharacter — LXRCore character selection & creation
    Developer: iBoss21 / LXRCore · https://www.lxrcore.com
    © 2026 iBoss21 / LXRCore | lxrcore.com | All Rights Reserved
-->

<img src="https://raw.githubusercontent.com/LXRCore/.github/main/profile/lxrcore-logo.png" alt="LXRCore" width="72" align="left" style="margin-right:12px">

# lxr-multicharacter — Character selection for LXRCore v3

![Version](https://img.shields.io/badge/version-2.0.0-c4a574)
![Core](https://img.shields.io/badge/requires-lxr--core_v3-1a1512)
![NUI](https://img.shields.io/badge/NUI-vanilla_%C2%B7_no_CDN-brightgreen)
![Platform](https://img.shields.io/badge/platform-RedM-100e0c)

The first screen a player sees: list characters, preview their appearance,
create a new one, delete, or leave. Version 2 is a rewrite on the LXRCore v3
API — the previous NUI posted to a wrong resource name and loaded jQuery /
Materialize from CDNs, so it could not work.

## Character & life experience (traits)

Creation is a three-step personal file: identity → **character & life experience** (advantages / disadvantages with a point balance, 2–4 advantages, ≤ 12 traits, conflicts, linked flaws, seven ready-made fates) → **skills & experience** (leftover balance becomes starting skill levels). Everything is validated on the server before `Player.Login`; the result lives in `players.metadata.traits` and is published as the `traits` state bag plus `GetTraits / HasTrait / GetModifier` exports. Definitions are data in `config_traits.lua`; see [docs/TRAITS.md](docs/TRAITS.md) and [docs/API.md](docs/API.md). `lua tests/run.lua` covers the engine, presets and locale coverage.

## What it does

| | |
|---|---|
| **Server-authoritative** | slot limit, name / birth-date / gender / nationality rules, blocked words, create cooldown and ownership are all checked on the server; the client only relays |
| **Slots** | default from `Config.Characters.default` (or lxr-core `Config.Player.maxCharacters`), per-license overrides, ACE bonus slots |
| **Preview** | character ped with stored appearance (`lxr-clothing` exports when present), default model otherwise |
| **Hand-off** | after load: `lxr-spawn:client:setupSpawnUI(cData, isNew)`; new characters also get `lxr-clothing:client:newPlayer` and starter items from `LXRShared.StarterItems` |
| **Performance** | one `Wait(250)` poll until the session starts, a per-frame loop only while the scene is open, nothing afterwards |
| **Localised** | English + Georgian; the NUI receives the same bundle |
| **NUI** | vanilla HTML/CSS/JS, LXRCore design tokens, Georgian-safe font stack, ESC closes modals, logo shipped in `html/img/` |

## Install

```cfg
ensure lxr-core
ensure lxr-inventory
ensure lxr-multicharacter
ensure lxr-spawn
```
No SQL: characters live in lxr-core's `players` table. Appearance preview reads
`playerskins` when `lxr-clothing` is running.

## Events & API

| Name | Side | Purpose |
|---|---|---|
| `lxr-multicharacter:client:open` | client | open the selection scene (`chooseChar` kept as alias) |
| `lxr-multicharacter:client:closeUI` | client | close it (`closeNUI` alias) |
| `lxr-multicharacter:client:refresh` | client | reload the list |
| `lxr-multicharacter:server:select(citizenid)` | net | load a character |
| `lxr-multicharacter:server:create(data)` | net | create (validated) |
| `lxr-multicharacter:server:delete(citizenid)` | net | delete (ownership enforced) |
| `lxr-multicharacter:server:disconnect` | net | leave |
| `exports['lxr-multicharacter']:GetMaxCharacters(src)` | server | slot count for a player |
| `/logout` (admin), `/closemulti` | commands | |

## Verification

| Check | Result |
|---|---|
| Lua syntax (`luac -p`), JS syntax (`node --check`) | ✅ |
| NUI rendered in a browser with mock data: list, detail, Georgian names, create modal, validation, ESC | ✅ |
| In-game flow (scene camera, preview ped, login hand-off) | **NOT TESTED** yet |

> © 2026 iBoss21 / LXRCore | [lxrcore.com](https://www.lxrcore.com) | All Rights Reserved
