/* ============================================================
   CHATBOT GLOBAL JAVASCRIPT - PC STORE AI ASSISTANT
   ============================================================ */

(function () {
    // 1. Load stylesheet dynamically if not already present
    if (!document.getElementById('chatbot-global-style')) {
        const link = document.createElement('link');
        link.id = 'chatbot-global-style';
        link.rel = 'stylesheet';
        link.href = '/assets/css/chatbot-global.css?v=1.1.2';
        document.head.appendChild(link);
    }

    // 2. Inject Chatbot HTML markup to the bottom of the body
    const chatbotHtml = `
        <div id="chatbot-button" class="chatbot-button" title="Mở trợ lý AI">
            💬
            <span id="chatbot-badge" class="chatbot-button-badge"></span>
        </div>

        <div id="chatbot-bubble" class="chatbot-notification-bubble">
            <div id="chatbot-bubble-text">Đang chuẩn bị gợi ý...</div>
            <div style="font-size: 11px; color: #38bdf8; margin-top: 8px; text-align: right; font-weight: 500;">Bấm để xem & phản hồi ➜</div>
        </div>

        <div id="chatbot-modal" class="chatbot-modal">
            <div class="chatbot-header">
                <div class="chatbot-header-info">
                    <div class="chatbot-avatar">🤖</div>
                    <div class="chatbot-header-text">
                        <h3>AI Assistant</h3>
                        <div class="chatbot-status">Đang trực tuyến</div>
                    </div>
                </div>
                <button id="chatbot-close" class="chatbot-close">✕</button>
            </div>
            <div id="chatbot-messages" class="chatbot-messages">
                <div class="chatbot-msg-row bot">
                    <div class="chatbot-msg-bubble">
                        👋 Xin chào! Tôi là trợ lý công nghệ AI của PC Store. Tôi có thể giúp gì cho bạn về các dòng PC, Laptop, linh kiện hoặc tư vấn cấu hình hôm nay?
                    </div>
                </div>
            </div>
            <div class="chatbot-input-area">
                <input type="text" id="chatbot-input" class="chatbot-input-field" placeholder="Nhập câu hỏi của bạn..." autocomplete="off">
                <button id="chatbot-send" class="chatbot-send-btn" title="Gửi câu hỏi">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" style="display:block; margin:auto;">
                        <line x1="22" y1="2" x2="11" y2="13"></line>
                        <polygon points="22 2 15 22 11 13 2 9 22 2"></polygon>
                    </svg>
                </button>
            </div>
        </div>
    `;

    // Wait for DOM to be ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initChatbot);
    } else {
        initChatbot();
    }

    function initChatbot() {
        // Prevent duplicate rendering
        if (document.getElementById('chatbot-button')) return;

        const container = document.createElement('div');
        container.innerHTML = chatbotHtml;
        document.body.appendChild(container);

        // DOM elements
        const btn = document.getElementById("chatbot-button");
        const modal = document.getElementById("chatbot-modal");
        const closeBtn = document.getElementById("chatbot-close");
        const messagesContainer = document.getElementById("chatbot-messages");
        const inputField = document.getElementById("chatbot-input");
        const sendBtn = document.getElementById("chatbot-send");
        const badge = document.getElementById("chatbot-badge");
        const bubble = document.getElementById("chatbot-bubble");
        const bubbleText = document.getElementById("chatbot-bubble-text");

        const API_CHAT = "/api/chatbot";
        const API_CONTEXT = "/api/chatbot/context-greeting";

        // Get/Create Chat Session ID
        let sessionId = sessionStorage.getItem("pc_store_chat_session");
        if (!sessionId) {
            sessionId = "sess_" + Math.random().toString(36).substring(2, 15) + Math.random().toString(36).substring(2, 15);
            sessionStorage.setItem("pc_store_chat_session", sessionId);
        }

        // Toggle modal functions
        function openChatbot() {
            modal.classList.add("active");
            btn.classList.add("active");
            inputField.focus();
            
            // Clear notifications when chat is opened
            if (badge) badge.style.display = "none";
            if (bubble) bubble.style.display = "none";
            
            // Scroll to bottom
            messagesContainer.scrollTop = messagesContainer.scrollHeight;
        }

        function closeChatbot() {
            modal.classList.remove("active");
            btn.classList.remove("active");
        }

        // Bind open events
        btn.addEventListener("click", () => {
            if (modal.classList.contains("active")) {
                closeChatbot();
            } else {
                openChatbot();
            }
        });

        if (bubble) {
            bubble.addEventListener("click", () => {
                openChatbot();
            });
        }

        closeBtn.addEventListener("click", (e) => {
            e.stopPropagation();
            closeChatbot();
        });

        // Enter key support
        inputField.addEventListener("keydown", (e) => {
            if (e.key === "Enter" && !e.shiftKey) {
                e.preventDefault();
                sendMessage();
            }
        });

        sendBtn.addEventListener("click", sendMessage);

        function appendMessage(text, sender) {
            const row = document.createElement("div");
            row.className = `chatbot-msg-row ${sender}`;
            row.innerHTML = `<div class="chatbot-msg-bubble">${text}</div>`;
            messagesContainer.appendChild(row);
            messagesContainer.scrollTop = messagesContainer.scrollHeight;
        }

        function showLoading() {
            const row = document.createElement("div");
            row.className = "chatbot-msg-row bot";
            row.id = "chatbot-loading-indicator";
            row.innerHTML = `
                <div class="chatbot-msg-bubble chatbot-loading-bubble">
                    <span></span><span></span><span></span>
                </div>
            `;
            messagesContainer.appendChild(row);
            messagesContainer.scrollTop = messagesContainer.scrollHeight;
        }

        function hideLoading() {
            const indicator = document.getElementById("chatbot-loading-indicator");
            if (indicator) indicator.remove();
        }

        // Send normal chat message
        async function sendMessage() {
            const text = inputField.value.trim();
            if (!text) return;

            // Clear input
            inputField.value = "";
            appendMessage(text, "user");

            // Disable UI while processing
            inputField.disabled = true;
            sendBtn.disabled = true;
            showLoading();

            // Get logged-in user id if any
            let userId = null;
            if (typeof getCartUser === 'function') {
                const user = getCartUser();
                if (user && user.userId) {
                    userId = parseInt(user.userId);
                }
            }

            try {
                const response = await fetch(API_CHAT, {
                    method: "POST",
                    headers: { "Content-Type": "application/json" },
                    body: JSON.stringify({
                        message: text,
                        sessionId: sessionId,
                        userId: userId
                    })
                });

                if (!response.ok) throw new Error("API_ERROR");

                const data = await response.json();
                appendMessage(data.reply || "Xin lỗi, tôi gặp sự cố khi xử lý phản hồi.", "bot");
            } catch (error) {
                console.error("Chatbot error:", error);
                appendMessage("Xin lỗi, kết nối với AI đang bị gián đoạn. Vui lòng thử lại sau.", "bot");
            } finally {
                hideLoading();
                inputField.disabled = false;
                sendBtn.disabled = false;
                inputField.focus();
            }
        }

        // ============================================================
        // CONTEXTUAL AWARENESS & TRIGGER (Đọc vị ngữ cảnh)
        // ============================================================
        
        // 1. Nếu đang ở trang chi tiết sản phẩm, lưu sản phẩm đã xem vào sessionStorage
        const pathName = window.location.pathname.toLowerCase();
        if (pathName.includes("/product/") || pathName.includes("product-detail")) {
            // Đợi API load dữ liệu và hiển thị tên sản phẩm lên giao diện
            setTimeout(() => {
                const productName = document.getElementById("pd-name")?.textContent?.trim();
                if (productName) {
                    sessionStorage.setItem("pc_store_last_viewed_product", productName);
                    console.log("[Chatbot Context] Saved last viewed product to session:", productName);
                }
            }, 2000); // Trì hoãn 2 giây để đảm bảo DOM đã cập nhật xong từ API
        }

        let hasTriggeredContext = false;
        const triggerDelayMs = 20000; // 20 giây theo yêu cầu mới

        setTimeout(async () => {
            // Chỉ tự động kích hoạt khi:
            // - Khung chat chưa mở
            // - Chưa kích hoạt tự động ở trang này
            // - Người dùng ĐÃ TỪNG xem ít nhất một chi tiết sản phẩm trong phiên làm việc
            if (modal.classList.contains("active") || hasTriggeredContext) return;

            const lastViewedProduct = sessionStorage.getItem("pc_store_last_viewed_product");
            if (!lastViewedProduct) {
                console.log("[Chatbot Context] No product viewed yet in session. Auto-popup skipped.");
                return;
            }

            hasTriggeredContext = true;

            // Xác định loại trang hiện tại
            let pageType = "General";
            if (pathName.includes("/product/") || pathName.includes("product-detail")) {
                pageType = "ProductDetail";
            } else if (pathName.includes("/shoppingcart")) {
                pageType = "ShoppingCart";
            } else if (pathName.includes("/pcbuild")) {
                pageType = "PCBuild";
            } else if (pathName === "/" || pathName === "" || pathName.includes("/homepage")) {
                pageType = "Homepage";
            }

            // Lấy ID người dùng nếu đã đăng nhập
            let userId = null;
            if (typeof getCartUser === 'function') {
                const user = getCartUser();
                if (user && user.userId) {
                    userId = parseInt(user.userId);
                }
            }

            console.log(`[Chatbot Context] Fetching background greeting on ${pageType} for product: ${lastViewedProduct}`);

            try {
                const response = await fetch(API_CONTEXT, {
                    method: "POST",
                    headers: { "Content-Type": "application/json" },
                    body: JSON.stringify({
                        url: window.location.href,
                        pageType: pageType,
                        pageTitle: document.title,
                        productName: lastViewedProduct,
                        sessionId: sessionId,
                        userId: userId
                    })
                });

                if (response.ok) {
                    const data = await response.json();
                    
                    // 1. Thêm câu trả lời vào trong chatbox ngầm
                    appendMessage(data.reply, "bot");

                    // 2. Hiển thị dấu chấm đỏ thông báo và bong bóng chat bên ngoài
                    if (badge) badge.style.display = "block";
                    if (bubbleText) bubbleText.textContent = data.reply;
                    if (bubble) bubble.style.display = "block";

                    console.log("[Chatbot Context] Background greeting loaded and notification shown.");
                } else {
                    throw new Error("API_ERROR");
                }
            } catch (err) {
                console.error("Failed to load context greeting:", err);
                
                // Phản hồi mặc định nếu API lỗi
                let defaultMsg = `Chào bạn! Tôi thấy bạn đang quan tâm sản phẩm ${lastViewedProduct}. Bạn có cần tôi tư vấn thêm về thông số kỹ thuật hay ưu đãi đi kèm không?`;
                appendMessage(defaultMsg, "bot");

                if (badge) badge.style.display = "block";
                if (bubbleText) bubbleText.textContent = defaultMsg;
                if (bubble) bubble.style.display = "block";
            }
        }, triggerDelayMs);
    }
})();
