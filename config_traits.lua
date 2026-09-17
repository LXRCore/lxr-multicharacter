--[[
    ██╗     ██╗  ██╗██████╗        ███╗   ███╗██╗   ██╗██╗  ████████╗██╗ ██████╗██╗  ██╗ █████╗ ██████╗
    ██║     ╚██╗██╔╝██╔══██╗       ████╗ ████║██║   ██║██║  ╚══██╔══╝██║██╔════╝██║  ██║██╔══██╗██╔══██╗
    ██║      ╚███╔╝ ██████╔╝█████╗██╔████╔██║██║   ██║██║     ██║   ██║██║     ███████║███████║██████╔╝
    ██║      ██╔██╗ ██╔══██╗╚════╝██║╚██╔╝██║██║   ██║██║     ██║   ██║██║     ██╔══██║██╔══██║██╔══██╗
    ███████╗██╔╝ ██╗██║  ██║      ██║ ╚═╝ ██║╚██████╔╝███████╗██║   ██║╚██████╗██║  ██║██║  ██║██║  ██║
    ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝      ╚═╝     ╚═╝ ╚═════╝ ╚══════╝╚═╝   ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝

    🐺 LXR Core - Character Traits Configuration ("Character & Life Experience")

    A character starts with NO free points. Disadvantages give points,
    advantages spend them, and the balance may never go negative. Between
    minPerks and maxPerks advantages are required and a character may carry
    at most maxTraits traits in total. Some advantages automatically add
    linked disadvantages (`requires`). Whatever balance is left over can be
    spent on starting skill levels in the "Skills & experience" tab.

    Every trait carries a flat `modifiers` table. The server sums the modifiers
    of the locked selection and publishes the result (see docs/TRAITS.md):
      • keys ending in `_mult` multiply       (default 1.0)
      • keys ending in `_add`  add            (default 0)
      • boolean keys starting with `can_` AND (false wins)
      • other boolean keys OR                 (true wins)
      • `move_rate` multiplies                (default 1.0, applied by this resource)

    Text for each trait lives in locales/*.lua under traits.<id>.*
    (name, tag, fx1 … fxN). `effects` is the number of fx lines to show.

    Developer:   iBoss21 / LXRCore
    Website:     https://www.lxrcore.com
    © 2026 iBoss21 / LXRCore | lxrcore.com | All Rights Reserved
]]

ConfigTraits = ConfigTraits or {}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ POINT BUDGET RULES ████████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

ConfigTraits.Rules = {
    basePoints = 0,   -- Free points every new character starts with (reference design: 0)
    minPerks   = 2,   -- Advantages required before the selection can be locked
    maxPerks   = 4,   -- Advantages allowed
    maxTraits  = 12,  -- Advantages + disadvantages allowed in total (linked flaws count)
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ CATEGORIES ████████████████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████
-- Order is the sort order inside each column. Label from locale: traits.cat.<id>

ConfigTraits.Categories = { 'physique', 'survival', 'trade', 'knowledge', 'character', 'habits' }

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ ADVANTAGES (cost points) ██████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████
--  requires  = disadvantages that are added automatically with this advantage
--  conflicts = traits that cannot be taken together with this one

ConfigTraits.Perks = {
    { id = 'strong_back',      category = 'physique',  cost = 6,  icon = 'back',     effects = 1,
      conflicts = { 'frail_build' },
      modifiers = { slots_mult = 1.5 } },

    { id = 'hardened',         category = 'physique',  cost = 2,  icon = 'snow',     effects = 1,
      conflicts = {},
      modifiers = { temp_cold_immune = true } },

    { id = 'iron_stomach',     category = 'physique',  cost = 3,  icon = 'flask',    effects = 3,
      conflicts = { 'weak_stomach' },
      modifiers = { alcohol_mult = 0.7, vomit_threshold_add = 0.2, vomit_chance_mult = 0.5 } },

    { id = 'frontier_expert',  category = 'survival',  cost = 9,  icon = 'compass',  effects = 6,
      conflicts = { 'inept_skinner' },
      modifiers = { herb_yield_mult = 2.0, butcher_double_add = 0.15, cattle_drive_pay_mult = 1.2, legendary_parts_price_mult = 1.2, aim_sway_mult = 0.5, craft_speed_mult = 1.15 } },

    { id = 'light_step',       category = 'survival',  cost = 3,  icon = 'feather',  effects = 2,
      conflicts = {},
      modifiers = { noise_mult = 0.6, detect_range_mult = 0.7 } },

    { id = 'born_rider',       category = 'survival',  cost = 3,  icon = 'horse',    effects = 2,
      conflicts = {},
      modifiers = { horse_stamina_mult = 0.75, horse_bond_mult = 1.2 } },

    { id = 'steady_aim',       category = 'survival',  cost = 5,  icon = 'target',   effects = 2,
      conflicts = { 'trembling_hands', 'bad_eyes' },
      modifiers = { aim_sway_mult = 0.75, reload_speed_mult = 1.1 } },

    { id = 'bounty_hunter',    category = 'trade',     cost = 4,  icon = 'poster',   effects = 1,
      conflicts = { 'unreliable' },
      modifiers = { bounty_reward_mult = 1.5 } },

    { id = 'hard_worker',      category = 'trade',     cost = 5,  icon = 'crate',    effects = 3,
      conflicts = { 'frail_build' },
      modifiers = { dock_pay_mult = 1.25, delivery_pay_mult = 1.25, craft_speed_mult = 1.15 } },

    { id = 'prospector',       category = 'trade',     cost = 7,  icon = 'pickaxe',  effects = 3,
      conflicts = {},
      modifiers = { rare_timber_add = 0.15, can_use_concentration_table = true, gold_pan_mult = 1.25, rare_ore_add = 0.15 } },

    { id = 'field_medic',      category = 'knowledge', cost = 6,  icon = 'syringe',  effects = 2,
      conflicts = {},
      modifiers = { heal_mult = 1.25, craft_speed_mult = 1.10 } },

    { id = 'progress_devotee', category = 'knowledge', cost = 3,  icon = 'train',    effects = 1,
      conflicts = { 'illiterate' },
      modifiers = { engineer_pay_mult = 1.2 } },

    { id = 'intellectual',     category = 'knowledge', cost = 10, icon = 'book',     effects = 2,
      requires  = { 'tenderfoot', 'trembling_hands' },
      conflicts = { 'illiterate' },
      modifiers = { salaried_pay_mult = 1.25 } },

    { id = 'scoundrel',        category = 'character', cost = 8,  icon = 'outlaw',   effects = 3,
      requires  = { 'unreliable', 'alcoholism' },
      conflicts = {},
      modifiers = { can_trade_illegal = true, aim_sway_mult = 0.75 } },

    { id = 'silver_tongue',    category = 'character', cost = 4,  icon = 'tongue',   effects = 2,
      conflicts = {},
      modifiers = { shop_buy_mult = 0.9, shop_sell_mult = 1.1 } },

    { id = 'lucky',            category = 'character', cost = 5,  icon = 'clover',   effects = 2,
      conflicts = {},
      modifiers = { loot_rare_add = 0.10, escape_chance_add = 0.10 } },
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ DISADVANTAGES (refund points) █████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

ConfigTraits.Flaws = {
    { id = 'frail_build',      category = 'physique',  refund = 10, icon = 'bones',   effects = 5,
      conflicts = { 'strong_back', 'hard_worker' },
      modifiers = { move_rate = 0.67, heavy_trauma_add = 0.5, melee_damage_taken_mult = 1.6, can_carry_bodies = false, craft_speed_mult = 0.8 } },

    { id = 'weak_lungs',       category = 'physique',  refund = 5,  icon = 'lungs',   effects = 2,
      conflicts = {},
      modifiers = { smoke_cough = true, stamina_drain_mult = 2.0 } },

    { id = 'weak_stomach',     category = 'physique',  refund = 3,  icon = 'stomach', effects = 3,
      conflicts = { 'iron_stomach' },
      modifiers = { stomach_upset = true, alcohol_mult = 1.3, vomit_chance_add = 0.08 } },

    { id = 'slow_healing',     category = 'physique',  refund = 6,  icon = 'bandage', effects = 1,
      conflicts = {},
      modifiers = { heal_mult = 0.7, regen_mult = 0.7 } },

    { id = 'tenderfoot',       category = 'physique',  refund = 4,  icon = 'fist',    effects = 2,
      conflicts = {},
      modifiers = { melee_damage_taken_mult = 1.6, craft_speed_mult = 0.8 } },

    { id = 'poor_health',      category = 'physique',  refund = 5,  icon = 'heart',   effects = 1,
      conflicts = {},
      modifiers = { injury_on_ko_add = 0.30 } },

    { id = 'inept_skinner',    category = 'survival',  refund = 5,  icon = 'knife',   effects = 1,
      conflicts = { 'frontier_expert' },
      modifiers = { can_skin = false } },

    { id = 'bad_eyes',         category = 'survival',  refund = 5,  icon = 'eye',     effects = 2,
      conflicts = { 'steady_aim' },
      modifiers = { aim_sway_mult = 1.3, spot_range_mult = 0.7 } },

    { id = 'illiterate',       category = 'knowledge', refund = 3,  icon = 'book',    effects = 2,
      conflicts = { 'intellectual', 'progress_devotee' },
      modifiers = { can_read = false, xp_mult = 0.85 } },

    { id = 'trembling_hands',  category = 'character', refund = 6,  icon = 'hands',   effects = 2,
      conflicts = { 'steady_aim' },
      modifiers = { aim_sway_mult = 1.5, craft_speed_mult = 0.6 } },

    { id = 'recklessness',     category = 'character', refund = 6,  icon = 'cross',   effects = 1,
      conflicts = {},
      modifiers = { permadeath_chance_add = 0.04 } },

    { id = 'unreliable',       category = 'character', refund = 8,  icon = 'cuffs',   effects = 3,
      conflicts = { 'bounty_hunter' },
      modifiers = { can_take_government_jobs = false, craft_speed_mult = 0.7, permadeath_chance_add = 0.09 } },

    { id = 'card_sharp',       category = 'character', refund = 4,  icon = 'cards',   effects = 1,
      conflicts = {},
      modifiers = { can_gamble = false } },

    { id = 'weak_nerves',      category = 'character', refund = 5,  icon = 'storm',   effects = 2,
      conflicts = {},
      modifiers = { stress_gain_mult = 1.5, lowhp_aim_sway_add = 0.25 } },

    { id = 'alcoholism',       category = 'habits',    refund = 2,  icon = 'bottle',  effects = 1,
      conflicts = {},
      modifiers = { needs_alcohol = true, vice_interval_min = 60, vice_interval_max = 120 } },

    { id = 'tobacco_addiction', category = 'habits',   refund = 2,  icon = 'pipe',    effects = 1,
      conflicts = {},
      modifiers = { needs_tobacco = true, vice_interval_min = 60, vice_interval_max = 120 } },
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ READY-MADE FATES (presets) ████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████
-- A preset only pre-fills the selection; the player may still change it and the
-- server validates the final selection exactly like a manual one. Linked flaws
-- are added automatically and need not be listed. Presets that break the rules
-- are reported in the server console on start and hidden.
-- Label / flavour text from locale: traits.preset.<id>.name / .desc

ConfigTraits.Presets = {
    { id = 'tracker',    perks = { 'frontier_expert', 'light_step' },            flaws = { 'weak_stomach', 'recklessness', 'tobacco_addiction', 'card_sharp' }, skills = { hunting = 2, herbalism = 1 } },
    { id = 'gunslinger', perks = { 'steady_aim', 'lucky' },                      flaws = { 'recklessness', 'alcoholism', 'card_sharp' },                        skills = { main = 2 } },
    { id = 'doctor',     perks = { 'intellectual', 'field_medic' },              flaws = { 'weak_nerves', 'tobacco_addiction' },                                skills = { herbalism = 1 } },
    { id = 'rancher',    perks = { 'strong_back', 'born_rider', 'hard_worker' }, flaws = { 'illiterate', 'weak_stomach', 'card_sharp', 'poor_health' },         skills = { main = 1 } },
    { id = 'salesman',   perks = { 'silver_tongue', 'progress_devotee', 'lucky' }, flaws = { 'tenderfoot', 'weak_lungs', 'inept_skinner' },                     skills = { fishing = 1, main = 1 } },
    { id = 'drifter',    perks = { 'hardened', 'iron_stomach', 'light_step' },   flaws = { 'alcoholism', 'bad_eyes', 'illiterate' },                            skills = { fishing = 2 } },
    { id = 'prospector', perks = { 'prospector', 'hardened', 'strong_back' },    flaws = { 'weak_lungs', 'trembling_hands', 'tobacco_addiction', 'slow_healing' }, skills = { mining = 3 } },
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ END OF CONFIGURATION ██████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████
