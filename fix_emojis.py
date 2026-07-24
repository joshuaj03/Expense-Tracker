import os

replacements = {
    'âŒ«': '⌫',
    'ðŸ”': '🔍',
    'ðŸ¤·': '🤷',
    'ðŸ“ ': '📄',
    'ðŸ ¦': '🏦',
    'ðŸ \\u2022': '🍽️',
    'ðŸ›’': '🛒',
    'ðŸš—': '🚗',
    'ðŸ› ï¸ ': '🛍️',
    'ðŸŽ¬': '🎬',
    'ðŸ’¡': '💡',
    'ðŸ ¥': '🏥',
    'ðŸ“š': '📚',
    'ðŸ  ': '🏠',
    'ðŸ›¡ï¸ ': '🛡️',
    'ðŸŽ ': '🎁',
    'ðŸ’µ': '💵',
    'ðŸ“±': '📱',
    'ðŸ‘›': '👛',
    'ðŸ’³': '💳',
    'âœˆï¸ ': '✈️'
}

def process_dir(directory):
    for root, _, files in os.walk(directory):
        for f in files:
            if f.endswith('.dart'):
                path = os.path.join(root, f)
                try:
                    with open(path, 'r', encoding='utf-8') as file:
                        content = file.read()
                    
                    changed = False
                    for bad, good in replacements.items():
                        if bad in content:
                            content = content.replace(bad, good)
                            changed = True
                            
                    if changed:
                        with open(path, 'w', encoding='utf-8') as file:
                            file.write(content)
                        print(f'Fixed emojis in {path}')
                except Exception as e:
                    print(f'Error reading {path}: {e}')

if __name__ == '__main__':
    process_dir('finara/lib')
