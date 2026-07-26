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
        if (loginLink) {
            loginLink.style.display = 'flex';
            // Không gán onclick để không chặn navigation mặc định của href
            // Chỉ set href đúng
            if (window.location.protocol === 'file:') {
                const isSubfolder = window.location.pathname.toLowerCase().includes('/profile/');
                loginLink.setAttribute('href', isSubfolder ? '../login.html' : 'login.html');
            } else {
                loginLink.setAttribute('href', '/Login');
            }
        }
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

        // Rebuild user dropdown items to standardize links and icons across all pages
        const dropdown = document.getElementById('userDropdown');
        if (dropdown) {
            const currentPath = window.location.pathname.toLowerCase();
            const isActivePage = (path) => currentPath === path.toLowerCase() || 
                                           (path === '/profile' && currentPath.startsWith('/profile/'));
            
            let htmlContent = `
                <div class="dropdown-header">
                    <span id="dropdownFullName">${fullName}</span>
                    <small id="dropdownEmail">${email}</small>
                </div>
            `;
            
            // Inject admin dashboard link if user is Admin
            if (user.role === 'Admin') {
                htmlContent += `
                    <a href="/admin" id="adminDashboardLink" class="dropdown-item" style="color: #0284c7; font-weight: 700;">
                        ⚙️ Trang Quản Trị
                    </a>
                `;
            }
            
            htmlContent += `
                <a href="/profile/info" class="dropdown-item ${isActivePage('/profile') || isActivePage('/profile/info') ? 'active' : ''}">
                    <svg width="16" height="16" fill="none" stroke="currentColor" stroke-width="1.8" viewBox="0 0 24 24"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>
                    Hồ sơ của tôi
                </a>
                <a href="/shoppingcart" class="dropdown-item ${isActivePage('/shoppingcart') ? 'active' : ''}">
                    <svg width="16" height="16" fill="none" stroke="currentColor" stroke-width="1.8" viewBox="0 0 24 24"><circle cx="9" cy="21" r="1"/><circle cx="20" cy="21" r="1"/><path d="M1 1h4l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L23 6H6"/></svg>
                    Giỏ hàng
                </a>
                <a href="/order-status" class="dropdown-item ${isActivePage('/order-status') ? 'active' : ''}">
                    <svg width="16" height="16" fill="none" stroke="currentColor" stroke-width="1.8" viewBox="0 0 24 24"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>
                    Đơn hàng
                </a>
                <a href="/customer-returns" class="dropdown-item ${isActivePage('/customer-returns') ? 'active' : ''}">
                    <svg width="16" height="16" fill="none" stroke="currentColor" stroke-width="1.8" viewBox="0 0 24 24"><path d="M3 12a9 9 0 0 1 15-6.7L21 8M21 3v5h-5M21 12a9 9 0 0 1-15 6.7L3 16M3 21v-5h5"/></svg>
                    Đổi trả / Hoàn tiền
                </a>
                <button class="dropdown-item logout" onclick="handleLogout()">
                    <svg width="16" height="16" fill="none" stroke="currentColor" stroke-width="1.8" viewBox="0 0 24 24"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/></svg>
                    Đăng xuất
                </button>
            `;
            
            dropdown.innerHTML = htmlContent;
        }

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

    // Xóa toàn bộ auth data
    localStorage.removeItem('pc_store_token');
    localStorage.removeItem('pc_store_refresh_token');
    localStorage.removeItem('pc_store_user');
    localStorage.removeItem('hyper_core_cart');
    localStorage.removeItem('hypercore_cart_items');
    localStorage.removeItem('hypercore_cart');
    localStorage.removeItem('shippingAddress');
    localStorage.removeItem('pc_store_cart_owner');
    sessionStorage.clear();
    console.log('✓ Auth, cart, and address data cleared');

    // Redirect về trang Login (không reload lại trang hiện tại)
    window.location.href = '/Login';
}

window.initAuthUI = initAuthUI;
window.toggleUserDropdown = toggleUserDropdown;
window.handleLogout = handleLogout;

/**
 * Auto-run khi trang load
 * Sử dụng DOMContentLoaded để đảm bảo DOM đã sẵn sàng
 */
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
        initAuthUI();
    });
} else {
    // DOM đã sẵn sàng, chạy ngay
    initAuthUI();
}
