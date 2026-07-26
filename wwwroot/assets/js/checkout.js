// ============================================
// CHECKOUT.JS - Merged Logic
// Gộp logic từ filladdress.html + payments.html
// ============================================

console.log('[Checkout] ============ PAGE LOAD ============');

// ==========================================
// 0. CONFIGURATION
// ==========================================
const API_BASE = '';
const voucherState = {
    get code() { return localStorage.getItem('checkout_voucher_code') || null; },
    set code(val) {
        console.trace('voucherState.code changed:', val);
        if (val) localStorage.setItem('checkout_voucher_code', val); else localStorage.removeItem('checkout_voucher_code');
    },
    get discount() { return Number(localStorage.getItem('checkout_voucher_discount')) || 0; },
    set discount(val) {
        console.trace('voucherState.discount changed:', val);
        localStorage.setItem('checkout_voucher_discount', val || 0);
    },
    get source() { return localStorage.getItem('checkout_voucher_source') || null; },
    set source(val) {
        console.trace('voucherState.source changed:', val);
        if (val) localStorage.setItem('checkout_voucher_source', val); else localStorage.removeItem('checkout_voucher_source');
    }
};

const testVouchers = {
    'PROMO10': { type: 'percent', value: 10 },
    'GIAM500K': { type: 'money', value: 500000 },
    'WELCOME100': { type: 'money', value: 100000 }
};

function isTestVoucher(code) {
    return !!testVouchers[code.toUpperCase()];
}

function logVoucherState(actionName) {
    console.log('[' + actionName + '] VOUCHER STATE', {
        code: voucherState.code,
        discount: voucherState.discount,
        source: voucherState.source
    });
}
let totalAmount = 0;
let currentShippingFee = 25000;
let currentOrderId = null;
let pollingInterval = null;

// Shipping selection states
let selectedShipping = 'standard';
let tempSelectedShipping = 'standard';
const shippingNames = { standard: 'Giao hàng nhanh - GHN', express: 'Hỏa tốc - Trong Ngày (GHN)' };

/**
 * Calculate weight and bulkiness for a product based on its name
 */
function estimateProductPhysics(name) {
    const lower = name.toLowerCase();

    // Default fallback
    let weight = 0.5; // kg
    let bulkiness = 1.0; // scale factor

    if (lower.includes('case') || lower.includes('vỏ máy') || lower.includes('thùng máy') || lower.includes('nyx') || lower.includes('h5 flow') || lower.includes('o11') || lower.includes('h9 flow') || lower.includes('4000d')) {
        weight = 7.0;
        bulkiness = 3.5;
    } else if (lower.includes('wheel') || lower.includes('vô lăng') || lower.includes('g923')) {
        weight = 8.0;
        bulkiness = 4.0;
    } else if (lower.includes('psu') || lower.includes('nguồn') || lower.includes('power') || lower.includes('pf650') || lower.includes('cv750') || lower.includes('rm1000') || lower.includes('rm850') || lower.includes('thor')) {
        weight = 2.0;
        bulkiness = 1.5;
    } else if (lower.includes('mainboard') || lower.includes('bo mạch') || lower.includes('mb') || lower.includes('strix') || lower.includes('tomahawk') || lower.includes('aorus') || lower.includes('h610') || lower.includes('b550') || lower.includes('z790') || lower.includes('b650') || lower.includes('x670') || lower.includes('prime')) {
        weight = 1.5;
        bulkiness = 1.5;
    } else if (lower.includes('vga') || lower.includes('card') || lower.includes('rtx') || lower.includes('geforce') || lower.includes('nvidia')) {
        weight = 1.8;
        bulkiness = 1.8;
    } else if (lower.includes('cooling') || lower.includes('tản nhiệt') || lower.includes('liquid') || lower.includes('air') || lower.includes('fan')) {
        weight = 1.5;
        bulkiness = 1.5;
    } else if (lower.includes('keyboard') || lower.includes('bàn phím') || lower.includes('k-elite')) {
        weight = 1.2;
        bulkiness = 1.2;
    } else if (lower.includes('headset') || lower.includes('tai nghe') || lower.includes('sound')) {
        weight = 0.4;
        bulkiness = 1.0;
    } else if (lower.includes('mic') || lower.includes('studio') || lower.includes('yeti')) {
        weight = 0.8;
        bulkiness = 1.0;
    } else if (lower.includes('gamepad') || lower.includes('tay cầm') || lower.includes('cmd') || lower.includes('controller')) {
        weight = 0.3;
        bulkiness = 0.8;
    } else if (lower.includes('mouse') || lower.includes('chuột') || lower.includes('m-pro') || lower.includes('superlight')) {
        weight = 0.1;
        bulkiness = 0.5;
    } else if (lower.includes('mousepad') || lower.includes('lót chuột') || lower.includes('pad pro')) {
        weight = 0.3;
        bulkiness = 0.5;
    } else if (lower.includes('ram') || lower.includes('ddr') || lower.includes('memory')) {
        weight = 0.05;
        bulkiness = 0.2;
    } else if (lower.includes('ssd') || lower.includes('hdd') || lower.includes('ổ cứng') || lower.includes('nvme') || lower.includes('980') || lower.includes('990') || lower.includes('spatium')) {
        weight = 0.08;
        bulkiness = 0.2;
    } else if (lower.includes('cpu') || lower.includes('core') || lower.includes('ryzen') || lower.includes('i5') || lower.includes('i7') || lower.includes('i9') || lower.includes('amd') || lower.includes('intel')) {
        weight = 0.05;
        bulkiness = 0.2;
    }

    return { weight, bulkiness };
}

/**
 * Compute shipping fee dynamically
 */
function calculateShippingFee(items, method, province) {
    if (!items || items.length === 0) {
        return { price: 0, weight: 0, bulkiness: 0 };
    }

    let totalWeight = 0;
    let totalBulkiness = 0;

    items.forEach(item => {
        const name = item.name || item.title || 'Sản phẩm';
        const qty = item.qty || item.quantity || 1;
        const physics = estimateProductPhysics(name);
        totalWeight += physics.weight * qty;
        totalBulkiness += physics.bulkiness * qty;
    });

    // Base Rates
    let baseRate = method === 'express' ? 35000 : 15000;

    // Weight Charge (per kg)
    let weightRate = method === 'express' ? 10000 : 4000;
    let weightCharge = totalWeight * weightRate;

    // Bulkiness Charge
    let bulkRate = method === 'express' ? 8000 : 3000;
    let bulkCharge = totalBulkiness * bulkRate;

    let subtotalShipping = baseRate + weightCharge + bulkCharge;

    // Province Modifier
    let modifier = 1.0;
    if (province) {
        const prov = province.toLowerCase();
        if (prov.includes('hà nội') || prov.includes('hồ chí minh') || prov.includes('hcm') || prov.includes('đà nẵng')) {
            modifier = 0.8; // Hub discount
        } else if (prov.includes('hà giang') || prov.includes('cao bằng') || prov.includes('lai châu') || prov.includes('điện biên') || prov.includes('cà mau') || prov.includes('kiên giang')) {
            modifier = 1.4; // Remote area surcharge
        } else {
            modifier = 1.1; // Standard province surcharge
        }
    }

    let finalShipping = Math.round((subtotalShipping * modifier) / 500) * 500; // Round to nearest 500đ

    return {
        price: finalShipping,
        weight: totalWeight.toFixed(2),
        bulkiness: totalBulkiness.toFixed(2)
    };
}

// ==========================================
// 1. AUTHENTICATION CHECK
// ==========================================
console.log('[Checkout] Checking authentication...');
const authToken = localStorage.getItem('pc_store_token');
const authUser = localStorage.getItem('pc_store_user');

