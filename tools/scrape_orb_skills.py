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

def scrape_orb_skills():
    # Configuration
    page_title = "Orb"
    url = "https://lineage2m.plaync.com/naeu/guidebook/view?title=Orb%20Skills"
    output_dir = "/home/arkiven4/Documents/Project/Other/myvampire/assets/art/ui/skill_icons/"
    
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
        print(f"Created directory: {output_dir}")

    chrome_options = Options()
    chrome_options.add_argument("--headless")
    chrome_options.add_argument("--no-sandbox")
    chrome_options.add_argument("--disable-dev-shm-usage")
    chrome_options.add_argument("user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")

    driver = webdriver.Chrome(options=chrome_options)
    driver.set_page_load_timeout(120) # 2 minute timeout as requested
    
    try:
        print(f"\n--- Scraping {page_title} Skills from {url} ---")
        
        try:
            driver.get(url)
            print("Page navigation initiated.")
        except TimeoutException:
            print("Page load timed out after 2 minutes. Attempting to proceed...")
            driver.execute_script("window.stop();")
        
        # Extra wait for dynamic content
        print("Waiting 15 seconds for dynamic content to settle...")
        time.sleep(15)
        
        # Wait for the table containers
        wait = WebDriverWait(driver, 60) # 1 minute wait for elements
        try:
            # Find all scroller containers
            containers = wait.until(EC.presence_of_all_elements_located((By.CLASS_NAME, "ncgbt-table-scroller")))
            num_containers = len(containers)
            print(f"Found {num_containers} table scroller containers.")
            
            # Use the last one as requested
            container = containers[-1]
            print(f"Using container {num_containers} (the last one).")
            
            # Scroll it into view
            driver.execute_script("arguments[0].scrollIntoView();", container)
            time.sleep(2)
            
            # Find all images in this container
            images = container.find_elements(By.TAG_NAME, "img")
            print(f"Found {len(images)} images in the selected scroller.")
            
            # Fallback if specific container has no images but others might
            if len(images) == 0 and num_containers > 1:
                print("Selected container has no images. Checking all scroller containers...")
                for i, c in enumerate(containers):
                    imgs = c.find_elements(By.TAG_NAME, "img")
                    if len(imgs) > 0:
                        print(f"Found {len(imgs)} images in container {i+1}. Using these.")
                        images = imgs
                        break

            for img in images:
                src = img.get_attribute("src")
                alt = img.get_attribute("alt") or img.get_attribute("title")
                
                if not alt:
                    try:
                        parent_row = img.find_element(By.XPATH, "./ancestor::tr")
                        alt = parent_row.text.split('\n')[0].strip()
                    except:
                        continue
                
                # Parsing logic
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
                
                filename = f"{page_title}_{clean_type}_{clean_name}.png"
                filepath = os.path.join(output_dir, filename)
                
                if src and src.startswith("http"):
                    if not os.path.exists(filepath):
                        print(f"Downloading: {filename}")
                        try:
                            response = requests.get(src, stream=True, timeout=15)
                            if response.status_code == 200:
                                with open(filepath, 'wb') as f:
                                    for chunk in response.iter_content(1024):
                                        f.write(chunk)
                        except Exception as e:
                            print(f"Error downloading {filename}: {e}")
                    else:
                        print(f"Skipping (exists): {filename}")
                        
        except Exception as e:
            print(f"Error: {e}")
            # Save debug source if failed
            with open("orb_fail_debug.html", "w") as f:
                f.write(driver.page_source)

    finally:
        driver.quit()

if __name__ == "__main__":
    scrape_orb_skills()
