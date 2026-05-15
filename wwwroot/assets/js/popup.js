class PopupWidget {

    constructor(id) {

        this.popup = document.getElementById(id);

        this.closeBtn = this.popup.querySelector('.widget-close');

        this.init();
    }

    init() {

        /* CLOSE BUTTON */

        this.closeBtn.addEventListener('click', () => {
            this.close();
        });

        /* CLICK OUTSIDE */

        this.popup.addEventListener('click', (e) => {

            if (e.target === this.popup) {
                this.close();
            }

        });

    }

    open() {
        this.popup.classList.add('active');
    }

    close() {
        this.popup.classList.remove('active');
    }

}

/* GLOBAL HELPERS FOR POPUPS */
window.openLoginPopup = () => document.getElementById("loginPopup")?.classList.add("active");
window.closeLoginPopup = () => document.getElementById("loginPopup")?.classList.remove("active");
window.openRegisterPopup = () => document.getElementById("registerPopup")?.classList.add("active");
window.closeRegisterPopup = () => document.getElementById("registerPopup")?.classList.remove("active");

window.switchToRegister = () => {
    window.closeLoginPopup();
    setTimeout(window.openRegisterPopup, 300);
};

window.switchToLogin = () => {
    window.closeRegisterPopup();
    setTimeout(window.openLoginPopup, 300);
};

/* REGISTRATION VALIDATION */
window.handleRegister = (event) => {
    event.preventDefault();

    const user = document.getElementById("regUser");
    const email = document.getElementById("regEmail");
    const pass = document.getElementById("regPass");
    const confirm = document.getElementById("regConfirm");

    const userError = document.getElementById("userError");
    const emailError = document.getElementById("emailError");
    const passError = document.getElementById("passError");
    const confirmError = document.getElementById("confirmError");

    // Reset
    document.querySelectorAll(".widget-input").forEach(input => input.classList.remove("error"));
    document.querySelectorAll(".error-msg").forEach(msg => msg.style.display = "none");

    let valid = true;

    // Username Validation
    if (user.value.trim().length < 3) {
        user.classList.add("error");
        userError.style.display = "block";
        valid = false;
    } else if (user.value.includes(" ")) {
        user.classList.add("error");
        userError.innerText = "Tên đăng nhập không được chứa khoảng trắng";
        userError.style.display = "block";
        valid = false;
    }

    // Email Validation
    const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailPattern.test(email.value)) {
        email.classList.add("error");
        emailError.style.display = "block";
        valid = false;
    }

    // Password Validation
    if (pass.value.length < 6) {
        pass.classList.add("error");
        passError.innerText = "Mật khẩu tối thiểu 6 ký tự";
        passError.style.display = "block";
        valid = false;
    } else if (!/[A-Z]/.test(pass.value)) {
        pass.classList.add("error");
        passError.innerText = "Mật khẩu phải có ít nhất 1 chữ in hoa";
        passError.style.display = "block";
        valid = false;
    } else if (!/[0-9]/.test(pass.value)) {
        pass.classList.add("error");
        passError.innerText = "Mật khẩu phải có ít nhất 1 chữ số";
        passError.style.display = "block";
        valid = false;
    }

    // Confirm Password
    if (confirm.value !== pass.value) {
        confirm.classList.add("error");
        confirmError.style.display = "block";
        valid = false;
    }

    if (valid) {
        alert("Đăng ký thành công 🚀");
        document.getElementById("registerForm").reset();
        window.closeRegisterPopup();
    }
    return false;
};

/* DYNAMIC LOADER SYSTEM */
async function loadWidget(url, containerId, popupId, triggerClass) {
    try {
        const response = await fetch(url);
        const html = await response.text();
        document.getElementById(containerId).innerHTML = html;

        const popup = new PopupWidget(popupId);
        const buttons = document.querySelectorAll(triggerClass);

        buttons.forEach(btn => {
            btn.addEventListener('click', (e) => {
                e.preventDefault();
                popup.open();
            });
        });

        // Initialize Real-time validation if this is the Register widget
        if (popupId === 'registerPopup') {
            initRegisterRealtime();
        }

    } catch (err) {
        console.error("Lỗi khi tải widget:", err);
    }
}

function initRegisterRealtime() {
    const user = document.getElementById("regUser");
    const email = document.getElementById("regEmail");
    const pass = document.getElementById("regPass");
    const confirm = document.getElementById("regConfirm");
    const userError = document.getElementById("userError");
    const emailError = document.getElementById("emailError");
    const passError = document.getElementById("passError");
    const confirmError = document.getElementById("confirmError");

    user?.addEventListener("input", function () {
        if (this.value.trim().length >= 3 && !this.value.includes(" ")) {
            this.classList.remove("error");
            userError.style.display = "none";
        }
    });

    email?.addEventListener("input", function () {
        const pattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (pattern.test(this.value)) {
            this.classList.remove("error");
            emailError.style.display = "none";
        }
    });

    pass?.addEventListener("input", function () {
        const val = this.value;
        if (val.length >= 6 && /[A-Z]/.test(val) && /[0-9]/.test(val)) {
            this.classList.remove("error");
            passError.style.display = "none";
        }
    });

    confirm?.addEventListener("input", function () {
        const p = document.getElementById("regPass").value;
        if (this.value === p) {
            this.classList.remove("error");
            confirmError.style.display = "none";
        }
    });
}

/* INITIALIZE WIDGETS */
document.addEventListener('DOMContentLoaded', () => {
    loadWidget('/assets/widgets/login.html', 'login-popup-container', 'loginPopup', '.login-glass-btn');
    loadWidget('/assets/widgets/register.html', 'register-popup-container', 'registerPopup', '.register-glass-btn');
});