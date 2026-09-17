/* ═══════════════════════════════════════════════════════════════════════════
   🐺 LXR-MULTICHARACTER — NUI logic (vanilla, no build step)
   Receives { action: 'open' | 'characters' | 'close' | 'error' } from the
   client and posts { preview, select, create, delete, disconnect, refresh }.
   The server validates everything; this file only renders and relays.
   © 2026 iBoss21 / LXRCore | lxrcore.com | All Rights Reserved
   ═══════════════════════════════════════════════════════════════════════════ */
(() => {
    'use strict';

    const resource = (typeof GetParentResourceName === 'function') ? GetParentResourceName() : 'lxr-multicharacter';
    const $ = (id) => document.getElementById(id);

    let locale = {};
    let characters = [];
    let maxSlots = 0;
    let selected = null;
    let pendingDelete = null;

    const postNUI = (event, payload) =>
        fetch(`https://${resource}/${event}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(payload || {}),
        }).then((r) => r.json()).catch(() => ({}));

    const t = (key, vars, fallback) => {
        let str = locale[key];
        if (str === undefined) str = fallback !== undefined ? fallback : key;
        if (vars) str = String(str).replace(/%\{(\w+)\}/g, (_, k) => (vars[k] !== undefined ? vars[k] : `%{${k}}`));
        return str;
    };

    const money = (n) => '$' + Number(n || 0).toLocaleString('en-US', { minimumFractionDigits: 0, maximumFractionDigits: 2 });
    const esc = (s) => String(s ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));

    // ── chrome & locale ───────────────────────────────────────────────────
    function applyLocale() {
        const map = {
            't-title': 'ui.title', 't-subtitle': 'ui.subtitle', 't-loading': 'ui.loading', 'btn-disconnect': 'ui.disconnect',
            't-job': 'ui.job', 't-born': 'ui.born', 't-nationality': 'ui.nationality', 't-cash': 'ui.cash', 't-bank': 'ui.bank',
            't-last': 'ui.last_played', 'btn-play': 'ui.play', 'btn-delete': 'ui.delete', 't-create-title': 'ui.create_title',
            't-firstname': 'ui.firstname', 't-lastname': 'ui.lastname', 't-birthdate': 'ui.birthdate', 't-nationality-l': 'ui.nationality',
            't-gender': 'ui.gender', 't-male': 'ui.male', 't-female': 'ui.female', 'btn-create-cancel': 'ui.cancel',
            'btn-create-confirm': 'ui.create', 'btn-delete-cancel': 'ui.cancel', 'btn-delete-confirm': 'ui.confirm',
        };
        for (const [id, key] of Object.entries(map)) {
            const el = $(id);
            if (el) el.textContent = t(key, null, el.textContent);
        }
        $('nationality-input').placeholder = t('ui.nationality_hint', null, '');
    }

    function applyServer(server) {
        if (!server) return;
        $('server-name').textContent = server.name || 'LXRCore';
        $('server-tagline').textContent = server.tagline || '';
    }

    // ── rendering ─────────────────────────────────────────────────────────
    function renderList() {
        const list = $('character-list');
        list.innerHTML = '';
        $('slots').textContent = t('ui.slots', { used: characters.length, max: maxSlots });

        for (let slot = 1; slot <= maxSlots; slot++) {
            const c = characters.find((x) => x.cid === slot);
            const li = document.createElement('li');
            const btn = document.createElement('button');
            btn.type = 'button';
            if (c) {
                btn.className = 'lxr-card' + (selected && selected.citizenid === c.citizenid ? ' lxr-card--active' : '');
                btn.innerHTML = `<span class="lxr-card__slot">${slot}</span>
                    <span><div class="lxr-card__name">${esc(c.firstname)} ${esc(c.lastname)}</div>
                    <div class="lxr-card__meta">${esc(c.job)}${c.grade ? ' · ' + esc(c.grade) : ''}</div></span>`;
                btn.addEventListener('click', () => select(c));
            } else {
                btn.className = 'lxr-card lxr-card--empty';
                btn.innerHTML = `<span class="lxr-card__slot">+</span><span>${esc(t('ui.new_character'))}</span>`;
                btn.addEventListener('click', openCreate);
            }
            li.appendChild(btn);
            list.appendChild(li);
        }
        if (characters.length === 0) {
            const li = document.createElement('li');
            li.className = 'lxr-muted';
            li.style.padding = '4px 2px 10px';
            li.textContent = t('ui.no_characters');
            list.prepend(li);
        }
    }

    function renderDetail() {
        const panel = $('detail');
        if (!selected) { panel.hidden = true; return; }
        panel.hidden = false;
        $('detail-name').textContent = `${selected.firstname} ${selected.lastname}`;
        $('d-job').textContent = selected.grade ? `${selected.job} — ${selected.grade}` : selected.job;
        $('d-born').textContent = selected.birthdate || '—';
        $('d-nationality').textContent = selected.nationality || '—';
        $('d-cash').textContent = money(selected.cash);
        $('d-bank').textContent = money(selected.bank);
        $('d-last').textContent = selected.lastPlayed ? selected.lastPlayed.replace('T', ' ').slice(0, 16) : t('ui.never');
    }

    function select(c) {
        selected = c;
        renderList();
        renderDetail();
        postNUI('preview', { citizenid: c.citizenid, gender: c.gender });
    }

    // ── create / delete ───────────────────────────────────────────────────
    function openCreate() {
        $('form-create').reset();
        $('create-error').hidden = true;
        $('modal-create').classList.remove('hidden');
        $('form-create').firstname.focus();
    }

    function closeCreate() { $('modal-create').classList.add('hidden'); }

    function submitCreate(e) {
        e.preventDefault();
        const f = $('form-create');
        const data = {
            firstname: f.firstname.value.trim(),
            lastname: f.lastname.value.trim(),
            birthdate: f.birthdate.value.trim(),
            nationality: f.nationality.value.trim(),
            gender: Number(f.gender.value),
        };
        const errBox = $('create-error');
        if (data.firstname.length < 2 || data.firstname.length > 20) { errBox.textContent = t('error.invalid_firstname'); errBox.hidden = false; return; }
        if (data.lastname.length < 2 || data.lastname.length > 20) { errBox.textContent = t('error.invalid_lastname'); errBox.hidden = false; return; }
        if (!/^\d{4}-\d{2}-\d{2}$/.test(data.birthdate)) { errBox.textContent = t('error.invalid_birthdate'); errBox.hidden = false; return; }
        $('btn-create-confirm').disabled = true;
        postNUI('create', data).then(() => {
            setTimeout(() => { $('btn-create-confirm').disabled = false; }, 3000);
            closeCreate();
        });
    }

    function openDelete() {
        if (!selected) return;
        pendingDelete = selected;
        $('delete-text').textContent = t('ui.confirm_delete', { name: `${selected.firstname} ${selected.lastname}` });
        $('modal-delete').classList.remove('hidden');
    }

    function closeDelete() { pendingDelete = null; $('modal-delete').classList.add('hidden'); }

    // ── wiring ────────────────────────────────────────────────────────────
    $('btn-play').addEventListener('click', () => { if (selected) postNUI('select', { citizenid: selected.citizenid }); });
    $('btn-delete').addEventListener('click', openDelete);
    $('btn-disconnect').addEventListener('click', () => postNUI('disconnect'));
    $('form-create').addEventListener('submit', submitCreate);
    $('btn-create-cancel').addEventListener('click', closeCreate);
    $('btn-delete-cancel').addEventListener('click', closeDelete);
    $('btn-delete-confirm').addEventListener('click', () => {
        if (!pendingDelete) return;
        postNUI('delete', { citizenid: pendingDelete.citizenid });
        selected = null;
        closeDelete();
    });

    document.addEventListener('keyup', (e) => {
        if (e.key !== 'Escape') return;
        // ESC closes the top-most modal; the character screen itself stays open
        if (!$('modal-create').classList.contains('hidden')) return closeCreate();
        if (!$('modal-delete').classList.contains('hidden')) return closeDelete();
    });

    window.addEventListener('message', (event) => {
        const data = event.data || {};
        switch (data.action) {
            case 'open':
                $('app').classList.remove('hidden');
                $('loading').classList.remove('hidden');
                $('detail').hidden = true;
                selected = null;
                break;
            case 'characters':
                locale = data.locale || locale;
                applyLocale();
                applyServer(data.server);
                characters = Array.isArray(data.characters) ? data.characters : [];
                maxSlots = Number(data.max) || characters.length;
                $('loading').classList.add('hidden');
                selected = characters[0] || null;
                renderList();
                renderDetail();
                break;
            case 'error':
                $('loading').classList.add('hidden');
                $('t-subtitle').textContent = data.message || '';
                break;
            case 'close':
                $('app').classList.add('hidden');
                closeCreate();
                closeDelete();
                break;
            default:
                break;
        }
    });
})();
