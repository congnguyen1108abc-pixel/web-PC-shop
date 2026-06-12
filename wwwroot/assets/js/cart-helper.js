// ============================================================
// CART-HELPER.JS - QUẢN LÝ GIỎ HÀNG ĐỒNG BỘ VỚI DATABASE REST API
// ============================================================

const CART_API_BASE = 'http://localhost:5187/api';

/**
 * Kiểm tra người dùng đã đăng nhập chưa
 */
function isUserLoggedIn() {
    const token = localStorage.getItem('pc_store_token');
    const user = localStorage.getItem('pc_store_user');
    return !!(token && user);
}

/**
 * Lấy thông tin user hiện tại
 */
function getCartUser() {
    try {
        return JSON.parse(localStorage.getItem('pc_store_user') || 'null');
    } catch (e) {
        return null;
    }
}

/**
 * Lấy Token JWT hiện tại
 */
function getCartToken() {
    return localStorage.getItem('pc_store_token');
}

/**
 * Đồng bộ giỏ hàng từ Database về LocalStorage
 */
async function syncCartFromDb() {
    if (!isUserLoggedIn()) return;
    const user = getCartUser();
    const token = getCartToken();
    if (!user || !user.userId || !token) return;

    try {
        const response = await fetch(`${CART_API_BASE}/Cart/user/${user.userId}`, {
            method: 'GET',
            headers: {
                'Authorization': `Bearer ${token}`,
                'Content-Type': 'application/json'
            }
        });

        if (response.ok) {
            const dbItems = await response.json();
            
            // Map dữ liệu DB -> Cấu trúc cart cục bộ (hyper_core_cart)
            const localCart = dbItems.map(item => ({
                id: item.productId, // id cục bộ dùng productId
                cartId: item.cartId, // Lưu lại cartId để cập nhật/xóa
                name: item.productName,
                specs: item.sku || '',
                price: item.unitPrice,
                currency: "VND",
                qty: item.quantity,
                img: item.defaultImageUrl || "https://placehold.co/100x100/081120/7dd3fc?text=Product"
            }));

            localStorage.setItem('hyper_core_cart', JSON.stringify(localCart));

            // Đồng bộ sang hypercore_cart_items (các trang khác dùng song song)
            const cartItems = localCart.map(item => ({
                id: item.id,
                title: item.name,
                variant: item.specs,
                price: item.price,
                qty: item.qty,
                img: item.img
            }));
            localStorage.setItem('hypercore_cart_items', JSON.stringify(cartItems));

            // Cập nhật badge giỏ hàng trên header
            updateHeaderCartCount();

            // Kích hoạt event thông báo giỏ hàng đã đồng bộ xong
            window.dispatchEvent(new CustomEvent('cartSynced', { detail: localCart }));
        } else if (response.status === 401) {
            console.warn("Phiên đăng nhập hết hạn khi đồng bộ giỏ hàng.");
        }
    } catch (error) {
        console.error("Lỗi khi đồng bộ giỏ hàng từ DB:", error);
    }
}

/**
 * Thêm sản phẩm vào giỏ hàng (DB + Local)
 */