console.log('[Checkout] Token exists:', !!authToken);
console.log('[Checkout] User data exists:', !!authUser);

if (!authToken || !authUser) {
    console.error('[Checkout] ❌ Not authenticated - redirecting to login');
    alert('Vui lòng đăng nhập để tiếp tục thanh toán!');
    window.location.href = '/Login?redirect=' + encodeURIComponent(window.location.pathname);
} else {
    console.log('[Checkout] ✅ User authenticated');
    try {
        const user = JSON.parse(authUser);
        console.log('[Checkout] User ID:', user.userId, '| Name:', user.fullName, '| Email:', user.email);
    } catch (e) {
        console.error('[Checkout] ❌ Invalid user data - redirecting');
        clearAuthAndRedirect();
    }
}

// ==========================================
// 2. HELPER FUNCTIONS
// ==========================================

/**
 * Format currency to Vietnamese dong
 */
function formatCurrency(amount) {
    return new Intl.NumberFormat('vi-VN').format(amount) + 'đ';
}

/**
 * Clear authentication and redirect to login
 */
function clearAuthAndRedirect() {
    localStorage.removeItem('pc_store_token');
    localStorage.removeItem('pc_store_refresh_token');
    localStorage.removeItem('pc_store_user');
    localStorage.removeItem('hyper_core_cart');
    localStorage.removeItem('hypercore_cart_items');
    sessionStorage.removeItem('checkout_addressId');
    sessionStorage.removeItem('checkout_address');
    sessionStorage.removeItem('current_orderId');
    sessionStorage.removeItem('current_sePayOrderId');
    window.location.href = '/Login';
}

/**
 * Show loading overlay
 */
function showLoading(text = 'Đang xử lý...', subtext = 'Vui lòng đợi trong giây lát') {
    const overlay = document.getElementById('loadingOverlay');
    const loadingText = overlay.querySelector('.loading-text');
    const loadingSubtext = overlay.querySelector('.loading-subtext');

    if (loadingText) loadingText.textContent = text;
    if (loadingSubtext) loadingSubtext.textContent = subtext;

    overlay.classList.add('active');
}

/**
 * Hide loading overlay
 */
function hideLoading() {
    const overlay = document.getElementById('loadingOverlay');
    overlay.classList.remove('active');
}

// ==========================================
// 3. LOAD VIETNAMESE PROVINCES API
// ==========================================
const citySelect = document.getElementById("citySelect");
const districtSelect = document.getElementById("districtSelect");
const wardSelect = document.getElementById("wardSelect");

let citiesLoadedResolve;
const citiesLoadedPromise = new Promise((resolve) => {
    citiesLoadedResolve = resolve;
});

async function loadCities() {
    try {
        citySelect.innerHTML = '<option value="">Đang tải danh sách tỉnh thành...</option>';
        const response = await fetch("/api/orders/shipping/provinces");
        const resData = await response.json();
        const allProvinces = resData.data || [];

        // ── Lọc bỏ các tỉnh test/giả của GHN Sandbox ──────────────────────────────
        // Danh sách 63 tỉnh/thành thực tế của Việt Nam
        const VALID_PROVINCES = new Set([
            'An Giang', 'Bà Rịa - Vũng Tàu', 'Bắc Giang', 'Bắc Kạn', 'Bạc Liêu',
            'Bắc Ninh', 'Bến Tre', 'Bình Định', 'Bình Dương', 'Bình Phước',
            'Bình Thuận', 'Cà Mau', 'Cần Thơ', 'Cao Bằng', 'Đà Nẵng',
            'Đắk Lắk', 'Đắk Nông', 'Điện Biên', 'Đồng Nai', 'Đồng Tháp',
            'Gia Lai', 'Hà Giang', 'Hà Nam', 'Hà Nội', 'Hà Tĩnh',
            'Hải Dương', 'Hải Phòng', 'Hậu Giang', 'Hòa Bình', 'Hưng Yên',
            'Khánh Hòa', 'Kiên Giang', 'Kon Tum', 'Lai Châu', 'Lâm Đồng',
            'Lạng Sơn', 'Lào Cai', 'Long An', 'Nam Định', 'Nghệ An',
            'Ninh Bình', 'Ninh Thuận', 'Phú Thọ', 'Phú Yên', 'Quảng Bình',
            'Quảng Nam', 'Quảng Ngãi', 'Quảng Ninh', 'Quảng Trị', 'Sóc Trăng',
            'Sơn La', 'Tây Ninh', 'Thái Bình', 'Thái Nguyên', 'Thanh Hóa',
            'Thừa Thiên Huế', 'Tiền Giang', 'TP. Hồ Chí Minh', 'Trà Vinh',
            'Tuyên Quang', 'Vĩnh Long', 'Vĩnh Phúc', 'Yên Bái'
        ]);

        const provinces = allProvinces.filter(p => {
            const name = (p.ProvinceName || '').trim();
            const testPattern = /\d|test|alert|demo|fake|trial/i;
            return VALID_PROVINCES.has(name) && !testPattern.test(name);
        });

        // Sắp xếp Alphabet
        provinces.sort((a, b) => a.ProvinceName.localeCompare(b.ProvinceName));

        citySelect.innerHTML = '<option value="">--- Chọn Tỉnh / Thành phố ---</option>';
        provinces.forEach(prov => {
            const option = document.createElement("option");
            option.value = prov.ProvinceName;
            option.dataset.code = prov.ProvinceID;
            option.textContent = prov.ProvinceName;
            citySelect.appendChild(option);
        });

        console.log('[Checkout] ✅ Loaded', provinces.length, 'provinces from GHN');
    } catch (error) {
        console.error('[Checkout] ❌ Error loading provinces:', error);
        citySelect.innerHTML = '<option value="">Lỗi tải dữ liệu tỉnh thành</option>';
    } finally {
        if (typeof citiesLoadedResolve === 'function') {
            citiesLoadedResolve();
        }
    }
}

// Load districts when province changes
citySelect.addEventListener("change", async function () {
    const selectedOption = this.options[this.selectedIndex];
    const provinceId = selectedOption ? selectedOption.dataset.code : '';

    districtSelect.innerHTML = '<option value="">--- Chọn Quận / Huyện ---</option>';
    wardSelect.innerHTML = '<option value="">--- Chọn Phường / Xã ---</option>';
    districtSelect.disabled = true;
    wardSelect.disabled = true;

    if (!provinceId) {
        loadAndRenderCart();
        return;
    }

    try {
        districtSelect.disabled = true;
        districtSelect.innerHTML = '<option value="">Đang tải quận huyện...</option>';
        const response = await fetch(`/api/orders/shipping/districts?provinceId=${provinceId}`);
        const resData = await response.json();
        const allDistricts = resData.data || [];

        // Lọc quận huyện ảo của Sandbox
        const testPattern = /\d|test|alert|demo|fake|trial/i;
        const districts = allDistricts.filter(d => !testPattern.test(d.DistrictName || ''));

        // Sắp xếp
        districts.sort((a, b) => a.DistrictName.localeCompare(b.DistrictName));

        districtSelect.innerHTML = '<option value="">--- Chọn Quận / Huyện ---</option>';
        districts.forEach(d => {
            const option = document.createElement("option");
            option.value = d.DistrictName;
            option.dataset.code = d.DistrictID;
            option.textContent = d.DistrictName;
            districtSelect.appendChild(option);
        });
        districtSelect.disabled = false;
        console.log('[Checkout] ✅ Loaded', districts.length, 'districts from GHN');
    } catch (error) {
        console.error('[Checkout] ❌ Error loading districts:', error);
        districtSelect.innerHTML = '<option value="">Lỗi tải dữ liệu quận huyện</option>';
    } finally {
        loadAndRenderCart();
    }
});

