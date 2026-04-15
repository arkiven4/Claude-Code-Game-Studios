import os
import requests
import time
import re
import json
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException

def scrape_all_skills():
    skill_pages = [
        {"title": "Bow", "url": "https://lineage2m.plaync.com/naeu/guidebook/view?title=Bow%20Skills"},
        {"title": "Orb", "url": "https://lineage2m.plaync.com/naeu/guidebook/view?title=Orb%20Skills"},
        {"title": "Sword", "url": "https://lineage2m.plaync.com/naeu/guidebook/view?title=Sword%20Skills"},
        {"title": "Staff", "url": "https://lineage2m.plaync.com/naeu/guidebook/view?title=Staff%20Skills"},
        {"title": "Dagger", "url": "https://lineage2m.plaync.com/naeu/guidebook/view?title=Dagger%20Skills"},
        {"title": "Common", "url": "https://lineage2m.plaync.com/naeu/guidebook/view?title=Common%20Inheritor%20Skills"}
    ]
    
    data_file = "/home/arkiven4/Documents/Project/Other/myvampire/assets/data/skills/lineage2m_data.json"
    os.makedirs(os.path.dirname(data_file), exist_ok=True)

    chrome_options = Options()
    chrome_options.add_argument("--headless")
    chrome_options.add_argument("--no-sandbox")
    chrome_options.add_argument("--disable-dev-shm-usage")
    chrome_options.add_argument("user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")

    driver = webdriver.Chrome(options=chrome_options)
    driver.set_page_load_timeout(60)
    
    all_skill_data = []

    try:
        for page in skill_pages:
            page_title = page["title"]
            url = page["url"]
            print(f"\n--- Scraping {page_title} Skills ---")
            
            try:
                driver.get(url)
            except TimeoutException:
                driver.execute_script("window.stop();")
            
            wait = WebDriverWait(driver, 30)
            try:
                scrollers = wait.until(EC.presence_of_all_elements_located((By.CLASS_NAME, "ncgbt-table-scroller")))
                container = scrollers[-1]
                
                rows = container.find_elements(By.TAG_NAME, "tr")
                print(f"Processing {len(rows)} rows...")
                
                for row in rows:
                    cells = row.find_elements(By.TAG_NAME, "td")
                    if len(cells) < 2: continue
                    
                    try:
                        # Extract Icon from any img in the row
                        imgs = row.find_elements(By.TAG_NAME, "img")
                        if not imgs: continue
                        img = imgs[0]
                        src = img.get_attribute("src")
                        
                        # Skill Name is usually text in the first or second cell
                        # Let's try to find the one that isn't just "Active" or "Passive"
                        skill_name = ""
                        skill_type = "Skill"
                        
                        for i, cell in enumerate(cells[:2]):
                            text = cell.text.strip()
                            if not text: continue
                            lines = [l.strip() for l in text.split("\n") if l.strip()]
                            if not lines: continue
                            
                            if lines[0] in ["Active", "Passive"]:
                                skill_type = lines[0]
                                if len(lines) > 1: skill_name = lines[1]
                            else:
                                if not skill_name: skill_name = lines[0]
                                if len(lines) > 1 and lines[1] in ["Active", "Passive"]:
                                    skill_type = lines[1]

                        # Description is the last cell
                        description = cells[-1].text.strip()
                        
                        if not skill_name:
                            # Final fallback: use alt text
                            alt = img.get_attribute("alt") or img.get_attribute("title") or ""
                            if alt:
                                skill_name = alt.split("Active")[0].split("Passive")[0].strip()

                        if not skill_name: continue

                        def clean(s):
                            return re.sub(r'[^a-zA-Z0-9]', '_', s).strip('_')

                        clean_name = re.sub(r'_+', '_', clean(skill_name))
                        clean_type = re.sub(r'_+', '_', clean(skill_type))
                        filename = f"{page_title}_{clean_type}_{clean_name}.png"
                        
                        all_skill_data.append({
                            "page": page_title,
                            "name": skill_name,
                            "type": skill_type,
                            "description": description,
                            "filename": filename,
                            "icon_url": src
                        })

                    except Exception:
                        continue
                        
            except Exception as e:
                print(f"Error on {page_title}: {e}")
                
        with open(data_file, 'w') as f:
            json.dump(all_skill_data, f, indent=4)
        print(f"\nSaved {len(all_skill_data)} skills to {data_file}")

    finally:
        driver.quit()

if __name__ == "__main__":
    scrape_all_skills()
