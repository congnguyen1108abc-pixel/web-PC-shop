// ========================================
// FILLADDRESS.JS - Connect to REST API
// ========================================

const API_BASE = '';
const API_USERS = '/api/users';

// Get JWT token from localStorage
function getAuthToken() {
    return localStorage.getItem('authToken');
}

// Get current user info from localStorage
function getCurrentUser() {
    const userStr = localStorage.getItem('userInfo');
    return userStr ? JSON.parse(userStr) : null;
}

// Check if user is logged in
function checkAuth() {
    const token = getAuthToken();
    const user = getCurrentUser();
    
    if (!token || !user) {
        alert('Vui lòng đăng nhập để tiếp tục!');
        window.location.href = '/Login?redirect=' + encodeURIComponent(window.location.pathname);
        return false;
    }
    
    return true;
}

// Load user's existing addresses
async function loadUserAddresses() {
    if (!checkAuth()) return;
    
    const user = getCurrentUser();
    const token = getAuthToken();
    
    try {
        const response = await fetch(`${API_USERS}/addresses/${user.userId}`, {
            method: 'GET',
            headers: {
                'Authorization': `Bearer ${token}`,
                'Content-Type': 'application/json'
            }
        });
        
        if (!response.ok) {
            throw new Error('Không thể tải địa chỉ');
        }
        
        const addresses = await response.json();
        console.log('User addresses:', addresses);
        
        // If has default address, auto-fill form
        if (addresses && addresses.length > 0) {
            const defaultAddr = addresses.find(a => a.isDefault) || addresses[0];
            autoFillAddress(defaultAddr);
        }
        
        return addresses;
    } catch (error) {
        console.error('Error loading addresses:', error);
        return [];
    }
}

// Auto-fill form with existing address
function autoFillAddress(address) {
    document.getElementById('fullName').value = address.receiverName || '';
    document.getElementById('phoneNumber').value = address.phoneNumber || '';
    
    // Auto-select city, district, ward if matches
    // Wait for cities to load first
    setTimeout(() => {
        selectCity(address.province);
        setTimeout(() => {
            selectDistrict(address.district);
            setTimeout(() => {
                selectWard(address.ward);
            }, 500);
        }, 500);
    }, 1000);
    
    document.getElementById('streetAddress').value = address.detailAddress || '';
    
    if (address.isDefault) {
        document.getElementById('defaultAddress').checked = true;
    }
}

function selectCity(cityName) {
    const citySelect = document.getElementById('citySelect');
    const options = citySelect.options;
    for (let i = 0; i < options.length; i++) {
        if (options[i].value === cityName || options[i].textContent === cityName) {
            citySelect.selectedIndex = i;
            citySelect.dispatchEvent(new Event('change'));
            break;
        }
    }
}

function selectDistrict(districtName) {
    const districtSelect = document.getElementById('districtSelect');
    const options = districtSelect.options;
    for (let i = 0; i < options.length; i++) {
        if (options[i].value === districtName || options[i].textContent === districtName) {
            districtSelect.selectedIndex = i;
            districtSelect.dispatchEvent(new Event('change'));
            break;
        }
    }
}

function selectWard(wardName) {
    const wardSelect = document.getElementById('wardSelect');
    const options = wardSelect.options;
    for (let i = 0; i < options.length; i++) {
        if (options[i].value === wardName || options[i].textContent === wardName) {
            wardSelect.selectedIndex = i;
            break;
        }
    }
}

// Save address to database
async function saveAddress() {
    if (!checkAuth()) return false;
    
    // Validate form
    const fullName = document.getElementById('fullName').value.trim();
    const phoneNumber = document.getElementById('phoneNumber').value.trim();
    const emailAddress = document.getElementById('emailAddress').value.trim();
    const city = document.getElementById('citySelect').value;
    const district = document.getElementById('districtSelect').value;
    const ward = document.getElementById('wardSelect').value;
    const streetAddress = document.getElementById('streetAddress').value.trim();
    const isDefault = document.getElementById('defaultAddress').checked;
    
    // Validation
    if (!fullName) {
        alert('Vui lòng nhập họ tên!');
        return false;
    }
    
    if (!phoneNumber || !/^0[0-9]{9}$/.test(phoneNumber)) {
        alert('Số điện thoại không hợp lệ! (Phải là 10 số, bắt đầu bằng 0)');
        return false;
    }
    
    if (!city || !district || !ward) {
        alert('Vui lòng chọn đầy đủ Tỉnh/Thành, Quận/Huyện, Phường/Xã!');
        return false;
    }
    
    if (!streetAddress) {
        alert('Vui lòng nhập số nhà, tên đường!');
        return false;
    }
    
    const user = getCurrentUser();
    const token = getAuthToken();
    
    const addressData = {
        userId: user.userId,
        receiverName: fullName,
        phoneNumber: phoneNumber,
        province: city,
        district: district,
        ward: ward,
        detailAddress: streetAddress,
        isDefault: isDefault
    };
    
    try {
        console.log('Saving address:', addressData);
        
        const response = await fetch(`${API_USERS}/addresses`, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${token}`,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(addressData)
        });
        
        const result = await response.json();
        
        if (!response.ok) {
            throw new Error(result.message || 'Lưu địa chỉ thất bại');
        }
        
        console.log('Address saved successfully:', result);
        
        // Save address to localStorage for order
        const shippingAddress = {
            fullName: fullName,
            phoneNumber: phoneNumber,
            email: emailAddress,
            province: city,
            district: district,
            ward: ward,
            detailAddress: streetAddress,
            fullAddress: `${streetAddress}, ${ward}, ${district}, ${city}`
        };
        
        localStorage.setItem('shippingAddress', JSON.stringify(shippingAddress));
        
        return true;
    } catch (error) {
        console.error('Error saving address:', error);
        alert('Lỗi: ' + error.message);
        return false;
    }
}

// Handle submit button
document.addEventListener('DOMContentLoaded', function() {
    // Check auth on page load
    if (!checkAuth()) return;
    
    // Load user's addresses
    loadUserAddresses();
    
    // Submit button handler
    const submitBtn = document.querySelector('.submit-btn');
    if (submitBtn) {
        submitBtn.addEventListener('click', async function(e) {
            e.preventDefault();
            
            console.log('Submit button clicked!');
            
            // Save address first
            const saved = await saveAddress();
            
            if (saved) {
                alert('✅ Đã lưu địa chỉ thành công!');
                // Redirect to payments page
                window.location.href = '/payments';
            }
        });
    }
    
    // Back button handler
    const backBtn = document.querySelector('.back-btn');
    if (backBtn) {
        backBtn.addEventListener('click', function() {
            window.location.href = '/shoppingcart';
        });
    }
    
    console.log('✅ Filladdress page initialized with API connection!');
});
