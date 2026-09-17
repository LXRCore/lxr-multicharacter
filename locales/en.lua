--[[ ═══════════════════════════════════════════════════════════════════════════
     🐺 LXR-MULTICHARACTER — Locale: English (canonical)
     ═══════════════════════════════════════════════════════════════════════════
     Developer   : iBoss21 | Brand : LXRCore | https://www.lxrcore.com
     © 2026 iBoss21 / LXRCore — All Rights Reserved
     ═══════════════════════════════════════════════════════════════════════════ ]]

Locale.Register('en', {
    error = {
        invalid_data        = 'Invalid character data',
        invalid_firstname   = 'First name must be 2–20 letters',
        invalid_lastname    = 'Last name must be 2–20 letters',
        invalid_birthdate   = 'Birth date must be YYYY-MM-DD between 1830 and 1899',
        invalid_gender      = 'Choose a gender',
        invalid_nationality = 'Nationality is too long',
        character_limit     = 'You have used all your character slots',
        not_owned           = 'That character does not belong to you',
        login_failed        = 'The character could not be loaded, try again',
        too_fast            = 'Please wait a moment before trying again',
    },
    info = {
        deleted      = 'Character deleted',
        disconnected = 'You have left the server',
    },
    command = {
        logout     = 'Return to character selection (admin)',
        closemulti = 'Close the character screen',
    },
    ui = {
        title            = 'Choose your character',
        subtitle         = 'Every story starts with a name',
        slots            = '%{used} / %{max} characters',
        empty_slot       = 'Empty slot',
        new_character    = 'New character',
        play             = 'Ride out',
        delete           = 'Delete',
        disconnect       = 'Leave server',
        loading          = 'Fetching your characters…',
        job              = 'Occupation',
        cash             = 'Cash',
        bank             = 'Bank',
        born             = 'Born',
        nationality      = 'Nationality',
        last_played      = 'Last seen',
        never            = 'Never',
        create_title     = 'Create a character',
        firstname        = 'First name',
        lastname         = 'Last name',
        birthdate        = 'Birth date',
        gender           = 'Gender',
        male             = 'Male',
        female           = 'Female',
        nationality_hint = 'e.g. American, Georgian, Irish',
        create           = 'Create',
        cancel           = 'Cancel',
        confirm_delete   = 'Delete %{name}? This cannot be undone.',
        confirm          = 'Yes, delete',
        no_characters    = 'No characters yet. Create your first one.',
    },
})
