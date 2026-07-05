import os
import re

directories = [
    r"g:\PC_Store\PC_Store\Page",
    r"g:\PC_Store\PC_Store\Page\profile"
]

replacements = {
    r"profile-common\.css(\?v=[\d\.]+)?": "profile-common.css?v=1.0.4",
    r"auth-ui\.css(\?v=[\d\.]+)?": "auth-ui.css?v=1.0.4",
    r"style\.css(\?v=[\d\.]+)?": "style.css?v=1.0.4",
    r"profile-common\.js(\?v=[\d\.]+)?": "profile-common.js?v=1.0.4",
    r"auth-ui\.js(\?v=[\d\.]+)?": "auth-ui.js?v=1.0.4",
    r"cart-helper\.js(\?v=[\d\.]+)?": "cart-helper.js?v=1.0.4"
}

for folder in directories:
    if not os.path.exists(folder):
        continue
    for filename in os.listdir(folder):
        if filename.endswith(".html"):
            filepath = os.path.join(folder, filename)
            with open(filepath, "r", encoding="utf-8") as f:
                content = f.read()
            
            original_content = content
            for pattern, replacement in replacements.items():
                content = re.sub(pattern, replacement, content)
            
            if content != original_content:
                with open(filepath, "w", encoding="utf-8") as f:
                    f.write(content)
                print(f"Updated cache-busting in {folder}\\{filename}")
