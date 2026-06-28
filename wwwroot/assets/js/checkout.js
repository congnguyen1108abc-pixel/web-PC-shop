// ============================================
// CHECKOUT.JS - Merged Logic
// Gộp logic từ filladdress.html + payments.html
// ============================================

console.log('[Checkout] ============ PAGE LOAD ============');

// ==========================================
// 0. CONFIGURATION
// ==========================================
const API_BASE = '';
const DISCOUNT = 0; // Chưa hỗ trợ voucher
let totalAmount = 0;
let currentOrderId = null;
let pollingInterval = null;

// Shipping selection states
let selectedShipping = 'standard';
let tempSelectedShipping = 'standard';
const shippingRates = { standard: 16500, express: 25000 };
const shippingNames = { standard: 'Nhanh - Shopee Xử Lý', express: 'Trong Ngày' };

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
    } catch(e) {
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
        const response = await fetch("https://provinces.open-api.vn/api/p/");
        const cities = await response.json();

        citySelect.innerHTML = '<option value="">--- Chọn Tỉnh / Thành phố ---</option>';
        cities.forEach(city => {
            const option = document.createElement("option");
            option.value = city.name;
            option.dataset.code = city.code;
            option.textContent = city.name;
            citySelect.appendChild(option);
        });

        console.log('[Checkout] ✅ Loaded', cities.length, 'provinces');
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
    const cityCode = selectedOption ? selectedOption.dataset.code : '';

    districtSelect.innerHTML = '<option value="">--- Chọn Quận / Huyện ---</option>';
    wardSelect.innerHTML = '<option value="">--- Chọn Phường / Xã ---</option>';
    districtSelect.disabled = true;
    wardSelect.disabled = true;

    if (!cityCode) return;

    try {
        districtSelect.disabled = true;
        districtSelect.innerHTML = '<option value="">Đang tải quận huyện...</option>';
        const response = await fetch(`https://provinces.open-api.vn/api/p/${cityCode}?depth=2`);
        const data = await response.json();

        districtSelect.innerHTML = '<option value="">--- Chọn Quận / Huyện ---</option>';
        data.districts.forEach(district => {
            const option = document.createElement("option");
            option.value = district.name;
            option.dataset.code = district.code;
            option.textContent = district.name;
            districtSelect.appendChild(option);
        });
        districtSelect.disabled = false;
        console.log('[Checkout] ✅ Loaded', data.districts.length, 'districts');
    } catch (error) {
        console.error('[Checkout] ❌ Error loading districts:', error);
        districtSelect.innerHTML = '<option value="">Lỗi tải dữ liệu quận huyện</option>';
    }
});

// Load wards when district changes
districtSelect.addEventListener("change", async function () {
    const selectedOption = this.options[this.selectedIndex];
    const districtCode = selectedOption ? selectedOption.dataset.code : '';

    wardSelect.innerHTML = '<option value="">--- Chọn Phường / Xã ---</option>';
    wardSelect.disabled = true;

    if (!districtCode) return;

    try {
        wardSelect.disabled = true;
        wardSelect.innerHTML = '<option value="">Đang tải phường xã...</option>';
        const response = await fetch(`https://provinces.open-api.vn/api/d/${districtCode}?depth=2`);
        const data = await response.json();

        wardSelect.innerHTML = '<option value="">--- Chọn Phường / Xã ---</option>';
        data.wards.forEach(ward => {
            const option = document.createElement("option");
            option.value = ward.name;
            option.textContent = ward.name;
            wardSelect.appendChild(option);
        });
        wardSelect.disabled = false;
        console.log('[Checkout] ✅ Loaded', data.wards.length, 'wards');
    } catch (error) {
        console.error('[Checkout] ❌ Error loading wards:', error);
        wardSelect.innerHTML = '<option value="">Lỗi tải dữ liệu phường xã</option>';
    }
});

