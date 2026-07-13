/**
 * bank-lookup.js — Shared module tích hợp VietQR API
 * Cung cấp:
 *  - loadBankList(selectEl)       : nạp danh sách NH vào <select>
 *  - renderBankSelector(selectEl) : tạo custom dropdown có logo
 *  - lookupAccountName(bin, stk)  : tra cứu tên chủ tài khoản
 *
 * API: https://api.vietqr.io/v2/banks  (bank list – public, free)
 *      https://api.vietqr.io/v2/lookup (account name – cần x-client-id + x-api-key)
 *
 * Để dùng tính năng tra cứu tên tài khoản:
 *   Đăng ký miễn phí tại https://my.vietqr.io → lấy Client ID & API Key
 *   → gán vào VIETQR_CLIENT_ID và VIETQR_API_KEY bên dưới.
 */

const VIETQR_CLIENT_ID = 'your_client_id';   // ← thay bằng key thật
const VIETQR_API_KEY   = 'your_api_key';     // ← thay bằng key thật
const VIETQR_BANK_URL  = 'https://api.vietqr.io/v2/banks';
const VIETQR_LOOKUP_URL = 'https://api.vietqr.io/v2/lookup';

let _bankList = [];   // cache

/* ─────────────────────────────────────────────────────── */
/* 1. Fetch bank list từ VietQR                            */
/* ─────────────────────────────────────────────────────── */
async function fetchBankList() {
    if (_bankList.length) return _bankList;
    try {
        const res = await fetch(VIETQR_BANK_URL);
        const json = await res.json();
        _bankList = (json.data || []).filter(b => b.bin && b.short_name);
        return _bankList;
    } catch (e) {
        console.error('[BankLookup] fetchBankList failed:', e);
        return [];
    }
}

/* ─────────────────────────────────────────────────────── */
/* 2. Nạp danh sách vào <select> chuẩn (fallback)         */
/* ─────────────────────────────────────────────────────── */
async function loadBankSelect(selectEl, currentValue) {
    const banks = await fetchBankList();
    selectEl.innerHTML = '<option value="">-- Chọn ngân hàng --</option>';
    banks.sort((a, b) => a.short_name.localeCompare(b.short_name));
    banks.forEach(b => {
        const opt = document.createElement('option');
        opt.value     = b.short_name;
        opt.dataset.bin = b.bin;
        opt.textContent = `${b.short_name} – ${b.name}`;
        if (currentValue && (currentValue === b.short_name || currentValue === b.name)) {
            opt.selected = true;
        }
        selectEl.appendChild(opt);
    });
}

/* ─────────────────────────────────────────────────────── */
/* 3. Tạo Custom Bank Picker với logo + search            */
/* ─────────────────────────────────────────────────────── */
function buildBankPicker(containerId, { onSelect, currentValue } = {}) {
    const container = document.getElementById(containerId);
    if (!container) return;

    container.innerHTML = `
        <div class="bank-picker-wrap" id="bp_${containerId}">
            <div class="bank-picker-trigger" id="bp_trigger_${containerId}" onclick="toggleBankPicker('${containerId}', event)">
                <div class="bp-selected" id="bp_selected_${containerId}">
                    <div class="bp-placeholder">-- Chọn ngân hàng --</div>
                </div>
                <svg class="bp-chevron" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="6 9 12 15 18 9"/></svg>
            </div>
            <div class="bank-picker-dropdown" id="bp_dropdown_${containerId}">
                <div class="bp-search-wrap">
                    <input type="text" class="bp-search" id="bp_search_${containerId}"
                           placeholder="🔍 Tìm ngân hàng..."
                           oninput="filterBankPicker('${containerId}', this.value)">
                </div>
                <div class="bp-list" id="bp_list_${containerId}"></div>
            </div>
            <input type="hidden" id="bp_value_${containerId}" name="bankPickerValue">
            <input type="hidden" id="bp_bin_${containerId}"   name="bankPickerBin">
        </div>`;

    fetchBankList().then(banks => {
        renderBankPickerList(containerId, banks, currentValue);
    });

    // Store callback
    window[`_bankPickerCb_${containerId}`] = onSelect;

    // Đăng ký global click listener chỉ 1 lần duy nhất
    if (!window._bankPickerClickListenerRegistered) {
        window._bankPickerClickListenerRegistered = true;
        document.addEventListener('click', (e) => {
            // Đóng tất cả bank picker dropdowns đang mở nếu click ra ngoài
            document.querySelectorAll('.bank-picker-wrap').forEach(wrap => {
                if (!wrap.contains(e.target)) {
                    wrap.querySelector('.bank-picker-dropdown')?.classList.remove('open');
                }
            });
        }); // bubbling phase — không dùng capture để tránh block các dropdown khác
    }
}

