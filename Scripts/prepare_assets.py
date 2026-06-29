from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageOps


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "Assets" / "source.png"
ICON_SOURCE = ROOT / "Assets" / "icon-source.jpg"
ASSETS = ROOT / "Assets"


SPRITES = {
    "carrot_front.png": (78, 232, 872, 1370),
    "carrot_side.png": (952, 228, 1644, 1370),
    "carrot_back.png": (1724, 232, 2497, 1370),
}


def extract_character_alpha(image: Image.Image) -> Image.Image:
    """Keep the carrot character and remove the paper sticker/background."""
    rgba = image.convert("RGBA")
    rgb = image.convert("RGB")
    hsv = rgb.convert("HSV")
    width, height = rgba.size

    colorful = Image.new("L", (width, height), 0)
    dark = Image.new("L", (width, height), 0)
    colorful_pixels = colorful.load()
    dark_pixels = dark.load()
    rgb_pixels = rgb.load()
    hsv_pixels = hsv.load()

    for y in range(height):
        for x in range(width):
            r, g, b = rgb_pixels[x, y]
            _, saturation, value = hsv_pixels[x, y]
            luminance = int(0.299 * r + 0.587 * g + 0.114 * b)
            if saturation > 45 and value > 35:
                colorful_pixels[x, y] = 255
            if luminance < 82:
                dark_pixels[x, y] = 255

    near_color = colorful.filter(ImageFilter.MaxFilter(17))
    dark_near_color = ImageChops.multiply(dark, near_color)
    seed = ImageChops.lighter(colorful, dark_near_color)
    seed = keep_largest_alpha_component(seed)
    hard_alpha = fill_alpha_holes(seed)
    edge = hard_alpha.filter(ImageFilter.GaussianBlur(0.55))
    alpha = ImageChops.lighter(hard_alpha, edge)
    rgba.putalpha(alpha)

    clean_pixels = rgba.load()
    alpha_pixels = alpha.load()
    for y in range(height):
        for x in range(width):
            if alpha_pixels[x, y] == 0:
                clean_pixels[x, y] = (255, 255, 255, 0)
    return rgba


def keep_largest_alpha_component(alpha: Image.Image) -> Image.Image:
    width, height = alpha.size
    source = alpha.load()
    visited = bytearray(width * height)
    components: list[list[tuple[int, int]]] = []

    for y in range(height):
        for x in range(width):
            index = y * width + x
            if source[x, y] == 0 or visited[index]:
                continue
            queue = [(x, y)]
            visited[index] = 1
            component: list[tuple[int, int]] = []
            while queue:
                cx, cy = queue.pop()
                component.append((cx, cy))
                for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
                    if 0 <= nx < width and 0 <= ny < height:
                        next_index = ny * width + nx
                        if source[nx, ny] > 0 and not visited[next_index]:
                            visited[next_index] = 1
                            queue.append((nx, ny))
            components.append(component)

    out = Image.new("L", (width, height), 0)
    if not components:
        return out
    pixels = out.load()
    for x, y in max(components, key=len):
        pixels[x, y] = 255
    return out


def fill_alpha_holes(alpha: Image.Image) -> Image.Image:
    width, height = alpha.size
    source = alpha.load()
    outside = bytearray(width * height)
    queue: list[tuple[int, int]] = []

    for x in range(width):
        for y in (0, height - 1):
            if source[x, y] == 0:
                queue.append((x, y))
                outside[y * width + x] = 1
    for y in range(height):
        for x in (0, width - 1):
            if source[x, y] == 0:
                queue.append((x, y))
                outside[y * width + x] = 1

    while queue:
        x, y = queue.pop()
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < width and 0 <= ny < height:
                index = ny * width + nx
                if source[nx, ny] == 0 and not outside[index]:
                    outside[index] = 1
                    queue.append((nx, ny))

    out = Image.new("L", (width, height), 255)
    pixels = out.load()
    for y in range(height):
        for x in range(width):
            if outside[y * width + x]:
                pixels[x, y] = 0
    return out


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


def make_app_icon() -> None:
    iconset = ASSETS / "AppIcon.iconset"
    iconset.mkdir(exist_ok=True)
    source = Image.open(ICON_SOURCE).convert("RGB")
    side = min(source.size)
    left = (source.width - side) // 2
    top = (source.height - side) // 2
    square = source.crop((left, top, left + side, top + side))
    sizes = [
        ("icon_16x16.png", 16),
        ("icon_16x16@2x.png", 32),
        ("icon_32x32.png", 32),
        ("icon_32x32@2x.png", 64),
        ("icon_128x128.png", 128),
        ("icon_128x128@2x.png", 256),
        ("icon_256x256.png", 256),
        ("icon_256x256@2x.png", 512),
        ("icon_512x512.png", 512),
        ("icon_512x512@2x.png", 1024),
    ]
    for name, size in sizes:
        square.resize((size, size), Image.Resampling.LANCZOS).save(iconset / name)
    square.save(ASSETS / "AppIcon.icns", sizes=[(16, 16), (32, 32), (64, 64), (128, 128), (256, 256), (512, 512), (1024, 1024)])


def main() -> None:
    ASSETS.mkdir(exist_ok=True)
    source = Image.open(SOURCE).convert("RGBA")
    generated: dict[str, Image.Image] = {}

    for name, crop in SPRITES.items():
        sprite = source.crop(crop)
        sprite = extract_character_alpha(sprite)
        sprite = fit_canvas(sprite)
        sprite = make_shadow(sprite)
        sprite.save(ASSETS / name)
        generated[name] = sprite

    front = generated["carrot_front.png"]
    make_squish(front).save(ASSETS / "carrot_squish.png")

    side = generated["carrot_side.png"]
    ImageOps.mirror(side).save(ASSETS / "carrot_side_left.png")
    make_app_icon()


if __name__ == "__main__":
    main()
