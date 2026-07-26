// Global Cart Drawer Component
(function () {
    let currentDrawerTab = 'cart'; // 'cart' or 'recent'

    // Inject drawer HTML on load if not present
    function injectDrawerHTML() {
        if (document.getElementById('cartDrawer')) return;

        // Drawer overlay
        const overlay = document.createElement('div');
        overlay.className = 'cart-drawer-overlay';
        overlay.id = 'cartOverlay';
        document.body.appendChild(overlay);

        // Drawer container
        const drawer = document.createElement('div');
        drawer.className = 'cart-drawer';
        drawer.id = 'cartDrawer';
        drawer.innerHTML = `
            <!-- Header -->
            <div class="cart-drawer-header">
                <div class="cart-drawer-tabs">
                    <span class="cart-tab active">Cart <span class="cart-badge-count" id="drawerCartCount">0</span></span>
                    <span class="cart-tab">Recently viewed</span>
                </div>
                <div style="display: flex; align-items: center; gap: 10px;">
                    <button class="cart-clear-all-btn" id="cartClearAllBtn" onclick="clearCartGlobal()" style="display: none;">
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <polyline points="3 6 5 6 21 6"></polyline>
                            <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path>
                            <line x1="10" y1="11" x2="10" y2="17"></line>
                            <line x1="14" y1="11" x2="14" y2="17"></line>
                        </svg>
                        Xóa tất cả
                    </button>
                    <button class="cart-drawer-close" id="cartCloseBtn">
                        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <line x1="18" y1="6" x2="6" y2="18"></line>
                            <line x1="6" y1="6" x2="18" y2="18"></line>
                        </svg>
                    </button>
                </div>
            </div>

            <!-- Scrollable Content -->
            <div class="cart-drawer-content">
                <!-- Cart Items -->
                <div class="cart-items-list" id="cartItemsList"></div>

                <!-- Recommendation Section -->
                <div class="cart-recommendations"></div>
            </div>

            <!-- Actions Bar -->
            <div class="cart-drawer-actions">
                <div class="action-item">
                    <span class="action-icon">📝</span>
                    <span>Order note</span>
                </div>
                <div class="action-item">
                    <span class="action-icon">🚚</span>
                    <span>Shipping</span>
                </div>
                <div class="action-item">
                    <span class="action-icon">🏷️</span>
                    <span>Discount</span>
                </div>
            </div>

            <!-- Footer -->
            <div class="cart-drawer-footer">
                <div class="cart-subtotal-row">
                    <div class="subtotal-left">
                        <span>Taxes included and shipping calculated at checkout.</span>
                    </div>
                    <div class="subtotal-right">
                        <span class="subtotal-label">Subtotal</span>
                        <span class="subtotal-amount" id="drawerSubtotal">$0.00 USD</span>
                    </div>
                </div>
                <button class="cart-checkout-btn" onclick="window.location.href='/checkout'">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="margin-right:8px;">
                        <rect x="3" y="11" width="18" height="11" rx="2" ry="2"></rect>
                        <path d="M7 11V7a5 5 0 0 1 10 0v4"></path>
                    </svg>
                    Thanh toán
                </button>
            </div>
        `;
        document.body.appendChild(drawer);

        // Bind overlay and close button click events
        document.getElementById('cartCloseBtn').addEventListener('click', closeCartDrawer);
        overlay.addEventListener('click', closeCartDrawer);

        // Bind tab switching events
        initDrawerTabs();
    }

    let cachedRecommendations = [];

    async function fetchCartRecommendations() {
        let cart = [];
        try {
            cart = JSON.parse(localStorage.getItem('hyper_core_cart') || '[]');
        } catch(e) {}

        let url = '/api/recommendations/homepage?topN=4';
        if (cart.length > 0) {
            const firstItem = cart[0];
            const productId = firstItem.id;
            if (productId) {
                url = `/api/recommendations/product/${productId}?topN=4`;
            }
        }

        try {
            const res = await fetch(url);
            if (res.ok) {
                const data = await res.json();
                cachedRecommendations = data.map(item => ({
                    id: item.productId,
                    name: item.productName,
                    price: item.price,
                    oldPrice: item.discountPrice > 0 ? item.price : 0,
                    img: item.defaultImageUrl || 'https://placehold.co/100x100?text=No+Image',
                    specs: 'Sản phẩm gợi ý'
                }));
            }
        } catch (e) {
            console.error('[fetchCartRecommendations Error]:', e);
        }
    }

    function openCartDrawer() {
        const cartDrawer = document.getElementById('cartDrawer');
        const cartOverlay = document.getElementById('cartOverlay');
        if (cartDrawer && cartOverlay) {
            // Render before opening to match correct active tab state
            renderCartDrawer();
            cartDrawer.classList.add('open');
            cartOverlay.classList.add('open');
            document.body.style.overflow = 'hidden';
        }
    }

    function closeCartDrawer() {
        const cartDrawer = document.getElementById('cartDrawer');
        const cartOverlay = document.getElementById('cartOverlay');
        if (cartDrawer && cartOverlay) {
            cartDrawer.classList.remove('open');
            cartOverlay.classList.remove('open');
            document.body.style.overflow = '';
        }
    }

    // Expose openCartDrawer and closeCartDrawer globally
    window.openCartDrawer = openCartDrawer;
    window.closeCartDrawer = closeCartDrawer;

    // Bind tab events
    function initDrawerTabs() {
        const tabs = document.querySelectorAll('#cartDrawer .cart-tab');
        if (tabs.length >= 2) {
            tabs[0].addEventListener('click', () => {
                currentDrawerTab = 'cart';
                tabs[0].classList.add('active');
                tabs[1].classList.remove('active');
                renderCartDrawer();
            });
            tabs[1].addEventListener('click', () => {
                currentDrawerTab = 'recent';
                tabs[1].classList.add('active');
                tabs[0].classList.remove('active');
                renderCartDrawer();
            });
        }
    }

    window.viewProductDetailGlobal = function(id, name) {
        if (window.location.protocol === 'file:') {
            window.location.href = `product-detail.html?id=${id}`;
        } else {
            window.location.href = `/product-detail?id=${id}`;
        }
    };

    // Render cart items inside the drawer
    async function renderCartDrawer() {
        const listEl = document.getElementById('cartItemsList');
        const countEl = document.getElementById('drawerCartCount');
        const badgeEl = document.getElementById('cartCount');
        const subtotalEl = document.getElementById('drawerSubtotal');

        if (!listEl) return;

        let cart = JSON.parse(localStorage.getItem('hyper_core_cart')) || [];

        const recEl = document.querySelector('.cart-recommendations');
        const actionsEl = document.querySelector('.cart-drawer-actions');
        const footerEl = document.querySelector('.cart-drawer-footer');

        const clearAllBtn = document.getElementById('cartClearAllBtn');

        // Render Recently Viewed tab
        if (currentDrawerTab === 'recent') {
            if (clearAllBtn) clearAllBtn.style.display = 'none';
            if (recEl) recEl.style.display = 'none';
            if (actionsEl) actionsEl.style.display = 'none';
            if (footerEl) footerEl.style.display = 'none';

            let recentlyViewed = [];
            try {
                recentlyViewed = JSON.parse(localStorage.getItem('hyper_core_recently_viewed')) || [];
            } catch (e) {}

            if (recentlyViewed.length === 0) {
                listEl.innerHTML = `
                    <div class="cart-empty-state" style="display: flex; flex-direction: column; align-items: center; justify-content: center; text-align: center; padding: 80px 24px; min-height: 380px;">
                        <h2 style="font-size: 26px; font-weight: 700; margin-bottom: 12px; color: #000000; font-family: 'Inter', sans-serif;">No recently viewed products.</h2>
                        <p style="font-size: 15px; color: rgba(0, 0, 0, 0.5); line-height: 1.6; margin-bottom: 30px; font-family: 'Inter', sans-serif;">Browse our premium electronic products to see them listed here!</p>
                        <button class="continue-shopping-btn" onclick="closeCartDrawer(); window.location.href='/Products'" style="background: #fff; color: #FFFFFF; border: none; padding: 14px 28px; border-radius: 99px; font-size: 15px; font-weight: 600; display: inline-flex; align-items: center; gap: 8px; cursor: pointer; transition: 0.3s; font-family: 'Inter', sans-serif;">
                            Explore products
                            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="transform: translateY(1px);">
                                <line x1="5" y1="12" x2="19" y2="12"></line>
                                <polyline points="12 5 19 12 12 19"></polyline>
                            </svg>
                        </button>
                    </div>
                `;
                return;
            }

            listEl.innerHTML = '';
            recentlyViewed.forEach(item => {
                const formattedPrice = item.price.toLocaleString('vi-VN') + ' đ';
                
                let imgUrl = item.img;
                if (window.location.protocol === 'file:' && imgUrl && imgUrl.startsWith('/')) {
                    imgUrl = '../wwwroot' + imgUrl;
                }

                const itemEl = document.createElement('div');
                itemEl.className = 'cart-item-row';
                itemEl.innerHTML = `
                    <img src="${imgUrl}" class="cart-item-img" alt="${item.name}" style="cursor:pointer;" onclick="viewProductDetailGlobal(${item.id}, '${item.name}')">
                    <div class="cart-item-details">
                        <span class="cart-item-name" style="cursor:pointer;" onclick="viewProductDetailGlobal(${item.id}, '${item.name}')">${item.name}</span>
                        <span class="cart-item-specs">${item.specs || ''}</span>
                        <span class="cart-item-price">${formattedPrice}</span>
                    </div>
                    <div class="cart-item-controls">
                        <button class="recommend-add-btn" onclick="addRecommendedItemGlobal(${item.id})">+ Add</button>
                    </div>
                `;
                listEl.appendChild(itemEl);
            });

            // Update badge count inside drawer tab header to reflect actual cart items
            const totalItems = cart.reduce((sum, item) => sum + item.qty, 0);
            if (countEl) countEl.textContent = totalItems;
            return;
        }

        // Render Cart tab
        if (recEl) recEl.style.display = 'block';
        if (actionsEl) actionsEl.style.display = 'flex';
        if (footerEl) footerEl.style.display = 'block';

        if (cart.length === 0) {
            if (clearAllBtn) clearAllBtn.style.display = 'none';
            listEl.innerHTML = `
                <div class="cart-empty-state" style="display: flex; flex-direction: column; align-items: center; justify-content: center; text-align: center; padding: 80px 24px; min-height: 380px;">
                    <h2 style="font-size: 26px; font-weight: 700; margin-bottom: 12px; color: #000000; font-family: 'Inter', sans-serif;">Your cart is currently empty.</h2>
                    <p style="font-size: 15px; color: rgba(0, 0, 0, 0.5); line-height: 1.6; margin-bottom: 30px; font-family: 'Inter', sans-serif;">Not sure where to start?<br>Try these collections:</p>
                    <button class="continue-shopping-btn" onclick="closeCartDrawer(); window.location.href='/Products'" style="background: #fff; color: #FFFFFF; border: none; padding: 14px 28px; border-radius: 99px; font-size: 15px; font-weight: 600; display: inline-flex; align-items: center; gap: 8px; cursor: pointer; transition: 0.3s; font-family: 'Inter', sans-serif;">
                        Continue shopping 
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="transform: translateY(1px);">
                            <line x1="5" y1="12" x2="19" y2="12"></line>
                            <polyline points="12 5 19 12 12 19"></polyline>
                        </svg>
                    </button>
                </div>
            `;
            if (recEl) recEl.style.display = 'none';
            if (actionsEl) actionsEl.style.display = 'none';
            if (footerEl) footerEl.style.display = 'none';
            if (countEl) countEl.textContent = '0';
            if (badgeEl) badgeEl.style.display = 'none';
            return;
        }

        if (clearAllBtn) clearAllBtn.style.display = 'inline-flex';

        listEl.innerHTML = '';
        let totalUsd = 0;
        let totalVnd = 0;
        let totalItems = 0;

        cart.forEach(item => {
            totalItems += item.qty;
            if (item.currency === 'USD') {
                totalUsd += item.price * item.qty;
            } else {
                totalVnd += item.price * item.qty;
            }

            const formattedPrice = item.currency === 'USD'
                ? `$${(item.price * item.qty).toFixed(2)} USD`
                : (item.price * item.qty).toLocaleString('vi-VN') + ' đ';

            let imgUrl = item.img;
            if (window.location.protocol === 'file:' && imgUrl && imgUrl.startsWith('/')) {
                imgUrl = '../wwwroot' + imgUrl;
            }

            const safeItemName = (item.name || '').replace(/'/g, "\\'");

            const itemEl = document.createElement('div');
            itemEl.className = 'cart-item-row';
            itemEl.innerHTML = `
                <img src="${imgUrl}" class="cart-item-img" alt="${item.name}">
                <div class="cart-item-details">
                    <span class="cart-item-name">${item.name}</span>
                    <span class="cart-item-specs">${item.specs || ''}</span>
                    <span class="cart-item-price">${formattedPrice}</span>
                </div>
                <div class="cart-item-controls">
                    <div class="quantity-selector">
                        <span class="qty-display">${item.qty}</span>
                        <div class="qty-btn-col">
                            <button class="qty-btn-arrow" onclick="changeQtyGlobal(${item.id || 0}, '${safeItemName}', 1)">▲</button>
                            <button class="qty-btn-arrow" onclick="changeQtyGlobal(${item.id || 0}, '${safeItemName}', -1)">▼</button>
                        </div>
                    </div>
                    <button class="cart-remove-btn" onclick="removeFromCartGlobal(${item.id || 0}, '${safeItemName}')" title="Xóa sản phẩm">
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <polyline points="3 6 5 6 21 6"></polyline>
                            <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path>
                            <line x1="10" y1="11" x2="10" y2="17"></line>
                            <line x1="14" y1="11" x2="14" y2="17"></line>
                        </svg>
                    </button>
                </div>
            `;
            listEl.appendChild(itemEl);
        });

        let subtotalText = '';
        if (totalUsd > 0 && totalVnd > 0) {
            subtotalText = `$${totalUsd.toFixed(2)} USD + ${totalVnd.toLocaleString('vi-VN')} đ`;
        } else if (totalUsd > 0) {
            subtotalText = `$${totalUsd.toFixed(2)} USD`;
        } else {
            subtotalText = `${totalVnd.toLocaleString('vi-VN')} đ`;
        }

        if (subtotalEl) subtotalEl.textContent = subtotalText;
        if (countEl) countEl.textContent = totalItems;

        if (badgeEl) {
            badgeEl.textContent = totalItems;
            badgeEl.style.display = totalItems > 0 ? 'flex' : 'none';
        }
        await fetchCartRecommendations();
        renderRecommendations();
    }

    function renderRecommendations() {
        const recContainer = document.querySelector('.cart-recommendations');
        if (!recContainer) return;

        let cart = JSON.parse(localStorage.getItem('hyper_core_cart')) || [];
        const availableRecs = cachedRecommendations.filter(rec => !cart.some(item => item.id === rec.id || item.name === rec.name));

        if (availableRecs.length === 0) {
            recContainer.style.display = 'none';
            return;
        }

        recContainer.style.display = 'block';
        let html = `<h5>You may also like</h5><div style="display:flex; flex-direction:column; gap:16px;">`;

        availableRecs.forEach(rec => {
            const formattedPrice = rec.price.toLocaleString('vi-VN') + ' đ';
            const formattedOldPrice = rec.oldPrice ? rec.oldPrice.toLocaleString('vi-VN') + ' đ' : '';

            html += `
                <div class="recommend-card">
                    <img src="${rec.img}" alt="${rec.name}">
                    <div class="recommend-info">
                        <span class="recommend-title">${rec.name}</span>
                        <div class="recommend-price">
                            <span class="price-usd-new" style="color: #555555;">${formattedPrice}</span>
                            ${formattedOldPrice ? `<span class="price-usd-old">${formattedOldPrice}</span>` : ''}
                        </div>
                    </div>
                    <button class="recommend-add-btn" onclick="addRecommendedItemGlobal(${rec.id})">+ Add</button>
                </div>
            `;
        });

        html += `</div>`;
        recContainer.innerHTML = html;
    }

    // Global Helpers for item manipulation
    window.changeQtyGlobal = async function (id, name, delta) {
        let cart = JSON.parse(localStorage.getItem('hyper_core_cart')) || [];
        const item = cart.find(i => (id && i.id === id) || i.name === name);
        if (item) {
            const newQty = item.qty + delta;
            if (newQty <= 0) {
                if (typeof deleteCartItemHelper === 'function') {
                    await deleteCartItemHelper(item.id, item.cartId);
                } else {
                    cart = cart.filter(i => i !== item);
                    localStorage.setItem('hyper_core_cart', JSON.stringify(cart));
                }
            } else {
                if (typeof updateCartItemHelper === 'function') {
                    await updateCartItemHelper(item.id, newQty, item.cartId);
                } else {
                    item.qty = newQty;
                    localStorage.setItem('hyper_core_cart', JSON.stringify(cart));
                }
            }
            if (typeof updateCartItemHelper !== 'function') {
                renderCartDrawer();
                if (typeof updateHeaderCartCount === 'function') updateHeaderCartCount();
            }
        }
    };

    window.removeFromCartGlobal = async function (id, name) {
        let cart = JSON.parse(localStorage.getItem('hyper_core_cart')) || [];
        const item = cart.find(i => (id && i.id === id) || i.name === name);
        if (item) {
            if (typeof deleteCartItemHelper === 'function') {
                await deleteCartItemHelper(item.id, item.cartId);
            } else {
                cart = cart.filter(i => i !== item);
                localStorage.setItem('hyper_core_cart', JSON.stringify(cart));
            }
            if (typeof deleteCartItemHelper !== 'function') {
                renderCartDrawer();
                if (typeof updateHeaderCartCount === 'function') updateHeaderCartCount();
            }
        }
    };

    window.clearCartGlobal = async function () {
        let cart = JSON.parse(localStorage.getItem('hyper_core_cart')) || [];
        if (cart.length === 0) return;

        if (!confirm('Bạn có chắc chắn muốn xóa toàn bộ sản phẩm khỏi giỏ hàng?')) {
            return;
        }

        if (typeof clearCartHelper === 'function') {
            await clearCartHelper();
        } else {
            localStorage.setItem('hyper_core_cart', '[]');
            localStorage.setItem('hypercore_cart_items', '[]');
            if (typeof updateHeaderCartCount === 'function') updateHeaderCartCount();
        }

        renderCartDrawer();
    };

    window.addRecommendedItemGlobal = async function (id) {
        if (typeof addToCartHelper === 'function') {
            await addToCartHelper(id, 1);
        } else {
            const rec = cachedRecommendations.find(r => r.id === id);
            if (rec) {
                let cart = JSON.parse(localStorage.getItem('hyper_core_cart')) || [];
                cart.push({
                    id: rec.id,
                    name: rec.name,
                    specs: rec.specs,
                    price: rec.price,
                    currency: 'VND',
                    qty: 1,
                    img: rec.img
                });
                localStorage.setItem('hyper_core_cart', JSON.stringify(cart));
            }
        }
        if (typeof addToCartHelper !== 'function') {
            renderCartDrawer();
            if (typeof updateHeaderCartCount === 'function') updateHeaderCartCount();
        }
    };

    // Register event listeners on cart badge / cart icon
    function initCartLinkInterception() {
        // Intercept any link pointing to shoppingcart
        document.querySelectorAll('a[href*="shoppingcart"]').forEach(btn => {
            btn.addEventListener('click', (e) => {
                e.preventDefault();
                openCartDrawer();
            });
        });

        const cartBtns = document.querySelectorAll('.cart-link');
        cartBtns.forEach(btn => {
            btn.addEventListener('click', (e) => {
                e.preventDefault();
                openCartDrawer();
            });
        });
    }

    async function initCartDrawer() {
        const path = window.location.pathname.toLowerCase();
        if (path.includes('checkout.html') || path === '/checkout') {
            return;
        }

        injectDrawerHTML();
        renderCartDrawer();
        initCartLinkInterception();

        // Listen for sync events from DB to update drawer dynamically
        window.addEventListener('cartSynced', (e) => {
            renderCartDrawer();
        });

        // Listen for recently viewed updates
        window.addEventListener('recentlyViewedUpdated', (e) => {
            if (currentDrawerTab === 'recent') {
                renderCartDrawer();
            }
        });

        // Auto-open drawer if requested in URL
        const urlParams = new URLSearchParams(window.location.search);
        if (urlParams.get('openCart') === 'true') {
            const newUrl = window.location.protocol + "//" + window.location.host + window.location.pathname;
            window.history.replaceState({ path: newUrl }, '', newUrl);
            setTimeout(() => {
                openCartDrawer();
            }, 300);
        }

        // If local protocol is file:, adjust links
        if (window.location.protocol === 'file:') {
            document.querySelectorAll(".cart-checkout-btn").forEach(btn => {
                btn.onclick = function() { window.location.href = 'checkout.html'; };
            });
            document.querySelectorAll(".continue-shopping-btn").forEach(btn => {
                btn.onclick = function() { closeCartDrawer(); window.location.href = 'products.html'; };
            });
        }
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initCartDrawer);
    } else {
        initCartDrawer();
    }


})();