// Load wards when district changes
districtSelect.addEventListener("change", async function () {
    const selectedOption = this.options[this.selectedIndex];
    const districtId = selectedOption ? selectedOption.dataset.code : '';

    wardSelect.innerHTML = '<option value="">--- Chọn Phường / Xã ---</option>';
    wardSelect.disabled = true;

    if (!districtId) {
        loadAndRenderCart();
        return;
    }

    try {
        wardSelect.disabled = true;
        wardSelect.innerHTML = '<option value="">Đang tải phường xã...</option>';
        const response = await fetch(`/api/orders/shipping/wards?districtId=${districtId}`);
        const resData = await response.json();
        const allWards = resData.data || [];

        // Lọc phường xã ảo
        const testPattern = /\d|test|alert|demo|fake|trial/i;
        const wards = allWards.filter(w => !testPattern.test(w.WardName || ''));

        // Sắp xếp
        wards.sort((a, b) => a.WardName.localeCompare(b.WardName));

        wardSelect.innerHTML = '<option value="">--- Chọn Phường / Xã ---</option>';
        wards.forEach(w => {
            const option = document.createElement("option");
            option.value = w.WardName;
            option.dataset.code = w.WardCode;
            option.textContent = w.WardName;
            wardSelect.appendChild(option);
        });
        wardSelect.disabled = false;
        console.log('[Checkout] ✅ Loaded', wards.length, 'wards from GHN');
    } catch (error) {
        console.error('[Checkout] ❌ Error loading wards:', error);
        wardSelect.innerHTML = '<option value="">Lỗi tải dữ liệu phường xã</option>';
    } finally {
        loadAndRenderCart();
    }
});

// Load cities on start
loadCities();

// Listener when ward changes
wardSelect.addEventListener("change", loadAndRenderCart);

// ==========================================
// 4. LOAD AND RENDER CART
// ==========================================
async function loadAndRenderCart() {
    console.log('[Checkout] ============ CART LOAD START ============');

    // Sync cart from database if user is logged in
    const token = localStorage.getItem('pc_store_token');
    const userRaw = localStorage.getItem('pc_store_user');

    if (token && userRaw) {
        try {
            const user = JSON.parse(userRaw);
            if (user && user.userId) {
                console.log('[Checkout] 🔄 Syncing cart from API for UserID:', user.userId);
                const res = await fetch(`/api/Cart/user/${user.userId}`, {
                    headers: {
                        'Authorization': `Bearer ${token}`,
                        'Content-Type': 'application/json'
                    }
                });

                console.log('[Checkout] API Response status:', res.status);

                if (res.ok) {
                    const dbItems = await res.json();
                    console.log('[Checkout] ✅ Received', dbItems.length, 'items from database');

                    const localCart = dbItems.map(item => ({
                        id: item.productId,
                        cartId: item.cartId,
                        name: item.productName,
                        specs: item.sku || '',
                        price: item.unitPrice,
                        qty: item.quantity,
                        img: item.defaultImageUrl || '/assets/img/placeholder-product.png'
                    }));

                    localStorage.setItem('hyper_core_cart', JSON.stringify(localCart));
                    console.log('[Checkout] ✅ Cart saved to localStorage');
                } else if (res.status === 401) {
                    console.error('[Checkout] ❌ Unauthorized - Token may be invalid');
                    clearAuthAndRedirect();
                    return;
                }
            }
        } catch (e) {
            console.error('[Checkout] ❌ Exception syncing cart:', e);
        }
    }

    // Read cart from localStorage
    let rawItems = [];
    try {
        const cartStr = localStorage.getItem('hyper_core_cart');
        rawItems = JSON.parse(cartStr) || [];
        console.log('[Checkout] Parsed cart items count:', rawItems.length);
    } catch (e) {
        console.error('[Checkout] ❌ Error parsing cart:', e);
    }

    const productList = document.getElementById('dynamic-product-list');
    const subtotalEl = document.getElementById('summary-subtotal');
    const shippingEl = document.getElementById('summary-shipping');
    const discountEl = document.getElementById('summary-discount');
    const totalEl = document.getElementById('display-total');

    if (!rawItems.length) {
        console.warn('[Checkout] ⚠ Cart is empty');
        productList.innerHTML = '<p style="color:#6b7280;text-align:center;padding:30px;line-height:1.8;">Giỏ hàng của bạn đang trống.<br><a href="/Products" style="color:#38bdf8;text-decoration:underline;">Tiếp tục mua sắm</a></p>';

        if (subtotalEl) subtotalEl.innerText = formatCurrency(0);
        if (shippingEl) shippingEl.innerText = formatCurrency(0);
        if (discountEl) discountEl.innerText = '-' + formatCurrency(0);
        if (totalEl) totalEl.innerText = formatCurrency(0);

        return;
    }

    // Render products
    console.log('[Checkout] 🎨 Rendering', rawItems.length, 'product items...');
    productList.innerHTML = '';
    let subtotal = 0;

    rawItems.forEach((item, index) => {
        const name = item.name || item.title || 'Sản phẩm';
        const variant = item.specs || item.variant || '';
        const price = item.price || 0;
        const qty = item.qty || item.quantity || 1;
        const img = item.img || '/assets/img/placeholder-product.png';
        const lineTotal = price * qty;
        subtotal += lineTotal;

        console.log(`[Checkout] Item ${index + 1}: "${name}" | Qty: ${qty} | Price: ${price} | Total: ${lineTotal}`);

        const productHTML = `
            <div class="product-item">
                <img src="${img}" alt="${name}" onerror="this.onerror=null; this.src='/assets/img/placeholder-product.png';" />
                <div class="product-info">
                    <h4>${name} <span style="color:#6b7280;font-size:14px;font-weight:normal;">(x${qty})</span></h4>
                    ${variant ? `<p style="color:#9ca3af;font-size:13px;">${variant}</p>` : ''}
                    <div class="price">${formatCurrency(lineTotal)}</div>
                </div>
            </div>
        `;
        productList.innerHTML += productHTML;
    });

    // Calculate dynamic shipping fee from GHN API
    let estWeight = 2.0;

    const selectedDistrictOption = districtSelect ? districtSelect.options[districtSelect.selectedIndex] : null;
    const selectedWardOption = wardSelect ? wardSelect.options[wardSelect.selectedIndex] : null;
    const districtId = (selectedDistrictOption && selectedDistrictOption.dataset.code) ? parseInt(selectedDistrictOption.dataset.code) : 0;
    const wardCode = (selectedWardOption && selectedWardOption.dataset.code) ? selectedWardOption.dataset.code : '';

    if (districtId && wardCode) {
        try {
            // Tính khối lượng từ giỏ hàng để gửi lên GHN
            let totalWeightGrams = 0;
            rawItems.forEach(item => {
                const qty = item.qty || item.quantity || 1;
                const physics = estimateProductPhysics(item.name || '');
                totalWeightGrams += Math.round(physics.weight * 1000) * qty;
            });
            if (totalWeightGrams === 0) totalWeightGrams = 2000;
            estWeight = totalWeightGrams / 1000.0;

            // Luôn lấy phí chuẩn (standard) từ GHN thực tế
            const feeResponse = await fetch('/api/orders/shipping/fee', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    toDistrictId: districtId,
                    toWardCode: wardCode,
                    weightGrams: totalWeightGrams
                })
            });

            if (feeResponse.ok) {
                const feeData = await feeResponse.json();
                const standardFee = feeData.fee;

                if (selectedShipping === 'express') {
                    // Phí hỏa tốc = phí chuẩn × 2.5, nhưng chỉ update nếu chưa được set từ modal
                    if (!window._ghnExpressFee) {
                        window._ghnExpressFee = Math.round(standardFee * 2.5 / 1000) * 1000;
                    }
                    currentShippingFee = window._ghnExpressFee;
                } else {
                    currentShippingFee = standardFee;
                    window._ghnExpressFee = null; // Reset express khi về standard
                }
            }
        } catch (err) {
            console.error('[Checkout] Failed to fetch GHN fee, using default:', err);
            if (currentShippingFee <= 0) currentShippingFee = 25000;
        }
    } else {
        // Chưa chọn đủ địa chỉ — dùng giá mặc định
        currentShippingFee = 25000;
    }

    const discount = voucherState.discount;
    totalAmount = Math.max(0, subtotal + currentShippingFee - discount);

    console.log('[Checkout] 💰 Order Summary (GHN Sandbox):');
    console.log('[Checkout] - Subtotal:', subtotal);
    console.log('[Checkout] - Shipping:', currentShippingFee);
    console.log('[Checkout] - Discount:', discount);
    console.log('[Checkout] - TOTAL:', totalAmount);

    if (subtotalEl) subtotalEl.innerText = formatCurrency(subtotal);
    if (shippingEl) shippingEl.innerText = formatCurrency(currentShippingFee);
    if (discountEl) discountEl.innerText = '-' + formatCurrency(discount);
    if (totalEl) totalEl.innerText = formatCurrency(totalAmount);

    // Initial populate of dates/info on shipping display card
    const nameDisplay = document.getElementById('shippingNameDisplay');
    const timeDisplay = document.getElementById('shippingTimeDisplay');
    const priceDisplay = document.getElementById('shippingPriceDisplay');
    const subDisplay = document.getElementById('shippingSubDisplay');

    if (selectedShipping === 'standard') {
        if (nameDisplay) nameDisplay.textContent = 'Giao hàng nhanh - GHN';
        if (timeDisplay) timeDisplay.textContent = `Dự kiến giao: ${getStandardShippingEstimate().replace('Dự kiến giao: ', '')}`;
        if (priceDisplay) priceDisplay.textContent = formatCurrency(currentShippingFee);
        if (subDisplay) subDisplay.style.display = 'flex';
    } else {
        if (nameDisplay) nameDisplay.textContent = 'Hỏa tốc - Trong Ngày (GHN)';
        if (timeDisplay) timeDisplay.textContent = 'Dự kiến giao: Hôm nay';
        if (priceDisplay) priceDisplay.textContent = formatCurrency(currentShippingFee);
        if (subDisplay) subDisplay.style.display = 'none';
    }

    // Check and re-apply voucher if needed, and render voucher list
    if (typeof renderAvailableVouchers === 'function') {
        renderAvailableVouchers(subtotal);
    }

    console.log('[Checkout] ✅ Order summary updated in DOM');
    console.log('[Checkout] ============ CART LOAD END ============');
}

