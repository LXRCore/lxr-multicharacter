# 🐺 lxr-multicharacter — Character Traits Reference

## Rules (`ConfigTraits.Rules`)

| Rule | Default | Enforced |
|---|---|---|
| `basePoints` | 0 | You start with **no** free points |
| `minPerks` / `maxPerks` | 2 / 4 | Advantages required / allowed |
| `maxTraits` | 12 | Advantages + disadvantages (linked flaws count) |
| balance | ≥ 0 | `basePoints + refunds − costs − skillPoints` may never be negative |
| conflicts | | Declared on either side; checked both ways |
| `requires` | | Linked disadvantages are added automatically and cannot be removed while the advantage is selected |
| skills | 3 / skill, 6 total | Leftover balance → starting levels (`Config.TraitFlow.skills`) |

The NUI computes the same numbers for live feedback; the server (`shared/traits.lua → Traits.Validate`) is the only authority and re-validates presets too.

## Categories

`physique` · `survival` · `trade` · `knowledge` · `character` · `habits`

## Advantages (cost points)

| id | Category | Cost | Effects (modifiers) | Conflicts | Requires |
|---|---|---|---|---|---|
| `strong_back` | physique | 6 | `slots_mult 1.5` | frail_build | |
| `hardened` | physique | 2 | `temp_cold_immune` | | |
| `iron_stomach` | physique | 3 | `alcohol_mult 0.7`, `vomit_threshold_add 0.2`, `vomit_chance_mult 0.5` | weak_stomach | |
| `frontier_expert` | survival | 9 | `herb_yield_mult 2`, `butcher_double_add 0.15`, `cattle_drive_pay_mult 1.2`, `legendary_parts_price_mult 1.2`, `aim_sway_mult 0.5`, `craft_speed_mult 1.15` | inept_skinner | |
| `light_step` | survival | 3 | `noise_mult 0.6`, `detect_range_mult 0.7` | | |
| `born_rider` | survival | 3 | `horse_stamina_mult 0.75`, `horse_bond_mult 1.2` | | |
| `steady_aim` | survival | 5 | `aim_sway_mult 0.75`, `reload_speed_mult 1.1` | trembling_hands, bad_eyes | |
| `bounty_hunter` | trade | 4 | `bounty_reward_mult 1.5` | unreliable | |
| `hard_worker` | trade | 5 | `dock_pay_mult 1.25`, `delivery_pay_mult 1.25`, `craft_speed_mult 1.15` | frail_build | |
| `prospector` | trade | 7 | `rare_timber_add 0.15`, `can_use_concentration_table`, `gold_pan_mult 1.25`, `rare_ore_add 0.15` | | |
| `field_medic` | knowledge | 6 | `heal_mult 1.25`, `craft_speed_mult 1.1` | | |
| `progress_devotee` | knowledge | 3 | `engineer_pay_mult 1.2` | illiterate | |
| `intellectual` | knowledge | 10 | `salaried_pay_mult 1.25` | illiterate | **tenderfoot, trembling_hands** |
| `scoundrel` | character | 8 | `can_trade_illegal`, `aim_sway_mult 0.75` | | **unreliable, alcoholism** |
| `silver_tongue` | character | 4 | `shop_buy_mult 0.9`, `shop_sell_mult 1.1` | | |
| `lucky` | character | 5 | `loot_rare_add 0.1`, `escape_chance_add 0.1` | | |

## Disadvantages (refund points)

| id | Category | Refund | Effects (modifiers) | Conflicts |
|---|---|---|---|---|
| `frail_build` | physique | 10 | `move_rate 0.67`, `heavy_trauma_add 0.5`, `melee_damage_taken_mult 1.6`, `can_carry_bodies false`, `craft_speed_mult 0.8` | strong_back, hard_worker |
| `weak_lungs` | physique | 5 | `smoke_cough`, `stamina_drain_mult 2` | |
| `weak_stomach` | physique | 3 | `stomach_upset`, `alcohol_mult 1.3`, `vomit_chance_add 0.08` | iron_stomach |
| `slow_healing` | physique | 6 | `heal_mult 0.7`, `regen_mult 0.7` | |
| `tenderfoot` | physique | 4 | `melee_damage_taken_mult 1.6`, `craft_speed_mult 0.8` | |
| `poor_health` | physique | 5 | `injury_on_ko_add 0.3` | |
| `inept_skinner` | survival | 5 | `can_skin false` | frontier_expert |
| `bad_eyes` | survival | 5 | `aim_sway_mult 1.3`, `spot_range_mult 0.7` | steady_aim |
| `illiterate` | knowledge | 3 | `can_read false`, `xp_mult 0.85` | intellectual, progress_devotee |
| `trembling_hands` | character | 6 | `aim_sway_mult 1.5`, `craft_speed_mult 0.6` | steady_aim |
| `recklessness` | character | 6 | `permadeath_chance_add 0.04` | |
| `unreliable` | character | 8 | `can_take_government_jobs false`, `craft_speed_mult 0.7`, `permadeath_chance_add 0.09` | bounty_hunter |
| `card_sharp` | character | 4 | `can_gamble false` | |
| `weak_nerves` | character | 5 | `stress_gain_mult 1.5`, `lowhp_aim_sway_add 0.25` | |
| `alcoholism` | habits | 2 | `needs_alcohol`, `vice_interval_min 60`, `vice_interval_max 120` | |
| `tobacco_addiction` | habits | 2 | `needs_tobacco`, `vice_interval_min 60`, `vice_interval_max 120` | |

