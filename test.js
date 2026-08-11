





        /* =====================================================
           GAMINGGEAR.JS — All logic, UTF-8 clean
        ===================================================== */

        // ── 1. HEADER SCROLL ──
        const header = document.getElementById('header');
        window.addEventListener('scroll', () => {
            header.classList.toggle('scrolled', window.scrollY > 50);
        }, { passive: true });

        // ── 2. SHOWCASE SCROLL REVEAL ──
        const sectionObserver = new IntersectionObserver((entries) => {
            entries.forEach(e => { if (e.isIntersecting) e.target.classList.add('show'); });
        }, { threshold: 0.18 });
        document.querySelectorAll('.item-section').forEach(s => sectionObserver.observe(s));
        const footerEl = document.querySelector('footer');
        if (footerEl) sectionObserver.observe(footerEl);

        // ── 3. PARALLAX — nhẹ trên showcase ──
        window.addEventListener('scroll', () => {
            const sy = window.scrollY;
            document.querySelectorAll('.showcase-img').forEach(img => {
                img.style.transform = `translateY(${sy * 0.04}px)`;
            });
        }, { passive: true });

        // ── 4. MOUSE PARALLAX trên showcase cards ──
        document.querySelectorAll('.item-section .tilt-card').forEach(card => {
            card.addEventListener('mousemove', e => {
                const r = card.getBoundingClientRect();
                const x = (e.clientX - r.left - r.width / 2) / r.width;
                const y = (e.clientY - r.top - r.height / 2) / r.height;
                const img = card.querySelector('.product-img');
                if (img) img.style.transform = `translate(${x * 6}px, ${y * 6}px)`;
            });
            card.addEventListener('mouseleave', () => {
                const img = card.querySelector('.product-img');
                if (img) img.style.transform = '';
            });
        });

        // ── 5. GRID ITEM SCROLL REVEAL (stagger) ──
        function revealGridItems() {
            const visibleItems = Array.from(document.querySelectorAll('.grid-item:not(.hidden)'));
            visibleItems.forEach((item, i) => {
                item.style.opacity = '0';
                item.style.transform = 'translateY(24px)';
                setTimeout(() => {
                    item.style.transition = 'opacity .5s ease, transform .5s cubic-bezier(.22,1,.36,1)';
                    item.style.opacity = '1';
                    item.style.transform = 'translateY(0)';
                }, i * 70);
            });
        }

        // ── 6. FILTER STATE ──
        let currentCategory = 'all';
        let currentBrand = 'all';
        let currentQuick = 'all';
        let currentPage = 1;
        const itemsPerPage = 9;
        const priceSelect = document.getElementById('priceSelect');

        function filterProducts() {
            const priceVal = priceSelect.value;
            const gridItems = Array.from(document.querySelectorAll('.grid-item'));

            // Find all items that match current filter selections
            const matchingItems = [];
            gridItems.forEach(item => {
                const itemPrice = parseInt(item.getAttribute('data-price'));
                const itemCat = item.getAttribute('data-category');
                const itemBrand = item.getAttribute('data-brand') || 'all';
                const itemTags = item.getAttribute('data-tags') || '';

                const catMatch = currentCategory === 'all' || currentCategory === itemCat;
                const brandMatch = currentBrand === 'all' || itemBrand === currentBrand;
                const quickMatch = currentQuick === 'all' || itemTags.includes(currentQuick);
                let priceMatch = true;
                if (priceVal === 'under2' && itemPrice >= 2000000) priceMatch = false;
                if (priceVal === '2to4' && (itemPrice < 2000000 || itemPrice > 4000000)) priceMatch = false;
                if (priceVal === 'over4' && itemPrice <= 4000000) priceMatch = false;

                if (catMatch && brandMatch && quickMatch && priceMatch) {
                    matchingItems.push(item);
                } else {
                    item.style.display = 'none';
                    item.classList.add('hidden');
                    item.style.opacity = '0';
                }
            });

            // Check empty state
            let emptyState = document.getElementById('ggEmptyState');
            if (!emptyState) {
                emptyState = document.createElement('div');
                emptyState.id = 'ggEmptyState';
                emptyState.style.cssText = 'grid-column: 1 / -1; text-align: center; font-size: 16px; color: #888; padding: 40px 0; width: 100%;';
                emptyState.textContent = 'Hiện chưa có sản phẩm.';
                const grid = document.getElementById('productGrid');
                if (grid) grid.appendChild(emptyState);
            }
            emptyState.style.display = (matchingItems.length === 0) ? 'block' : 'none';

            // Calculate pagination parameters
            const totalItems = matchingItems.length;
            const totalPages = Math.ceil(totalItems / itemsPerPage) || 1;
            if (currentPage > totalPages) {
                currentPage = totalPages;
            }

            const startIndex = (currentPage - 1) * itemsPerPage;
            const endIndex = startIndex + itemsPerPage;

            // Render matching items for current page with delay transition
            let delay = 0;
            matchingItems.forEach((item, idx) => {
                if (idx >= startIndex && idx < endIndex) {
                    item.style.display = 'flex';
                    item.classList.remove('hidden');
                    item.style.opacity = '0';
                    item.style.transform = 'translateY(20px)';
                    item.style.transition = `opacity .45s ease ${delay * 65}ms, transform .45s cubic-bezier(.22,1,.36,1) ${delay * 65}ms`;
                    setTimeout((_item => () => {
                        _item.style.opacity = '1';
                        _item.style.transform = 'translateY(0)';
                    })(item), 20 + delay * 65);
                    delay++;
                } else {
                    item.style.display = 'none';
                    item.classList.add('hidden');
                    item.style.opacity = '0';
                }
            });

            // Re-render pagination buttons
            renderPaginationControls(totalPages);
        }

        function renderPaginationControls(totalPages) {
            let container = document.getElementById('paginationContainer');
            if (!container) {
                const grid = document.getElementById('productGrid');
                container = document.createElement('div');
                container.id = 'paginationContainer';
                container.className = 'pagination-container';
                grid.parentNode.appendChild(container);
            }

            if (totalPages <= 1) {
                container.innerHTML = '';
                return;
            }

            let html = '';

            // First page button (<<)
            html += `<button class="page-btn ${currentPage === 1 ? 'disabled' : ''}" onclick="changePage(1)" ${currentPage === 1 ? 'disabled' : ''}>&lt;&lt;</button>`;

            // Prev button (<)
            html += `<button class="page-btn ${currentPage === 1 ? 'disabled' : ''}" onclick="changePage(${currentPage - 1})" ${currentPage === 1 ? 'disabled' : ''}>&lt;</button>`;

            // Calculate the window of 5 pages
            let startPage = currentPage - 2;
            let endPage = currentPage + 2;

            if (startPage < 1) {
                endPage = Math.min(totalPages, endPage + (1 - startPage));
                startPage = 1;
            }
            if (endPage > totalPages) {
                startPage = Math.max(1, startPage - (endPage - totalPages));
                endPage = totalPages;
            }

            // Ellipsis before
            if (startPage > 1) {
                html += `<span class="page-ellipsis">...</span>`;
            }

            // Page numbers
            for (let i = startPage; i <= endPage; i++) {
                html += `<button class="page-btn ${i === currentPage ? 'active' : ''}" onclick="changePage(${i})">${i}</button>`;
            }

            // Ellipsis after
            if (endPage < totalPages) {
                html += `<span class="page-ellipsis">...</span>`;
            }

            // Next button (>)
            html += `<button class="page-btn ${currentPage === totalPages ? 'disabled' : ''}" onclick="changePage(${currentPage + 1})" ${currentPage === totalPages ? 'disabled' : ''}>&gt;</button>`;

            // Last page button (>>)
            html += `<button class="page-btn ${currentPage === totalPages ? 'disabled' : ''}" onclick="changePage(${totalPages})" ${currentPage === totalPages ? 'disabled' : ''}>&gt;&gt;</button>`;

            container.innerHTML = html;
        }

        window.changePage = function (page) {
            currentPage = page;
            filterProducts();
            document.getElementById('all-gear').scrollIntoView({ behavior: 'smooth', block: 'start' });
        };

        // ── 7. CATEGORY BUTTONS (Đã chuyển vào trong loadProductTypesAndMenu để handle động) ──


        // ── 8. BRAND FILTER BUTTONS ──
        document.querySelectorAll('.brand-btn').forEach(btn => {
            btn.addEventListener('click', () => {
                document.querySelectorAll('.brand-btn').forEach(b => b.classList.remove('active'));
                btn.classList.add('active');
                currentBrand = btn.getAttribute('data-brand-filter');
                currentPage = 1;
                filterProducts();
            });
        });

        // ── 9. BRAND SHOWCASE PILLS (sync with brand filter) ──
        document.querySelectorAll('.brand-pill').forEach(pill => {
            pill.addEventListener('click', () => {
                document.querySelectorAll('.brand-pill').forEach(p => p.classList.remove('active'));
                pill.classList.add('active');
                const brand = pill.getAttribute('data-brand');
                currentBrand = brand;
                document.querySelectorAll('.brand-btn').forEach(b => {
                    b.classList.toggle('active', b.getAttribute('data-brand-filter') === brand);
                });
                currentPage = 1;
                filterProducts();
                document.getElementById('all-gear').scrollIntoView({ behavior: 'smooth', block: 'start' });
            });
        });

        // ── 10. QUICK FILTER ──
        document.querySelectorAll('.quick-btn').forEach(btn => {
            btn.addEventListener('click', () => {
                const isActive = btn.classList.contains('active');
                document.querySelectorAll('.quick-btn').forEach(b => b.classList.remove('active'));
                if (!isActive) {
                    btn.classList.add('active');
                    currentQuick = btn.getAttribute('data-quick');
                } else {
                    currentQuick = 'all';
                }
                currentPage = 1;
                filterProducts();
            });
        });

        // ── 11. PRICE FILTER ──
        priceSelect.addEventListener('change', () => {
            currentPage = 1;
            filterProducts();
        });

        // ── 12. URL PARAMS ──
        function applyUrlParams() {
            const urlParams = new URLSearchParams(window.location.search);
            let catParam = urlParams.get('category') || urlParams.get('cat');
            if (catParam) {
                const mapped = catParam.toLowerCase();
                currentCategory = mapped;
                document.querySelectorAll('.cat-btn').forEach(b => {
                    b.classList.toggle('active', b.getAttribute('data-filter') === mapped);
                });
                filterProducts();
            }
        }

        // ── 13. CART ──
        function updateCartBadge() {
            const cart = JSON.parse(localStorage.getItem('hyper_core_cart')) || [];
            const countEl = document.getElementById('cartCount');
            if (countEl) {
                const total = cart.reduce((acc, i) => acc + i.qty, 0);
                countEl.innerText = total;
                countEl.style.display = total > 0 ? 'flex' : 'none';
            }
        }

        const formatPrice = n => n.toLocaleString('vi-VN') + ' ₫';

        function getSubcategoryFromProduct(p) {
            const productType = p.productType ?? p.ProductType ?? '';
            return productType.trim().toLowerCase();
        }

        function getTagsFromProduct(p) {
            const sku = (p.sku || p.SKU || '').toUpperCase();
            const name = (p.productName || p.ProductName || '').toLowerCase();
            const desc = (p.description || p.Description || '').toLowerCase();
            const tags = [];

            if (name.includes('wireless') || desc.includes('không dây') || desc.includes('wireless') || desc.includes('bluetooth') || name.includes('pro')) {
                tags.push('wireless');
            }
            if (name.includes('rgb') || desc.includes('rgb') || desc.includes('led')) {
                tags.push('rgb');
            }
            if (sku.includes('MOUSE') || sku.includes('PAD') || sku.includes('RC')) {
                tags.push('bestseller');
            }
            if (sku.includes('KB') || sku.includes('MIC') || sku.includes('ACC')) {
                tags.push('hotdeal');
            }
            if (sku.includes('HS')) {
                tags.push('newarrival');
            }
            return tags.join(' ');
        }

        function renderShowcaseCard() {
            const showcaseProd = PRODUCTS[0];
            if (showcaseProd) {
                const card = document.getElementById('showcaseCard1');
                if (card) {
                    const img = card.querySelector('.product-img');
                    const tag = card.querySelector('.item-tag');
                    const name = card.querySelector('.item-name');
                    const price = card.querySelector('.item-price');

                    if (img) img.src = showcaseProd.img;
                    if (tag) tag.textContent = showcaseProd.specs;
                    if (name) name.textContent = showcaseProd.name;
                    if (price) price.textContent = formatPrice(showcaseProd.price);

                    card.onclick = () => {
                        window.location.href = window.location.protocol === 'file:'
                            ? `product-detail.html?id=${showcaseProd.id}`
                            : `/product-detail?id=${showcaseProd.id}`;
                    };
                    card.style.cursor = 'pointer';
                }
            }
        }

        function renderTrendingGrid() {
            const trendingCards = document.querySelectorAll('.trending-card');
            trendingCards.forEach((card, idx) => {
                const p = PRODUCTS[idx];
                if (p) {
                    const img = card.querySelector('.trending-card-img');
                    const tag = card.querySelector('.trending-card-tag');
                    const name = card.querySelector('.trending-card-name');
                    const priceRow = card.querySelector('.trending-card-price-row');
                    const btnAdd = card.querySelector('.btn-add');
                    const btnDetail = card.querySelector('.btn-detail');

                    if (img) img.src = p.img;
                    if (tag) tag.textContent = p.specs;
                    if (name) name.textContent = p.name;
                    if (priceRow) {
                        priceRow.innerHTML = `<span class="trending-card-price">${formatPrice(p.price)}</span>`;
                        if (p.oldPrice) {
                            priceRow.innerHTML += `
                            <span class="price-old-tag" style="margin-left: 8px;">${formatPrice(p.oldPrice)}</span>
                            <span class="discount-tag" style="margin-left: 4px;">-${p.discount}%</span>
                        `;
                        }
                    }
                    if (btnAdd) {
                        btnAdd.setAttribute('data-name', p.name);
                        if (p.stock === 'out') {
                            btnAdd.setAttribute('disabled', 'true');
                            btnAdd.querySelector('.btn-text').textContent = 'Hết hàng';
                        } else {
                            btnAdd.removeAttribute('disabled');
                            btnAdd.querySelector('.btn-text').textContent = 'Thêm vào giỏ';
                        }
                    }
                    if (btnDetail) {
                        btnDetail.href = window.location.protocol === 'file:'
                            ? `product-detail.html?id=${p.id}`
                            : `/product-detail?id=${p.id}`;
                    }
                }
            });
        }

        function renderMainGrid(list) {
            const grid = document.getElementById('productGrid');
            if (!grid) return;
            grid.innerHTML = '';

            list.forEach(p => {
                const card = document.createElement('div');
                card.className = 'tilt-card grid-item';
                card.setAttribute('data-category', p.cat);
                card.setAttribute('data-price', p.price);
                card.setAttribute('data-brand', p.brand ? p.brand.toLowerCase() : 'all');
                card.setAttribute('data-tags', p.tags || '');

                const isOut = p.stock === 'out';
                const badgeHTML = p.badge ? `<span class="card-badge ${p.badge}">${p.badge.toUpperCase()}</span>` : '';
                const oldPriceHTML = p.oldPrice ? `
                <span class="price-old-tag">${formatPrice(p.oldPrice)}</span>
                <span class="discount-tag">-${p.discount}%</span>
            ` : '';

                const detailUrl = window.location.protocol === 'file:' ? `product-detail.html?id=${p.id}` : `/product-detail?id=${p.id}`;
                card.innerHTML = `
                <div class="glass-base"></div>
                <div class="card-img-wrap">
                    ${badgeHTML}
                    <img src="${p.img}" alt="${p.name}" loading="lazy">
                </div>
                <div class="card-body">
                    <div class="card-name">${p.name}</div>
                    <div class="card-specs">${p.specs}</div>
                    <div class="card-price-row">
                        <span class="price-new">${formatPrice(p.price)}</span>
                        ${oldPriceHTML}
                    </div>
                    <div class="card-actions">
                        <button class="btn-add" data-name="${p.name}" ${isOut ? 'disabled' : ''}>
                            <span class="btn-text">${isOut ? 'Hết hàng' : 'Thêm vào giỏ'}</span>
                            <span class="btn-check">✓ Đã thêm</span>
                        </button>
                        <a href="${detailUrl}" class="btn-detail">Chi tiết</a>
                    </div>
                </div>
            `;
                grid.appendChild(card);
            });
        }

        function setupAddToCartButtons() {
            document.querySelectorAll('.btn-add').forEach(btn => {
                if (btn.dataset.listenerAttached) return;
                btn.dataset.listenerAttached = 'true';

                btn.addEventListener('click', async (e) => {
                    e.preventDefault(); e.stopPropagation();
                    if (btn.classList.contains('added')) return;
                    const name = btn.getAttribute('data-name');
                    const p = PRODUCTS.find(x => x.name === name);
                    if (!p) return;
                    const ok = await addToCartHelper(p.id, 1);
                    if (ok) {
                        btn.classList.add('added');
                        updateCartBadge();
                        setTimeout(() => btn.classList.remove('added'), 2200);
                    }
                });

                btn.addEventListener('mousedown', (e) => {
                    const r = btn.getBoundingClientRect();
                    btn.style.setProperty('--rx', (e.clientX - r.left) + 'px');
                    btn.style.setProperty('--ry', (e.clientY - r.top) + 'px');
                    btn.classList.add('ripple');
                    setTimeout(() => btn.classList.remove('ripple'), 500);
                });
            });
        }

        let PRODUCTS = [];


        async function loadCategoriesMapping() {
            try {
                const baseUrl = window.location.protocol === 'file:' ? 'https://localhost:7115' : '';
                const res = await fetch(`${baseUrl}/api/Categories`);
                if (!res.ok) return 7;
                const data = await res.json();
                const cats = Array.isArray(data) ? data : (data.items ?? data.Items ?? []);
                const ggCat = cats.find(c => {
                    const name = c.categoryName ?? c.CategoryName ?? '';
                    return name.toLowerCase().includes('gaming gear');
                });
                return ggCat ? (ggCat.categoryId ?? ggCat.CategoryId) : 7;
            } catch (e) {
                console.warn('[GamingGear] Could not load categories mapping:', e);
                return 7;
            }
        }

        async function loadGamingGearFromAPI() {
            console.log('[GamingGear] Loading products from SQL via API...');
            const categoryId = await loadCategoriesMapping();
            try {
                const baseUrl = window.location.protocol === 'file:' ? 'https://localhost:7115' : '';
                const response = await fetch(`${baseUrl}/api/Products?CategoryId=${categoryId}&PageSize=100&OnlyActive=true`);
                if (!response.ok) {
                    console.error('[GamingGear] API error:', response.status, response.statusText);
                    return;
                }
                const data = await response.json();
                const items = data.items ?? data.Items ?? [];
                if (!Array.isArray(items) || items.length === 0) {
                    console.warn('[GamingGear] API returned 0 products, using hardcoded fallback.');
                    return;
                }

                PRODUCTS = items.map(p => {
                    const productId = p.productId ?? p.ProductId;
                    const brandName = p.brandName ?? p.BrandName ?? 'Unknown';
                    const productName = p.productName ?? p.ProductName ?? '';
                    const description = p.description ?? p.Description ?? '';
                    const price = p.price ?? p.Price ?? 0;
                    const discountPrice = p.discountPrice ?? p.DiscountPrice ?? 0;
                    const effectivePrice = p.effectivePrice ?? p.EffectivePrice ?? price;
                    const stockQuantity = p.stockQuantity ?? p.StockQuantity ?? 0;
                    const defaultImageUrl = p.defaultImageUrl ?? p.DefaultImageUrl ?? null;
                    const slug = p.slug ?? p.Slug ?? null;

                    const cat = getSubcategoryFromProduct(p);
                    const tags = getTagsFromProduct(p);

                    let stock = 'in';
                    if (stockQuantity <= 0) stock = 'out';
                    else if (stockQuantity < 10) stock = 'low';

                    let badge = null;
                    if (discountPrice > 0 && discountPrice < price) badge = 'sale';
                    else if (tags.includes('bestseller')) badge = 'hot';

                    const img = defaultImageUrl || `https://placehold.co/300x200/081120/7dd3fc?text=${encodeURIComponent((productName || 'Product').substring(0, 20))}`;

                    const oldPrice = (discountPrice > 0 && discountPrice < price) ? price : null;
                    const discount = oldPrice ? Math.round((1 - effectivePrice / oldPrice) * 100) : 0;

                    return {
                        id: productId,
                        name: productName,
                        price: effectivePrice,
                        oldPrice: oldPrice,
                        discount: discount,
                        img: img,
                        specs: description ? description.substring(0, 80) : 'Xem chi tiết để biết thêm',
                        cat: cat,
                        brand: brandName,
                        tags: tags,
                        stock: stock,
                        badge: badge,
                        slug: slug
                    };
                });

                console.log('[GamingGear] Loaded', PRODUCTS.length, 'products from SQL');

                renderShowcaseCard();
                renderTrendingGrid();
                renderMainGrid(PRODUCTS);

                const gridItems = Array.from(document.querySelectorAll('#productGrid .grid-item'));

                if (typeof renderBrandFilter === 'function') await renderBrandFilter();
                filterProducts();
                setupAddToCartButtons();
                revealTrendingCards();

            } catch (error) {
                console.error('[GamingGear] Error loading products from SQL:', error);
            }
        }

        // ── 14. COUNTER ANIMATION ──
        function animateCounter(el) {
            const target = parseInt(el.getAttribute('data-target'));
            const suffix = el.getAttribute('data-suffix') || '+';
            let current = 0;
            const step = Math.ceil(target / 40);
            const timer = setInterval(() => {
                current = Math.min(current + step, target);
                el.textContent = current + suffix;
                if (current >= target) clearInterval(timer);
            }, 35);
        }
        const statsObserver = new IntersectionObserver((entries) => {
            entries.forEach(e => {
                if (e.isIntersecting) {
                    e.target.classList.add('show');
                    const num = e.target.querySelector('.stat-number');
                    if (num && !num.dataset.animated) {
                        num.dataset.animated = '1';
                        animateCounter(num);
                    }
                }
            });
        }, { threshold: 0.3 });
        document.querySelectorAll('.stat-card').forEach(c => statsObserver.observe(c));

        // ── 15. TRENDING CARDS REVEAL ──
        function revealTrendingCards() {
            const trendingCards = Array.from(document.querySelectorAll('.trending-card'));
            trendingCards.forEach((item, i) => {
                item.style.opacity = '0';
                item.style.transform = 'translateY(24px)';
                setTimeout(() => {
                    item.style.transition = 'opacity .5s ease, transform .5s cubic-bezier(.22,1,.36,1)';
                    item.style.opacity = '1';
                    item.style.transform = 'translateY(0)';
                    item.classList.add('show');
                }, i * 70);
            });
        }

        function updateShowcase() {
            const pinnedId = localStorage.getItem('PinnedGGProductID');
            if (!pinnedId) return;

            const product = PRODUCTS.find(p => p.id == pinnedId);
            if (!product) return;

            const showcaseCard = document.getElementById('showcaseCard1');
            if (!showcaseCard) return;

            const img = showcaseCard.querySelector('.showcase-img');
            if (img) {
                img.src = product.img;
                img.alt = product.name;
            }

            const tag = showcaseCard.querySelector('.item-tag');
            if (tag) tag.textContent = (product.cat || 'Gaming Gear').toUpperCase();

            const nameEl = showcaseCard.querySelector('.item-name');
            if (nameEl) nameEl.textContent = product.name;

            const priceEl = showcaseCard.querySelector('.item-price');
            if (priceEl) {
                if (product.oldPrice) {
                    priceEl.innerHTML = `<span style="color:#f59e0b; font-weight:700;">${product.price.toLocaleString()} ₫</span> 
                                         <span style="text-decoration:line-through; font-size:0.8em; color:#94a3b8; margin-left:8px;">${product.oldPrice.toLocaleString()} ₫</span>`;
                } else {
                    priceEl.textContent = `${product.price.toLocaleString()} ₫`;
                }
            }

            const sideDesc = document.querySelector('.side-content .side-desc');
            if (sideDesc && product.specs) {
                sideDesc.textContent = product.specs;
            }

            let badgeEl = showcaseCard.querySelector('.showcase-badge');
            if (!badgeEl && product.badge) {
                badgeEl = document.createElement('span');
                badgeEl.style.position = 'absolute';
                badgeEl.style.top = '16px';
                badgeEl.style.left = '16px';
                badgeEl.style.zIndex = '10';
                showcaseCard.appendChild(badgeEl);
            }
            if (badgeEl) {
                if (product.badge) {
                    badgeEl.textContent = product.badge === 'sale' ? 'SALE' : 'HOT';
                    badgeEl.className = 'showcase-badge card-badge ' + (product.badge === 'sale' ? 'sale' : 'hot');
                    badgeEl.style.display = 'inline-block';
                } else {
                    badgeEl.style.display = 'none';
                }
            }

            showcaseCard.style.cursor = 'pointer';
            showcaseCard.onclick = () => window.location.href = `/product-detail?id=${product.id}`;
        }

        // ── 15b. DYNAMIC HERO BANNER LOADER & CATEGORY ──
        const GG_FIXED_CATEGORIES = [
            "Chuột", "Bàn phím", "Tai nghe", "Màn hình", "Loa",
            "Micro", "Webcam", "Ghế Gaming", "Mouse Pad", "Tay cầm", "Phụ kiện"
        ];

        const PC_COMPONENT_BRANDS = [
            "gigabyte", "asrock", "colorful", "palit", "zotac", "pny", "kingston", "wd",
            "seagate", "intel", "amd", "nvidia", "crucial", "adata", "g.skill", "teamgroup",
            "lexar", "deepcool", "thermaltake", "antec", "coolmoon"
        ];

        async function renderBrandFilter() {
            const container = document.getElementById('ggBrandFilterContainer');
            if (!container) return;

            try {
                const baseUrl = window.location.protocol === 'file:' ? 'https://localhost:7115' : '';
                const brandRes = await fetch(`${baseUrl}/api/Brands`);
                if (!brandRes.ok) return;
                const allBrands = await brandRes.json();

                let brandsToRender = window.getFilteredBrandsForCategory ?
                    window.getFilteredBrandsForCategory(allBrands, 'gaming gear').map(b => b.brandName) :
                    allBrands.map(b => b.brandName);

                if (brandsToRender.length === 0) {
                    container.innerHTML = '<span style="font-size: 14px; color: #666; margin-left: 10px;">Chưa có thương hiệu.</span>';
                    return;
                }

                let html = `<button class="brand-btn ${currentBrand === 'all' ? 'active' : ''}" data-brand-filter="all">Tất cả</button>`;
                brandsToRender.forEach(b => {
                    const isActive = (currentBrand === b) ? 'active' : '';
                    html += `<button class="brand-btn ${isActive}" data-brand-filter="${b}">${b}</button>`;
                });
                container.innerHTML = html;

                container.querySelectorAll('.brand-btn').forEach(btn => {
                    btn.addEventListener('click', () => {
                        container.querySelectorAll('.brand-btn').forEach(bb => bb.classList.remove('active'));
                        btn.classList.add('active');
                        currentBrand = btn.getAttribute('data-brand-filter');
                        currentPage = 1;
                        filterProducts();
                    });
                });
            } catch (err) {
                console.error("[GamingGear] Lỗi tải Brands:", err);
            }
        }

        async function loadProductTypesAndMenu() {
            try {
                const baseUrl = window.location.protocol === 'file:' ? 'https://localhost:7115' : '';

                // Fetch category counts
                const typeRes = await fetch(`${baseUrl}/api/gaminggear/categories`);
                let fetchedCategories = [];
                if (typeRes.ok) fetchedCategories = await typeRes.json();

                const catCounts = {};
                fetchedCategories.forEach(c => {
                    catCounts[(c.name || '').toLowerCase()] = c.count; // c.name is the Code like "Chair"
                });

                // Fetch true product types mapping (Code <-> Name)
                const defRes = await fetch(`${baseUrl}/api/products/gaming/product-types`);
                let productTypes = [];
                if (defRes.ok) productTypes = await defRes.json();

                // 1. Cập nhật Category Panel trên Navbar
                const ggHeaderPanel = document.getElementById('ggHeaderCategoryPanel');
                if (ggHeaderPanel && productTypes.length > 0) {
                    let panelHtml = '<h3>Gaming Gear</h3>';
                    productTypes.forEach(pt => {
                        const count = catCounts[(pt.code || '').toLowerCase()] || 0;
                        panelHtml += `<a href="#" data-panel-filter="${pt.code}">${pt.name} (${count})</a>`;
                    });
                    ggHeaderPanel.innerHTML = panelHtml;

                    ggHeaderPanel.querySelectorAll('a[data-panel-filter]').forEach(a => {
                        a.addEventListener('click', async (e) => {
                            e.preventDefault();
                            const subcat = a.getAttribute('data-panel-filter');
                            currentBrand = 'all'; // Reset brand filter
                            currentCategory = subcat.toLowerCase();
                            currentPage = 1;
                            await fetchAndRenderGamingProducts(subcat);
                        });
                    });
                }

                // 2. Cập nhật Category Menu dạng pill (Filter Bar)
                const menuContainer = document.getElementById('categoryMenu');
                if (menuContainer && productTypes.length > 0) {
                    let html = '<button class="cat-btn active" data-filter="all">Tất Cả</button>';
                    productTypes.forEach(pt => {
                        html += `<button class="cat-btn" data-filter="${pt.code}">${pt.name}</button>`;
                    });
                    menuContainer.innerHTML = html;
                    menuContainer.querySelectorAll('.cat-btn').forEach(btn => {
                        btn.addEventListener('click', async () => {
                            menuContainer.querySelectorAll('.cat-btn').forEach(b => b.classList.remove('active'));
                            btn.classList.add('active');
                            const filterVal = btn.getAttribute('data-filter');
                            currentBrand = 'all'; // Reset brand filter
                            currentCategory = filterVal.toLowerCase();
                            currentPage = 1;
                            if (filterVal === 'all') {
                                await loadGamingGearFromAPI();
                            } else {
                                await fetchAndRenderGamingProducts(filterVal);
                            }
                        });
                    });
                }
            } catch (e) {
                console.error('Failed to load product types:', e);
            }
            applyUrlParams();
        }

        async function fetchAndRenderGamingProducts(subcategory) {
            try {
                const baseUrl = window.location.protocol === 'file:' ? 'https://localhost:7115' : '';
                const response = await fetch(`${baseUrl}/api/gaminggear/products?subcategory=${encodeURIComponent(subcategory)}`);
                if (!response.ok) {
                    console.error('Error fetching subcategory products:', response.status);
                    return;
                }
                const data = await response.json();
                const items = data.items || data;

                // Map sang format Frontend
                PRODUCTS = items.map(p => {
                    const price = p.price ?? p.Price ?? 0;
                    const discountPrice = p.discountPrice ?? p.DiscountPrice ?? 0;
                    const effectivePrice = p.effectivePrice ?? p.EffectivePrice ?? price;
                    const oldPrice = (discountPrice > 0 && discountPrice < price) ? price : null;
                    const discount = oldPrice ? Math.round((1 - effectivePrice / oldPrice) * 100) : 0;

                    return {
                        id: p.productId ?? p.ProductId,
                        name: p.productName ?? p.ProductName,
                        price: effectivePrice,
                        oldPrice: oldPrice,
                        discount: discount,
                        img: p.defaultImageUrl ?? p.DefaultImageUrl ?? 'https://placehold.co/300x200?text=No+Image',
                        specs: p.description ? p.description.substring(0, 80) : 'Xem chi tiết',
                        cat: subcategory.toLowerCase(),
                        brand: p.brandName ?? 'Unknown',
                        tags: '',
                        stock: (p.stockQuantity > 0) ? 'in' : 'out',
                        badge: null
                    };
                });

                renderMainGrid(PRODUCTS);
                setupAddToCartButtons();
                filterProducts(); // to trigger empty state checking

                // Đổi active state của pill buttons (nếu có)
                const menuContainer = document.getElementById('categoryMenu');
                if (menuContainer) {
                    menuContainer.querySelectorAll('.cat-btn').forEach(b => b.classList.remove('active'));
                    const targetBtn = menuContainer.querySelector(`.cat-btn[data-filter="${subcategory}"]`);
                    if (targetBtn) targetBtn.classList.add('active');
                }

                // Cuộn xuống grid
                document.getElementById('all-gear').scrollIntoView({ behavior: 'smooth' });
            } catch (e) {
                console.error('Error in fetchAndRenderGamingProducts', e);
            }
        }

        async function loadGamingGearBanner() {
            try {
                const baseUrl = window.location.protocol === 'file:' ? 'https://localhost:7115' : '';
                const res = await fetch(`${baseUrl}/api/Banners/active`);
                if (!res.ok) return;
                const banners = await res.json();
                const ggBanner = banners.find(b => b.title && b.title.startsWith('[gaminggear]') && b.isActive !== false);
                if (ggBanner && ggBanner.imageUrl) {
                    const heroImg = document.querySelector('.hero-banner-img');
                    const heroLink = document.getElementById('heroBannerLink');
                    if (heroImg) {
                        heroImg.style.opacity = '0';
                        setTimeout(() => {
                            heroImg.onload = () => {
                                heroImg.style.opacity = '1';
                            };
                            heroImg.src = window.location.protocol === 'file:' ? '../wwwroot' + ggBanner.imageUrl : ggBanner.imageUrl;
                            heroImg.alt = ggBanner.title.replace('[gaminggear] ', '') || 'Gaming Gear Banner';
                            if (heroLink && ggBanner.link) {
                                heroLink.href = ggBanner.link;
                            }
                        }, 50);
                    }
                }
            } catch (e) {
                console.warn('[GamingGear] Could not load banner from API:', e);
            }
        }

        // ── 16. INITIALIZATION ──
        (async function init() {
            console.log('[GamingGear] Initializing page...');

            // Load Product Types & Sinh Category Menu
            await loadProductTypesAndMenu();

            // Load dynamic hero banner from Admin
            loadGamingGearBanner();

            // Setup static add-to-cart click listeners (fallback)
            setupAddToCartButtons();

            // Fetch products from SQL database via API
            await loadGamingGearFromAPI();
            updateShowcase();

            // If API didn't load any items (e.g. running locally via file:// or API failed),
            // animate the fallback products already in HTML
            if (document.querySelectorAll('#productGrid .grid-item').length > 0 &&
                !document.querySelector('#productGrid .grid-item').classList.contains('hidden')) {
                // Already handled by API response callback (filterProducts + revealTrendingCards)
            } else {
                revealGridItems();
                revealTrendingCards();
            }

            // Sync cart badge
            updateCartBadge();
        })();

        // ── 18. LOCAL FILE PROTOCOL FIX ──
        if (window.location.protocol === 'file:') {
            document.querySelectorAll('a').forEach(a => {
                const href = a.getAttribute('href');
                if (href && href.startsWith('/')) {
                    const path = href.toLowerCase();
                    const search = href.includes('?') ? href.substring(href.indexOf('?')) : '';
                    if (path === '/homepage' || path.startsWith('/homepage?')) a.href = 'homepage.html' + search;
                    else if (path.startsWith('/products')) a.href = 'products.html' + search;
                    else if (path.startsWith('/gaminggear')) a.href = 'gaminggear.html' + search;
                    else if (path.startsWith('/pcbuild')) a.href = 'pcbuild.html' + search;
                    else if (path.startsWith('/login')) a.href = 'login.html' + search;
                    else if (path.startsWith('/shoppingcart')) a.href = 'shoppingcart.html' + search;
                    else if (path.startsWith('/product-detail')) a.href = 'product-detail.html' + search;
                }
            });
            document.querySelectorAll("link[rel='stylesheet']").forEach(link => {
                const href = link.getAttribute('href');
                if (href && href.startsWith('/')) link.href = '../wwwroot' + href;
            });
            document.querySelectorAll('img').forEach(img => {
                const src = img.getAttribute('src');
                if (src && src.startsWith('/')) img.src = '../wwwroot' + src;
            });
        }
    