// ==========================================
// 4B. SHIPPING OPTION MODAL LOGIC
// ==========================================
function getStandardShippingEstimate() {
    const today = new Date();
    const tomorrow = new Date(today);
    tomorrow.setDate(today.getDate() + 1);
    const threeDays = new Date(today);
    threeDays.setDate(today.getDate() + 3);

    const formatDayMonth = (date) => {
        const day = String(date.getDate()).padStart(2, '0');
        const month = String(date.getMonth() + 1).padStart(2, '0');
        return `${day} Th${month}`;
    };

    return `Dự kiến giao: ${formatDayMonth(tomorrow)} - ${formatDayMonth(threeDays)}`;
}

async function openShippingModal() {
    tempSelectedShipping = selectedShipping;
    updateModalSelectionUI();

    const estText = document.getElementById('standardTimeEstimateText');
    if (estText) {
        estText.innerHTML = `Get by ${getStandardShippingEstimate().replace('Dự kiến giao: ', '')} <span class="help-circle">?</span>`;
    }

    // ── Lấy phí ship thực tế từ GHN ──────────────────────────────────────
    const selectedDistrictOption = districtSelect ? districtSelect.options[districtSelect.selectedIndex] : null;
    const selectedWardOption = wardSelect ? wardSelect.options[wardSelect.selectedIndex] : null;
    const districtId = (selectedDistrictOption && selectedDistrictOption.dataset.code) ? parseInt(selectedDistrictOption.dataset.code) : 0;
    const wardCode = (selectedWardOption && selectedWardOption.dataset.code) ? selectedWardOption.dataset.code : '';

    // Tính khối lượng
    let totalWeightGrams = 2000;
    try {
        const cartStr = localStorage.getItem('hyper_core_cart');
        const rawItems = JSON.parse(cartStr) || [];
        let w = 0;
        rawItems.forEach(item => {
            const qty = item.qty || item.quantity || 1;
            const physics = estimateProductPhysics(item.name || '');
            w += Math.round(physics.weight * 1000) * qty;
        });
        if (w > 0) totalWeightGrams = w;
    } catch (e) { }

    const optStandardPrice = document.querySelector('#opt-standard .option-price-tag');
    const optExpressPrice = document.querySelector('#opt-express .option-price-tag');

    if (districtId && wardCode) {
        // Lấy phí chuẩn (service_type_id=2) từ GHN thực tế
        let standardFee = currentShippingFee; // dùng giá đang có sẵn trước
        try {
            const r = await fetch('/api/orders/shipping/fee', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ toDistrictId: districtId, toWardCode: wardCode, weightGrams: totalWeightGrams })
            });
            if (r.ok) {
                const d = await r.json();
                standardFee = d.fee || standardFee;
                currentShippingFee = standardFee; // Đồng bộ lại fee ngoài
            }
        } catch (e) { }

        // Phí hỏa tốc ≈ phí chuẩn × 2.5 (GHN quy định giao trong ngày đắt hơn)
        const expressFee = Math.round(standardFee * 2.5 / 1000) * 1000;
        window._ghnExpressFee = expressFee;

        if (optStandardPrice) optStandardPrice.textContent = formatCurrency(standardFee);
        if (optExpressPrice) optExpressPrice.textContent = formatCurrency(expressFee);
    } else {
        // Chưa chọn địa chỉ — hiển thị giá mặc định
        if (optStandardPrice) optStandardPrice.textContent = '— (chưa chọn địa chỉ)';
        if (optExpressPrice) optExpressPrice.textContent = '— (chưa chọn địa chỉ)';
    }

    document.getElementById('shippingModalOverlay').classList.add('active');
}

function closeShippingModal() {
    document.getElementById('shippingModalOverlay').classList.remove('active');
}

function selectShippingOption(option) {
    tempSelectedShipping = option;
    updateModalSelectionUI();
}

function updateModalSelectionUI() {
    const standardCard = document.getElementById('opt-standard');
    const expressCard = document.getElementById('opt-express');

    if (standardCard && expressCard) {
        if (tempSelectedShipping === 'standard') {
            standardCard.classList.add('active');
            expressCard.classList.remove('active');
        } else {
            expressCard.classList.add('active');
            standardCard.classList.remove('active');
        }
    }
}

async function confirmShippingOption() {
    selectedShipping = tempSelectedShipping;

    // Khi chọn hỏa tốc: dùng phí express đã tính; khi chọn chuẩn: dùng currentShippingFee
    if (selectedShipping === 'express' && window._ghnExpressFee) {
        currentShippingFee = window._ghnExpressFee;
    }

    closeShippingModal();
    await loadAndRenderCart();
}

// ==========================================
// 4C. VOUCHER / DISCOUNT LOGIC
// ==========================================
// applyVoucher API removed

