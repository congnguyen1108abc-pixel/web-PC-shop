// ============================================================
// SEARCH.JS - QUẢN LÝ VÀ XỬ LÝ TÌM KIẾM TOÀN CỤC
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
};

window.saveRecentSearch = function(query) {
    if (!query || query.trim() === '') return;
    const q = query.trim();
    let searches = window.getRecentSearches();
    searches = searches.filter(item => item.toLowerCase() !== q.toLowerCase());
    searches.unshift(q);
    searches = searches.slice(0, 5);
    localStorage.setItem(LOCAL_STORAGE_KEY_RECENT, JSON.stringify(searches));
};

window.removeRecentSearch = function(query) {
    let searches = window.getRecentSearches();
    searches = searches.filter(item => item.toLowerCase() !== query.toLowerCase());
    localStorage.setItem(LOCAL_STORAGE_KEY_RECENT, JSON.stringify(searches));
};

window.clearAllRecentSearches = function() {
    localStorage.removeItem(LOCAL_STORAGE_KEY_RECENT);
};

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
    if (!container) return;
    const input = container.querySelector('.header-search-input');
    if (container.classList.contains('active')) {
        if (input && input.value.trim() !== "") {
            window.handleHeaderSearch(input);
        } else {
            container.classList.remove('active');
            window.hideHeaderSearchDropdown(container);
        }
    } else {
        container.classList.add('active');
        if (input) input.focus();
    }
};

window.handleHeaderSearch = function(input) {
    const val = input ? input.value.trim() : '';
    if (val !== "") {
        window.saveRecentSearch(val);
        window.location.href = '/Products?search=' + encodeURIComponent(val);
    }
};

window.showHeaderSearchDropdown = function(container, htmlContent) {
    let dropdown = container.querySelector('.header-search-dropdown');
    if (!dropdown) {
        dropdown = document.createElement('div');
        dropdown.className = 'header-search-dropdown';
        container.appendChild(dropdown);
    }
    dropdown.innerHTML = htmlContent;
    dropdown.classList.add('show');
};

window.hideHeaderSearchDropdown = function(container) {
    const dropdown = container.querySelector('.header-search-dropdown');
    if (dropdown) {
        dropdown.classList.remove('show');
    }
};

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
};

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
                (p.productName && p.productName.toLowerCase().includes(val)) || 
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

// Auto-run khi DOM sẵn sàng
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initGlobalSearch);
} else {
    initGlobalSearch();
}
