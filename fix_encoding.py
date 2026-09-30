import os

replacements = {
    'Ã¢â€ â€™': '→',
    'Ã‚Â·': '·',
    'Ã¢â‚¬Â¦': '…',
    'Ã¢â‚¬Â¢': '•',
    'â‚¹': '₹',
    'Ã¢â‚¬â„¢': '’',
    'â€"': '—',
    'â€¢': '•',
    'Ã¢â€šÂ¹': '₹',
}

def fix_file(filepath):
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
            
        new_content = content
        for bad, good in replacements.items():
            new_content = new_content.replace(bad, good)
            
        if new_content != content:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(new_content)
            print(f"Fixed {filepath}")
    except Exception as e:
        pass

for root, _, files in os.walk(r'C:\Users\mkail\Desktop\mad assignment 4 and 5\TripGo\frontend\lib'):
    for file in files:
        if file.endswith('.dart'):
            fix_file(os.path.join(root, file))