// Initialize loading of cities
loadCities();

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

    const shipping = shippingRates[selectedShipping];
    const discount = DISCOUNT;
    totalAmount = subtotal + shipping - discount;

    console.log('[Checkout] 💰 Order Summary:');
    console.log('[Checkout] - Subtotal:', subtotal);
    console.log('[Checkout] - Shipping:', shipping);
    console.log('[Checkout] - Discount:', discount);
    console.log('[Checkout] - TOTAL:', totalAmount);

    if (subtotalEl) subtotalEl.innerText = formatCurrency(subtotal);
    if (shippingEl) shippingEl.innerText = formatCurrency(shipping);
    if (discountEl) discountEl.innerText = '-' + formatCurrency(discount);
    if (totalEl) totalEl.innerText = formatCurrency(totalAmount);

    // Initial populate of dates/info on shipping display card
    const nameDisplay = document.getElementById('shippingNameDisplay');
    const timeDisplay = document.getElementById('shippingTimeDisplay');
    const priceDisplay = document.getElementById('shippingPriceDisplay');
    const subDisplay = document.getElementById('shippingSubDisplay');
    
    if (selectedShipping === 'standard') {
        if (nameDisplay) nameDisplay.textContent = 'Nhanh - Shopee Xử Lý';
        if (timeDisplay) timeDisplay.textContent = `Dự kiến giao: ${getStandardShippingEstimate().replace('Dự kiến giao: ', '')}`;
        if (priceDisplay) priceDisplay.textContent = '16.500đ';
        if (subDisplay) subDisplay.style.display = 'flex';
    } else {
        if (nameDisplay) nameDisplay.textContent = 'Trong Ngày (Hỏa tốc)';
        if (timeDisplay) timeDisplay.textContent = 'Dự kiến giao: Hôm nay';
        if (priceDisplay) priceDisplay.textContent = '25.000đ';
        if (subDisplay) subDisplay.style.display = 'none';
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

function openShippingModal() {
    tempSelectedShipping = selectedShipping;
    updateModalSelectionUI();
    
    const estText = document.getElementById('standardTimeEstimateText');
    if (estText) {
        estText.innerHTML = `Get by ${getStandardShippingEstimate().replace('Dự kiến giao: ', '')} <span class="help-circle">?</span>`;
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

function confirmShippingOption() {
    selectedShipping = tempSelectedShipping;
    closeShippingModal();
    loadAndRenderCart();
}

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
    document.addEventListener('DOMContentLoaded', loadAndRenderCart);
} else {
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

                // Clear cart and redirect
                setTimeout(() => {
                    localStorage.removeItem('hyper_core_cart');
                    localStorage.removeItem('hypercore_cart_items');
                    sessionStorage.setItem('current_orderId', orderId);
                    alert('Thanh toán thành công! Đơn hàng của bạn đã được xác nhận.');
                    window.location.href = `/paymentcomplete?status=success&orderId=${orderId}&method=sepay`;
                }, 2000);
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
document.getElementById('confirmPayBtn').addEventListener('click', async function() {
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
    const paypal = document.getElementById('paypal');
    const sepay = document.getElementById('sepay');

    let paymentMethod = '';
    if (creditCard.checked) paymentMethod = 'Credit Card';
    else if (paypal.checked) paymentMethod = 'PayPal';
    else if (sepay.checked) paymentMethod = 'SePay';

    if (!paymentMethod) {
        alert('Vui lòng chọn phương thức thanh toán!');
        return;
    }

    console.log('[Checkout] Payment method:', paymentMethod);

    // Show loading
    showLoading('Đang tạo đơn hàng...', 'Vui lòng đợi');

    try {
        // Create order via API
        const orderPayload = {
            userId: userId,
            shippingAddress: fullAddress,
            paymentMethod: paymentMethod,
            voucherCode: null // TODO: Add voucher support later
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
        } else {
            // For other payment methods, handle accordingly
            hideLoading();
            alert('Phương thức thanh toán ' + paymentMethod + ' đang được phát triển.');
        }

    } catch (error) {
        hideLoading();
        console.error('[Checkout] ❌ Error processing payment:', error);
        alert('Có lỗi xảy ra khi xử lý thanh toán. Vui lòng thử lại!');
    }
});

// ==========================================
// 8. CLEANUP ON PAGE UNLOAD
// ==========================================
window.addEventListener('beforeunload', () => {
    stopPaymentPolling();
});

console.log('[Checkout] ============ SCRIPT LOADED ============');
