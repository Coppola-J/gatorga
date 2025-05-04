
import os
from PIL import Image

print("Current working directory:", os.getcwd())

# Expand tilde to full path
bmp_path = os.path.expanduser("scripts/attachments/title.bmp")
coe_path = os.path.expanduser("scripts/attachments/title.coe")

# Load the BMP and convert to 1-bit
img = Image.open(bmp_path).convert("1")
width, height = img.size
pixels = img.load()

with open(coe_path, "w") as f:
    f.write("memory_initialization_radix=2;\n")
    f.write("memory_initialization_vector=\n")

    for y in range(height):
        line = ''
        for x in range(width):
            line += '1' if pixels[x, y] == 0 else '0'  # black = 1, white = 0
        f.write(line + (",\n" if y < height - 1 else "\n"))

    f.write(";")