## Ready-made fates (`ConfigTraits.Presets`)

| id | Advantages | Disadvantages (+linked) | Skills | Balance |
|---|---|---|---|---|
| `tracker` | frontier_expert, light_step | weak_stomach, recklessness, tobacco_addiction, card_sharp | hunting 2, herbalism 1 | 0 |
| `gunslinger` | steady_aim, lucky | recklessness, alcoholism, card_sharp | main 2 | 0 |
| `doctor` | intellectual, field_medic | weak_nerves, tobacco_addiction, *tenderfoot, trembling_hands* | herbalism 1 | 0 |
| `rancher` | strong_back, born_rider, hard_worker | illiterate, weak_stomach, card_sharp, poor_health | main 1 | 0 |
| `salesman` | silver_tongue, progress_devotee, lucky | tenderfoot, weak_lungs, inept_skinner | fishing 1, main 1 | 0 |
| `drifter` | hardened, iron_stomach, light_step | alcoholism, bad_eyes, illiterate | fishing 2 | 0 |
| `prospector` | prospector, hardened, strong_back | weak_lungs, trembling_hands, tobacco_addiction, slow_healing | mining 3 | +1 |

A preset only pre-fills the selection; the player may edit it afterwards and the server validates the final result like any manual choice.

## How modifiers are combined (`Traits.Modifiers`)

| Key shape | Combine | Default when absent |
|---|---|---|
| `*_mult`, `move_rate` | multiply | 1.0 |
| `*_add` and any other number | add | 0 |
| `*_min` / `*_max` | min / max | — |
| boolean `can_*` | AND (false wins) | true |
| other booleans | OR (true wins) | false |

## Who consumes which modifier

This resource applies **directly**:

| Modifier | Applied by |
|---|---|
| `slots_mult`, `weight_mult` | server → `players.slots` / `players.weight` (`Config.TraitFlow.applyInventory`) |
| starting skill levels | server → `Player.Functions.AddXp` (`xpPerLevel` from lxr-core) |
| `move_rate` | client → `SetPedMoveRateOverride` while on foot (`Config.TraitFlow.applyMoveRate`) |

Everything else is a **contract for other resources**. Read it with the exports in [API.md](API.md) — recommended consumers:

| Modifier | Suggested consumer |
|---|---|
| `heal_mult`, `regen_mult`, `injury_on_ko_add`, `heavy_trauma_add`, `permadeath_chance_add`, `melee_damage_taken_mult` | medic / death system |
| `alcohol_mult`, `vomit_chance_*`, `vomit_threshold_add`, `stomach_upset`, `smoke_cough`, `needs_alcohol`, `needs_tobacco`, `vice_interval_*` | consumables / needs / status HUD |
| `temp_cold_immune` | temperature system |
| `stamina_drain_mult`, `lowhp_aim_sway_add`, `aim_sway_mult`, `reload_speed_mult` | combat / stamina scripts |
| `craft_speed_mult`, `craft_fail_add` | crafting |
| `herb_yield_mult`, `butcher_double_add`, `can_skin`, `rare_timber_add`, `rare_ore_add`, `gold_pan_mult`, `can_use_concentration_table` | gathering / hunting / mining / lumber |
| `cattle_drive_pay_mult`, `legendary_parts_price_mult`, `dock_pay_mult`, `delivery_pay_mult`, `engineer_pay_mult`, `salaried_pay_mult`, `bounty_reward_mult` | jobs / paycheck |
| `shop_buy_mult`, `shop_sell_mult`, `can_trade_illegal` | shops / black market |
| `can_take_government_jobs` | job centre / bossmenu hiring |
| `can_gamble` | gambling |
| `can_read` | letters / notes / contracts |
| `noise_mult`, `detect_range_mult`, `spot_range_mult` | stealth / NPC awareness |
| `horse_stamina_mult`, `horse_bond_mult` | horses |
| `xp_mult` | wrap `Player.Functions.AddXp` in your skill scripts |
| `stress_gain_mult` | stress system |
| `loot_rare_add`, `escape_chance_add` | loot tables / lawmen |

Example (server, crafting):

```lua
local speed = exports['lxr-multicharacter']:GetModifier(src, 'craft_speed_mult', 1.0)
local duration = math.floor(recipe.time / speed)
```

## Storage format (`players.metadata.traits`)

```json
{
  "version": 1, "locked": true, "lockedAt": 1789000000, "reason": "create",
  "perks": ["intellectual", "field_medic"],
  "flaws": ["weak_nerves", "tobacco_addiction", "tenderfoot", "trembling_hands"],
  "skills": { "herbalism": 1 },
  "mods": { "salaried_pay_mult": 1.25, "heal_mult": 1.25, "craft_speed_mult": 0.528, "...": "..." },
  "points": { "base": 0, "cost": 16, "refund": 17, "skills": 1, "free": 0 }
}
```

`locked = false` (after `/resettraits` or `/retrait`) makes the trait screen open again on next login when `promptExisting` is on.

---
© 2026 iBoss21 / LXRCore · lxrcore.com · 🐺 wolves.land
