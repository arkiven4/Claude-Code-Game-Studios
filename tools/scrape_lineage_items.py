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

def scrape_lineage_items():
    pages = [
        {"main_type": "Weapon", "url": "https://lineage2m.plaync.com/naeu/guidebook/view?title=Weapons"},
        {"main_type": "Armor", "url": "https://lineage2m.plaync.com/naeu/guidebook/view?title=Armor"},
        {"main_type": "Accessory", "url": "https://lineage2m.plaync.com/naeu/guidebook/view?title=Accessories"}
    ]
    
    icon_dir = "/home/arkiven4/Documents/Project/Other/myvampire/assets/art/ui/item_icons/"
    data_dir = "/home/arkiven4/Documents/Project/Other/myvampire/assets/data/items/"
    
    os.makedirs(icon_dir, exist_ok=True)
    os.makedirs(data_dir, exist_ok=True)

    chrome_options = Options()
    chrome_options.add_argument("--headless")
    chrome_options.add_argument("--no-sandbox")
    chrome_options.add_argument("--disable-dev-shm-usage")
    chrome_options.add_argument("user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")

    driver = webdriver.Chrome(options=chrome_options)
    driver.set_page_load_timeout(120)
    
    all_items = []

    try:
        for page in pages:
            main_type = page["main_type"]
            url = page["url"]
            print(f"\n=== Scraping {main_type} from {url} ===")
            
            try:
                driver.get(url)
            except TimeoutException:
                driver.execute_script("window.stop();")
            
            # Wait for dynamic content to load
            time.sleep(25)
            
            scrollers = driver.find_elements(By.CLASS_NAME, "ncgbt-table-scroller")
            if not scrollers:
                print(f"No scrollers found for {main_type}. Retrying wait...")
                time.sleep(15)
                scrollers = driver.find_elements(By.CLASS_NAME, "ncgbt-table-scroller")
            
            print(f"Found {len(scrollers)} scrollers.")
            if not scrollers: continue

            # Step 1: Extract sub-types (e.g., One-handed Sword, Helmet, Ring)
            sub_types = []
            try:
                type_rows = scrollers[0].find_elements(By.TAG_NAME, "tr")
                for tr in type_rows:
                    cells = tr.find_elements(By.TAG_NAME, "td")
                    if len(cells) >= 2:
                        t_name = cells[1].text.strip()
                        if t_name and "Types of" not in t_name and "Features" not in t_name:
                            # Use only the first line for names like "Plate Armor\nHeavy"
                            t_name = t_name.split('\n')[0].strip()
                            sub_types.append(t_name)
            except Exception as e:
                print(f"  Error detecting sub-types: {e}")
            
            print(f"  Detected sub-types: {sub_types}")

            # Step 2: Process item tables
            item_scrollers = scrollers[1:]
            for i, scroller in enumerate(item_scrollers):
                class_specific = sub_types[i] if i < len(sub_types) else "General"
                print(f"  Processing Table {i+2} ({class_specific})...")
                
                rows = scroller.find_elements(By.TAG_NAME, "tr")
                if not rows: continue
                
                # Dynamic header detection
                header_cells = rows[0].find_elements(By.TAG_NAME, "td")
                if not header_cells: header_cells = rows[0].find_elements(By.TAG_NAME, "th")
                headers = [h.text.strip().lower() for h in header_cells]
                
                col_map = {"name": 0, "rank": 1, "icon": 0, "stats": [], "options": -1, "material": -1}
                for idx, h in enumerate(headers):
                    if "name" in h or "item" in h: col_map["name"] = col_map["icon"] = idx
                    elif "rank" in h or "rarity" in h: col_map["rank"] = idx
                    elif any(s in h for s in ["damage", "defense", "accuracy", "weight"]): col_map["stats"].append(idx)
                    elif "options" in h: col_map["options"] = idx
                    elif "material" in h: col_map["material"] = idx

                for row_idx, row in enumerate(rows[1:]):
                    cells = row.find_elements(By.TAG_NAME, "td")
                    if len(cells) <= max(col_map["name"], col_map["rank"]): continue
                    
                    try:
                        name_cell = cells[col_map["name"]]
                        item_name = name_cell.text.split("\n")[0].strip()
                        if not item_name: continue
                        
                        item_rank = cells[col_map["rank"]].text.strip()
                        
                        # Extract Icon
                        img = None
                        try: img = name_cell.find_element(By.TAG_NAME, "img")
                        except:
                            imgs = row.find_elements(By.TAG_NAME, "img")
                            if imgs: img = imgs[0]
                        src = img.get_attribute("src") if img else ""

                        # Extract Stats
                        item_stats = {}
                        for s_idx in col_map["stats"]:
                            stat_name = headers[s_idx].replace("\n", " ").strip()
                            stat_val = cells[s_idx].text.strip()
                            item_stats[stat_name] = stat_val
                        
                        # Options and Material
                        options = cells[col_map["options"]].text.strip() if col_map["options"] != -1 else ""
                        material = cells[col_map["material"]].text.strip() if col_map["material"] != -1 else ""

                        # Helper to clean strings for filename
                        def clean(s):
                            return re.sub(r'_+', '_', re.sub(r'[^a-zA-Z0-9]', '_', s)).strip('_')

                        c_type = clean(main_type)
                        c_class = clean(class_specific)
                        c_rank = clean(item_rank)
                        c_name = clean(item_name)
                        
                        # Final Convention: {Type}_{ClassSpecific}_{Rarity}_{Name}.png
                        filename = f"{c_type}_{c_class}_{c_rank}_{c_name}.png"
                        filepath = os.path.join(icon_dir, filename)
                        
                        item_entry = {
                            "main_type": main_type,
                            "class_specific": class_specific,
                            "name": item_name,
                            "rank": item_rank,
                            "stats": item_stats,
                            "options": options,
                            "material": material,
                            "filename": filename,
                            "icon_url": src
                        }
                        all_items.append(item_entry)

                        if src and src.startswith("http") and not os.path.exists(filepath):
                            try:
                                resp = requests.get(src, timeout=10)
                                if resp.status_code == 200:
                                    with open(filepath, 'wb') as f: f.write(resp.content)
                            except: pass
                    except: continue

        # Save all results
        with open(os.path.join(data_dir, "lineage2m_items_full.json"), 'w') as f:
            json.dump(all_items, f, indent=4)
        print(f"\nSaved {len(all_items)} items total to lineage2m_items_full.json")

    finally:
        driver.quit()

if __name__ == "__main__":
    scrape_lineage_items()
