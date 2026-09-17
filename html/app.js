/* ═══════════════════════════════════════════════════════════════════════════
   LXR-MULTICHARACTER — NUI logic (vanilla, no build step)
   Receives { action: 'open' | 'characters' | 'openTraits' | 'createFailed' |
   'close' | 'error' } from the client and posts { preview, rotate, select,
   create, delete, disconnect, refresh, lockTraits, closeTraits }.
   The server validates everything; this file only renders, keeps the live
   point balance for feedback and relays ids.
   © 2026 iBoss21 / LXRCore | lxrcore.com | All Rights Reserved
   ═══════════════════════════════════════════════════════════════════════════ */
(() => {
    'use strict';

    const resource = (typeof GetParentResourceName === 'function') ? GetParentResourceName() : 'lxr-multicharacter';
    const $ = (id) => document.getElementById(id);
    const MOCK = typeof window.__LXR_MOCK__ === 'object';

    // ── state ─────────────────────────────────────────────────────────────
    let locale = {};
    let characters = [];
    let maxSlots = 0;
    let selected = null;
    let creation = { birthYearMin: 1830, birthYearMax: 1889 };
    let T = null;               // trait payload from the server
    let byId = {};              // trait id → definition
    let mode = 'create';        // 'create' | 'standalone'
    let identity = null;
    let sel = { perks: [], flaws: [], linked: {}, skills: {}, preset: null };
    let busy = false;

    const postNUI = (event, payload) => {
        if (MOCK) { console.log('[NUI →]', event, payload); return Promise.resolve({}); }
        return fetch(`https://${resource}/${event}`, {
            method: 'POST', headers: { 'Content-Type': 'application/json; charset=UTF-8' }, body: JSON.stringify(payload || {}),
        }).then((r) => r.json()).catch(() => ({}));
    };

    const t = (key, vars, fallback) => {
        let str = locale[key];
        if (str === undefined) str = fallback !== undefined ? fallback : key;
        if (vars) str = String(str).replace(/%\{(\w+)\}/g, (_, k) => (vars[k] !== undefined ? vars[k] : `%{${k}}`));
        return str;
    };
    const esc = (s) => String(s ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
    const money = (n) => { const v = Number(n || 0); return '$' + v.toLocaleString('en-US', { minimumFractionDigits: Number.isInteger(v) ? 0 : 2, maximumFractionDigits: 2 }); };
    const setText = (id, value) => { const el = $(id); if (el) el.textContent = value; };
    const show = (id, on) => { const el = $(id); if (el) el.classList.toggle('hidden', !on); };

    // ── icons (inline stroke SVG, keyed by config icon name) ──────────────
    const ICONS = {
        back: '<path d="M12 3v18M7 8l5-5 5 5M6 14h12M8 18h8"/>',
        snow: '<path d="M12 2v20M2 12h20M5 5l14 14M19 5L5 19M12 5l-2 2M12 5l2 2M12 19l-2-2M12 19l2-2"/>',
        flask: '<path d="M9 3h6M10 3v6L4 20h16l-6-11V3M7 15h10"/>',
        compass: '<circle cx="12" cy="12" r="9"/><path d="M15.5 8.5l-2 5-5 2 2-5z"/>',
        feather: '<path d="M20 4c-6 0-11 4-13 10l-3 6 6-3c6-2 10-7 10-13zM7 17l7-7"/>',
        horse: '<path d="M4 20l3-8 3-2 2-5 3-1 3 3-1 3-3 1v9M7 12l-3 2"/>',
        target: '<circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="5"/><circle cx="12" cy="12" r="1"/>',
        poster: '<rect x="5" y="3" width="14" height="18"/><circle cx="12" cy="10" r="3"/><path d="M8 17h8"/>',
        crate: '<rect x="3" y="7" width="18" height="13"/><path d="M3 12h18M12 7v13M6 7l2-4h8l2 4"/>',
        pickaxe: '<path d="M4 20L14 10M10 6c3-2 7-2 10 1M10 6c-3 2-5 5-5 9M14 10l2-2"/>',
        syringe: '<path d="M4 20l4-4M7 17l9-9 2 2-9 9zM14 6l4 4M16 4l4 4M12 12l2 2"/>',
        train: '<rect x="5" y="4" width="14" height="13" rx="2"/><path d="M5 11h14M9 17l-2 4M15 17l2 4M9 14h.01M15 14h.01"/>',
        book: '<path d="M4 4h7a2 2 0 0 1 2 2v14a2 2 0 0 0-2-2H4zM20 4h-7a2 2 0 0 0-2 2v14a2 2 0 0 1 2-2h7z"/>',
        outlaw: '<circle cx="12" cy="9" r="5"/><path d="M4 21c1-4 4-6 8-6s7 2 8 6M8 9h8M9 6l-1-3M15 6l1-3"/>',
        tongue: '<circle cx="12" cy="12" r="9"/><path d="M8 10h.01M16 10h.01M8 14c1 2 3 3 4 3s3-1 4-3M12 17v3"/>',
        clover: '<path d="M12 12c-3 0-5-2-5-4s2-3 3-2 2 2 2 4M12 12c3 0 5-2 5-4s-2-3-3-2-2 2-2 4M12 12c-3 0-5 2-5 4s2 3 3 2 2-2 2-4M12 12c3 0 5 2 5 4s-2 3-3 2-2-2-2-4M12 16v5"/>',
        bones: '<path d="M6 8l10 10M5 7a2 2 0 1 1 2-2 2 2 0 1 1 2 2M17 17a2 2 0 1 1-2 2 2 2 0 1 1-2-2"/>',
        lungs: '<path d="M12 3v9M12 8c-3 0-4 3-4 7 0 3-1 4-3 4s-2-3-2-6c0-4 3-7 7-7M12 8c3 0 4 3 4 7 0 3 1 4 3 4s2-3 2-6c0-4-3-7-7-7"/>',
        stomach: '<path d="M9 3v5a4 4 0 0 0 4 4h1a5 5 0 0 1 0 10H9"/>',
        bandage: '<path d="M4 8l12 12 4-4L8 4zM8 8l1 1M11 11l1 1M14 14l1 1"/>',
        fist: '<path d="M7 11V7a1.5 1.5 0 0 1 3 0v4M10 10V6a1.5 1.5 0 0 1 3 0v5M13 11V7a1.5 1.5 0 0 1 3 0v6M16 12a1.5 1.5 0 0 1 3 1v3a6 6 0 0 1-6 6h-2a5 5 0 0 1-5-5v-6"/>',
        heart: '<path d="M12 21s-8-5-8-11a4 4 0 0 1 8-1 4 4 0 0 1 8 1c0 6-8 11-8 11zM8 11h2l1-2 2 4 1-2h2"/>',
        knife: '<path d="M4 20l6-6M10 14l9-9c1 0 2 1 2 2l-9 9zM10 14l-2-2"/>',
        eye: '<path d="M2 12s4-7 10-7 10 7 10 7-4 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/><path d="M4 4l16 16"/>',
        hands: '<path d="M8 21v-5l-3-5a1.5 1.5 0 0 1 2.5-1.5L9 12V5a1.5 1.5 0 0 1 3 0v6M12 11V4a1.5 1.5 0 0 1 3 0v7M15 11V6a1.5 1.5 0 0 1 3 0v9a6 6 0 0 1-6 6H8M4 8l1 1M20 8l-1 1"/>',
        cross: '<path d="M12 3v18M6 9h12M8 21h8"/>',
        cuffs: '<circle cx="7" cy="15" r="4"/><circle cx="17" cy="15" r="4"/><path d="M7 11V7a5 5 0 0 1 10 0v4M11 15h2"/>',
        cards: '<rect x="4" y="6" width="10" height="14" rx="1" transform="rotate(-8 9 13)"/><rect x="10" y="4" width="10" height="14" rx="1" transform="rotate(8 15 11)"/><path d="M14 9h.01"/>',
        storm: '<path d="M6 16a4 4 0 0 1 1-8 5 5 0 0 1 10 1 3.5 3.5 0 0 1 0 7h-1M12 12l-2 4h4l-2 4"/>',
        bottle: '<path d="M10 3h4v4l2 3v10a1 1 0 0 1-1 1H9a1 1 0 0 1-1-1V10l2-3zM8 14h8"/>',
        pipe: '<path d="M3 13h8v4a3 3 0 0 1-3 3H6a3 3 0 0 1-3-3zM11 13l9-8M14 5l1 1M17 4v-1"/>',
    };
    const icon = (name) => `<svg viewBox="0 0 24 24">${ICONS[name] || '<circle cx="12" cy="12" r="8"/>'}</svg>`;

    // ── chrome & locale ───────────────────────────────────────────────────
    function applyLocale() {
        const map = {
            't-title': 'ui.title', 't-subtitle': 'ui.subtitle', 'btn-disconnect': 'ui.disconnect', 'btn-play': 'ui.play',
            'btn-delete': 'ui.delete', 'btn-confirm': 'ui.confirm', 'btn-cancel-delete': 'ui.cancel',
            'l-born': 'ui.born', 'l-nat': 'ui.nationality', 'l-cash': 'ui.cash', 'l-bank': 'ui.bank', 'l-last': 'ui.last_played', 'l-traits': 'ui.traits_of',
            's-identity': 'ui.step_identity', 's-traits': 'ui.step_traits', 'c-title': 'ui.create_title',
            'l-first': 'ui.firstname', 'l-lname': 'ui.lastname', 'l-birth': 'ui.birthdate', 'l-gender': 'ui.gender', 'g-male': 'ui.male', 'g-female': 'ui.female',
            'l-nation': 'ui.nationality', 'btn-id-back': 'ui.back', 'btn-id-next': 'ui.next',
            'tr-title': 'ui.traits_title', 'tr-sub': 'ui.traits_subtitle', 'tab-traits': 'ui.tab_traits', 'tab-skills': 'ui.tab_skills',
            'tr-free-label': 'ui.free_points', 'tr-presets-label': 'ui.presets', 'tr-perks': 'ui.perks', 'tr-flaws': 'ui.flaws', 'tr-flaws-hint': 'ui.flaws_hint',
            'tr-choice': 'ui.your_choice', 'tr-refund-note': 'ui.flaws_refund', 'btn-lock': 'ui.lock_in', 'btn-lock-skills': 'ui.lock_in', 'btn-later': 'ui.later',
            'sk-title': 'ui.skills_title', 'sk-sub': 'ui.skills_subtitle', 'sk-note': 'ui.locked_note', 'btn-tr-back': 'ui.back', 'tr-locked-note': 'ui.locked_note',
            'in-title': 'ui.intro_title', 'in-p1': 'ui.intro_p1', 'in-p2': 'ui.intro_p2', 'in-p4': 'ui.intro_p4', 'btn-intro': 'ui.intro_continue',
        };
        for (const [id, key] of Object.entries(map)) setText(id, t(key));
        document.body.classList.toggle('lang-ka', /[Ⴀ-ჿ]/.test(t('ui.traits_title')));
        $('f-nation').placeholder = t('ui.nationality_hint');
        const year = (T && T.year) || 1901;
        setText('c-file', t('ui.file_label', { year }));
        setText('c-subtitle', t('ui.create_subtitle', { year }));
        setText('tr-file', t('ui.file_label', { year }));
        if (T) setText('in-p3', t('ui.intro_p3', { min: T.rules.minPerks, max: T.rules.maxPerks, total: T.rules.maxTraits }));
    }

    function toast(msg) {
        const el = $('toast'); el.textContent = msg; el.classList.remove('hidden');
        clearTimeout(toast.h); toast.h = setTimeout(() => el.classList.add('hidden'), 3200);
    }

    function view(name) {
        for (const v of ['view-list', 'view-identity', 'view-traits']) show(v, v === `view-${name}`);
    }

    // ── character list ────────────────────────────────────────────────────
    function renderList() {
        setText('t-slots', t('ui.slots', { used: characters.length, max: maxSlots }));
        const ul = $('charlist'); ul.innerHTML = '';
        if (!characters.length) {
            const li = document.createElement('li'); li.className = 'muted'; li.textContent = t('ui.no_characters'); ul.appendChild(li);
        }
        for (const c of characters) {
            const li = document.createElement('li');
            const b = document.createElement('button');
            b.className = 'char' + (selected && selected.citizenid === c.citizenid ? ' char--on' : '');
            b.innerHTML = `<span class="char__cid">${c.cid}</span><span><div class="char__name">${esc(c.firstname)} ${esc(c.lastname)}</div><div class="char__meta">${esc(c.job || '')}${c.grade ? ' · ' + esc(c.grade) : ''}</div></span>`;
            b.onclick = () => selectChar(c);
            li.appendChild(b); ul.appendChild(li);
        }
        for (let i = characters.length; i < maxSlots; i++) {
            const li = document.createElement('li');
            const b = document.createElement('button');
            b.className = 'char char--empty';
            b.innerHTML = `<span class="char__cid">+</span><span><div class="char__name">${esc(t('ui.new_character'))}</div><div class="char__meta">${esc(t('ui.empty_slot'))}</div></span>`;
            b.onclick = startCreate;
            li.appendChild(b); ul.appendChild(li);
        }
    }

    function selectChar(c) {
        selected = c;
        renderList();
        show('detail', true); show('confirm', false);
        setText('d-name', `${c.firstname} ${c.lastname}`);
        setText('d-job', [c.job, c.grade].filter(Boolean).join(' · '));
        setText('d-born', c.birthdate || '—');
        setText('d-nat', c.nationality || '—');
        setText('d-cash', money(c.cash));
        setText('d-bank', money(c.bank));
        setText('d-last', c.lastPlayed || t('ui.never'));
        const box = $('d-traits'); box.innerHTML = '';
        if (c.traits && (c.traits.perks.length || c.traits.flaws.length)) {
            for (const n of c.traits.perks) box.insertAdjacentHTML('beforeend', `<span class="chip chip--perk">${esc(n)}</span>`);
            for (const n of c.traits.flaws) box.insertAdjacentHTML('beforeend', `<span class="chip chip--flaw">${esc(n)}</span>`);
        } else box.innerHTML = `<span class="chip">${esc(t('ui.no_traits'))}</span>`;
        postNUI('preview', { citizenid: c.citizenid, gender: c.gender });
    }

    $('btn-play').onclick = () => { if (selected && !busy) { busy = true; postNUI('select', { citizenid: selected.citizenid }); } };
    $('btn-delete').onclick = () => {
        if (!selected) return;
        setText('confirm-text', t('ui.confirm_delete', { name: `${selected.firstname} ${selected.lastname}` }));
        show('confirm', true);
    };
    $('btn-cancel-delete').onclick = () => show('confirm', false);
    $('btn-confirm').onclick = () => { if (selected) { postNUI('delete', { citizenid: selected.citizenid }); selected = null; show('detail', false); } };
    $('btn-disconnect').onclick = () => postNUI('disconnect');

    // ── identity step ─────────────────────────────────────────────────────
    let gender = 0;
    function startCreate() {
        if (characters.length >= maxSlots) return;
        mode = 'create';
        show('detail', false);
        $('identity').reset();
        setGender(0);
        show('identity-error', false);
        view('identity');
        $('f-first').focus();
        postNUI('preview', { citizenid: null, gender: 0 });
    }
    function setGender(g) {
        gender = g;
        for (const b of document.querySelectorAll('.seg__btn')) b.classList.toggle('seg__btn--on', Number(b.dataset.gender) === g);
        postNUI('preview', { citizenid: null, gender: g });
    }
    for (const b of document.querySelectorAll('.seg__btn')) b.onclick = () => setGender(Number(b.dataset.gender));
    $('btn-id-back').onclick = () => { view('list'); if (characters[0]) selectChar(characters[0]); };
    $('identity').onsubmit = (e) => {
        e.preventDefault();
        const first = $('f-first').value.trim(), last = $('f-last').value.trim(), birth = $('f-birth').value, nat = $('f-nation').value.trim();
        const err = (key) => { setText('identity-error', t(key)); show('identity-error', true); };
        if (first.length < 2 || first.length > 20) return err('error.invalid_firstname');
        if (last.length < 2 || last.length > 20) return err('error.invalid_lastname');
        const y = Number((birth || '').slice(0, 4));
        if (!birth || y < creation.birthYearMin || y > creation.birthYearMax) return err('error.invalid_birthdate');
        identity = { firstname: first, lastname: last, birthdate: birth, gender, nationality: nat };
        if (!T || !T.enabled) return submitCreate();
        openTraits('create');
    };

    // ── trait screen ──────────────────────────────────────────────────────
    function resetSelection() { sel = { perks: [], flaws: [], linked: {}, skills: {}, preset: null }; }

    function openTraits(m) {
        mode = m;
        resetSelection();
        show('btn-tr-back', m === 'create');
        show('btn-later', m === 'standalone');
        show('intro', true);
        switchTab('traits');
        view('traits');
        renderTraits();
    }
    $('btn-intro').onclick = () => show('intro', false);
    $('btn-tr-back').onclick = () => view('identity');
    $('btn-later').onclick = () => postNUI('closeTraits');
    $('rot-l').onclick = () => postNUI('rotate', { dir: -1 });
    $('rot-r').onclick = () => postNUI('rotate', { dir: 1 });
    for (const b of document.querySelectorAll('.tab')) b.onclick = () => switchTab(b.dataset.tab);
    function switchTab(name) {
        for (const b of document.querySelectorAll('.tab')) b.classList.toggle('tab--on', b.dataset.tab === name);
        show('pane-traits', name === 'traits'); show('pane-skills', name === 'skills');
        if (name === 'skills') renderSkills();
    }

    // budget math — same rules as shared/traits.lua
    function summary() {
        const R = T.rules, SR = T.skillRules;
        let cost = 0, refund = 0;
        for (const id of sel.perks) cost += byId[id].points;
        for (const id of sel.flaws) refund += byId[id].points;
        let levels = 0; for (const v of Object.values(sel.skills)) levels += v;
        const skillCost = levels * (SR.pointsPerLevel || 1);
        const total = sel.perks.length + sel.flaws.length;
        const free = (R.basePoints || 0) + refund - cost - skillCost;
        let error = null, vars = {};
        if (sel.perks.length < R.minPerks) { error = 'ui.need_more_perks'; vars = { n: R.minPerks - sel.perks.length, have: sel.perks.length, min: R.minPerks }; }
        else if (total > R.maxTraits) { error = 'ui.too_many_traits'; vars = { n: total - R.maxTraits }; }
        else if (free < 0) { error = 'ui.over_budget'; vars = { n: -free }; }
        return { cost, refund, free, total, levels, skillCost, error, vars, ok: !error };
    }

    const has = (id) => sel.perks.includes(id) || sel.flaws.includes(id);
    function conflictWith(id) {
        const def = byId[id];
        for (const other of def.conflicts) if (has(other)) return other;
        for (const cid of sel.perks.concat(sel.flaws)) if (byId[cid].conflicts.includes(id)) return cid;
        return null;
    }
    function isLinked(flawId) { return sel.perks.some((p) => byId[p].requires.includes(flawId)); }

    function togglePerk(id) {
        const def = byId[id];
        sel.preset = null;
        if (sel.perks.includes(id)) {
            sel.perks = sel.perks.filter((p) => p !== id);
            for (const f of def.requires) { if (sel.linked[f] && !isLinked(f)) { sel.flaws = sel.flaws.filter((x) => x !== f); delete sel.linked[f]; } }
        } else {
            if (sel.perks.length >= T.rules.maxPerks) return toast(t('error.traits_max_perks'));
            const c = conflictWith(id); if (c) return toast(t('ui.conflict_with', { name: byId[c].name }));
            for (const f of def.requires) { const fc = conflictWith(f); if (fc && fc !== id) return toast(t('ui.conflict_with', { name: byId[fc].name })); }
            sel.perks.push(id);
            for (const f of def.requires) { if (!sel.flaws.includes(f)) sel.flaws.push(f); sel.linked[f] = true; }
        }
        renderTraits();
    }
    function toggleFlaw(id) {
        sel.preset = null;
        if (sel.flaws.includes(id)) {
            if (isLinked(id)) return toast(t('ui.linked_flaw', { name: byId[sel.perks.find((p) => byId[p].requires.includes(id))].name }));
            sel.flaws = sel.flaws.filter((f) => f !== id); delete sel.linked[id];
        } else {
            const c = conflictWith(id); if (c) return toast(t('ui.conflict_with', { name: byId[c].name }));
            sel.flaws.push(id);
        }
        renderTraits();
    }
    function applyPreset(p) {
        resetSelection();
        sel.preset = p.id;
        sel.perks = p.perks.slice();
        sel.flaws = p.flaws.slice();
        for (const pid of p.perks) for (const f of byId[pid].requires) sel.linked[f] = true;
        sel.skills = Object.assign({}, p.skills || {});
        renderTraits();
    }

    function traitCard(def) {
        const on = has(def.id);
        const linked = def.kind === 'flaw' && on && isLinked(def.id);
        const conflict = !on ? conflictWith(def.id) : null;
        const el = document.createElement('div');
        el.className = `trait trait--${def.kind}` + (on ? ' trait--on' : '') + (conflict ? ' trait--off' : '') + (linked ? ' trait--linked' : '');
        const sign = def.kind === 'perk' ? '−' : '+';
        let why = '';
        if (conflict) why = `<p class="trait__why">${esc(t('ui.conflict_with', { name: byId[conflict].name }))}</p>`;
        else if (linked) why = `<p class="trait__why">${esc(t('ui.linked_flaw', { name: byId[sel.perks.find((p) => byId[p].requires.includes(def.id))].name }))}</p>`;
        el.innerHTML = `
            <div class="trait__icon">${icon(def.icon)}</div>
            <div class="trait__body">
                <div class="trait__top">
                    <span class="trait__name">${esc(def.name)}</span>
                    <span class="trait__cat">${esc(def.categoryLabel)}</span>
                    <span class="trait__pts">${sign}${def.points} ${esc(t('ui.pts'))}</span>
                </div>
                <p class="trait__tag">${esc(def.tag)}</p>
                <ul class="trait__fx">${def.effects.map((f) => `<li>${esc(f)}</li>`).join('')}</ul>
                ${why}
            </div>`;
        el.onclick = () => { if (conflict) return toast(t('ui.conflict_with', { name: byId[conflict].name })); def.kind === 'perk' ? togglePerk(def.id) : toggleFlaw(def.id); };
        return el;
    }

    function renderTraits() {
        if (!T) return;
        const sorted = (list) => list.slice().sort((a, b) => a.order - b.order || b.points - a.points);
        const lp = $('list-perks'), lf = $('list-flaws');
        const sp = lp.scrollTop, sf = lf.scrollTop;
        lp.innerHTML = ''; lf.innerHTML = '';
        for (const d of sorted(T.perks)) lp.appendChild(traitCard(d));
        for (const d of sorted(T.flaws)) lf.appendChild(traitCard(d));
        lp.scrollTop = sp; lf.scrollTop = sf;

        const pr = $('presets'); pr.innerHTML = '';
        for (const p of T.presets) {
            const b = document.createElement('button'); b.className = 'preset' + (sel.preset === p.id ? ' preset--on' : ''); b.textContent = p.label; b.onclick = () => applyPreset(p); pr.appendChild(b);
        }

        const ch = $('choice'); ch.innerHTML = '';
        if (!sel.perks.length && !sel.flaws.length) ch.innerHTML = `<div class="choice__empty">${esc(t('ui.nothing_chosen'))}</div>`;
        const pick = (id) => {
            const d = byId[id], linked = d.kind === 'flaw' && isLinked(id);
            const row = document.createElement('div'); row.className = `pick pick--${d.kind}`;
            row.innerHTML = `${icon(d.icon)}<span class="pick__name">${esc(d.name)}</span><span class="pick__pts">${d.kind === 'perk' ? '−' : '+'}${d.points}</span>` +
                (linked ? '<span class="pick__lock">🔗</span>' : '<button class="pick__x" title="×">×</button>');
            if (!linked) row.querySelector('.pick__x').onclick = () => (d.kind === 'perk' ? togglePerk(id) : toggleFlaw(id));
            ch.appendChild(row);
        };
        sel.perks.forEach(pick); sel.flaws.forEach(pick);

        const s = summary();
        setText('tr-perks-hint', t('ui.perks_hint', { n: sel.perks.length, max: T.rules.maxPerks }));
        setText('tr-count', t('ui.traits_count', { n: s.total, max: T.rules.maxTraits }));
        setText('tr-free', s.free);
        $('points-box').classList.toggle('points--neg', s.free < 0);
        $('points-box').classList.toggle('points--pos', s.free > 0);
        const st = $('tr-status');
        st.classList.toggle('choice__status--ok', s.ok);
        st.textContent = s.ok ? (s.free > 0 ? t('ui.ready', { free: s.free }) : t('ui.ready_zero')) : t(s.error, s.vars);
        $('btn-lock').disabled = $('btn-lock-skills').disabled = !s.ok || busy;
        const preset = T.presets.find((p) => p.id === sel.preset);
        setText('tr-preset-desc', preset ? preset.desc : '');
        if (!$('pane-skills').classList.contains('hidden')) renderSkills();
    }

    // skills tab
    function renderSkills() {
        const SR = T.skillRules, s = summary();
        const box = $('skills'); box.innerHTML = '';
        setText('sk-limit', t('ui.skills_limit', { per: SR.maxPerSkill, total: SR.maxTotal }));
        if (!SR.enabled || !T.skills.length) { setText('sk-status', ''); return; }
        for (const sk of T.skills) {
            const lvl = sel.skills[sk.id] || 0;
            const row = document.createElement('div'); row.className = 'skill';
            const pips = Array.from({ length: SR.maxPerSkill }, (_, i) => `<span class="pip${i < lvl ? ' pip--on' : ''}"></span>`).join('');
            row.innerHTML = `<span class="skill__name">${esc(sk.label)}</span><span class="skill__pips">${pips}</span><span class="skill__lvl">${esc(t('ui.skill_levels', { lvl }))}</span>
                <span class="skill__btns"><button class="skill__btn" data-d="-1">−</button><button class="skill__btn" data-d="1">+</button></span>`;
            const [minus, plus] = row.querySelectorAll('.skill__btn');
            minus.disabled = lvl <= 0;
            plus.disabled = lvl >= SR.maxPerSkill || s.levels >= SR.maxTotal || s.free < (SR.pointsPerLevel || 1);
            minus.onclick = () => { sel.skills[sk.id] = lvl - 1; if (!sel.skills[sk.id]) delete sel.skills[sk.id]; sel.preset = null; renderTraits(); renderSkills(); };
            plus.onclick = () => { sel.skills[sk.id] = lvl + 1; sel.preset = null; renderTraits(); renderSkills(); };
            box.appendChild(row);
        }
        setText('sk-status', s.free <= 0 && s.levels === 0 ? t('ui.skills_none') : (s.ok ? t('ui.ready', { free: s.free }) : t(s.error, s.vars)));
    }

    // lock / submit
    $('btn-lock').onclick = $('btn-lock-skills').onclick = () => {
        if (busy || !summary().ok) return;
        busy = true; $('btn-lock').disabled = $('btn-lock-skills').disabled = true;
        const traits = { perks: sel.perks, flaws: sel.flaws, skills: sel.skills };
        if (mode === 'standalone') postNUI('lockTraits', traits);
        else submitCreate(traits);
    };
    function submitCreate(traits) {
        busy = true;
        postNUI('create', { identity, traits: traits || { perks: [], flaws: [], skills: {} } });
    }

    // ── keyboard ──────────────────────────────────────────────────────────
    document.addEventListener('keydown', (e) => {
        if (e.key !== 'Escape') return;
        if (!$('intro').classList.contains('hidden')) return;
        if (!$('view-traits').classList.contains('hidden')) { if (mode === 'standalone') postNUI('closeTraits'); else view('identity'); }
        else if (!$('view-identity').classList.contains('hidden')) $('btn-id-back').click();
    });

    // ── messages from the client ──────────────────────────────────────────
    function loadTraits(payload) {
        T = payload; byId = {};
        for (const d of (T.perks || []).concat(T.flaws || [])) byId[d.id] = d;
    }
    window.addEventListener('message', (e) => {
        const m = e.data || {};
        switch (m.action) {
            case 'open':
                busy = false; show('app', true); view('list'); show('detail', false); break;
            case 'characters':
                locale = m.locale || locale; characters = m.characters || []; maxSlots = m.max || 0; creation = m.creation || creation;
                if (m.traits) loadTraits(m.traits);
                if (m.server) { setText('srv-name', m.server.name || ''); setText('srv-tagline', m.server.tagline || ''); }
                applyLocale(); renderList(); busy = false;
                if (characters[0]) selectChar(characters[0]); else show('detail', false);
                break;
            case 'openTraits':
                locale = m.locale || locale; loadTraits(m.traits); applyLocale();
                busy = false; show('app', true); openTraits('standalone'); break;
            case 'createFailed':
                busy = false; renderTraits(); if (m.stage === 'traits') switchTab('traits'); break;
            case 'error':
                toast(m.message || 'error'); busy = false; break;
            case 'close':
                show('app', false); busy = false; break;
        }
    });

    if (MOCK) {
        const mk = window.__LXR_MOCK__;
        window.postMessage({ action: 'open' }, '*');
        window.postMessage({ action: 'characters', ...mk }, '*');
    }
})();
