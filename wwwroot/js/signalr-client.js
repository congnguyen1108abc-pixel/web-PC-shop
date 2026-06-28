/**
 * PC_Store — SignalR Notification Client
 * ──────────────────────────────────────
 * Kết nối đến /hubs/notification và lắng nghe 2 loại event:
 *   - "ReceiveNotification" → thông báo cá nhân (Order, Warranty, System)
 *   - "AdminEvent"          → sự kiện Admin (NewOrder, OrderUpdated)
 *
 * Cách dùng:
 *   1. Nhúng thẻ script vào HTML (xem ví dụ ở cuối file)
 *   2. Sau khi user đăng nhập, gọi: SignalRClient.connect(userId)
 *   3. Lắng nghe event tùy ý bằng: SignalRClient.on("ReceiveNotification", handler)
 *   4. Admin thêm: SignalRClient.joinAdmin()
 */

const SignalRClient = (() => {

    // ── Config ────────────────────────────────────────────────────────────────
    const HUB_URL     = '/hubs/notification';
    const RETRY_DELAY = [0, 2000, 5000, 10000]; // ms tự reconnect

    // ── State ─────────────────────────────────────────────────────────────────
    let _connection = null;
    let _handlers   = {};      // { eventName: [fn, fn, ...] }
    let _connected  = false;

    // ── Private: Tạo connection ───────────────────────────────────────────────
    function _build() {
        return new signalR.HubConnectionBuilder()
            .withUrl(HUB_URL)
            .withAutomaticReconnect(RETRY_DELAY)
            .configureLogging(signalR.LogLevel.Warning)
            .build();
    }

    // ── Private: Đăng ký lắng nghe tất cả events đã đăng ký trước ────────────
    function _bindHandlers() {
        Object.entries(_handlers).forEach(([event, fns]) => {
            fns.forEach(fn => _connection.on(event, fn));
        });
    }

    // ── Public API ────────────────────────────────────────────────────────────

    /**
     * Kết nối Hub và join nhóm cá nhân của user.
     * @param {number|string} userId - ID của user đang đăng nhập
     */
    async function connect(userId) {
        if (_connected) return;

        _connection = _build();

        // Lắng nghe event "ReceiveNotification" (thông báo cá nhân)
        _connection.on('ReceiveNotification', (data) => {
            console.log('[SignalR] ReceiveNotification:', data);
            // Dispatch Custom DOM Event để các page tự xử lý
            window.dispatchEvent(new CustomEvent('signalr:notification', { detail: data }));
            // Hiện badge số thông báo chưa đọc
            _incrementBadge();
        });

        // Lắng nghe event "AdminEvent" (dành cho Admin panel)
        _connection.on('AdminEvent', (data) => {
            console.log('[SignalR] AdminEvent:', data);
            window.dispatchEvent(new CustomEvent('signalr:admin-event', { detail: data }));
        });

        // Gắn thêm handlers đã đăng ký bằng SignalRClient.on()
        _bindHandlers();

        try {
            await _connection.start();
            _connected = true;
            console.log('[SignalR] Đã kết nối thành công → /hubs/notification');

            // Join nhóm cá nhân của user
            await _connection.invoke('JoinUserGroup', String(userId));
            console.log(`[SignalR] Đã join group user_${userId}`);

        } catch (err) {
            console.error('[SignalR] Kết nối thất bại:', err);
        }

        // Lắng nghe reconnect tự động
        _connection.onreconnected(async () => {
            console.log('[SignalR] Đã kết nối lại!');
            await _connection.invoke('JoinUserGroup', String(userId));
        });
    }

    /**
     * Admin gọi hàm này để join nhóm "admin" và nhận sự kiện đơn hàng mới.
     */
    async function joinAdmin() {
        if (!_connected) {
            console.warn('[SignalR] Chưa kết nối. Hãy gọi connect(userId) trước.');
            return;
        }
        await _connection.invoke('JoinAdminGroup');
        console.log('[SignalR] Admin đã join nhóm admin');
    }

    /**
     * Đăng ký thêm handler cho 1 event bất kỳ.
     * @param {string} eventName - "ReceiveNotification" | "AdminEvent"
     * @param {Function} handler - callback(data)
     */
    function on(eventName, handler) {
        if (!_handlers[eventName]) _handlers[eventName] = [];
        _handlers[eventName].push(handler);
        // Nếu đã kết nối rồi thì gắn ngay
        if (_connected && _connection) {
            _connection.on(eventName, handler);
        }
    }

    /**
     * Ngắt kết nối (dùng khi logout).
     */
    async function disconnect() {
        if (_connection) {
            await _connection.stop();
            _connected = false;
            _handlers  = {};
            console.log('[SignalR] Đã ngắt kết nối.');
        }
    }

    // ── Private: Tăng badge số thông báo chưa đọc ────────────────────────────
    function _incrementBadge() {
        const badge = document.getElementById('notification-badge');
        if (!badge) return;
        const current = parseInt(badge.textContent || '0', 10);
        badge.textContent = current + 1;
        badge.style.display = 'inline-block';
    }

    // ── Export ────────────────────────────────────────────────────────────────
    return { connect, joinAdmin, on, disconnect };

})();


/* ════════════════════════════════════════════════════════════════════════════
   HƯỚNG DẪN TÍCH HỢP VÀO HTML
   ════════════════════════════════════════════════════════════════════════════

1. NHÚNG THƯ VIỆN + SCRIPT VÀO <head> hoặc cuối <body>:

   <!-- SignalR JS từ CDN (không cần cài npm) -->
   <script src="https://cdnjs.cloudflare.com/ajax/libs/microsoft-signalr/8.0.0/signalr.min.js"></script>
   <!-- Client helper của PC_Store -->
   <script src="/js/signalr-client.js"></script>


2. KHỞI ĐỘNG SAU KHI USER ĐĂNG NHẬP (trong file JS của từng page):

   // Lấy userId từ JWT hoặc localStorage sau khi login
   const userId = localStorage.getItem('userId');  // hoặc decode từ JWT

   if (userId) {
       SignalRClient.connect(userId);
   }


3. LẮNG NGHE THÔNG BÁO ĐƠN HÀNG (customer pages):

   window.addEventListener('signalr:notification', (e) => {
       const { title, message, type, relatedId } = e.detail;

       // Hiện toast / popup
       showToast(title, message);

       // Nếu đang ở trang lịch sử đơn hàng → reload lại danh sách
       if (type === 'Order' && window.location.pathname.includes('orders')) {
           loadOrderHistory();
       }
   });


4. LẮNG NGHE SỰ KIỆN ADMIN (admin dashboard):

   // Thêm vào sau khi đã kết nối với vai trò Admin
   SignalRClient.connect(userId).then(() => SignalRClient.joinAdmin());

   window.addEventListener('signalr:admin-event', (e) => {
       const { eventType, data } = e.detail;

       if (eventType === 'NewOrder') {
           showToast('Đơn hàng mới!', data.message);
           refreshOrderList();       // Gọi lại API lấy danh sách đơn
           refreshDashboardStats();  // Cập nhật số liệu dashboard
       }

       if (eventType === 'OrderUpdated') {
           refreshOrderList();
       }
   });


5. KHI USER ĐĂNG XUẤT:

   SignalRClient.disconnect();
   localStorage.removeItem('userId');

   ════════════════════════════════════════════════════════════════════════════ */
