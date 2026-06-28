from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageOps


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "Assets" / "source.png"
ASSETS = ROOT / "Assets"


SPRITES = {
    "carrot_front.png": (78, 232, 872, 1370),
    "carrot_side.png": (952, 228, 1644, 1370),
    "carrot_back.png": (1724, 232, 2497, 1370),
}


def flood_background_alpha(image: Image.Image, threshold: int = 38) -> Image.Image:
    """Remove only the connected off-white page background."""
    rgba = image.convert("RGBA")
    pixels = rgba.load()
    width, height = rgba.size
    visited = bytearray(width * height)
    queue: list[tuple[int, int]] = []

    def is_background(x: int, y: int) -> bool:
        r, g, b, _ = pixels[x, y]
        return r > 212 and g > 212 and b > 208 and abs(r - g) < threshold and abs(g - b) < threshold

    for x in range(width):
        for y in (0, height - 1):
            if is_background(x, y):
                queue.append((x, y))
                visited[y * width + x] = 1
    for y in range(height):
        for x in (0, width - 1):
            if is_background(x, y):
                queue.append((x, y))
                visited[y * width + x] = 1

    while queue:
        x, y = queue.pop()
        r, g, b, _ = pixels[x, y]
        distance = max(0, 255 - min(r, g, b))
        alpha = min(255, max(0, distance * 8))
        pixels[x, y] = (r, g, b, alpha)
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < width and 0 <= ny < height:
                index = ny * width + nx
                if not visited[index] and is_background(nx, ny):
                    visited[index] = 1
                    queue.append((nx, ny))

    alpha = rgba.getchannel("A").filter(ImageFilter.GaussianBlur(0.45))
    rgba.putalpha(alpha)
    return rgba


def trim_alpha(image: Image.Image, padding: int = 12) -> Image.Image:
    alpha = image.getchannel("A")
    bbox = alpha.getbbox()
    if bbox is None:
        return image
    left, top, right, bottom = bbox
    left = max(0, left - padding)
    top = max(0, top - padding)
    right = min(image.width, right + padding)
    bottom = min(image.height, bottom + padding)
    return image.crop((left, top, right, bottom))


def fit_canvas(image: Image.Image, size: int = 640) -> Image.Image:
    image = trim_alpha(image, padding=8)
    scale = min((size * 0.92) / image.width, (size * 0.92) / image.height)
    resized = image.resize((round(image.width * scale), round(image.height * scale)), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (size, size), (255, 255, 255, 0))
    x = (size - resized.width) // 2
    y = size - resized.height - 18
    canvas.alpha_composite(resized, (x, y))
    return canvas


def make_shadow(image: Image.Image) -> Image.Image:
    shadow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(shadow)
    draw.ellipse((130, 560, 510, 625), fill=(0, 0, 0, 42))
    shadow = shadow.filter(ImageFilter.GaussianBlur(14))
    out = Image.new("RGBA", image.size, (0, 0, 0, 0))
    out.alpha_composite(shadow)
    out.alpha_composite(image)
    return out


def make_squish(front: Image.Image) -> Image.Image:
    bbox = front.getchannel("A").getbbox()
    if bbox is None:
        return front
    body = front.crop(bbox)
    squished = body.resize((body.width + 46, body.height - 44), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", front.size, (255, 255, 255, 0))
    canvas.alpha_composite(squished, ((front.width - squished.width) // 2, front.height - squished.height - 10))
    return canvas


def main() -> None:
    ASSETS.mkdir(exist_ok=True)
    source = Image.open(SOURCE).convert("RGBA")
    generated: dict[str, Image.Image] = {}

    for name, crop in SPRITES.items():
        sprite = source.crop(crop)
        sprite = flood_background_alpha(sprite)
        sprite = fit_canvas(sprite)
        sprite = make_shadow(sprite)
        sprite.save(ASSETS / name)
        generated[name] = sprite

    front = generated["carrot_front.png"]
    make_squish(front).save(ASSETS / "carrot_squish.png")

    side = generated["carrot_side.png"]
    ImageOps.mirror(side).save(ASSETS / "carrot_side_left.png")


if __name__ == "__main__":
    main()
