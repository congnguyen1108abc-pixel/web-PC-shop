// ============================================================
// CART-MANAGER.JS - QUẢN LÝ CART CHO CHECKOUT PAGE
// ============================================================

/**
 * Lấy danh sách sản phẩm trong giỏ hàng từ localStorage
 * @returns {Array} Mảng các sản phẩm trong giỏ hàng
 */
function getCartItems() {
    try {
        const cartData = localStorage.getItem('hyper_core_cart');
        if (!cartData) {
            return [];
        }
        const cart = JSON.parse(cartData);
        // Filter out pre-seed items (id 999) if any
        return Array.isArray(cart) ? cart.filter(item => item.id !== 999) : [];
    } catch (error) {
        console.error('Error reading cart from localStorage:', error);
        return [];
    }
}

/**
 * Xóa toàn bộ giỏ hàng từ localStorage
 * CHỈ GỌI SAU KHI THANH TOÁN THÀNH CÔNG
 */
function clearCart() {
    try {
        localStorage.removeItem('hyper_core_cart');
        localStorage.removeItem('hypercore_cart_items');
        localStorage.removeItem('hypercore_cart');
        console.log('Cart cleared successfully');
        
        // Cập nhật badge giỏ hàng trên header (nếu có)
        const countEl = document.getElementById("cartCount");
        if (countEl) {
            countEl.style.display = "none";
            countEl.innerText = "0";
        }
        
        return true;
    } catch (error) {
        console.error('Error clearing cart:', error);
        return false;
    }
}

/**
 * Tính tổng giá trị đơn hàng (subtotal)
 * @param {Array} items - Mảng các sản phẩm trong giỏ hàng
 * @returns {number} Tổng giá trị đơn hàng
 */
function calculateSubtotal(items) {
    if (!Array.isArray(items) || items.length === 0) {
        return 0;
    }
    
    return items.reduce((total, item) => {
        const price = parseFloat(item.price) || 0;
        const qty = parseInt(item.qty) || 0;
        return total + (price * qty);
    }, 0);
}

/**
 * Tính tổng tiền cuối cùng (subtotal + shipping - discount)
 * @param {number} subtotal - Tổng giá trị sản phẩm
 * @param {number} shippingFee - Phí vận chuyển (mặc định 0)
 * @param {number} discount - Giảm giá (mặc định 0)
 * @returns {number} Tổng tiền cuối cùng
 */
function calculateTotal(subtotal, shippingFee = 0, discount = 0) {
    const total = subtotal + shippingFee - discount;
    return Math.max(0, total); // Đảm bảo không âm
}

/**
 * Format số tiền theo định dạng VND
 * @param {number} amount - Số tiền cần format
 * @returns {string} Chuỗi đã format (vd: "15.990.000đ")
 */
function formatCurrency(amount) {
    if (typeof amount !== 'number' || isNaN(amount)) {
        return '0đ';
    }
    return amount.toLocaleString('vi-VN') + 'đ';
}

// Export các functions để sử dụng trong checkout.js
if (typeof module !== 'undefined' && module.exports) {
    // Node.js/CommonJS environment
    module.exports = {
        getCartItems,
        clearCart,
        calculateSubtotal,
        calculateTotal,
        formatCurrency
    };
}
