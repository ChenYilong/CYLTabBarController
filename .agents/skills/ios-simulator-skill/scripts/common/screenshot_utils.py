#!/usr/bin/env python3
"""
Screenshot utilities with dual-mode support.

Provides unified screenshot handling with:
- File-based mode: Persistent artifacts for test documentation
- Inline base64 mode: Vision-based automation for agent analysis
- Size presets: Token optimization (full/half/quarter/thumb)
- Semantic naming: {appName}_{screenName}_{state}_{timestamp}.png

Supports resize operations via PIL (optional dependency).

Used by:
- test_recorder.py - Step-based screenshot recording
- app_state_capture.py - State snapshot captures
"""

import base64
import os
import subprocess
import sys
from datetime import datetime
from pathlib import Path
from typing import Any

# Try to import PIL for resizing, but make it optional
try:
    from PIL import Image

    HAS_PIL = True
except ImportError:
    HAS_PIL = False


def generate_screenshot_name(
    app_name: str | None = None,
    screen_name: str | None = None,
    state: str | None = None,
    timestamp: str | None = None,
    extension: str = "png",
) -> str:
    """Generate semantic screenshot filename.

    Format: {appName}_{screenName}_{state}_{timestamp}.{ext}
    Falls back to: screenshot_{timestamp}.{ext}

    Args:
        app_name: Application name (e.g., 'MyApp')
        screen_name: Screen name (e.g., 'Login')
        state: State description (e.g., 'Empty', 'Filled', 'Error')
        timestamp: ISO timestamp (uses current time if None)
        extension: File extension (default: 'png')

    Returns:
        Semantic filename ready for safe file creation

    Example:
        name = generate_screenshot_name('MyApp', 'Login', 'Empty')
        # Returns: 'MyApp_Login_Empty_20251028-143052.png'

        name = generate_screenshot_name()
        # Returns: 'screenshot_20251028-143052.png'
    """
    if timestamp is None:
        timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")

    # Build semantic name
    if app_name or screen_name or state:
        parts = [app_name, screen_name, state]
        parts = [p for p in parts if p]  # Filter None/empty
        name = "_".join(parts) + f"_{timestamp}"
    else:
        name = f"screenshot_{timestamp}"

    return f"{name}.{extension}"


def get_size_preset(size: str = "half") -> tuple[float, float]:
    """Get scale factors for size preset.

    Args:
        size: 'full', 'half', 'quarter', 'thumb'

    Returns:
        Tuple of (scale_x, scale_y) for resizing

    Example:
        scale_x, scale_y = get_size_preset('half')
        # Returns: (0.5, 0.5)
    """
    presets = {
        "full": (1.0, 1.0),
        "half": (0.5, 0.5),
        "quarter": (0.25, 0.25),
        "thumb": (0.1, 0.1),
    }
    return presets.get(size, (0.5, 0.5))


def resize_screenshot(
    input_path: str,
    output_path: str | None = None,
    size: str = "half",
    quality: int = 85,
) -> tuple[str, int, int]:
    """Resize screenshot for token optimization.

    Requires PIL (Pillow). Falls back gracefully without it.

    Args:
        input_path: Path to original screenshot
        output_path: Output path (uses input_path if None)
        size: 'full', 'half', 'quarter', 'thumb'
        quality: JPEG quality (1-100, default: 85)

    Returns:
        Tuple of (output_path, width, height) of resized image

    Raises:
        FileNotFoundError: If input file doesn't exist
        ValueError: If PIL not installed and size != 'full'

    Example:
        output, w, h = resize_screenshot(
            'screenshot.png',
            'screenshot_half.png',
            'half'
        )
        print(f"Resized to {w}x{h}")
    """
    input_file = Path(input_path)
    if not input_file.exists():
        raise FileNotFoundError(f"Screenshot not found: {input_path}")

    # If full size, just copy
    if size == "full":
        if output_path:
            import shutil

            shutil.copy(input_path, output_path)
            output_file = Path(output_path)
        else:
            output_file = input_file

        # Get original dimensions
        if HAS_PIL:
            img = Image.open(str(output_file))
            return (str(output_file), img.width, img.height)
        return (str(output_file), 0, 0)  # Dimensions unknown without PIL

    # Need PIL to resize
    if not HAS_PIL:
        raise ValueError(
            f"Size preset '{size}' requires PIL (Pillow). " "Install with: pip3 install pillow"
        )

    # Open original image
    img = Image.open(str(input_file))
    orig_w, orig_h = img.size

    # Calculate new size
    scale_x, scale_y = get_size_preset(size)
    new_w = int(orig_w * scale_x)
    new_h = int(orig_h * scale_y)

    # Resize with high-quality resampling
    resized = img.resize((new_w, new_h), Image.Resampling.LANCZOS)

    # Determine output path
    if output_path is None:
        # Insert size marker before extension
        stem = input_file.stem
        suffix = input_file.suffix
        output_path = str(input_file.parent / f"{stem}_{size}{suffix}")

    # Save resized image
    resized.save(output_path, quality=quality, optimize=True)

    return (output_path, new_w, new_h)


