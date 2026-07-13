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
    document.addEventListener('DOMContentLoaded', () => {
        initAuthUI();
        initGlobalSearch();
    });
} else {
    // DOM đã sẵn sàng, chạy ngay
    initAuthUI();
    initGlobalSearch();
}

// ============================================================
// GLOBAL SEARCH LOGIC FOR HEADER
// ============================================================
let globalProductsCache = null;
const LOCAL_STORAGE_KEY_RECENT = 'header_recent_searches';

window.getRecentSearches = function() {
    try {
        const stored = localStorage.getItem(LOCAL_STORAGE_KEY_RECENT);
        return stored ? JSON.parse(stored) : [];
    } catch (_) {
        return [];
    }
}

window.saveRecentSearch = function(query) {
    if (!query || query.trim() === '') return;
    const q = query.trim();
    let searches = window.getRecentSearches();
    searches = searches.filter(item => item.toLowerCase() !== q.toLowerCase());
    searches.unshift(q);
    searches = searches.slice(0, 5);
    localStorage.setItem(LOCAL_STORAGE_KEY_RECENT, JSON.stringify(searches));
}

window.removeRecentSearch = function(query) {
    let searches = window.getRecentSearches();
    searches = searches.filter(item => item.toLowerCase() !== query.toLowerCase());
    localStorage.setItem(LOCAL_STORAGE_KEY_RECENT, JSON.stringify(searches));
}

window.clearAllRecentSearches = function() {
    localStorage.removeItem(LOCAL_STORAGE_KEY_RECENT);
}

async function fetchGlobalProducts() {
    if (globalProductsCache) return globalProductsCache;
    try {
        const response = await fetch('/api/Products?PageSize=100&OnlyActive=true');
        if (response.ok) {
            const data = await response.json();
            globalProductsCache = data.items || [];
            return globalProductsCache;
        }
    } catch (e) {
        console.error('Error fetching products for global search:', e);
    }
    return [];
}

window.toggleHeaderSearch = function(btn) {
    const container = btn.closest('.header-search-container');
    const input = container.querySelector('.header-search-input');
    if (container.classList.contains('active')) {
        if (input.value.trim() !== "") {
            window.handleHeaderSearch(input);
        } else {
            container.classList.remove('active');
            window.hideHeaderSearchDropdown(container);
        }
    } else {
        container.classList.add('active');
        input.focus();
    }
}

window.handleHeaderSearch = function(input) {
    const val = input.value.trim();
    if (val !== "") {
        window.saveRecentSearch(val);
        window.location.href = '/Products?search=' + encodeURIComponent(val);
    }
}

window.showHeaderSearchDropdown = function(container, htmlContent) {
    let dropdown = container.querySelector('.header-search-dropdown');
    if (!dropdown) {
        dropdown = document.createElement('div');
        dropdown.className = 'header-search-dropdown';
        container.appendChild(dropdown);
    }
    dropdown.innerHTML = htmlContent;
    dropdown.classList.add('show');
}

window.hideHeaderSearchDropdown = function(container) {
    const dropdown = container.querySelector('.header-search-dropdown');
    if (dropdown) {
        dropdown.classList.remove('show');
    }
}

window.renderRecentSearches = function(container) {
    const searches = window.getRecentSearches();
    if (searches.length === 0) {
        window.hideHeaderSearchDropdown(container);
        return;
    }
    
    let html = `
        <div class="header-search-history">
            <div class="history-title">
                <span>Tìm kiếm gần đây</span>
                <button class="clear-all-btn" onclick="window.handleClearAllRecent(event)">Xóa tất cả</button>
            </div>
            <div class="history-items">
    `;
    
    searches.forEach(q => {
        html += `
            <div class="history-item" onclick="window.handleRecentItemClick(event, '${q.replace(/'/g, "\\'")}')">
                <div class="history-item-left">
                    <span class="history-item-icon">🕒</span>
                    <span>${q}</span>
                </div>
                <button class="delete-history-btn" onclick="window.handleDeleteRecentClick(event, '${q.replace(/'/g, "\\'")}')" title="Xóa">✕</button>
            </div>
        `;
    });
    
    html += `
            </div>
        </div>
    `;
    
    window.showHeaderSearchDropdown(container, html);
}

window.handleClearAllRecent = function(e) {
    e.stopPropagation();
    window.clearAllRecentSearches();
    const dropdown = e.target.closest('.header-search-dropdown');
    if (dropdown) {
        dropdown.classList.remove('show');
    }
};

window.handleDeleteRecentClick = function(e, q) {
    e.stopPropagation();
    window.removeRecentSearch(q);
    const container = e.target.closest('.header-search-container');
    if (container) {
        window.renderRecentSearches(container);
    }
};

window.handleRecentItemClick = function(e, q) {
    if (e.target.classList.contains('delete-history-btn')) return;
    
    const container = e.target.closest('.header-search-container');
    if (container) {
        const input = container.querySelector('.header-search-input');
        if (input) {
            input.value = q;
            window.saveRecentSearch(q);
            window.handleHeaderSearch(input);
        }
    }
};

function initGlobalSearch() {
    const searchInputs = document.querySelectorAll('.header-search-input');
    searchInputs.forEach(input => {
        const container = input.closest('.header-search-container');
        if (!container) return;
        
        // Listen for typing
        input.addEventListener('input', async (e) => {
            const val = e.target.value.trim().toLowerCase();
            if (val.length === 0) {
                window.renderRecentSearches(container);
                return;
            }
            
            const products = await fetchGlobalProducts();
            const filtered = products.filter(p => 
                p.productName.toLowerCase().includes(val) || 
                (p.brandName && p.brandName.toLowerCase().includes(val)) ||
                (p.categoryName && p.categoryName.toLowerCase().includes(val))
            );
            
            if (filtered.length === 0) {
                window.showHeaderSearchDropdown(container, `<div class="header-search-no-results">Không tìm thấy sản phẩm nào</div>`);
                return;
            }
            
            // Build html for dropdown
            let html = '';
            filtered.slice(0, 5).forEach(p => {
                const imgHtml = p.defaultImageUrl 
                    ? `<img src="${p.defaultImageUrl}" alt="${p.productName}" />` 
                    : `<div class="header-search-placeholder-img">🖥️</div>`;
                const price = p.effectivePrice ? p.effectivePrice.toLocaleString('vi-VN') + ' đ' : 'Liên hệ';
                const slugOrId = p.slug || p.productId;
                html += `
                    <a href="/product/${slugOrId}" class="header-search-item" onclick="window.saveRecentSearch(this.closest('.header-search-container').querySelector('.header-search-input').value)">
                        ${imgHtml}
                        <div class="header-search-item-info">
                            <span class="header-search-item-name">${p.productName}</span>
                            <span class="header-search-item-price">${price}</span>
                        </div>
                    </a>
                `;
            });
            window.showHeaderSearchDropdown(container, html);
        });
        
        // Listen for focus & click
        input.addEventListener('focus', () => {
            if (input.value.trim() === '') {
                window.renderRecentSearches(container);
            }
        });
        
        input.addEventListener('click', (e) => {
            e.stopPropagation();
            if (input.value.trim() === '') {
                window.renderRecentSearches(container);
            }
        });
        
        // Hide dropdown when clicking outside
        document.addEventListener('click', (e) => {
            if (!container.contains(e.target)) {
                window.hideHeaderSearchDropdown(container);
            }
        });
    });
}
