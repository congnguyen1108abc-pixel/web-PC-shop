// ============================================================
// AUTH-UI.JS - QUẢN LÝ HIỂN THỊ TRẠNG THÁI ĐĂNG NHẬP TRÊN HEADER
// ============================================================

/**
 * Khởi tạo UI authentication cho header
 * Tự động kiểm tra localStorage và cập nhật header để hiển thị:
 * - Icon "Đăng nhập" nếu chưa đăng nhập
 * - User greeting với dropdown nếu đã đăng nhập
 */
function initAuthUI() {
    console.log('=== INIT AUTH UI ===');
    const token = localStorage.getItem('pc_store_token');
    const userRaw = localStorage.getItem('pc_store_user');
    
    console.log('Token exists:', !!token);
    console.log('User info exists:', !!userRaw);

    const loginLink = document.getElementById('accountLoginLink');
    const greetWrap = document.getElementById('userGreetingWrap');

    if (!token || !userRaw) {
        // Chưa đăng nhập — hiện icon login
        console.log('User NOT logged in - showing login link');
        if (loginLink) loginLink.style.display = 'flex';
        if (greetWrap) greetWrap.style.display = 'none';
        return;
    }

    try {
        const user = JSON.parse(userRaw);
        console.log('Logged in user:', user);
        
        const fullName = user.fullName || user.email || 'Người dùng';
        const email = user.email || '';

        // Avatar: chữ cái đầu
        const initial = fullName.trim().charAt(0).toUpperCase();
        const avatarEl = document.getElementById('userAvatar');
        if (avatarEl) avatarEl.textContent = initial;

        // Tên hiển thị (lấy tên đầu tiên nếu họ tên đầy đủ)
        const firstName = fullName.split(' ').pop(); // lấy tên cuối (vd: Phong)
        const displayEl = document.getElementById('userDisplayName');
        if (displayEl) displayEl.textContent = firstName;

        // Dropdown header
        const dropName = document.getElementById('dropdownFullName');
        const dropEmail = document.getElementById('dropdownEmail');
        if (dropName) dropName.textContent = fullName;
        if (dropEmail) dropEmail.textContent = email;

        // Ẩn icon login, hiện greeting
        if (loginLink) loginLink.style.display = 'none';
        if (greetWrap) greetWrap.style.display = 'flex';
        
        console.log('✓ Auth UI updated - User greeting displayed');

    } catch (e) {
        console.error('❌ Error parsing user info:', e);
        // Token lỗi — xóa
        localStorage.removeItem('pc_store_token');
        localStorage.removeItem('pc_store_user');
        if (loginLink) loginLink.style.display = 'flex';
        if (greetWrap) greetWrap.style.display = 'none';
    }
}

/**
 * Toggle user dropdown menu
 */
function toggleUserDropdown() {
    const wrap = document.getElementById('userGreetingWrap');
    if (wrap) wrap.classList.toggle('open');
}

/**
 * Đóng dropdown khi click ra ngoài
 */
document.addEventListener('click', function (e) {
    const wrap = document.getElementById('userGreetingWrap');
    if (wrap && !wrap.contains(e.target)) {
        wrap.classList.remove('open');
    }
});

/**
 * Xử lý đăng xuất
 */
async function handleLogout() {
    console.log('=== LOGOUT ===');
    
    // Revoke token trên server nếu có
    const refreshToken = localStorage.getItem('pc_store_refresh_token');
    if (refreshToken) {
        try {
            await fetch('/api/auth/revoke-token', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ refreshToken })
            });
            console.log('✓ Token revoked on server');
        } catch (err) {
            console.warn('Failed to revoke token:', err);
        }
    }

    // Xóa local storage auth
    localStorage.removeItem('pc_store_token');
    localStorage.removeItem('pc_store_refresh_token');
    localStorage.removeItem('pc_store_user');
    
    // Xóa local/session storage giỏ hàng và địa chỉ giao hàng trực tiếp để bảo mật phiên đăng nhập
    localStorage.removeItem('hyper_core_cart');
    localStorage.removeItem('hypercore_cart_items');
    localStorage.removeItem('hypercore_cart');
    localStorage.removeItem('shippingAddress');
    localStorage.removeItem('pc_store_cart_owner');
    
    sessionStorage.removeItem('checkout_addressId');
    sessionStorage.removeItem('checkout_address');
    sessionStorage.removeItem('current_orderId');
    console.log('✓ Auth, cart, and address data cleared from storage');

    // Reload để cập nhật UI
    console.log('Reloading page...');
    window.location.reload();
}

/**
 * Auto-run khi trang load
 * Sử dụng DOMContentLoaded để đảm bảo DOM đã sẵn sàng
 */
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initAuthUI);
} else {
    // DOM đã sẵn sàng, chạy ngay
    initAuthUI();
}
