import os
import requests
import time
import re
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException

def scrape_all_skills():
    # Configuration
    skill_pages = [
        {"title": "Bow", "url": "https://lineage2m.plaync.com/naeu/guidebook/view?title=Bow%20Skills"},
        {"title": "Orb", "url": "https://lineage2m.plaync.com/naeu/guidebook/view?title=Orb%20Skills"},
        {"title": "Sword", "url": "https://lineage2m.plaync.com/naeu/guidebook/view?title=Sword%20Skills"},
        {"title": "Staff", "url": "https://lineage2m.plaync.com/naeu/guidebook/view?title=Staff%20Skills"},
        {"title": "Dagger", "url": "https://lineage2m.plaync.com/naeu/guidebook/view?title=Dagger%20Skills"},
        {"title": "Common", "url": "https://lineage2m.plaync.com/naeu/guidebook/view?title=Common%20Inheritor%20Skills"}
    ]
    
    output_dir = "/home/arkiven4/Documents/Project/Other/myvampire/assets/art/ui/skill_icons/"
    
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
        print(f"Created directory: {output_dir}")

    chrome_options = Options()
    chrome_options.add_argument("--headless")
    chrome_options.add_argument("--no-sandbox")
    chrome_options.add_argument("--disable-dev-shm-usage")
    chrome_options.add_argument("user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36")

    driver = webdriver.Chrome(options=chrome_options)
    driver.set_page_load_timeout(45) # Increased timeout
    
    try:
        for page in skill_pages:
            page_title = page["title"]
            url = page["url"]
            print(f"\n--- Scraping {page_title} Skills from {url} ---")
            
            try:
                driver.get(url)
                # Extra wait for dynamic content
                time.sleep(3) 
            except TimeoutException:
                print(f"Page load timed out for {page_title}, attempting to proceed with whatever loaded...")
                driver.execute_script("window.stop();")
            
            # Wait for the table within 'ncgbt-table-scroller' to be present
            wait = WebDriverWait(driver, 20)
            
            try:
                # First wait for the container
                container = wait.until(EC.presence_of_element_located((By.CLASS_NAME, "ncgbt-table-scroller")))
                print(f"Found table scroller container for {page_title}.")
                
                # Now find all image elements within this container
                images = container.find_elements(By.TAG_NAME, "img")
                print(f"Found {len(images)} images in the scroller.")
                
                # If no images, try to wait a bit more or find table directly
                if len(images) == 0:
                    print("No images found yet, waiting 5 more seconds...")
                    time.sleep(5)
                    images = container.find_elements(By.TAG_NAME, "img")
                    print(f"Retry: Found {len(images)} images.")

                for img in images:
                    src = img.get_attribute("src")
                    alt = img.get_attribute("alt") or img.get_attribute("title")
                    
                    if not alt:
                        try:
                            parent_row = img.find_element(By.XPATH, "./ancestor::tr")
                            alt = parent_row.text.split('\n')[0].strip()
                        except:
                            continue
                    
                    skill_name = "Unknown"
                    skill_type = "Skill"
                    
                    if "Active" in alt:
                        skill_type = "Active"
                        skill_name = alt.split("Active")[0].strip()
                    elif "Passive" in alt:
                        skill_type = "Passive"
                        skill_name = alt.split("Passive")[0].strip()
                    else:
                        skill_name = alt.split("-")[0].strip()

                    def clean_for_filename(s):
                        s = re.sub(r'[^a-zA-Z0-9]', '_', s)
                        s = re.sub(r'_+', '_', s)
                        return s.strip('_')

                    clean_name = clean_for_filename(skill_name)
                    clean_type = clean_for_filename(skill_type)
                    
                    # Construct filename: {PageTitle}_{SkillType}_{SkillName}.png
                    filename = f"{page_title}_{clean_type}_{clean_name}.png"
                    filepath = os.path.join(output_dir, filename)
                    
                    # Download the image
                    if src and src.startswith("http"):
                        # Only download if it doesn't exist or is small
                        if not os.path.exists(filepath):
                            print(f"Downloading: {filename}")
                            try:
                                response = requests.get(src, stream=True, timeout=10)
                                if response.status_code == 200:
                                    with open(filepath, 'wb') as f:
                                        for chunk in response.iter_content(1024):
                                            f.write(chunk)
                                else:
                                    print(f"Failed to download {src}: Status {response.status_code}")
                            except Exception as e:
                                print(f"Error downloading {src}: {e}")
                    else:
                        print(f"Invalid or missing source for {alt}: {src}")
                        
            except Exception as e:
                print(f"Error finding table content for {page_title}: {e}")
                
    finally:
        driver.quit()

if __name__ == "__main__":
    scrape_all_skills()