// Close modal when clicking on overlay background
document.addEventListener('DOMContentLoaded', () => {
    const overlay = document.getElementById('shippingModalOverlay');
    if (overlay) {
        overlay.addEventListener('click', (e) => {
            if (e.target === overlay) {
                closeShippingModal();
            }
        });
    }
});

// Load cart when DOM ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
        logVoucherState('Reload Checkout');
        loadAndRenderCart();
    });
} else {
    logVoucherState('Reload Checkout');
    loadAndRenderCart();
}

// ==========================================
// 5. FORM VALIDATION
// ==========================================
function validateForm() {
    const fullName = document.getElementById('fullName').value.trim();
    const phoneNumber = document.getElementById('phoneNumber').value.trim();
    const province = document.getElementById('citySelect').value;
    const district = document.getElementById('districtSelect').value;
    const ward = document.getElementById('wardSelect').value;
    const streetAddress = document.getElementById('streetAddress').value.trim();

    if (!fullName) {
        alert('Vui lòng nhập họ tên!');
        return false;
    }

    const phoneRegex = /^0[0-9]{9}$/;
    if (!phoneNumber || !phoneRegex.test(phoneNumber)) {
        alert('Số điện thoại không hợp lệ! (Phải là 10 số, bắt đầu bằng 0)');
        return false;
    }

    if (!province || !district || !ward) {
        alert('Vui lòng chọn đầy đủ Tỉnh/Thành, Quận/Huyện, Phường/Xã!');
        return false;
    }

    if (!streetAddress) {
        alert('Vui lòng nhập số nhà, tên đường!');
        return false;
    }

    return true;
}

// ==========================================
// 6. SEPAY PAYMENT INTEGRATION
// ==========================================

/**
 * Create SePay payment and display QR code
 */
