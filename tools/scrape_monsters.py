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

def scrape_monsters():
    url = "https://lineage2m.plaync.com/naeu/guidebook/view?title=Common%20and%20Elite%20Monsters"
    icon_dir = "/home/arkiven4/Documents/Project/Other/myvampire/assets/art/ui/monster_icons/"
    data_file = "/home/arkiven4/Documents/Project/Other/myvampire/assets/data/monsters/lineage2m_monsters.json"
    
    os.makedirs(icon_dir, exist_ok=True)
    os.makedirs(os.path.dirname(data_file), exist_ok=True)

    chrome_options = Options()
    chrome_options.add_argument("--headless")
    chrome_options.add_argument("--no-sandbox")
    chrome_options.add_argument("--disable-dev-shm-usage")
    chrome_options.add_argument("user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")

    driver = webdriver.Chrome(options=chrome_options)
    driver.set_page_load_timeout(120)
    
    all_monsters = []

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
        
        # Monsters usually have one main table in this section
        for i, scroller in enumerate(scrollers):
            print(f"\n--- Processing Table {i+1} ---")
            
            rows = scroller.find_elements(By.TAG_NAME, "tr")
            if not rows: continue
            
            # Header detection
            header_cells = rows[0].find_elements(By.TAG_NAME, "td")
            if not header_cells: header_cells = rows[0].find_elements(By.TAG_NAME, "th")
            headers = [h.text.strip().lower() for h in header_cells]
            print(f"Headers: {headers}")
            
            # Spawn Area | Monster Name | Lv. | Class | Dropped Item
            col_map = {"area": -1, "name": -1, "level": -1, "class": -1, "drops": -1, "icon": -1}
            for idx, h in enumerate(headers):
                if "area" in h: col_map["area"] = idx
                elif "name" in h or "monster" in h: col_map["name"] = col_map["icon"] = idx
                elif "lv" in h or "level" in h: col_map["level"] = idx
                elif "class" in h: col_map["class"] = idx
                elif "drop" in h or "item" in h: col_map["drops"] = idx

            for row_idx, row in enumerate(rows[1:]):
                cells = row.find_elements(By.TAG_NAME, "td")
                if len(cells) <= max(col_map["name"], 0): continue
                
                try:
                    name_cell = cells[col_map["name"]]
                    monster_name = name_cell.text.split("\n")[0].strip()
                    if not monster_name: continue
                    
                    # Extract level (remove 'Lv.')
                    lv_text = cells[col_map["level"]].text.strip() if col_map["level"] != -1 else "1"
                    lv = re.findall(r'\d+', lv_text)
                    monster_lv = int(lv[0]) if lv else 1
                    
                    monster_area = cells[col_map["area"]].text.strip() if col_map["area"] != -1 else "Unknown"
                    monster_class = cells[col_map["class"]].text.strip() if col_map["class"] != -1 else "Common"
                    
                    # Extract dropped items (often a list of names or icons)
                    drops_text = cells[col_map["drops"]].text.strip() if col_map["drops"] != -1 else ""
                    # Sometimes drops are multiple icons in the same cell, let's try to get all text
                    drops = [d.strip() for d in drops_text.split("\n") if d.strip()]
                    
                    img = None
                    try: img = name_cell.find_element(By.TAG_NAME, "img")
                    except:
                        imgs = row.find_elements(By.TAG_NAME, "img")
                        if imgs: img = imgs[0]
                    
                    src = img.get_attribute("src") if img else ""

                    def clean(s):
                        return re.sub(r'_+', '_', re.sub(r'[^a-zA-Z0-9]', '_', s)).strip('_')

                    c_name = clean(monster_name)
                    c_class = clean(monster_class)
                    
                    filename = f"Monster_{c_class}_{c_name}.png"
                    filepath = os.path.join(icon_dir, filename)
                    
                    entry = {
                        "name": monster_name,
                        "level": monster_lv,
                        "class": monster_class,
                        "area": monster_area,
                        "drops": drops,
                        "filename": filename,
                        "icon_url": src
                    }
                    all_monsters.append(entry)

                    if src and src.startswith("http") and not os.path.exists(filepath):
                        try:
                            resp = requests.get(src, timeout=10)
                            if resp.status_code == 200:
                                with open(filepath, 'wb') as f: f.write(resp.content)
                                print(f"  Downloaded: {filename}")
                        except: pass
                except Exception as e:
                    continue
        
        with open(data_file, 'w') as f:
            json.dump(all_monsters, f, indent=4)
        print(f"\nSaved {len(all_monsters)} monsters to {data_file}")

    finally:
        driver.quit()

if __name__ == "__main__":
    scrape_monsters()
