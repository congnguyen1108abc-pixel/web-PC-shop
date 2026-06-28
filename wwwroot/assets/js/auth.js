// ============================================================
// AUTH.JS - TÍCH HỢP FRONTEND VỚI REST API
// Backend tự động hash password - Frontend gửi plain text
// Token lưu trong sessionStorage - tự động xóa khi đóng browser
// ============================================================

const API_BASE_URL = window.location.origin + '/api';

// ============================================================
// UTILITY FUNCTIONS
// ============================================================

// Lưu token vào sessionStorage (tự động xóa khi đóng browser)
function saveToken(token) {
    sessionStorage.setItem('hypercore_token', token);
}

// Lấy token từ sessionStorage
function getToken() {
    return sessionStorage.getItem('hypercore_token');
}

// Xóa token (logout)
function clearToken() {
    sessionStorage.removeItem('hypercore_token');
    sessionStorage.removeItem('hypercore_user');
}

// Lưu thông tin user vào sessionStorage
function saveUser(user) {
    sessionStorage.setItem('hypercore_user', JSON.stringify(user));
}

// Lấy thông tin user từ sessionStorage
function getUser() {
    const userJson = sessionStorage.getItem('hypercore_user');
    return userJson ? JSON.parse(userJson) : null;
}

// Hiển thị thông báo
function showNotification(message, type = 'success') {
    // Tạo notification element
    const notification = document.createElement('div');
    notification.className = `notification notification-${type}`;
    notification.innerHTML = `
        <div class="notification-content">
            <span class="notification-icon">${type === 'success' ? '✓' : '✕'}</span>
            <span class="notification-message">${message}</span>
        </div>
    `;
    
    // Thêm vào body
    document.body.appendChild(notification);
    
    // Hiển thị
    setTimeout(() => {
        notification.classList.add('show');
    }, 100);
    
    // Tự động ẩn sau 3 giây
    setTimeout(() => {
        notification.classList.remove('show');
        setTimeout(() => {
            notification.remove();
        }, 300);
    }, 3000);
}

// ============================================================
// ĐĂNG KÝ
// ============================================================

async function handleRegister(event) {
    event.preventDefault();
    
    // Lấy giá trị từ form
    const fullName = document.getElementById('regUser').value.trim();
    const email = document.getElementById('regEmail').value.trim();
    const password = document.getElementById('regPass').value;
    const confirmPassword = document.getElementById('regConfirm').value;
    
    // Validate
    if (fullName.length < 3) {
        showNotification('Tên đăng nhập tối thiểu 3 ký tự', 'error');
        return false;
    }
    
    if (!email.includes('@')) {
        showNotification('Email không hợp lệ', 'error');
        return false;
    }
    
    if (password.length < 6) {
        showNotification('Mật khẩu tối thiểu 6 ký tự', 'error');
        return false;
    }
    
    if (password !== confirmPassword) {
        showNotification('Mật khẩu xác nhận không khớp', 'error');
        return false;
    }
    
    try {
        // Gọi API đăng ký - Gửi password plain text, backend sẽ tự động hash
        const response = await fetch(`${API_BASE_URL}/auth/register`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                fullName: fullName,
                email: email,
                password: password,
                phoneNumber: null
            })
        });
        
        const data = await response.json();
        
        if (response.ok) {
            // Đăng ký thành công
            showNotification('Đăng ký thành công! Vui lòng đăng nhập.', 'success');
            
            // Đóng popup đăng ký
            closeRegisterPopup();
            
            // Mở popup đăng nhập sau 1 giây
            setTimeout(() => {
                openLoginPopup();
            }, 1000);
            
            // Reset form
            document.getElementById('registerForm').reset();
        } else {
            // Đăng ký thất bại
            showNotification(data.message || 'Đăng ký thất bại. Email có thể đã tồn tại.', 'error');
        }
    } catch (error) {
        console.error('Lỗi đăng ký:', error);
        showNotification('Có lỗi xảy ra. Vui lòng thử lại sau.', 'error');
    }
    
    return false;
}

// ============================================================
// ĐĂNG NHẬP
// ============================================================

