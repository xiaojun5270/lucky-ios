#!/usr/bin/env python3
"""Build the iOS icon assets from Icon/LuckySource.png."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageEnhance, ImageFilter


SIZE = 1024
MARK_SIZE = 820


def fitted_mark(source: Image.Image) -> Image.Image:
    mark = source.convert("RGBA").resize((MARK_SIZE, MARK_SIZE), Image.Resampling.LANCZOS)
    # A light unsharp pass offsets some softness from the small supplied raster without changing
    # the logo geometry or colours.
    return mark.filter(ImageFilter.UnsharpMask(radius=1.2, percent=70, threshold=2))


def composite(mark: Image.Image, background: tuple[int, int, int]) -> Image.Image:
    canvas = Image.new("RGB", (SIZE, SIZE), background)
    origin = ((SIZE - mark.width) // 2, (SIZE - mark.height) // 2)
    canvas.paste(mark.convert("RGB"), origin, mark.getchannel("A"))
    return canvas


def tinted(mark: Image.Image) -> Image.Image:
    alpha = mark.getchannel("A")
    luminance = ImageEnhance.Contrast(mark.convert("L")).enhance(1.15)
    result = Image.new("RGBA", mark.size, (0, 0, 0, 0))
    white = Image.merge("RGBA", (luminance, luminance, luminance, alpha))
    result.alpha_composite(white)
    canvas = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    canvas.alpha_composite(result, ((SIZE - mark.width) // 2, (SIZE - mark.height) // 2))
    return canvas


def main() -> None:
    project = Path(__file__).resolve().parent.parent
    source_path = project / "Icon" / "LuckySource.png"
    appiconset = project / "LuckyGlass" / "Assets.xcassets" / "AppIcon.appiconset"
    imageset = project / "LuckyGlass" / "Assets.xcassets" / "LuckyMark.imageset"
    appiconset.mkdir(parents=True, exist_ok=True)
    imageset.mkdir(parents=True, exist_ok=True)

    source = Image.open(source_path)
    mark = fitted_mark(source)
    composite(mark, (246, 248, 250)).save(appiconset / "AppIcon-Light.png", "PNG")
    composite(mark, (11, 14, 19)).save(appiconset / "AppIcon-Dark.png", "PNG")
    tinted(mark).save(appiconset / "AppIcon-Tinted.png", "PNG")

    in_app = source.convert("RGBA").resize((SIZE, SIZE), Image.Resampling.LANCZOS)
    in_app.filter(ImageFilter.UnsharpMask(radius=1.2, percent=70, threshold=2)).save(
        imageset / "LuckyMark.png", "PNG"
    )

    preview = Image.new("RGB", (SIZE * 2, SIZE), (32, 35, 41))
    preview.paste(composite(mark, (246, 248, 250)), (0, 0))
    preview.paste(composite(mark, (11, 14, 19)), (SIZE, 0))
    preview.resize((512, 256), Image.Resampling.LANCZOS).save(project / "Icon" / "preview.png")


if __name__ == "__main__":
    main()
