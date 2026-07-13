const API_BASE = '';
let currentUserId = null;
let authToken = null;
let userOrders = [];

// DOM elements
const orderSelect = document.getElementById('orderSelect');
const refundAmountInput = document.getElementById('refundAmount');
const provinceSelect = document.getElementById('provinceSelect');
const districtSelect = document.getElementById('districtSelect');
const wardSelect = document.getElementById('wardSelect');
const submitBtn = document.getElementById('submitBtn');

document.addEventListener('DOMContentLoaded', async () => {
    checkAuth();
    await loadProvinces();
    await loadCompletedOrders();
    await loadReturnHistory();

    // Event listeners for GHN dropdowns
    provinceSelect.addEventListener('change', onProvinceChange);
    districtSelect.addEventListener('change', onDistrictChange);
});

function checkAuth() {
    const token = localStorage.getItem('pc_store_token');
    const userStr = localStorage.getItem('pc_store_user');

    if (!token || !userStr) {
        window.location.href = '/Login?redirect=/customer-returns';
        return;
    }

    authToken = token;
    const userData = JSON.parse(userStr);
    currentUserId = userData.userId;

    document.getElementById('userDisplayName').textContent = userData.fullName || userData.username;
    document.getElementById('dropdownFullName').textContent = userData.fullName || userData.username;
    document.getElementById('dropdownEmail').textContent = userData.email;
    document.getElementById('userGreetingWrap').style.display = 'flex';
    document.getElementById('accountLoginLink').style.display = 'none';
}

// ── 1. LOAD DATA FROM API ──

async function loadProvinces() {
    try {
        const res = await fetch(`${API_BASE}/api/orders/shipping/provinces`);
        const resData = await res.json();
        const provinces = resData.data || [];

        provinces.sort((a, b) => a.ProvinceName.localeCompare(b.ProvinceName));
        provinceSelect.innerHTML = '<option value="">--- Chọn Tỉnh / Thành ---</option>';
        provinces.forEach(p => {
            const opt = document.createElement('option');
            opt.value = p.ProvinceName;
            opt.dataset.code = p.ProvinceID;
            opt.textContent = p.ProvinceName;
            provinceSelect.appendChild(opt);
        });
    } catch (err) {
        console.error('Error loading provinces:', err);
    }
}

async function onProvinceChange() {
    const selectedOpt = provinceSelect.options[provinceSelect.selectedIndex];
    const provinceId = selectedOpt ? selectedOpt.dataset.code : '';

    districtSelect.innerHTML = '<option value="">--- Chọn Quận / Huyện ---</option>';
    districtSelect.disabled = true;
    wardSelect.innerHTML = '<option value="">--- Chọn Phường / Xã ---</option>';
    wardSelect.disabled = true;

    if (!provinceId) return;

    try {
        districtSelect.innerHTML = '<option value="">Đang tải quận huyện...</option>';
        const res = await fetch(`${API_BASE}/api/orders/shipping/districts?provinceId=${provinceId}`);
        const resData = await res.json();
        const districts = resData.data || [];

        districts.sort((a, b) => a.DistrictName.localeCompare(b.DistrictName));
        districtSelect.innerHTML = '<option value="">--- Chọn Quận / Huyện ---</option>';
        districts.forEach(d => {
            const opt = document.createElement('option');
            opt.value = d.DistrictName;
            opt.dataset.code = d.DistrictID;
            opt.textContent = d.DistrictName;
            districtSelect.appendChild(opt);
        });
        districtSelect.disabled = false;
    } catch (err) {
        console.error('Error loading districts:', err);
        districtSelect.innerHTML = '<option value="">Lỗi tải quận huyện</option>';
    }
}