async function addToCartHelper(productId, quantity = 1) {
    if (!isUserLoggedIn()) {
        // Chưa đăng nhập: thêm vào LocalStorage như bình thường
        let cart = JSON.parse(localStorage.getItem('hyper_core_cart')) || [];
        // Lọc bỏ sản phẩm pre-seed nếu có
        cart = cart.filter(i => i.id !== 999);

        const existing = cart.find(item => item.id === productId);
        if (existing) {
            existing.qty += quantity;
        } else {
            // Tìm thông tin sản phẩm từ danh sách PRODUCTS (nếu có ở trang hiện tại)
            let prodName = "Sản phẩm";
            let prodSpecs = "";
            let prodPrice = 0;
            let prodImg = "https://placehold.co/100x100/081120/7dd3fc?text=Product";

            if (typeof PRODUCTS !== 'undefined') {
                const p = PRODUCTS.find(x => x.id === productId);
                if (p) {
                    prodName = p.name;
                    prodSpecs = p.specs || "";
                    prodPrice = p.price;
                    prodImg = p.img;
                }
            } else if (typeof RECOMMEND_PRODUCTS !== 'undefined') {
                const p = RECOMMEND_PRODUCTS.find(x => x.id === productId);
                if (p) {
                    prodName = p.name;
                    prodSpecs = p.specs || "";
                    prodPrice = p.price;
                    prodImg = p.img;
                }
            }

            cart.push({
                id: productId,
                name: prodName,
                specs: prodSpecs,
                price: prodPrice,
                currency: "VND",
                qty: quantity,
                img: prodImg
            });
        }
        localStorage.setItem('hyper_core_cart', JSON.stringify(cart));
        
        // Cập nhật hypercore_cart_items
        const cartItems = cart.map(item => ({
            id: item.id,
            title: item.name,
            variant: item.specs,
            price: item.price,
            qty: item.qty,
            img: item.img
        }));
        localStorage.setItem('hypercore_cart_items', JSON.stringify(cartItems));

        updateHeaderCartCount();
        window.dispatchEvent(new CustomEvent('cartSynced', { detail: cart }));
        return true;
    }

    // Đã đăng nhập: Gọi API để lưu vào Database
    const user = getCartUser();
    const token = getCartToken();
    
    try {
        const response = await fetch(`${CART_API_BASE}/Cart/add`, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${token}`,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                userId: parseInt(user.userId),
                productId: parseInt(productId),
                quantity: parseInt(quantity)
            })
        });

        if (response.ok) {
            await syncCartFromDb();
            return true;
        } else {
            console.error("Lỗi API thêm vào giỏ hàng:", response.status);
            return false;
        }
    } catch (error) {
        console.error("Lỗi mạng thêm vào giỏ hàng:", error);
        return false;
    }
}

/**
 * Cập nhật số lượng sản phẩm (DB + Local)
 */
async function updateCartItemHelper(productId, newQty, cartId = null) {
    if (!isUserLoggedIn()) {
        let cart = JSON.parse(localStorage.getItem('hyper_core_cart')) || [];
        if (newQty <= 0) {
            cart = cart.filter(item => item.id !== productId);
        } else {
            const item = cart.find(item => item.id === productId);
            if (item) item.qty = newQty;
        }
        localStorage.setItem('hyper_core_cart', JSON.stringify(cart));

        const cartItems = cart.map(item => ({
            id: item.id,
            title: item.name,
            variant: item.specs,
            price: item.price,
            qty: item.qty,
            img: item.img
        }));
        localStorage.setItem('hypercore_cart_items', JSON.stringify(cartItems));

        updateHeaderCartCount();
        window.dispatchEvent(new CustomEvent('cartSynced', { detail: cart }));
        return true;
    }

    const user = getCartUser();
    const token = getCartToken();

    // Tìm cartId nếu chưa truyền vào
    let finalCartId = cartId;
    if (!finalCartId) {
        const cart = JSON.parse(localStorage.getItem('hyper_core_cart')) || [];
        const item = cart.find(i => i.id === productId);
        if (item) finalCartId = item.cartId;
    }

    if (!finalCartId) {
        console.error("Không tìm thấy CartId để cập nhật");
        return false;
    }

    try {
        const response = await fetch(`${CART_API_BASE}/Cart/item`, {
            method: 'PUT',
            headers: {
                'Authorization': `Bearer ${token}`,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                cartId: parseInt(finalCartId),
                userId: parseInt(user.userId),
                newQuantity: parseInt(newQty)
            })
        });

        if (response.ok) {
            await syncCartFromDb();
            return true;
        } else {
            console.error("Lỗi API cập nhật giỏ hàng:", response.status);
            return false;
        }
    } catch (error) {
        console.error("Lỗi mạng cập nhật giỏ hàng:", error);
        return false;
    }
}

/**
 * Xóa sản phẩm khỏi giỏ hàng (DB + Local)
 */
async function deleteCartItemHelper(productId, cartId = null) {
    if (!isUserLoggedIn()) {
        let cart = JSON.parse(localStorage.getItem('hyper_core_cart')) || [];
        cart = cart.filter(item => item.id !== productId);
        localStorage.setItem('hyper_core_cart', JSON.stringify(cart));

        const cartItems = cart.map(item => ({
            id: item.id,
            title: item.name,
            variant: item.specs,
            price: item.price,
            qty: item.qty,
            img: item.img
        }));
        localStorage.setItem('hypercore_cart_items', JSON.stringify(cartItems));

        updateHeaderCartCount();
        window.dispatchEvent(new CustomEvent('cartSynced', { detail: cart }));
        return true;
    }

    const user = getCartUser();
    const token = getCartToken();

    // Tìm cartId nếu chưa truyền vào
    let finalCartId = cartId;
    if (!finalCartId) {
        const cart = JSON.parse(localStorage.getItem('hyper_core_cart')) || [];
        const item = cart.find(i => i.id === productId);
        if (item) finalCartId = item.cartId;
    }

    if (!finalCartId) {
        console.error("Không tìm thấy CartId để xóa");
        return false;
    }

    try {
        const response = await fetch(`${CART_API_BASE}/Cart/item/${finalCartId}/user/${user.userId}`, {
            method: 'DELETE',
            headers: {
                'Authorization': `Bearer ${token}`,
                'Content-Type': 'application/json'
            }
        });

        if (response.ok) {
            await syncCartFromDb();
            return true;
        } else {
            console.error("Lỗi API xóa giỏ hàng:", response.status);
            return false;
        }
    } catch (error) {
        console.error("Lỗi mạng xóa giỏ hàng:", error);
        return false;
    }
}

/**
 * Đồng bộ giỏ hàng của Khách (guest) lên Database khi Đăng nhập thành công
 */
async function syncGuestCartToDbHelper(userId, token) {
    const guestCart = JSON.parse(localStorage.getItem('hyper_core_cart') || '[]');
    // Bỏ qua sản phẩm pre-seed mặc định
    const realGuestItems = guestCart.filter(item => item.id !== 999);
    
    if (realGuestItems.length === 0) {
        // Nếu không có sản phẩm khách nào, chỉ cần đồng bộ từ DB xuống Local
        await syncCartFromDb();
        return;
    }

    console.log("Đang đồng bộ giỏ hàng khách lên database cho user:", userId);
    for (const item of realGuestItems) {
        try {
            await fetch(`${CART_API_BASE}/Cart/add`, {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${token}`,
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    userId: parseInt(userId),
                    productId: parseInt(item.id),
                    quantity: parseInt(item.qty)
                })
            });
        } catch (err) {
            console.error("Lỗi đồng bộ sản phẩm khách:", item, err);
        }
    }

    // Xóa giỏ hàng khách tạm thời
    localStorage.setItem('hyper_core_cart', '[]');
    localStorage.setItem('hypercore_cart_items', '[]');

    // Đồng bộ lại toàn bộ từ Database xuống Local
    await syncCartFromDb();
}

/**
 * Cập nhật số lượng hiển thị trên Badge Giỏ hàng
 */
function updateHeaderCartCount() {
    let cartData = [];
    try {
        cartData = JSON.parse(localStorage.getItem('hyper_core_cart')) || [];
    } catch (e) {}
    
    const countEl = document.getElementById("cartCount");
    if (countEl) {
        const totalQty = cartData.reduce((acc, item) => acc + item.qty, 0);
        if (totalQty > 0) {
            countEl.innerText = totalQty;
            countEl.style.display = "flex";
        } else {
            countEl.style.display = "none";
        }
    }
}

/**
 * Xóa sạch thông tin giỏ hàng cục bộ (khi đăng xuất)
 */
function clearLocalCart() {
    localStorage.removeItem('hyper_core_cart');
    localStorage.removeItem('hypercore_cart_items');
    localStorage.removeItem('hypercore_cart');
    localStorage.removeItem('shippingAddress');
    sessionStorage.removeItem('checkout_addressId');
    sessionStorage.removeItem('checkout_address');
    sessionStorage.removeItem('current_orderId');
}
