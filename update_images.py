import re
import os

file_path = r'c:\Users\ganes\OneDrive\Desktop\pro\win\lib\screens\categories_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

categories = {
    'Drilling Machines': 'assets/images/drilling_machine.png',
    'Concrete Mixers': 'assets/images/concrete_mixer.png',
    'Welding Machines': 'assets/images/welding_machine.png',
    'Generators': 'assets/images/generator.png',
    'Ladders': 'assets/images/ladder.png',
    'Cutting Tools': 'assets/images/cutting_tool.png',
    'Safety Equipment': 'assets/images/cutting_tool.png',
}

count = 0

def replace_tool_image(match):
    global count
    cat_prefix = match.group(1)
    category = match.group(2)
    old_img = match.group(3)
    suffix = match.group(4)
    if category in categories:
        count += 1
        return cat_prefix + f"'{categories[category]}'" + suffix
    return match.group(0)

# The pattern needs to match: 'category': '...', ... 'image': '...',
pattern = r"('category':\s*'([^']+)'.*?'image':\s*)('[^']+')(\s*,)"
new_content = re.sub(pattern, replace_tool_image, content, flags=re.DOTALL)

print(f"Replaced {count} image URLs in categories_screen.dart")
with open(file_path, 'w', encoding='utf-8') as f:
    f.write(new_content)


file_path2 = r'c:\Users\ganes\OneDrive\Desktop\pro\win\lib\dummy_data\dummy_data.dart'
with open(file_path2, 'r', encoding='utf-8') as f:
    content2 = f.read()

count2 = 0
def replace_category_image(match):
    global count2
    prefix = match.group(1)
    cat_name = match.group(2)
    old_img = match.group(3)
    suffix = match.group(4)
    if cat_name in categories:
        count2 += 1
        return prefix + f"'{categories[cat_name]}'" + suffix
    return match.group(0)

pattern1 = r"(name:\s*'([^']+)'.*?imageUrl:\s*)('[^']+')(\s*,)"
content2 = re.sub(pattern1, replace_category_image, content2, flags=re.DOTALL)

count3 = 0
def replace_tool_model_image(match):
    global count3
    prefix = match.group(1)
    category = match.group(2)
    old_img = match.group(3)
    suffix = match.group(4)
    if category in categories:
        count3 += 1
        return prefix + f"'{categories[category]}'" + suffix
    return match.group(0)

pattern2 = r"(category:\s*'([^']+)'.*?imageUrl:\s*)('[^']+')(\s*,)"
content2 = re.sub(pattern2, replace_tool_model_image, content2, flags=re.DOTALL)

print(f"Replaced {count2} category images and {count3} tool images in dummy_data.dart")
with open(file_path2, 'w', encoding='utf-8') as f:
    f.write(content2)

