--[[ ═══════════════════════════════════════════════════════════════════════════
     🐺 LXR-MULTICHARACTER — Locale: Georgian (ქართული) — 1:1 mirror of en.lua
     ═══════════════════════════════════════════════════════════════════════════
     Developer   : iBoss21 | Brand : LXRCore | https://www.lxrcore.com
     © 2026 iBoss21 / LXRCore — All Rights Reserved
     ═══════════════════════════════════════════════════════════════════════════ ]]

Locale.Register('ka', {
    error = {
        invalid_data        = 'პერსონაჟის მონაცემები არასწორია',
        invalid_firstname   = 'სახელი უნდა იყოს 2–20 ასო',
        invalid_lastname    = 'გვარი უნდა იყოს 2–20 ასო',
        invalid_birthdate   = 'დაბადების თარიღი: წწწწ-თთ-დდ, 1830-დან 1899-მდე',
        invalid_gender      = 'აირჩიეთ სქესი',
        invalid_nationality = 'ეროვნება ძალიან გრძელია',
        character_limit     = 'პერსონაჟების ყველა ადგილი დაკავებულია',
        not_owned           = 'ეს პერსონაჟი თქვენი არ არის',
        login_failed        = 'პერსონაჟი ვერ ჩაიტვირთა, სცადეთ ხელახლა',
        too_fast            = 'გთხოვთ, ცოტა ხანში სცადოთ',
    },
    info = {
        deleted      = 'პერსონაჟი წაიშალა',
        disconnected = 'თქვენ დატოვეთ სერვერი',
    },
    command = {
        logout     = 'პერსონაჟის არჩევაზე დაბრუნება (ადმინი)',
        closemulti = 'პერსონაჟის ეკრანის დახურვა',
    },
    ui = {
        title            = 'აირჩიეთ პერსონაჟი',
        subtitle         = 'ყველა ისტორია სახელით იწყება',
        slots            = '%{used} / %{max} პერსონაჟი',
        empty_slot       = 'თავისუფალი ადგილი',
        new_character    = 'ახალი პერსონაჟი',
        play             = 'გზას გაუდექი',
        delete           = 'წაშლა',
        disconnect       = 'სერვერიდან გასვლა',
        loading          = 'პერსონაჟები იტვირთება…',
        job              = 'საქმიანობა',
        cash             = 'ნაღდი',
        bank             = 'ბანკი',
        born             = 'დაბადებული',
        nationality      = 'ეროვნება',
        last_played      = 'ბოლოს ნახეს',
        never            = 'არასდროს',
        create_title     = 'პერსონაჟის შექმნა',
        firstname        = 'სახელი',
        lastname         = 'გვარი',
        birthdate        = 'დაბადების თარიღი',
        gender           = 'სქესი',
        male             = 'მამრობითი',
        female           = 'მდედრობითი',
        nationality_hint = 'მაგ. ამერიკელი, ქართველი, ირლანდიელი',
        create           = 'შექმნა',
        cancel           = 'გაუქმება',
        confirm_delete   = 'წავშალოთ %{name}? ამის დაბრუნება შეუძლებელია.',
        confirm          = 'დიახ, წაშალე',
        no_characters    = 'პერსონაჟები ჯერ არ გაქვთ. შექმენით პირველი.',
    },
})