async function onDistrictChange() {
    const selectedOpt = districtSelect.options[districtSelect.selectedIndex];
    const districtId = selectedOpt ? selectedOpt.dataset.code : '';

    wardSelect.innerHTML = '<option value="">--- Chọn Phường / Xã ---</option>';
    wardSelect.disabled = true;

    if (!districtId) return;

    try {
        wardSelect.innerHTML = '<option value="">Đang tải phường xã...</option>';
        const res = await fetch(`${API_BASE}/api/orders/shipping/wards?districtId=${districtId}`);
        const resData = await res.json();
        const wards = resData.data || [];

        wards.sort((a, b) => a.WardName.localeCompare(b.WardName));
        wardSelect.innerHTML = '<option value="">--- Chọn Phường / Xã ---</option>';
        wards.forEach(w => {
            const opt = document.createElement('option');
            opt.value = w.WardName;
            opt.dataset.code = w.WardCode;
            opt.textContent = w.WardName;
            wardSelect.appendChild(opt);
        });
        wardSelect.disabled = false;
    } catch (err) {
        console.error('Error loading wards:', err);
        wardSelect.innerHTML = '<option value="">Lỗi tải phường xã</option>';
    }
}

async function loadCompletedOrders() {
    try {
        // Gọi API lấy lịch sử đơn hàng của khách hàng (lọc status = Hoàn tất)
        const res = await fetch(`${API_BASE}/api/orders/history/${currentUserId}?pageNumber=1&pageSize=100&status=${encodeURIComponent('Hoàn tất')}`, {
            headers: {
                'Authorization': `Bearer ${authToken}`
            }
        });
        if (!res.ok) throw new Error('Failed to fetch orders');

        const result = await res.json();
        userOrders = result.items || [];

        orderSelect.innerHTML = '<option value="">--- Chọn đơn hàng ---</option>';
        userOrders.forEach(o => {
            const opt = document.createElement('option');
            opt.value = o.orderId;
            opt.textContent = `#${o.orderId} - ${new Date(o.orderDate).toLocaleDateString('vi-VN')} (${o.finalAmount.toLocaleString('vi-VN')}đ)`;
            orderSelect.appendChild(opt);
        });

        // Hỗ trợ điền sẵn từ QueryString
        const urlParams = new URLSearchParams(window.location.search);
        const preselectId = urlParams.get('orderId');
        if (preselectId) {
            orderSelect.value = preselectId;
            onOrderChange();
        }
    } catch (err) {
        console.error('Error loading completed orders:', err);
    }
}

function onOrderChange() {
    const orderId = parseInt(orderSelect.value);
    const order = userOrders.find(o => o.orderId === orderId);
    if (order) {
        refundAmountInput.value = order.finalAmount.toLocaleString('vi-VN') + 'đ';
        refundAmountInput.dataset.value = order.finalAmount;
    } else {
        refundAmountInput.value = '';
        refundAmountInput.dataset.value = '0';
    }
}

async function loadReturnHistory() {
    const listContainer = document.getElementById('requestsList');
    try {
        const res = await fetch(`${API_BASE}/api/ReturnRequests/admin/list?pageNumber=1&pageSize=100`, {
            headers: { 'Authorization': `Bearer ${authToken}` }
        });
        if (!res.ok) throw new Error('Failed to load history');

        const result = await res.json();
        const allItems = result.items || [];
        // Lọc hiển thị yêu cầu của riêng khách hàng hiện tại
        const myItems = allItems.filter(x => x.userId === currentUserId);

        if (myItems.length === 0) {
            listContainer.innerHTML = `
                <div class="empty-state">
                    <div class="empty-icon">📦</div>
                    <p>Bạn chưa gửi yêu cầu đổi trả nào.</p>
                </div>`;
            return;
        }

        let html = '';
        myItems.forEach(item => {
            html += `
            <div class="request-item">
                <div class="request-header">
                    <span class="request-id">Yêu cầu #${item.returnId}</span>
                    <span class="request-date">${new Date(item.createdAt).toLocaleString('vi-VN')}</span>
                </div>
                <div class="request-details">
                    <div class="detail-row">
                        <span class="detail-label">Đơn hàng gốc</span>
                        <span class="detail-value">#${item.orderId}</span>
                    </div>
                    <div class="detail-row">
                        <span class="detail-label">Số tiền hoàn</span>
                        <span class="detail-value" style="font-weight:700; color:#111;">${item.refundAmount.toLocaleString('vi-VN')}đ</span>
                    </div>
                    <div class="detail-row">
                        <span class="detail-label">Lý do</span>
                        <span class="detail-value" style="max-width:70%; text-align:right;">${item.reason}</span>
                    </div>
                    <div class="detail-row">
                        <span class="detail-label">Trạng thái</span>
                        <span class="badge ${getBadgeClass(item.status)}">${getBadgeText(item.status)}</span>
                    </div>
                    ${item.returnTrackingCode ? `
                    <div class="detail-row" style="margin-top:8px;">
                        <span class="detail-label">Vận đơn thu hồi GHN</span>
                        <span class="detail-value" style="font-family:monospace; color:#0ea5e9; font-weight:800;">${item.returnTrackingCode}</span>
                    </div>` : ''}
                    ${item.adminNote ? `
                    <div class="admin-note-box">
                        <strong>Phản hồi từ Admin:</strong> ${item.adminNote}
                    </div>` : ''}
                </div>
            </div>`;
        });
        listContainer.innerHTML = html;
    } catch (err) {
        console.error('Error loading history:', err);
        listContainer.innerHTML = '<div style="color:red; text-align:center; padding:20px;">Lỗi tải lịch sử yêu cầu.</div>';
    }
}