def capture_screenshot(
    udid: str,
    output_path: str | None = None,
    size: str = "half",
    inline: bool = False,
    app_name: str | None = None,
    screen_name: str | None = None,
    state: str | None = None,
) -> dict[str, Any]:
    """Capture screenshot with flexible output modes.

    Supports both file-based (persistent artifacts) and inline base64 modes
    (for vision-based automation).

    Args:
        udid: Device UDID
        output_path: File path for file mode (generates semantic name if None)
        size: 'full', 'half', 'quarter', 'thumb' (default: 'half')
        inline: If True, returns base64 data instead of saving to file
        app_name: App name for semantic naming
        screen_name: Screen name for semantic naming
        state: State description for semantic naming

    Returns:
        Dict with mode-specific fields:

        File mode:
        {
            'mode': 'file',
            'file_path': str,
            'size_bytes': int,
            'width': int,
            'height': int,
            'size_preset': str
        }

        Inline mode:
        {
            'mode': 'inline',
            'base64_data': str,
            'mime_type': 'image/png',
            'width': int,
            'height': int,
            'size_preset': str
        }

    Example:
        # File mode
        result = capture_screenshot('ABC123', app_name='MyApp')
        print(f"Saved to: {result['file_path']}")

        # Inline mode
        result = capture_screenshot('ABC123', inline=True, size='half')
        print(f"Screenshot: {result['width']}x{result['height']}")
        print(f"Base64: {result['base64_data'][:50]}...")
    """
    try:
        # Capture raw screenshot to temp file
        temp_path = "/tmp/ios_simulator_screenshot.png"
        cmd = ["xcrun", "simctl", "io", udid, "screenshot", temp_path]

        subprocess.run(cmd, capture_output=True, text=True, check=True)

        if inline:
            # Inline mode: resize and convert to base64
            # Resize if needed
            if size != "full" and HAS_PIL:
                resized_path, width, height = resize_screenshot(temp_path, size=size)
            else:
                resized_path = temp_path
                # Get dimensions via PIL if available
                if HAS_PIL:
                    img = Image.open(resized_path)
                    width, height = img.size
                else:
                    width, height = 390, 844  # Fallback to common device size

            # Read and encode as base64
            with open(resized_path, "rb") as f:
                base64_data = base64.b64encode(f.read()).decode("utf-8")

            # Clean up temp files
            Path(temp_path).unlink(missing_ok=True)
            if resized_path != temp_path:
                Path(resized_path).unlink(missing_ok=True)

            return {
                "mode": "inline",
                "base64_data": base64_data,
                "mime_type": "image/png",
                "width": width,
                "height": height,
                "size_preset": size,
            }

        # File mode: save to output path with semantic naming
        if output_path is None:
            output_path = generate_screenshot_name(app_name, screen_name, state)

        # Resize if needed
        if size != "full" and HAS_PIL:
            final_path, width, height = resize_screenshot(temp_path, output_path, size)
        else:
            # Just move temp to output
            import shutil

            shutil.move(temp_path, output_path)
            final_path = output_path

            # Get dimensions via PIL if available
            if HAS_PIL:
                img = Image.open(final_path)
                width, height = img.size
            else:
                width, height = 390, 844  # Fallback

        # Get file size
        size_bytes = Path(final_path).stat().st_size

        return {
            "mode": "file",
            "file_path": final_path,
            "size_bytes": size_bytes,
            "width": width,
            "height": height,
            "size_preset": size,
        }

    except subprocess.CalledProcessError as e:
        raise RuntimeError(f"Failed to capture screenshot: {e.stderr}") from e
    except Exception as e:
        raise RuntimeError(f"Screenshot capture error: {e!s}") from e


def format_screenshot_result(result: dict[str, Any]) -> str:
    """Format screenshot result for human-readable output.

    Args:
        result: Result dictionary from capture_screenshot()

    Returns:
        Formatted string for printing

    Example:
        result = capture_screenshot('ABC123', inline=True)
        print(format_screenshot_result(result))
    """
    if result["mode"] == "file":
        return (
            f"Screenshot: {result['file_path']}\n"
            f"Dimensions: {result['width']}x{result['height']}\n"
            f"Size: {result['size_bytes']} bytes"
        )
    return (
        f"Screenshot (inline): {result['width']}x{result['height']}\n"
        f"Base64 length: {len(result['base64_data'])} chars"
    )
