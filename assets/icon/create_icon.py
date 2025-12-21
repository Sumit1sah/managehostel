from PIL import Image, ImageDraw, ImageFont

# Create main app icon (512x512)
img = Image.new('RGB', (512, 512), color='#2196F3')
draw = ImageDraw.Draw(img)

# Draw building shape
draw.rectangle([100, 150, 412, 450], fill='#FFFFFF', outline='#1976D2', width=8)

# Draw windows (3x4 grid)
for row in range(4):
    for col in range(3):
        x = 140 + col * 90
        y = 190 + row * 60
        draw.rectangle([x, y, x + 50, y + 40], fill='#64B5F6', outline='#1976D2', width=3)

# Draw door
draw.rectangle([220, 370, 292, 450], fill='#8B4513', outline='#654321', width=4)

# Draw roof
draw.polygon([(80, 150), (256, 80), (432, 150)], fill='#E91E63', outline='#C2185B')

img.save('assets/icon/app_icon.png')

# Create foreground for adaptive icon
img_fg = Image.new('RGBA', (512, 512), color=(0, 0, 0, 0))
draw_fg = ImageDraw.Draw(img_fg)

# Draw building
draw_fg.rectangle([100, 150, 412, 450], fill='#FFFFFF', outline='#1976D2', width=8)

# Draw windows
for row in range(4):
    for col in range(3):
        x = 140 + col * 90
        y = 190 + row * 60
        draw_fg.rectangle([x, y, x + 50, y + 40], fill='#64B5F6', outline='#1976D2', width=3)

# Draw door
draw_fg.rectangle([220, 370, 292, 450], fill='#8B4513', outline='#654321', width=4)

# Draw roof
draw_fg.polygon([(80, 150), (256, 80), (432, 150)], fill='#E91E63', outline='#C2185B')

img_fg.save('assets/icon/app_icon_foreground.png')

print("App icons created successfully!")
