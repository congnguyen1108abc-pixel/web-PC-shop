// profile-common.js
const API_BASE = window.location.origin;

window.currentProfileCache = null;

document.addEventListener("DOMContentLoaded", async () => {
    // 1. Authenticate user
    const authToken = localStorage.getItem('pc_store_token');
    const userRaw = localStorage.getItem('pc_store_user');
    if (!authToken || !userRaw) {
        window.location.href = '/Login';
        return;
    }

    const user = JSON.parse(userRaw);
    const userId = user.userId;

    // 2. Fetch profile data for details
    let profile = null;
    try {
        const res = await fetch(`${API_BASE}/api/Users/profile/${userId}`, {
            headers: { 'Authorization': `Bearer ${authToken}` }
        });
        if (res.ok) {
            profile = await res.json();
            window.currentProfileCache = profile;
        } else if (res.status === 401) {
            // Token expired
            localStorage.clear();
            window.location.href = '/Login';
            return;
        }
    } catch (err) {
        console.error("Error loading common profile:", err);
    }

    const fullName = profile ? profile.fullName : (user.fullName || 'Người dùng');
    const email = profile ? profile.email : user.email;
    const avatarUrl = profile ? profile.avatarUrl : '';

    // 3. Render dynamic sidebar
    const sidebarContainer = document.getElementById('profile-sidebar-container');
    if (sidebarContainer) {
        const path = window.location.pathname.toLowerCase();
        
        const isInfoActive = path.includes('/profile/info');
        const isPasswordActive = path.includes('/profile/password');
        const isBankActive = path.includes('/profile/bank');
        const isAddressActive = path.includes('/profile/address');
        const isLoyaltyActive = path.includes('/profile/loyalty');
        const isOrdersActive = path.includes('/profile/orders');
        const isNotifActive = path.includes('/profile/notifications');

        const isProfileOpen = isInfoActive || isPasswordActive || isBankActive || isAddressActive;
        const initial = fullName.trim().charAt(0).toUpperCase() || 'U';
        
        let avatarHTML = `<div class="sidebar-avatar">${initial}</div>`;
        if (avatarUrl && avatarUrl.trim().startsWith('http')) {
            avatarHTML = `<img src="${avatarUrl}" class="sidebar-avatar" style="object-fit: cover;">`;
        }

        sidebarContainer.className = "profile-sidebar glass-card";
        sidebarContainer.innerHTML = `
            <div class="user-summary">
                ${avatarHTML}
                <div class="user-info-text">
                    <h3>${fullName}</h3>
                    <p>${email}</p>
                </div>
            </div>
            <div class="sidebar-menu">
                <div class="menu-dropdown-wrapper ${isProfileOpen ? 'open' : ''}" id="myProfileWrapper">
                    <button class="menu-item" onclick="toggleProfileDropdown(event)" style="padding-right: 12px;">
                        👤 Hồ sơ của tôi
                        <svg class="dropdown-chevron" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                            <polyline points="6 9 12 15 18 9"/>
                        </svg>
                    </button>
                    <div class="menu-dropdown-items">
                        <a href="/profile/info" class="menu-subitem ${isInfoActive ? 'active' : ''}">Thông tin cá nhân</a>
                        <a href="/profile/password" class="menu-subitem ${isPasswordActive ? 'active' : ''}">Đổi mật khẩu</a>
                        <a href="/profile/bank" class="menu-subitem ${isBankActive ? 'active' : ''}">Tài khoản ngân hàng</a>
                        <a href="/profile/address" class="menu-subitem ${isAddressActive ? 'active' : ''}">Địa chỉ nhận hàng</a>
                    </div>
                </div>
                
                <a href="/profile/loyalty" class="menu-item ${isLoyaltyActive ? 'active' : ''}">
                    💎 Hạng thành viên
                </a>
                
                <a href="/profile/orders" class="menu-item ${isOrdersActive ? 'active' : ''}">
                    📦 Đơn mua của tôi
                </a>
                
                <a href="/profile/notifications" class="menu-item ${isNotifActive ? 'active' : ''}" id="sidebarNotifLink">
                    🔔 Thông báo
                </a>
            </div>
        `;
    }

    // Call page-specific initiation function if it exists
    if (typeof initPage === 'function') {
        initPage(userId, authToken, profile);
    }
});

