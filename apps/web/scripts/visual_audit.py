import os
from pathlib import Path

from playwright.sync_api import sync_playwright


BASE = os.environ.get("AUDIT_BASE_URL", "https://loopcard.dev").rstrip("/")
SHOTS = Path(__file__).resolve().parents[3] / "docs" / "visual-audit-2026-09-02"
SHOTS.mkdir(parents=True, exist_ok=True)


def load(page, route):
    page.goto(f"{BASE}{route}", wait_until="networkidle")
    page.wait_for_timeout(800)


with sync_playwright() as playwright:
    browser = playwright.chromium.launch(headless=True, channel="chrome")
    errors = []

    desktop = browser.new_context(viewport={"width": 1440, "height": 1000}, device_scale_factor=1)
    page = desktop.new_page()
    page.on("console", lambda msg: errors.append(msg.text) if msg.type == "error" else None)

    load(page, "/")
    page.screenshot(path=str(SHOTS / "01-desktop-home-hero.png"))
    page.locator(".deck-grid").first.scroll_into_view_if_needed()
    page.wait_for_timeout(300)
    page.screenshot(path=str(SHOTS / "02-desktop-home-decks.png"))
    page.locator(".download-cta").scroll_into_view_if_needed()
    page.wait_for_timeout(300)
    page.screenshot(path=str(SHOTS / "03-desktop-home-download.png"))

    load(page, "/market")
    page.screenshot(path=str(SHOTS / "04-desktop-market.png"))

    load(page, "/tools")
    page.screenshot(path=str(SHOTS / "05-desktop-tools.png"))
    desktop.close()

    mobile = browser.new_context(viewport={"width": 390, "height": 844}, device_scale_factor=1)
    phone = mobile.new_page()
    phone.on("console", lambda msg: errors.append(msg.text) if msg.type == "error" else None)

    load(phone, "/")
    phone.screenshot(path=str(SHOTS / "06-mobile-home.png"))

    load(phone, "/market")
    phone.screenshot(path=str(SHOTS / "07-mobile-market.png"))

    load(phone, "/app")
    phone.screenshot(path=str(SHOTS / "08-mobile-study-front.png"))
    phone.locator(".study-card").click()
    phone.wait_for_timeout(250)
    phone.screenshot(path=str(SHOTS / "09-mobile-study-back.png"))
    mobile.close()
    browser.close()

    if errors:
        raise RuntimeError(f"Browser console errors: {errors}")

print(f"captured=9 output={SHOTS}")
