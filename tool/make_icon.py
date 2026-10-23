import os
from PIL import Image, ImageDraw

RED = (225, 29, 46, 255)
BG = (10, 10, 11, 255)
CLEAR = (0, 0, 0, 0)
SIZE = 1024
GRID = 9
FIG = 0.6


def figure(img, hole_color):
    d = ImageDraw.Draw(img)
    u = SIZE * FIG / GRID
    off = (SIZE - SIZE * FIG) / 2

    def rect(x0, y0, x1, y1):
        d.rectangle(
            [off + x0 * u, off + y0 * u, off + x1 * u, off + y1 * u],
            fill=RED,
        )

    # Chakana: cruz andina escalonada
    rect(3, 0, 6, 9)
    rect(0, 3, 9, 6)
    rect(2, 2, 7, 7)

    # Triángulo de play recortado en el centro
    tri = [(3.7, 3.3), (3.7, 5.7), (5.6, 4.5)]
    d.polygon([(off + x * u, off + y * u) for x, y in tri], fill=hole_color)


os.makedirs("assets/icon", exist_ok=True)

full = Image.new("RGBA", (SIZE, SIZE), BG)
figure(full, BG)
full.save("assets/icon/icon.png")

fg = Image.new("RGBA", (SIZE, SIZE), CLEAR)
figure(fg, CLEAR)
fg.save("assets/icon/fg.png")

print("Iconos creados en assets/icon")
