import os
import re

def validate_tres_files():
    data_dir = "assets/data"
    tres_files = []
    for root, _, files in os.walk(data_dir):
        for f in files:
            if f.endswith(".tres"):
                tres_files.append(os.path.join(root, f))
    
    print(f"Validating {len(tres_files)} .tres files...")
    
    errors = []
    warnings = []
    
    for tres_path in tres_files:
        with open(tres_path, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
            
            # 1. Check for missing ext_resource paths
            # Pattern: [ext_resource type="..." path="res://..." id="..."]
            ext_resources = re.findall(r'\[ext_resource .* path="res://([^"]+)"', content)
            for path in ext_resources:
                if not os.path.exists(path):
                    errors.append(f"Missing resource in {tres_path}: {path}")
            
            # 2. Check for potential syntax errors in uid (if we manually generated them)
            # (Basic check: UIDs should be unique but we'll just check for placeholder chars)
            if "{uid}" in content:
                errors.append(f"Unfilled UID template in {tres_path}")
                
    # Print results
    if errors:
        print(f"\nFound {len(errors)} errors:")
        for err in errors[:50]: # Limit output
            print(f"  [ERROR] {err}")
        if len(errors) > 50:
            print(f"  ... and {len(errors) - 50} more errors.")
    else:
        print("\nNo critical resource path errors found.")
        
    if warnings:
        print(f"\nFound {len(warnings)} warnings:")
        for warn in warnings[:20]:
            print(f"  [WARN] {warn}")
            
    return len(errors) == 0

if __name__ == "__main__":
    success = validate_tres_files()
    if not success:
        exit(1)
