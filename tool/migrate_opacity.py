
import os
import re

def migrate_opacity(directory):
    # Regex to capture .withOpacity(value)
    # It catches simple balanced parentheses for the argument
    # Limitation: might fail on very complex nested parens, but unlikely for opacity values
    pattern = re.compile(r'\.withOpacity\((.*?)\)')
    
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith(".dart"):
                path = os.path.join(root, file)
                with open(path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                new_content = pattern.sub(r'.withValues(alpha: \1)', content)
                
                if new_content != content:
                    print(f"Updating {path}")
                    with open(path, 'w', encoding='utf-8') as f:
                        f.write(new_content)

if __name__ == "__main__":
    migrate_opacity(r"d:\scroll_game_app\lib")
