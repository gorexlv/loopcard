import os
from pathlib import Path

from playwright.sync_api import sync_playwright


BASE = os.environ.get("AUDIT_BASE_URL", "http://127.0.0.1:3200").rstrip("/")
SHOTS = Path(__file__).resolve().parents[3] / "docs" / "visual-qa-2026-09-03"
SHOTS.mkdir(parents=True, exist_ok=True)


def load(page, route):
    page.goto(f"{BASE}{route}", wait_until="domcontentloaded", timeout=30_000)
    page.wait_for_load_state("load")
    page.wait_for_timeout(800)


with sync_playwright() as playwright:
    browser = playwright.chromium.launch(headless=True, channel="chrome")
    errors = []

    desktop = browser.new_context(viewport={"width": 1440, "height": 1000}, device_scale_factor=1)
    page = desktop.new_page()
    page.on("console", lambda msg: errors.append(f"{page.url}: {msg.text}") if msg.type == "error" else None)

    load(page, "/")
    page.screenshot(path=str(SHOTS / "01-desktop-home.png"))

    load(page, "/market")
    page.screenshot(path=str(SHOTS / "02-desktop-market.png"))
    page.get_by_role("button", name="Science").click()
    page.wait_for_timeout(150)
    assert page.locator(".deck-tile").count() > 0
    page.screenshot(path=str(SHOTS / "03-desktop-market-filtered.png"))

    load(page, "/tools")
    page.screenshot(path=str(SHOTS / "04-desktop-tools.png"))
    page.get_by_role("button", name="Example").click()
    assert page.locator(".tool-card-list article").count() == 3
    page.screenshot(path=str(SHOTS / "05-desktop-tools-example.png"))
    desktop.close()

    mobile = browser.new_context(viewport={"width": 390, "height": 844}, device_scale_factor=1)
    phone = mobile.new_page()
    phone.on("console", lambda msg: errors.append(f"{phone.url}: {msg.text}") if msg.type == "error" else None)

    load(phone, "/")
    phone.screenshot(path=str(SHOTS / "06-mobile-home.png"))
    phone.locator(".mobile-menu summary").click()
    phone.screenshot(path=str(SHOTS / "07-mobile-menu.png"))

    load(phone, "/market")
    filters = phone.locator(".filter-viewport")
    assert filters.count() == 1
    phone.screenshot(path=str(SHOTS / "08-mobile-market.png"))
    phone.get_by_role("button", name="Science").click()
    assert phone.locator(".deck-tile").count() > 0

    load(phone, "/tools")
    phone.get_by_role("button", name="Example").click()
    phone.screenshot(path=str(SHOTS / "09-mobile-tools-example.png"))

    load(phone, "/app/study/preview")
    phone.screenshot(path=str(SHOTS / "10-mobile-study-front.png"))
    phone.locator(".study-card").click()
    phone.get_by_role("tab", name="象征").click()
    assert phone.get_by_role("button", name="收藏").count() == 1
    phone.screenshot(path=str(SHOTS / "11-mobile-study-back.png"))
    mobile.close()
    browser.close()

    if errors:
        raise RuntimeError(f"Browser console errors: {errors}")

print(f"captured=11 output={SHOTS}")