async function handleLogin(event) {
    event.preventDefault();
    
    // Lấy giá trị từ form
    const email = document.getElementById('loginEmail').value.trim();
    const password = document.getElementById('loginPassword').value;
    
    // Validate
    if (!email || !password) {
        showNotification('Vui lòng nhập đầy đủ thông tin', 'error');
        return false;
    }
    
    try {
        // Gọi API đăng nhập - Gửi password plain text, backend sẽ tự động hash
        const response = await fetch(`${API_BASE_URL}/auth/login`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                email: email,
                password: password
            })
        });
        
        const data = await response.json();
        
        if (response.ok) {
            // Đăng nhập thành công
            showNotification(`Xin chào ${data.fullName}! Đăng nhập thành công.`, 'success');
            
            // Lưu token và user info
            saveToken(data.token);
            saveUser({
                userId: data.userId,
                fullName: data.fullName,
                email: data.email,
                role: data.role
            });
            
            // Đóng popup đăng nhập
            closeLoginPopup();
            
            // Cập nhật UI
            updateUIAfterLogin();
            
            // Reset form
            document.getElementById('loginForm').reset();
        } else {
            // Đăng nhập thất bại
            showNotification(data.message || 'Email hoặc mật khẩu không chính xác', 'error');
        }
    } catch (error) {
        console.error('Lỗi đăng nhập:', error);
        showNotification('Có lỗi xảy ra. Vui lòng thử lại sau.', 'error');
    }
    
    return false;
}

// ============================================================
// CẬP NHẬT UI SAU KHI ĐĂNG NHẬP
// ============================================================

function updateUIAfterLogin() {
    const user = getUser();
    
    if (!user) return;
    
    // Ẩn nút Login và Register
    const loginBtn = document.querySelector('.login-glass-btn');
    const registerBtn = document.querySelector('.register-glass-btn');
    
    if (loginBtn) loginBtn.style.display = 'none';
    if (registerBtn) registerBtn.style.display = 'none';
    
    // Hiển thị tên người dùng và nút logout
    const navActions = document.querySelector('.nav-actions');
    
    if (navActions) {
        // Tạo user info element
        const userInfo = document.createElement('div');
        userInfo.className = 'user-info';
        userInfo.innerHTML = `
            <span class="user-greeting">Xin chào, <strong>${user.fullName}</strong></span>
            <button class="logout-btn" onclick="handleLogout()">Đăng xuất</button>
        `;
        
        // Thêm vào trước giỏ hàng
        const cartBtn = navActions.querySelector('.cart-btn');
        navActions.insertBefore(userInfo, cartBtn);
    }
}

// ============================================================
// ĐĂNG XUẤT
// ============================================================

function handleLogout() {
    // Xóa token và user info
    clearToken();
    
    // Hiển thị thông báo
    showNotification('Đăng xuất thành công!', 'success');
    
    // Reload trang
    setTimeout(() => {
        window.location.reload();
    }, 1000);
}

// ============================================================
// KIỂM TRA ĐĂNG NHẬP KHI LOAD TRANG
// ============================================================

function checkLoginStatus() {
    const user = getUser();
    
    if (user) {
        // Đã đăng nhập
        updateUIAfterLogin();
    }
}

// ============================================================
// POPUP FUNCTIONS
// ============================================================

function openLoginPopup() {
    const popup = document.getElementById('loginPopup');
    if (popup) {
        popup.style.display = 'flex';
        setTimeout(() => {
            popup.classList.add('active');
        }, 10);
    }
}

function closeLoginPopup() {
    const popup = document.getElementById('loginPopup');
    if (popup) {
        popup.classList.remove('active');
        setTimeout(() => {
            popup.style.display = 'none';
        }, 300);
    }
}

function openRegisterPopup() {
    const popup = document.getElementById('registerPopup');
    if (popup) {
        popup.style.display = 'flex';
        setTimeout(() => {
            popup.classList.add('active');
        }, 10);
    }
}

function closeRegisterPopup() {
    const popup = document.getElementById('registerPopup');
    if (popup) {
        popup.classList.remove('active');
        setTimeout(() => {
            popup.style.display = 'none';
        }, 300);
    }
}

function switchToRegister() {
    closeLoginPopup();
    setTimeout(() => {
        openRegisterPopup();
    }, 300);
}

function switchToLogin() {
    closeRegisterPopup();
    setTimeout(() => {
        openLoginPopup();
    }, 300);
}

// ============================================================
// INIT KHI LOAD TRANG
// ============================================================

document.addEventListener('DOMContentLoaded', function() {
    // Kiểm tra trạng thái đăng nhập
    checkLoginStatus();
    
    // Thêm event listener cho nút Login
    const loginBtn = document.querySelector('.login-glass-btn');
    if (loginBtn) {
        loginBtn.addEventListener('click', openLoginPopup);
    }
    
    // Thêm event listener cho nút Register
    const registerBtn = document.querySelector('.register-glass-btn');
    if (registerBtn) {
        registerBtn.addEventListener('click', openRegisterPopup);
    }
});