function getBadgeClass(status) {
    const map = {
        'Pending': 'badge-pending',
        'Approved': 'badge-approved',
        'Picking': 'badge-picking',
        'Received': 'badge-received',
        'Refunded': 'badge-refunded',
        'Rejected': 'badge-rejected'
    };
    return map[status] || 'badge-pending';
}

function getBadgeText(status) {
    const map = {
        'Pending': 'Chờ duyệt',
        'Approved': 'Đã duyệt',
        'Picking': 'Shipper đang lấy',
        'Received': 'Đã nhận hàng',
        'Refunded': 'Đã hoàn tiền',
        'Rejected': 'Từ chối'
    };
    return map[status] || status;
}

// ── 2. SUBMIT FORM ──

async function handleReturnSubmit(e) {
    e.preventDefault();
    const orderId = parseInt(orderSelect.value);
    if (!orderId) {
        alert('Vui lòng chọn đơn hàng!');
        return;
    }

    const reason = document.getElementById('returnReason').value.trim();
    const evidenceImages = document.getElementById('evidenceImages').value.trim();
    const refundAmount = parseFloat(refundAmountInput.dataset.value);
    const accountNo = document.getElementById('accountNo').value.trim();
    const accountName = document.getElementById('accountName').value.trim().toUpperCase();

    // Lấy thông tin địa chỉ thu hồi
    const streetAddress = document.getElementById('streetAddress').value.trim();
    const ward = wardSelect.value;
    const district = districtSelect.value;
    const province = provinceSelect.value;

    const selectedDistrictOption = districtSelect.options[districtSelect.selectedIndex];
    const districtId = selectedDistrictOption ? parseInt(selectedDistrictOption.dataset.code) : 0;
    const selectedWardOption = wardSelect.options[wardSelect.selectedIndex];
    const wardCode = selectedWardOption ? selectedWardOption.dataset.code : '';

    const fullAddress = `${streetAddress}, ${ward}, ${district}, ${province}`;

    submitBtn.disabled = true;
    submitBtn.textContent = 'Đang gửi...';

    const bankName = document.getElementById('bp_value_returnBankPickerContainer')?.value
                  || window._returnSelectedBank || '';

    if (!bankName) {
        alert('Vui lòng chọn ngân hàng!');
        return;
    }

    const body = {
        orderId,
        userId: currentUserId,
        reason,
        evidenceImages,
        refundAmount,
        refundBankName: bankName,
        refundAccountNo: accountNo,
        refundAccountName: accountName,
        returnAddress: fullAddress,
        returnWardCode: wardCode,
        returnDistrictId: districtId
    };

    try {
        const res = await fetch(`${API_BASE}/api/ReturnRequests/customer/request`, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${authToken}`,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(body)
        });

        const data = await res.json();
        if (res.ok) {
            alert('Gửi yêu cầu đổi trả thành công!');
            document.getElementById('returnForm').reset();
            districtSelect.disabled = true;
            wardSelect.disabled = true;
            onOrderChange();
            await loadReturnHistory();
        } else {
            alert(data.message || 'Lỗi gửi yêu cầu đổi trả.');
        }
    } catch (err) {
        console.error('Error submitting return request:', err);
        alert('Có lỗi xảy ra, vui lòng thử lại.');
    } finally {
        submitBtn.disabled = false;
        submitBtn.textContent = 'Gửi yêu cầu đổi trả';
    }
}