async function createSePayPayment(orderId, userId, amount) {
    console.log('[SePay] Creating payment for Order:', orderId, 'Amount:', amount);

    try {
        const response = await fetch('/api/sepay/create-payment', {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${authToken}`,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                orderId: orderId,
                userId: userId,
                amount: amount
            })
        });

        console.log('[SePay] API Response status:', response.status);

        if (!response.ok) {
            const errorData = await response.json();
            throw new Error(errorData.message || 'Không thể tạo thanh toán');
        }

        const result = await response.json();
        console.log('[SePay] ✅ Payment created:', result);

        // Display QR code
        const sePayDetail = document.getElementById('sePayDetail');
        const qrImg = document.getElementById('sepay-qr-img');
        const amountEl = document.getElementById('sepay-amount');
        const descriptionEl = document.getElementById('sepay-description');

        if (result.success && result.data) {
            // Update QR code với VietQR format
            const vietQRUrl = `https://img.vietqr.io/image/970422-0364885351-qr_only.png?amount=${amount}&addInfo=${encodeURIComponent(`HYPERCORE ${orderId}`)}&accountName=${encodeURIComponent('NGUYEN VAN CHI')}`;

            if (qrImg) qrImg.src = vietQRUrl;
            if (amountEl) amountEl.innerText = formatCurrency(amount);
            if (descriptionEl) descriptionEl.innerText = `HYPERCORE ${orderId}`;

            // Show payment detail box
            if (sePayDetail) {
                sePayDetail.classList.add('active');
                console.log('[SePay] ✅ QR code displayed');
            }

            // Save order ID to sessionStorage
            sessionStorage.setItem('current_sePayOrderId', orderId);

            return true;
        } else {
            throw new Error('Phản hồi không hợp lệ từ server');
        }
    } catch (error) {
        console.error('[SePay] ❌ Error creating payment:', error);
        alert('Không thể tạo thanh toán SePay: ' + error.message);
        return false;
    }
}

/**
 * Check payment status from SePay API
 */
async function checkPaymentStatus(orderId) {
    try {
        const response = await fetch(`/api/sepay/payment-status/${orderId}`, {
            method: 'GET',
            headers: {
                'Authorization': `Bearer ${authToken}`,
                'Content-Type': 'application/json'
            }
        });

        if (!response.ok) {
            throw new Error('Failed to check payment status');
        }

        const result = await response.json();
        console.log('[SePay] Payment status:', result);

        return result;
    } catch (error) {
        console.error('[SePay] ❌ Error checking payment status:', error);
        throw error;
    }
}

/**
 * Start polling payment status every 5 seconds
 */
function startPaymentPolling(orderId) {
    console.log('[SePay] 🔄 Starting payment polling for Order:', orderId);

    const pollingStatus = document.getElementById('sepay-polling-status');
    if (pollingStatus) {
        pollingStatus.textContent = '⏳ Đang chờ thanh toán...';
        pollingStatus.classList.add('active');
    }

    let consecutiveFailures = 0;
    const MAX_FAILURES = 5;

    pollingInterval = setInterval(async () => {
        try {
            const status = await checkPaymentStatus(orderId);
            consecutiveFailures = 0; // Reset on success

            if (status.isPaid) {
                console.log('[SePay] ✅ Payment confirmed!');
                stopPaymentPolling();

                if (pollingStatus) {
                    pollingStatus.textContent = '✅ Thanh toán thành công!';
                    pollingStatus.style.background = 'rgba(34, 197, 94, 0.1)';
                    pollingStatus.style.borderColor = 'rgba(34, 197, 94, 0.3)';
                    pollingStatus.style.color = '#059669';
                }

                // Show loading success state
                const spinner = document.querySelector('#loadingOverlay .loading-spinner');
                if (spinner) {
                    spinner.style.border = 'none';
                    spinner.style.animation = 'none';
                    spinner.style.display = 'flex';
                    spinner.style.justifyContent = 'center';
                    spinner.style.alignItems = 'center';
                    spinner.innerHTML = '<span style="font-size: 64px; line-height: 1; animation: popCheck 0.5s cubic-bezier(0.175, 0.885, 0.32, 1.275) both;">✅</span>';
                }

                showLoading(
                    'Thanh toán thành công!',
                    'Đơn hàng của bạn đã được xác nhận. Đang chuyển hướng sau giây lát...'
                );

                // Clear cart and redirect
                setTimeout(() => {
                    if (voucherState.code) markVoucherAsUsed(voucherState.code);
                    localStorage.removeItem('hyper_core_cart');
                    localStorage.removeItem('hypercore_cart_items');
                    sessionStorage.setItem('current_orderId', orderId);
                    window.location.href = `/paymentcomplete?status=success&orderId=${orderId}&method=sepay`;
                }, 3000);
            }
        } catch (error) {
            consecutiveFailures++;
            console.error('[SePay] ⚠ Polling error (', consecutiveFailures, '/', MAX_FAILURES, '):', error);

            if (consecutiveFailures >= MAX_FAILURES) {
                stopPaymentPolling();
                if (pollingStatus) {
                    pollingStatus.textContent = '⚠ Không thể kiểm tra trạng thái thanh toán. Vui lòng liên hệ hỗ trợ.';
                    pollingStatus.style.background = 'rgba(239, 68, 68, 0.1)';
                    pollingStatus.style.borderColor = 'rgba(239, 68, 68, 0.3)';
                    pollingStatus.style.color = '#dc2626';
                }
                alert('Không thể kiểm tra trạng thái thanh toán. Vui lòng liên hệ hỗ trợ hoặc kiểm tra lại đơn hàng sau.');
            }
        }
    }, 5000); // Poll every 5 seconds
}

/**
 * Stop polling payment status
 */
function stopPaymentPolling() {
    if (pollingInterval) {
        clearInterval(pollingInterval);
        pollingInterval = null;
        console.log('[SePay] ⏹ Payment polling stopped');
    }
}

// ==========================================
// 7. PAYMENT BUTTON HANDLER
// ==========================================
document.getElementById('confirmPayBtn').addEventListener('click', async function () {
    logVoucherState('Click Thanh Toan');
    console.log('[Checkout] ============ PAYMENT BUTTON CLICKED ============');

    // Validate form
    if (!validateForm()) {
        console.warn('[Checkout] ⚠ Form validation failed');
        return;
    }

    // Get user info
    const userRaw = localStorage.getItem('pc_store_user');
    if (!userRaw) {
        alert('Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại!');
        clearAuthAndRedirect();
        return;
    }

    const user = JSON.parse(userRaw);
    const userId = user.userId;

    // Get form data
    const fullName = document.getElementById('fullName').value.trim();
    const phoneNumber = document.getElementById('phoneNumber').value.trim();
    const email = document.getElementById('emailAddress').value.trim();
    const province = document.getElementById('citySelect').value;
    const district = document.getElementById('districtSelect').value;
    const ward = document.getElementById('wardSelect').value;
    const streetAddress = document.getElementById('streetAddress').value.trim();
    const shippingMethod = selectedShipping;
    const deliveryNote = document.getElementById('deliveryNote').value.trim();

    const fullAddress = `${streetAddress}, ${ward}, ${district}, ${province}`;

    // Get selected payment method
    const creditCard = document.getElementById('creditCard');
    const cod = document.getElementById('cod');
    const sepay = document.getElementById('sepay');

    let paymentMethod = '';
    if (creditCard && creditCard.checked) paymentMethod = 'Credit Card';
    else if (cod && cod.checked) paymentMethod = 'COD';
    else if (sepay && sepay.checked) paymentMethod = 'SePay';

    if (!paymentMethod) {
        alert('Vui lòng chọn phương thức thanh toán!');
        return;
    }

    console.log('[Checkout] Payment method:', paymentMethod);

    // Show loading
    showLoading('Đang tạo đơn hàng...', 'Vui lòng đợi');

    try {
        const selectedDistrictOption = districtSelect ? districtSelect.options[districtSelect.selectedIndex] : null;
        const selectedWardOption = wardSelect ? wardSelect.options[wardSelect.selectedIndex] : null;
        const districtId = (selectedDistrictOption && selectedDistrictOption.dataset.code) ? parseInt(selectedDistrictOption.dataset.code) : 0;
        const wardCode = (selectedWardOption && selectedWardOption.dataset.code) ? selectedWardOption.dataset.code : '';

        // Create order via API
        const orderPayload = {
            userId: userId,
            shippingAddress: fullAddress,
            paymentMethod: paymentMethod,
            voucherCode: voucherState.code,
            discount: voucherState.discount,
            total: totalAmount,
            shippingFee: currentShippingFee,
            toWardCode: wardCode,
            toDistrictId: districtId
        };

        console.log('[Checkout] Creating order with payload:', orderPayload);

        const orderResponse = await fetch('/api/orders/place', {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${authToken}`,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(orderPayload)
        });

        console.log('[Checkout] Order API response status:', orderResponse.status);

        if (!orderResponse.ok) {
            const errorData = await orderResponse.json();
            throw new Error(errorData.message || 'Không thể tạo đơn hàng');
        }

        const orderResult = await orderResponse.json();
        currentOrderId = orderResult.newOrderId;

        console.log('[Checkout] ✅ Order created with ID:', currentOrderId);

        // If SePay is selected, create payment and show QR
        if (paymentMethod === 'SePay') {
            hideLoading();

            const success = await createSePayPayment(currentOrderId, userId, totalAmount);

            if (success) {
                // Start polling for payment confirmation
                startPaymentPolling(currentOrderId);
            }
        } else if (paymentMethod === 'COD') {
            // Keep loading active and transition to success state
            const spinner = document.querySelector('#loadingOverlay .loading-spinner');
            if (spinner) {
                spinner.style.border = 'none';
                spinner.style.animation = 'none';
                spinner.style.display = 'flex';
                spinner.style.justifyContent = 'center';
                spinner.style.alignItems = 'center';
                spinner.innerHTML = '<span style="font-size: 64px; line-height: 1; animation: popCheck 0.5s cubic-bezier(0.175, 0.885, 0.32, 1.275) both;">✅</span>';
            }

            showLoading(
                'Đặt hàng thành công!',
                'Đơn hàng của bạn đã được ghi nhận. Đang chuyển hướng sau giây lát...'
            );

            // Clear cart
            if (voucherState.code) markVoucherAsUsed(voucherState.code);
            localStorage.removeItem('hyper_core_cart');
            localStorage.removeItem('hypercore_cart_items');
            sessionStorage.setItem('current_orderId', currentOrderId);

            // Redirect after 3 seconds
            setTimeout(() => {
                window.location.href = `/paymentcomplete?status=success&orderId=${currentOrderId}&method=cod`;
            }, 3000);
        } else {
            // For other payment methods, handle accordingly
            hideLoading();
            alert('Phương thức thanh toán ' + paymentMethod + ' đang được phát triển.');
        }

    } catch (error) {
        hideLoading();
        console.error('[Checkout] ❌ Error processing payment:', error);
        alert(error.message || 'Có lỗi xảy ra khi xử lý thanh toán. Vui lòng thử lại!');
    }
});

// ==========================================
// 8. CLEANUP ON PAGE UNLOAD
// ==========================================
window.addEventListener('beforeunload', () => {
    stopPaymentPolling();
});

console.log('[Checkout] ============ SCRIPT LOADED ============');

// ==========================================
// 9. VOUCHER PICKER SYSTEM
// ==========================================
let currentAvailableVouchers = [];
let vpAllVouchers = [];         // All active vouchers from /api/vouchers/active
let vpSubtotal = 0;             // Current subtotal for discount calculation

// ── Open / Close Picker ──────────────────────────────────────
function openVoucherPicker() {
    document.getElementById('voucherPickerOverlay').classList.add('active');
    document.body.style.overflow = 'hidden';
    const searchInput = document.getElementById('vp-search-input');
    if (searchInput) { searchInput.value = ''; filterVoucherList(''); }
    renderVoucherPickerList(vpAllVouchers, vpSubtotal);
}

function closeVoucherPicker(e) {
    if (e && e.target !== document.getElementById('voucherPickerOverlay')) return;
    _closeVoucherPicker();
}

function _closeVoucherPicker() {
    document.getElementById('voucherPickerOverlay').classList.remove('active');
    document.body.style.overflow = '';
}

// ── Filter list by search ──────────────────────────────────
function filterVoucherList(query) {
    if (!query || !query.trim()) {
        renderVoucherPickerList(vpAllVouchers, vpSubtotal);
        return;
    }
    const q = query.trim().toLowerCase();
    const filtered = vpAllVouchers.filter(v =>
        v.voucherCode.toLowerCase().includes(q) ||
        (v.description || '').toLowerCase().includes(q)
    );
    renderVoucherPickerList(filtered, vpSubtotal);
}

// ── Render voucher list inside picker ─────────────────────
function renderVoucherPickerList(vouchers, subtotal) {
    const listEl = document.getElementById('vp-list');
    if (!listEl) return;

    if (!vouchers || vouchers.length === 0) {
        listEl.innerHTML = `
            <div class="vp-empty">
                <div class="vp-empty-icon">🎟️</div>
                <div class="vp-empty-text">Không tìm thấy mã giảm giá</div>
                <div class="vp-empty-sub">Thử nhập mã thủ công ở ô bên trên</div>
            </div>`;
        return;
    }

    const appliedCode = voucherState.code ? voucherState.code.toUpperCase() : null;
    const cartItems = (() => {
        try { return JSON.parse(localStorage.getItem('hyper_core_cart')) || []; } catch(e) { return []; }
    })();

    listEl.innerHTML = vouchers.map((v, i) => {
        const eligible = subtotal >= (v.minOrderValue || 0);
        const isApplied = appliedCode === v.voucherCode.toUpperCase();

        const icon = '%';

        const discountStr = v.isPercent
            ? `Giảm ${v.discountAmount}%`
            : `Giảm ${formatCurrency(v.discountAmount)}`;

        const minOrderStr = (v.minOrderValue || 0) > 0
            ? `Đơn tối thiểu ${formatCurrency(v.minOrderValue)}`
            : 'Không giới hạn đơn tối thiểu';

        const condClass = eligible ? 'can-use' : 'cant-use';
        const condText = eligible ? '✓ Đủ điều kiện' : `Cần thêm ${formatCurrency((v.minOrderValue || 0) - subtotal)}`;

        // Convert expiryDate to standard dd/M/yyyy (e.g. 31/7/2026)
        const d = new Date(v.expiryDate);
        const expStr = `${d.getDate()}/${d.getMonth() + 1}/${d.getFullYear()}`;
        
        const applyBtnClass = isApplied ? 'vp-apply-btn applied-btn' : 'vp-apply-btn';
        const applyBtnText = isApplied ? '✓ Đang dùng' : 'Áp dụng';

        // Detail: list cart items
        const cartItemsHtml = cartItems.length > 0
            ? cartItems.map(ci => `<li>${ci.name || 'Sản phẩm'} (x${ci.qty || ci.quantity || 1})</li>`).join('')
            : '<li>Tất cả sản phẩm trong giỏ hàng</li>';

        return `
        <div class="vp-card ${eligible ? 'eligible' : 'ineligible'} ${isApplied ? 'selected' : ''}" id="vp-card-${i}">
            <div class="vp-card-main">
                <div class="vp-card-badge-icon">${icon}</div>
                <div class="vp-card-info">
                    <div class="vp-card-code">${v.voucherCode}</div>
                    <div class="vp-card-expiry">HSD: ${expStr}</div>
                    <div class="vp-card-discount-line">${discountStr}</div>
                </div>
                <div class="vp-card-actions">
                    <button class="${applyBtnClass}" 
                        ${!eligible && !isApplied ? 'disabled' : ''}
                        onclick="applyFromPicker('${v.voucherCode}')">${applyBtnText}</button>
                    <span class="vp-condition-pill ${condClass}">${condText}</span>
                </div>
            </div>
            <div class="vp-card-footer">
                <button class="vp-detail-toggle" onclick="toggleVpDetail(this, 'vp-detail-${i}')">
                    Xem chi tiết <span class="vp-chevron">⌵</span>
                </button>
                <div class="vp-detail-body" id="vp-detail-${i}">
                    <div class="vp-detail-body-container">
                        <ul>
                            <li>Mô tả: ${v.description || discountStr}</li>
                            <li>Áp dụng tối đa ${v.maxPerUser || 1} lần trên tài khoản khách hàng</li>
                            <li>${minOrderStr}</li>
                            ${v.maxDiscount && v.isPercent ? `<li>Giảm tối đa ${formatCurrency(v.maxDiscount)}</li>` : ''}
                        </ul>
                        <div class="detail-sub-label">Sản phẩm áp dụng</div>
                        <ul style="max-height: 120px; overflow-y: auto;">${cartItemsHtml}</ul>
                    </div>
                </div>
            </div>
        </div>`;
    }).join('');
}

// ── Toggle expand detail ────────────────────────────────────
function toggleVpDetail(btn, detailId) {
    const detailEl = document.getElementById(detailId);
    if (!detailEl) return;
    const isOpen = detailEl.classList.contains('open');
    detailEl.classList.toggle('open', !isOpen);
    btn.classList.toggle('open', !isOpen);
    btn.querySelector('.vp-chevron').textContent = isOpen ? '▾' : '▴';
}

// ── Apply voucher from picker ───────────────────────────────
function applyFromPicker(code) {
    processVoucher(code);
    _closeVoucherPicker();
}

// ── Render available vouchers (chips + quick row) ──────────
async function renderAvailableVouchers(subtotal) {
    vpSubtotal = subtotal;

    if (!authToken || !authUser) return;
    const userObj = JSON.parse(authUser);
    const userId = userObj.userId || userObj.UserId || 0;

    try {
        // Load available vouchers for this user + order value
        const res = await fetch(`/api/vouchers/available?userId=${userId}&orderValue=${subtotal}`, {
            headers: { 'Authorization': `Bearer ${authToken}` }
        });
        if (!res.ok) throw new Error('Voucher load failed');
        currentAvailableVouchers = await res.json() || [];
    } catch(e) {
        console.warn('[Voucher] Could not load available vouchers:', e);
        currentAvailableVouchers = [];
    }

    // Also load ALL active vouchers for the picker (no auth needed)
    try {
        const res2 = await fetch('/api/vouchers/active');
        if (res2.ok) vpAllVouchers = await res2.json() || [];
    } catch(e) {
        vpAllVouchers = currentAvailableVouchers;
    }

    // Render quick chips (top 3 eligible vouchers)
    const quickRow = document.getElementById('voucher-quick-row');
    const chipsEl = document.getElementById('voucher-chips-list');

    if (quickRow && chipsEl && vpAllVouchers.length > 0) {
        quickRow.style.display = 'block';
        const eligibleTop = vpAllVouchers.filter(v => subtotal >= (v.minOrderValue || 0)).slice(0, 3);
        chipsEl.innerHTML = eligibleTop.map(v => {
            const label = v.isPercent ? `Giảm ${v.discountAmount}%` : `Giảm ${formatCurrency(v.discountAmount)}`;
            const isApplied = voucherState.code && voucherState.code.toUpperCase() === v.voucherCode.toUpperCase();
            return `<button type="button" class="voucher-chip ${isApplied ? 'applied' : ''}" 
                onclick="processVoucher('${v.voucherCode}'); updateVoucherUI();">
                ${isApplied ? '✓ ' : ''}${label}
            </button>`;
        }).join('');
    }

    // Auto re-validate currently applied voucher
    if (voucherState.code) {
        processVoucher(voucherState.code, true);
    }

    updateVoucherAppliedBadge();
}

// ── Update the applied voucher badge ──────────────────────
function updateVoucherAppliedBadge() {
    const badgeEl = document.getElementById('voucher-applied-badge');
    if (badgeEl) badgeEl.style.display = 'none';

    const inp = document.getElementById('voucher-code-input');
    const btn = document.getElementById('apply-voucher-btn');
    const msgEl = document.getElementById('voucher-message');

    if (voucherState.code && voucherState.discount > 0) {
        const code = voucherState.code.toUpperCase();
        if (inp) {
            inp.value = code;
            inp.readOnly = false;
            inp.style.background = '';
            inp.style.color = '';
            inp.style.fontWeight = '';
            inp.style.borderColor = '';
        }
        if (btn) {
            btn.textContent = 'ÁP DỤNG';
            btn.style.background = '';
            btn.style.borderColor = '';
            btn.style.color = '';
            btn.onclick = (e) => {
                e.preventDefault();
                processVoucher(inp.value.trim());
            };
        }
        if (msgEl) {
            msgEl.innerHTML = `✓ Đã áp dụng mã <strong>${code}</strong> (Tiết kiệm ${formatCurrency(voucherState.discount)})`;
            msgEl.style.color = '#16a34a';
            msgEl.style.display = 'block';
            msgEl.style.marginTop = '6px';
            msgEl.style.fontSize = '13.5px';
            msgEl.style.fontWeight = '500';
        }
    } else {
        if (inp) {
            if (voucherState.code === null) {
                if (!inp.value.trim()) inp.value = '';
            }
            inp.readOnly = false;
            inp.style.background = '';
            inp.style.color = '';
            inp.style.fontWeight = '';
            inp.style.borderColor = '';
        }
        if (btn) {
            btn.textContent = 'ÁP DỤNG';
            btn.style.background = '';
            btn.style.borderColor = '';
            btn.style.color = '';
            btn.onclick = (e) => {
                e.preventDefault();
                processVoucher(inp.value.trim());
            };
        }
        if (msgEl) {
            msgEl.style.display = 'none';
            msgEl.textContent = '';
        }
    }
}

// ── Remove applied voucher ──────────────────────────────────
function removeVoucher() {
    voucherState.code = null;
    voucherState.discount = 0;
    voucherState.source = null;
    const inp = document.getElementById('voucher-code-input');
    if (inp) inp.value = '';
    const msgEl = document.getElementById('voucher-message');
    if (msgEl) { msgEl.style.display = 'none'; msgEl.textContent = ''; }
    updateTotalsDOM();
    updateVoucherUI();
    logVoucherState('Remove Voucher');
}

// ── Full UI refresh after voucher change ──────────────────
function updateVoucherUI() {
    updateVoucherAppliedBadge();
    // Refresh chips
    const quickRow = document.getElementById('voucher-quick-row');
    const chipsEl = document.getElementById('voucher-chips-list');
    if (chipsEl && vpAllVouchers.length > 0) {
        const eligibleTop = vpAllVouchers.filter(v => vpSubtotal >= (v.minOrderValue || 0)).slice(0, 3);
        chipsEl.innerHTML = eligibleTop.map(v => {
            const label = v.isPercent ? `Giảm ${v.discountAmount}%` : `Giảm ${formatCurrency(v.discountAmount)}`;
            const isApplied = voucherState.code && voucherState.code.toUpperCase() === v.voucherCode.toUpperCase();
            return `<button type="button" class="voucher-chip ${isApplied ? 'applied' : ''}" 
                onclick="processVoucher('${v.voucherCode}'); updateVoucherUI();">
                ${isApplied ? '✓ ' : ''}${label}
            </button>`;
        }).join('');
    }
}

function processVoucher(inputCode, isAutoRevalidate = false) {
    const messageEl = document.getElementById('voucher-message');

    if (!inputCode || !inputCode.trim()) {
        if (messageEl) { messageEl.style.display = 'none'; messageEl.textContent = ''; }
        voucherState.code = null;
        voucherState.discount = 0;
        updateTotalsDOM();
        updateVoucherUI();
        logVoucherState('Clear Voucher');
        return;
    }

    const code = inputCode.trim().toUpperCase();

    // Match against available vouchers (user-eligible)
    let v = currentAvailableVouchers.find(x => x.voucherCode && x.voucherCode.toUpperCase() === code);

    // Fallback: check all active vouchers
    if (!v) {
        v = vpAllVouchers.find(x => x.voucherCode && x.voucherCode.toUpperCase() === code);
    }

    if (!v) {
        if (messageEl && !isAutoRevalidate) {
            messageEl.innerHTML = '❌ Mã không tồn tại, đã hết hạn hoặc không áp dụng được.';
            messageEl.style.color = '#ef4444';
            messageEl.style.display = 'block';
        }
        voucherState.code = null;
        voucherState.discount = 0;
        updateTotalsDOM();
        updateVoucherUI();
        return;
    }

    // Calculate discount
    const cartStr = localStorage.getItem('hyper_core_cart');
    let rawItems = [];
    try { rawItems = JSON.parse(cartStr) || []; } catch(e) {}
    let subtotal = 0;
    rawItems.forEach(item => subtotal += (item.price || 0) * (item.qty || item.quantity || 1));

    if (subtotal < (v.minOrderValue || 0) && !isAutoRevalidate) {
        if (messageEl) {
            messageEl.innerHTML = `❌ Đơn hàng chưa đủ điều kiện. Cần thêm ${formatCurrency((v.minOrderValue || 0) - subtotal)}.`;
            messageEl.style.color = '#ef4444';
            messageEl.style.display = 'block';
        }
        return;
    }

    let discount = 0;
    if (v.isPercent) {
        discount = subtotal * (v.discountAmount / 100);
        if (v.maxDiscount && discount > v.maxDiscount) discount = v.maxDiscount;
    } else {
        discount = v.discountAmount;
    }
    if (discount > subtotal + currentShippingFee) discount = subtotal + currentShippingFee;

    voucherState.discount = discount;
    voucherState.code = code;
    voucherState.source = 'api';

    if (messageEl) { messageEl.style.display = 'none'; }

    updateTotalsDOM();
    updateVoucherUI();

    if (!isAutoRevalidate) {
        // Show brief success toast
        const toastEl = document.getElementById('voucher-message');
        if (toastEl) {
            toastEl.innerHTML = `✅ Áp dụng <strong>${code}</strong> thành công! Tiết kiệm ${formatCurrency(discount)}`;
            toastEl.style.color = '#16a34a';
            toastEl.style.display = 'block';
            setTimeout(() => { toastEl.style.display = 'none'; }, 3000);
        }
    }
    logVoucherState('Apply Voucher');
}

function updateTotalsDOM() {
    const cartStr = localStorage.getItem('hyper_core_cart');
    let rawItems = [];
    try { rawItems = JSON.parse(cartStr) || []; } catch(e) {}
    let subtotal = 0;
    rawItems.forEach(item => subtotal += (item.price || 0) * (item.qty || item.quantity || 1));

    const discount = voucherState.discount || 0;
    totalAmount = Math.max(0, subtotal + currentShippingFee - discount);
    const discountEl = document.getElementById('summary-discount');
    const totalEl = document.getElementById('display-total');
    if (discountEl) discountEl.innerText = '-' + formatCurrency(discount);
    if (totalEl) totalEl.innerText = formatCurrency(totalAmount);
}

// ── Bind UI events ─────────────────────────────────────────
document.addEventListener('DOMContentLoaded', () => {
    // Apply button
    const applyBtn = document.getElementById('apply-voucher-btn');
    const voucherInput = document.getElementById('voucher-code-input');
    if (applyBtn && voucherInput) {
        applyBtn.addEventListener('click', () => {
            processVoucher(voucherInput.value.trim());
        });
        voucherInput.addEventListener('keydown', (e) => {
            if (e.key === 'Enter') { e.preventDefault(); processVoucher(voucherInput.value.trim()); }
        });
        voucherInput.addEventListener('input', () => {
            if (!voucherInput.value.trim()) {
                // Tự tay xóa hết chữ trong ô -> Hủy voucher ngay lập tức
                voucherState.code = null;
                voucherState.discount = 0;
                voucherState.source = null;
                const messageEl = document.getElementById('voucher-message');
                if (messageEl) { messageEl.style.display = 'none'; messageEl.textContent = ''; }
                updateTotalsDOM();
                updateVoucherUI();
                logVoucherState('User Cleared Input');
            }
        });
    }

    // "Xem thêm mã giảm giá" button
    const openPickerBtn = document.getElementById('open-voucher-picker-btn');
    if (openPickerBtn) {
        openPickerBtn.addEventListener('click', openVoucherPicker);
    }

    // ESC key closes picker
    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') _closeVoucherPicker();
    });
});

function markVoucherAsUsed(code) {
    if (!code) return;
    console.log('[Checkout] ✅ Voucher used:', code);
    // Clear voucher state after order placed
    voucherState.code = null;
    voucherState.discount = 0;
    voucherState.source = null;
}
