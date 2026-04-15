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

def scrape_weapons():
    url = "https://lineage2m.plaync.com/naeu/guidebook/view?title=Weapons"
    output_dir = "/home/arkiven4/Documents/Project/Other/myvampire/assets/art/ui/item_icons/"
    data_file = "/home/arkiven4/Documents/Project/Other/myvampire/assets/data/items/lineage2m_weapons.json"
    
    os.makedirs(output_dir, exist_ok=True)
    os.makedirs(os.path.dirname(data_file), exist_ok=True)

    chrome_options = Options()
    chrome_options.add_argument("--headless")
    chrome_options.add_argument("--no-sandbox")
    chrome_options.add_argument("--disable-dev-shm-usage")
    chrome_options.add_argument("user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")

    driver = webdriver.Chrome(options=chrome_options)
    driver.set_page_load_timeout(120)
    
    all_weapon_data = []

    try:
        print(f"Navigating to {url}...")
        try:
            driver.get(url)
        except TimeoutException:
            print("Page load timed out. Stopping window and attempting to proceed...")
            driver.execute_script("window.stop();")
        
        # Wait for dynamic content
        print("Waiting for dynamic content to load (20s)...")
        time.sleep(20)
        
        # Find all scroller containers
        scrollers = driver.find_elements(By.CLASS_NAME, "ncgbt-table-scroller")
        print(f"Found {len(scrollers)} scroller containers.")
        
        for i, scroller in enumerate(scrollers):
            print(f"\n--- Processing Scroller {i+1} ---")
            
            # Find all rows in this scroller
            rows = scroller.find_elements(By.TAG_NAME, "tr")
            if not rows: continue
            
            # Identify columns based on headers if available
            headers = []
            try:
                header_row = rows[0]
                headers = [h.text.strip() for h in header_row.find_elements(By.TAG_NAME, "td")]
                if not headers:
                    headers = [h.text.strip() for h in header_row.find_elements(By.TAG_NAME, "th")]
            except: pass
            
            print(f"Detected Headers: {headers}")
            
            # Index mapping (heuristics)
            # We look for "Item", "Name", "Rank" or "Rarity"
            col_map = {"name": -1, "rank": -1, "icon": -1}
            
            for idx, h in enumerate(headers):
                h_low = h.lower()
                if "item" in h_low or "name" in h_low:
                    col_map["name"] = idx
                    col_map["icon"] = idx # Usually same column
                elif "rank" in h_low or "rarity" in h_low:
                    col_map["rank"] = idx
            
            # Default mapping if headers detection fails
            if col_map["name"] == -1: col_map["name"] = 0
            if col_map["rank"] == -1: col_map["rank"] = 1
            if col_map["icon"] == -1: col_map["icon"] = 0
            
            for row_idx, row in enumerate(rows[1:]): # Skip header row
                cells = row.find_elements(By.TAG_NAME, "td")
                if len(cells) <= max(col_map.values()): continue
                
                try:
                    # Extract Name and Icon from name column
                    name_cell = cells[col_map["name"]]
                    item_name = name_cell.text.split("\n")[0].strip()
                    
                    img = None
                    try:
                        img = name_cell.find_element(By.TAG_NAME, "img")
                    except:
                        # Try finding any img in the row
                        imgs = row.find_elements(By.TAG_NAME, "img")
                        if imgs: img = imgs[0]
                    
                    src = ""
                    if img:
                        src = img.get_attribute("src")
                    
                    # Extract Rank
                    item_rank = ""
                    if col_map["rank"] != -1:
                        item_rank = cells[col_map["rank"]].text.strip()
                    
                    if not item_name: continue
                    
                    # Clean for filename
                    def clean(s):
                        return re.sub(r'[^a-zA-Z0-9]', '_', s).strip('_')

                    clean_name = re.sub(r'_+', '_', clean(item_name))
                    clean_rank = re.sub(r'_+', '_', clean(item_rank))
                    
                    filename = f"Weapon_{clean_rank}_{clean_name}.png"
                    filepath = os.path.join(output_dir, filename)
                    
                    weapon_entry = {
                        "name": item_name,
                        "rank": item_rank,
                        "filename": filename,
                        "icon_url": src,
                        "scroller_index": i + 1
                    }
                    
                    all_weapon_data.append(weapon_entry)
                    
                    # Download icon
                    if src and src.startswith("http") and not os.path.exists(filepath):
                        try:
                            response = requests.get(src, timeout=10)
                            if response.status_code == 200:
                                with open(filepath, 'wb') as f:
                                    f.write(response.content)
                                print(f"  Downloaded: {filename}")
                        except: pass
                    elif not src:
                        print(f"  Warning: No icon found for {item_name}")

                except Exception as e:
                    print(f"  Error processing row {row_idx}: {e}")
                    continue
        
        # Save results
        with open(data_file, 'w') as f:
            json.dump(all_weapon_data, f, indent=4)
        print(f"\nSaved {len(all_weapon_data)} weapons to {data_file}")

    finally:
        driver.quit()

if __name__ == "__main__":
    scrape_weapons()
