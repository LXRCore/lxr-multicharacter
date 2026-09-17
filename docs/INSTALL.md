# 🐺 lxr-multicharacter — Installation & Configuration

## 1. Requirements

| Resource | Required | Notes |
|---|---|---|
| `lxr-core` v3 | ✅ | Provides `Player.Login/GetCharacters/DeleteCharacter`, metadata, XP, callbacks, DB, logging |
| `lxr-clothing` | optional | Appearance preview on the selection scene + creator for new characters (`Config.Integrations.appearance`) |
| `lxr-spawn` | optional | Spawn selection after a character loads (`Config.Integrations.afterSelect / afterCreate`) |

No database migration is needed. Traits are stored inside the existing `players.metadata` JSON column under the key `traits`. Inventory capacity changes are written to the existing `players.slots` / `players.weight` columns.

## 2. Install

1. Drop the folder into your resources as `lxr-multicharacter` (the folder name **must** match — the NUI posts to `https://lxr-multicharacter/…`).
2. Remove any other multicharacter resource (`rsg-multicharacter`, `qb-multicharacter`, an older `lxr-multicharacter`).
3. Add to `server.cfg` **after** `lxr-core`:

```cfg
ensure lxr-core
ensure lxr-multicharacter
ensure lxr-clothing   # optional
ensure lxr-spawn      # optional
```

4. Start the server once and check the console for `lxr-multicharacter v3.0.0 ready`. If a preset in `config_traits.lua` violates the rules you will see `preset "<id>" hidden: <reason>` — fix the preset or accept that it is not offered.

## 3. Configuration — `config.lua`

| Key | Default | Meaning |
|---|---|---|
| `LXRCore.Brand.name / tagline / year` | The Land of Wolves / მგლების მიწა / 1901 | Header text; `year` is the "Personal file · 1901" label |
| `Config.Lang` | `'en'` | `'en'` or `'ka'` — the NUI receives the same bundle |
| `Config.Characters.default` | 5 | Slots per licence (nil → `lxr-core Config.Player.maxCharacters`) |
| `Config.Characters.overrides` | `{}` | `['license:…'] = 8` |
| `Config.Characters.aceSlots` | admin 10 / god 20 | Players with the ace get `max(default, slots)` |
| `Config.Creation.*` | | Name length, Unicode names, birth years (1830–1889 → adult in 1901), blocked words, starter items, create cooldown |
| `Config.TraitFlow.enabled` | true | `false` → classic identity-only creation |
| `Config.TraitFlow.promptExisting` | true | Characters without locked traits get the trait screen ~4 s after login |
| `Config.TraitFlow.allowRetrait` | false | Lets players `/retrait` once per `retraitCooldownDays` |
| `Config.TraitFlow.applyInventory` | true | Writes `slots_mult` / `weight_mult` to `players.slots` / `players.weight` |
| `Config.TraitFlow.applyMoveRate` | true | Client applies `move_rate` with `SetPedMoveRateOverride` |
| `Config.TraitFlow.skills` | enabled, 3 per skill, 6 total, 1 point/level | Skill tab rules. `list = nil` → `lxr-core Config.Player.skills` |
| `Config.Scene.*` | Guarma cliff interior | Player/preview coords, cameras, imaps, light, timecycle, `rotateStep` for the side arrows |
| `Config.Integrations.*` | lxr-clothing / lxr-spawn | Appearance resource + table, hand-off events |
| `Config.Security.rateLimit` | 12 / 10 s | NUI-originated server events per player |
| `Config.Debug` | false | Extra console output on start |

## 4. Configuration — `config_traits.lua`

See [TRAITS.md](TRAITS.md) for the full reference. The essentials:

```lua
ConfigTraits.Rules = { basePoints = 0, minPerks = 2, maxPerks = 4, maxTraits = 12 }

ConfigTraits.Perks[#ConfigTraits.Perks + 1] = {
    id = 'night_owl', category = 'survival', cost = 3, icon = 'eye', effects = 2,
    conflicts = { 'bad_eyes' },          -- cannot be taken together
    requires  = {},                      -- flaws added automatically
    modifiers = { night_vision_mult = 1.3, sleep_need_mult = 0.8 },
}
```

Then add the text to **both** locale files:

```lua
traits = {
    night_owl = { name = 'Night owl', tag = 'Sees better when the sun is down.',
        fx1 = 'Night visibility: +30%', fx2 = 'Needs 20% less sleep' },
}
```

Available icons: `back snow flask compass feather horse target poster crate pickaxe syringe train book outlaw tongue clover bones lungs stomach bandage fist heart knife eye hands cross cuffs cards storm bottle pipe`. Unknown names fall back to a plain circle; add your own in `html/app.js → ICONS`.

## 5. Flow

```
connect → scene opens → list characters
   ├─ select  → server: ownership check → Player.Login → hand-off to lxr-spawn
   ├─ delete  → server: ownership check → Player.DeleteCharacter
   └─ new     → identity form → intro modal → traits → (skills) → LOCK IN
                → server: validate identity → validate traits → Player.Login(new)
                → apply traits (metadata, slots/weight, XP) → starter items → hand-off
login of a character without traits (promptExisting) → standalone trait screen → lockTraits
```

## 6. Troubleshooting

| Symptom | Check |
|---|---|
| Black screen after "Ride out" | `lxr-spawn` not started → the resource fades in itself after 1.5 s; check `Config.Integrations.afterSelect` |
| "Lock in" does nothing | Server notify tells you why (min perks / conflict / balance). Also check rate limit warnings in the server log |
| Preview ped is naked / wrong model | `Config.Integrations.appearance.resource` must export `loadSkin` / `loadClothes`; table must have `citizenid, model, skin, clothes` |
| Georgian text shows boxes | The NUI loads *Noto Sans Georgian* from Google Fonts; offline servers should ship the font locally and change the `<link>` in `html/index.html` |
| A preset is missing | Server console: `preset "<id>" hidden: <reason>` |

---
© 2026 iBoss21 / LXRCore · lxrcore.com · 🐺 wolves.land