function renderBankPickerList(containerId, banks, currentValue) {

    const list = document.getElementById(`bp_list_${containerId}`);
    if (!list) return;
    list.innerHTML = '';

    banks.sort((a, b) => a.short_name.localeCompare(b.short_name));
    banks.forEach(b => {
        const item = document.createElement('div');
        item.className = 'bp-item';
        item.dataset.shortName = b.short_name;
        item.dataset.bin = b.bin;
        item.innerHTML = `
            <img class="bp-logo" src="https://api.vietqr.io/img/${b.bin}.png"
                 onerror="this.style.display='none'"
                 loading="lazy" alt="${b.short_name}">
            <div class="bp-item-info">
                <strong>${b.short_name}</strong>
                <span>${b.name}</span>
            </div>`;
        item.onclick = () => selectBankItem(containerId, b);
        list.appendChild(item);

        // Auto-select if matches current value
        if (currentValue && (currentValue === b.short_name || currentValue === b.name)) {
            selectBankItem(containerId, b, false);
        }
    });
}

window.toggleBankPicker = function(containerId, event) {
    if (event) event.stopPropagation();
    const dd = document.getElementById(`bp_dropdown_${containerId}`);
    if (!dd) return;
    dd.classList.toggle('open');
    if (dd.classList.contains('open')) {
        document.getElementById(`bp_search_${containerId}`)?.focus();
    }
};

window.filterBankPicker = function(containerId, query) {
    const list = document.getElementById(`bp_list_${containerId}`);
    if (!list) return;
    const q = query.toLowerCase();
    list.querySelectorAll('.bp-item').forEach(item => {
        const name = item.dataset.shortName.toLowerCase();
        item.style.display = name.includes(q) ? '' : 'none';
    });
};

function selectBankItem(containerId, bank, closeDropdown = true) {
    // Update hidden inputs
    const valInput = document.getElementById(`bp_value_${containerId}`);
    const binInput = document.getElementById(`bp_bin_${containerId}`);
    if (valInput) valInput.value = bank.short_name;
    if (binInput) binInput.value = bank.bin;

    // Update trigger display
    const selected = document.getElementById(`bp_selected_${containerId}`);
    if (selected) {
        selected.innerHTML = `
            <img class="bp-logo" src="https://api.vietqr.io/img/${bank.bin}.png"
                 onerror="this.style.display='none'" alt="${bank.short_name}">
            <div class="bp-item-info">
                <strong>${bank.short_name}</strong>
                <span style="font-size:11px;">${bank.name}</span>
            </div>`;
    }

    if (closeDropdown) {
        document.getElementById(`bp_dropdown_${containerId}`)?.classList.remove('open');
    }

    // Fire callback
    const cb = window[`_bankPickerCb_${containerId}`];
    if (typeof cb === 'function') cb(bank);
}

/* ─────────────────────────────────────────────────────── */
/* 4. Tra cứu tên tài khoản                               */
/* ─────────────────────────────────────────────────────── */
async function lookupAccountName(bin, accountNumber) {
    if (!bin || !accountNumber || accountNumber.length < 6) return null;
    // Guard: yêu cầu có API key thật
    if (VIETQR_CLIENT_ID === 'your_client_id') return null;

    try {
        const res = await fetch(VIETQR_LOOKUP_URL, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'x-client-id': VIETQR_CLIENT_ID,
                'x-api-key':   VIETQR_API_KEY
            },
            body: JSON.stringify({ bin, accountNumber })
        });
        const json = await res.json();
        if (json.code === '00' && json.data?.accountName) {
            return json.data.accountName;
        }
        return null;
    } catch (e) {
        console.error('[BankLookup] lookupAccountName failed:', e);
        return null;
    }
}

/* ─────────────────────────────────────────────────────── */
/* 5. Helper: bind STK input → auto lookup + fill name    */
/* ─────────────────────────────────────────────────────── */
function bindAccountLookup({ stkInputId, accountNameInputId, getBin, statusElId }) {
    const stkInput    = document.getElementById(stkInputId);
    const nameInput   = document.getElementById(accountNameInputId);
    const statusEl    = statusElId ? document.getElementById(statusElId) : null;
    if (!stkInput || !nameInput) return;

    let debounceTimer = null;

    stkInput.addEventListener('input', () => {
        clearTimeout(debounceTimer);
        const stk = stkInput.value.replace(/\s/g, '');

        if (statusEl) {
            statusEl.textContent = '';
            statusEl.className = 'lookup-status';
        }
        nameInput.classList.remove('auto-filled');

        if (stk.length < 6) return;

        if (statusEl) {
            statusEl.textContent = '🔍 Đang tra cứu tên tài khoản...';
            statusEl.className = 'lookup-status loading';
        }

        debounceTimer = setTimeout(async () => {
            const bin = typeof getBin === 'function' ? getBin() : '';
            if (!bin) {
                if (statusEl) {
                    statusEl.textContent = '⚠️ Vui lòng chọn ngân hàng trước';
                    statusEl.className = 'lookup-status warn';
                }
                return;
            }

            const accountName = await lookupAccountName(bin, stk);
            if (accountName) {
                nameInput.value = accountName;
                nameInput.classList.add('auto-filled');
                if (statusEl) {
                    statusEl.textContent = `✅ Tìm thấy: ${accountName}`;
                    statusEl.className = 'lookup-status success';
                }
            } else {
                if (statusEl) {
                    if (VIETQR_CLIENT_ID === 'your_client_id') {
                        statusEl.textContent = '⚙️ Chưa cấu hình API Key — vui lòng tự nhập tên';
                    } else {
                        statusEl.textContent = '❌ Không tìm thấy — vui lòng nhập thủ công';
                    }
                    statusEl.className = 'lookup-status error';
                }
            }
        }, 800);
    });
}

