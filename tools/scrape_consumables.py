import os
import time
import re
import json
import requests
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException

def scrape_consumables():
    url = "https://lineage2m.plaync.com/naeu/guidebook/view?title=Common%20Items"
    icon_dir = "/home/arkiven4/Documents/Project/Other/myvampire/assets/art/ui/item_icons/"
    data_file = "/home/arkiven4/Documents/Project/Other/myvampire/assets/data/items/lineage2m_consumables.json"
    
    os.makedirs(icon_dir, exist_ok=True)
    os.makedirs(os.path.dirname(data_file), exist_ok=True)

    chrome_options = Options()
    chrome_options.add_argument("--headless")
    chrome_options.add_argument("--no-sandbox")
    chrome_options.add_argument("--disable-dev-shm-usage")
    chrome_options.add_argument("user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")

    driver = webdriver.Chrome(options=chrome_options)
    driver.set_page_load_timeout(120)
    
    all_consumables = []

    try:
        print(f"Navigating to {url}...")
        try:
            driver.get(url)
        except TimeoutException:
            driver.execute_script("window.stop();")
        
        # Wait for dynamic content
        time.sleep(25)
        
        scrollers = driver.find_elements(By.CLASS_NAME, "ncgbt-table-scroller")
        print(f"Found {len(scrollers)} scroller containers.")
        
        # Consumables are usually in the second scroller or later
        # First one is often 'Types of Items'
        item_scrollers = scrollers[1:] if len(scrollers) > 1 else scrollers
        
        for i, scroller in enumerate(item_scrollers):
            print(f"\n--- Processing Scroller {i+1} ---")
            
            rows = scroller.find_elements(By.TAG_NAME, "tr")
            if not rows: continue
            
            # Header detection
            header_cells = rows[0].find_elements(By.TAG_NAME, "td")
            if not header_cells: header_cells = rows[0].find_elements(By.TAG_NAME, "th")
            headers = [h.text.strip().lower() for h in header_cells]
            print(f"Headers: {headers}")
            
            col_map = {"name": 0, "type": 1, "details": -1, "icon": 0}
            for idx, h in enumerate(headers):
                if "name" in h or "item" in h: col_map["name"] = col_map["icon"] = idx
                elif "type" in h: col_map["type"] = idx
                elif "detail" in h or "effect" in h or "options" in h: col_map["details"] = idx

            # If details not found, try last column
            if col_map["details"] == -1 and len(headers) > 2:
                col_map["details"] = len(headers) - 1

            for row_idx, row in enumerate(rows[1:]):
                cells = row.find_elements(By.TAG_NAME, "td")
                if len(cells) <= max(col_map["name"], col_map["type"]): continue
                
                try:
                    name_cell = cells[col_map["name"]]
                    item_name = name_cell.text.split("\n")[0].strip()
                    if not item_name: continue
                    
                    item_type = cells[col_map["type"]].text.strip()
                    item_details = cells[col_map["details"]].text.strip() if col_map["details"] != -1 else ""
                    
                    img = None
                    try: img = name_cell.find_element(By.TAG_NAME, "img")
                    except:
                        imgs = row.find_elements(By.TAG_NAME, "img")
                        if imgs: img = imgs[0]
                    
                    src = img.get_attribute("src") if img else ""

                    def clean(s):
                        return re.sub(r'_+', '_', re.sub(r'[^a-zA-Z0-9]', '_', s)).strip('_')

                    c_type = clean(item_type)
                    c_name = clean(item_name)
                    
                    filename = f"Consumable_{c_type}_{c_name}.png"
                    filepath = os.path.join(icon_dir, filename)
                    
                    entry = {
                        "name": item_name,
                        "type": item_type,
                        "details": item_details,
                        "filename": filename,
                        "icon_url": src
                    }
                    all_consumables.append(entry)

                    if src and src.startswith("http") and not os.path.exists(filepath):
                        try:
                            resp = requests.get(src, timeout=10)
                            if resp.status_code == 200:
                                with open(filepath, 'wb') as f: f.write(resp.content)
                                print(f"  Downloaded: {filename}")
                        except: pass
                except Exception as e:
                    print(f"  Error row {row_idx}: {e}")
                    continue
        
        with open(data_file, 'w') as f:
            json.dump(all_consumables, f, indent=4)
        print(f"\nSaved {len(all_consumables)} consumables to {data_file}")

    finally:
        driver.quit()

if __name__ == "__main__":
    scrape_consumables()
