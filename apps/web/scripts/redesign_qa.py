import os
from pathlib import Path

from playwright.sync_api import sync_playwright


BASE = os.environ.get("AUDIT_BASE_URL", "http://localhost:3000").rstrip("/")
SHOTS = Path(__file__).resolve().parents[3] / "docs" / "visual-qa-2026-09-03-expansion"
SHOTS.mkdir(parents=True, exist_ok=True)


def load(page, route):
    page.goto(f"{BASE}{route}", wait_until="domcontentloaded", timeout=30_000)
    page.wait_for_load_state("load")
    page.wait_for_timeout(650)


with sync_playwright() as playwright:
    browser = playwright.chromium.launch(headless=True, channel="chrome")
    errors = []

    desktop = browser.new_context(viewport={"width": 1440, "height": 1000}, device_scale_factor=1, permissions=["clipboard-read", "clipboard-write"])
    page = desktop.new_page()
    page.on("console", lambda msg: errors.append(f"{page.url}: {msg.text}") if msg.type == "error" else None)

    load(page, "/market")
    assert page.locator(".deck-tile").count() == 12
    page.screenshot(path=str(SHOTS / "01-market-desktop.png"))
    page.locator(".market-results-head").scroll_into_view_if_needed()
    page.wait_for_timeout(250)
    page.evaluate("window.scrollBy(0, 480)")
    page.screenshot(path=str(SHOTS / "01b-market-deck-grid.png"))
    page.get_by_role("button", name="Science").click()
    assert page.locator(".deck-tile").count() >= 6
    page.screenshot(path=str(SHOTS / "02-market-science-filter.png"))
    page.locator(".market-search input").fill("astronomy")
    assert page.locator(".deck-tile").count() == 1

    load(page, "/market/chemistry-formulas")
    page.screenshot(path=str(SHOTS / "03-deck-front-back.png"))

    load(page, "/tools")
    page.screenshot(path=str(SHOTS / "04-tools-desktop.png"))
    page.get_by_role("button", name="Copy outline").click()
    page.wait_for_timeout(100)
    assert page.locator(".tool-utility-bar > span").inner_text() in {"Outline copied", "Copy unavailable in this browser"}
    page.locator(".template-gallery").scroll_into_view_if_needed()
    page.wait_for_timeout(250)
    page.screenshot(path=str(SHOTS / "05-tools-templates.png"))

    load(page, "/blog")
    page.screenshot(path=str(SHOTS / "06-journal-desktop.png"))
    page.locator(".journal-grid").scroll_into_view_if_needed()
    page.wait_for_timeout(250)
    page.screenshot(path=str(SHOTS / "07-journal-stories.png"))
    desktop.close()

    mobile = browser.new_context(viewport={"width": 390, "height": 844}, device_scale_factor=1)
    phone = mobile.new_page()
    phone.on("console", lambda msg: errors.append(f"{phone.url}: {msg.text}") if msg.type == "error" else None)

    load(phone, "/market")
    phone.screenshot(path=str(SHOTS / "08-market-mobile.png"))
    phone.locator(".market-controls").scroll_into_view_if_needed()
    phone.wait_for_timeout(250)
    phone.screenshot(path=str(SHOTS / "08b-market-mobile-filters.png"))
    phone.get_by_role("button", name="Culture").click()
    assert phone.locator(".deck-tile").count() >= 6
    phone.locator(".market-results-head").scroll_into_view_if_needed()
    phone.wait_for_timeout(250)
    phone.screenshot(path=str(SHOTS / "08c-market-mobile-decks.png"))

    load(phone, "/tools")
    phone.screenshot(path=str(SHOTS / "09-tools-mobile.png"))

    load(phone, "/blog")
    phone.screenshot(path=str(SHOTS / "10-journal-mobile.png"))
    mobile.close()
    browser.close()

    if errors:
        raise RuntimeError(f"Browser console errors: {errors}")

print(f"captured=10 output={SHOTS}")