// Intercept profile sidebar clicks for Single Page Application (SPA) behavior
document.addEventListener('click', (e) => {
    const link = e.target.closest('a.menu-subitem, a.menu-item');
    if (link) {
        const href = link.getAttribute('href');
        if (href && href.startsWith('/profile/')) {
            e.preventDefault();
            navigateToProfilePage(href);
        }
    }
});

// Handle browser navigation (back/forward)
window.addEventListener('popstate', () => {
    navigateToProfilePage(window.location.pathname);
});

// SPA page transition helper
async function navigateToProfilePage(url) {
    try {
        // Reset page-specific globals to avoid leaks/errors from previous page's scripts
        window.initPage = null;

        const res = await fetch(url);
        if (!res.ok) {
            window.location.href = url;
            return;
        }
        const html = await res.text();
        const parser = new DOMParser();
        const doc = parser.parseFromString(html, 'text/html');
        
        // 1. Update Title
        document.title = doc.title;
        
        // 2. Swap Content inside the main panel
        const newMain = doc.querySelector('.profile-main');
        const currentMain = document.querySelector('.profile-main');
        if (newMain && currentMain) {
            currentMain.innerHTML = newMain.innerHTML;
        }
        
        // 3. Update Browser URL and Sidebar Active State
        if (window.location.pathname !== url) {
            history.pushState(null, '', url);
        }
        updateSidebarActiveState(url);
        
        // 4. Remove injected scripts from previous AJAX swaps
        document.querySelectorAll('.injected-page-script').forEach(el => el.remove());
        
        // 5. Extract and run inline scripts from the fetched page
        const scripts = doc.querySelectorAll('script:not([src])');
        scripts.forEach(script => {
            const newScript = document.createElement('script');
            newScript.textContent = script.textContent;
            newScript.className = 'injected-page-script';
            document.body.appendChild(newScript);
        });
        
        // 6. Re-run initPage with current cache
        const authToken = localStorage.getItem('pc_store_token');
        const userRaw = localStorage.getItem('pc_store_user');
        if (authToken && userRaw) {
            const user = JSON.parse(userRaw);
            if (typeof window.initPage === 'function') {
                window.initPage(user.userId, authToken, window.currentProfileCache);
            }
        }
    } catch (e) {
        console.error("SPA transition failed, falling back to full reload:", e);
        window.location.href = url;
    }
}

// Update Active Classes and Dropdown expansion on navigation
function updateSidebarActiveState(url) {
    const path = url.toLowerCase();
    
    const isInfoActive = path.includes('/profile/info');
    const isPasswordActive = path.includes('/profile/password');
    const isBankActive = path.includes('/profile/bank');
    const isAddressActive = path.includes('/profile/address');
    const isLoyaltyActive = path.includes('/profile/loyalty');
    const isOrdersActive = path.includes('/profile/orders');
    const isNotifActive = path.includes('/profile/notifications');

    const isProfileOpen = isInfoActive || isPasswordActive || isBankActive || isAddressActive;

    // Update active classes on subitems
    const subitems = document.querySelectorAll('.menu-subitem');
    subitems.forEach(el => {
        const href = el.getAttribute('href').toLowerCase();
        if (path.includes(href)) {
            el.classList.add('active');
        } else {
            el.classList.remove('active');
        }
    });

    // Update active classes on main menu items
    const menuitems = document.querySelectorAll('.sidebar-menu > .menu-item');
    menuitems.forEach(el => {
        const href = el.getAttribute('href');
        if (href) {
            if (path.includes(href.toLowerCase())) {
                el.classList.add('active');
            } else {
                el.classList.remove('active');
            }
        }
    });

    // Update dropdown state
    const wrapper = document.getElementById('myProfileWrapper');
    if (wrapper) {
        if (isProfileOpen) {
            wrapper.classList.add('open');
        } else {
            wrapper.classList.remove('open');
        }
    }
}

// Dropdown Toggle helper
function toggleProfileDropdown(e) {
    e.preventDefault();
    const wrapper = document.getElementById('myProfileWrapper');
    if (wrapper) {
        wrapper.classList.toggle('open');
    }
}

// Currency Formatter
function formatVND(val) {
    return Number(val).toLocaleString('vi-VN') + 'đ';
}