/* ─────────────────────────────────────────────────────── */
/* 6. CSS (inject vào <head>)                             */
/* ─────────────────────────────────────────────────────── */
(function injectStyles() {
    if (document.getElementById('bank-lookup-css')) return;
    const style = document.createElement('style');
    style.id = 'bank-lookup-css';
    style.textContent = `
    /* Bank Picker */
    .bank-picker-wrap { position: relative; }

    .bank-picker-trigger {
        display: flex;
        align-items: center;
        justify-content: space-between;
        width: 100%;
        padding: 10px 14px;
        border: 1.5px solid #e2e8f0;
        border-radius: 10px;
        background: #f8fafc;
        cursor: pointer;
        transition: all 0.2s ease;
        min-height: 48px;
        gap: 8px;
    }

    .bank-picker-trigger:hover {
        border-color: #0284c7;
        background: #fff;
    }

    .bp-selected {
        display: flex;
        align-items: center;
        gap: 10px;
        flex: 1;
    }

    .bp-placeholder {
        color: #94a3b8;
        font-size: 14px;
    }

    .bp-chevron { color: #64748b; flex-shrink: 0; transition: transform 0.2s; }

    .bank-picker-dropdown {
        display: none;
        position: absolute;
        z-index: 500;
        top: calc(100% + 6px);
        left: 0; right: 0;
        background: #fff;
        border: 1.5px solid #e2e8f0;
        border-radius: 12px;
        box-shadow: 0 16px 40px rgba(0,0,0,0.10);
        overflow: hidden;
    }

    .bank-picker-dropdown.open { display: block; }
    .bank-picker-wrap .bp-chevron { }
    .bank-picker-dropdown.open ~ .bank-picker-trigger .bp-chevron,
    .bank-picker-trigger .bp-chevron {
        transition: transform 0.2s;
    }

    .bp-search-wrap { padding: 10px 12px; border-bottom: 1px solid #f1f5f9; }

    .bp-search {
        width: 100%;
        padding: 8px 12px;
        border: 1px solid #e2e8f0;
        border-radius: 8px;
        font-size: 13px;
        outline: none;
        background: #f8fafc;
        box-sizing: border-box;
    }

    .bp-list {
        max-height: 260px;
        overflow-y: auto;
        padding: 6px;
    }

    .bp-item {
        display: flex;
        align-items: center;
        gap: 10px;
        padding: 8px 10px;
        border-radius: 8px;
        cursor: pointer;
        transition: background 0.15s;
    }

    .bp-item:hover { background: #f0f9ff; }

    .bp-logo {
        width: 36px;
        height: 22px;
        object-fit: contain;
        border-radius: 4px;
        flex-shrink: 0;
        background: #fff;
        border: 1px solid #f1f5f9;
    }

    .bp-item-info {
        display: flex;
        flex-direction: column;
        line-height: 1.3;
    }

    .bp-item-info strong {
        font-size: 13px;
        font-weight: 700;
        color: #0f172a;
    }

    .bp-item-info span {
        font-size: 11px;
        color: #64748b;
    }

    /* Lookup status */
    .lookup-status {
        font-size: 12.5px;
        font-weight: 600;
        margin-top: 6px;
        padding: 6px 10px;
        border-radius: 8px;
        min-height: 28px;
        transition: all 0.2s;
    }

    .lookup-status.loading { background: #f0f9ff; color: #0369a1; }
    .lookup-status.success { background: #f0fdf4; color: #15803d; }
    .lookup-status.error   { background: #fff1f2; color: #b91c1c; }
    .lookup-status.warn    { background: #fefce8; color: #854d0e; }

    /* Auto-fill highlight */
    .form-control.auto-filled,
    input.auto-filled {
        border-color: #22c55e !important;
        background: #f0fdf4 !important;
        font-weight: 700;
        color: #15803d !important;
    }
    `;
    document.head.appendChild(style);
})();
