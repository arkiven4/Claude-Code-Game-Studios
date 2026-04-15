import os
import time
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

def explore_weapons_structure():
    url = "https://lineage2m.plaync.com/naeu/guidebook/view?title=Weapons"
    
    chrome_options = Options()
    chrome_options.add_argument("--headless")
    chrome_options.add_argument("--no-sandbox")
    chrome_options.add_argument("--disable-dev-shm-usage")
    chrome_options.add_argument("user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")

    driver = webdriver.Chrome(options=chrome_options)
    driver.set_page_load_timeout(60)
    
    try:
        print(f"Navigating to {url}...")
        driver.get(url)
        
        # Wait for dynamic content
        time.sleep(15)
        
        # Find all scroller containers
        scrollers = driver.find_elements(By.CLASS_NAME, "ncgbt-table-scroller")
        print(f"Found {len(scrollers)} scroller containers.")
        
        for i, scroller in enumerate(scrollers):
            print(f"\n--- Scroller {i+1} ---")
            
            # Get headers (usually the first row or inside <thead>)
            try:
                headers = scroller.find_elements(By.TAG_NAME, "th")
                if not headers:
                    # Try looking for the first <tr> and its <td> elements
                    first_row = scroller.find_element(By.TAG_NAME, "tr")
                    headers = first_row.find_elements(By.TAG_NAME, "td")
                
                header_texts = [h.text.strip() for h in headers if h.text.strip()]
                print(f"Headers: {header_texts}")
                
                # Print sample row
                rows = scroller.find_elements(By.TAG_NAME, "tr")
                if len(rows) > 1:
                    sample_row = rows[1] # Skip header row
                    cells = sample_row.find_elements(By.TAG_NAME, "td")
                    cell_texts = [c.text.strip() for c in cells]
                    print(f"Sample Row: {cell_texts}")
                    
                    # Check for images in sample row
                    imgs = sample_row.find_elements(By.TAG_NAME, "img")
                    if imgs:
                        print(f"Images in row: {[img.get_attribute('src')[:50] + '...' for img in imgs]}")
            except Exception as e:
                print(f"Error exploring scroller {i+1}: {e}")
                
    finally:
        driver.quit()

if __name__ == "__main__":
    explore_weapons_structure()
