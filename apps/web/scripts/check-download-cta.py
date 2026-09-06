from pathlib import Path

from playwright.sync_api import sync_playwright


def check_viewport(page, width: int, height: int, output: str) -> None:
    page.set_viewport_size({"width": width, "height": height})
    page.goto("http://127.0.0.1:3000", wait_until="networkidle")
    section = page.locator("#get-loopcard")
    section.scroll_into_view_if_needed()
    assert section.is_visible()
    assert section.get_by_text("Coming soon", exact=True).count() == 2
    plugin = section.get_by_role("link", name="Codex Marketplace")
    assert plugin.get_attribute("href") == "https://www.codex-marketplace.com/plugins/loopcard"
    section.screenshot(path=output)


with sync_playwright() as playwright:
    browser = playwright.chromium.launch(headless=True)
    page = browser.new_page()
    check_viewport(page, 1440, 1000, "/tmp/loopcard-download-desktop.png")
    check_viewport(page, 390, 844, "/tmp/loopcard-download-mobile.png")
    browser.close()

for screenshot in (
    "/tmp/loopcard-download-desktop.png",
    "/tmp/loopcard-download-mobile.png",
):
    assert Path(screenshot).stat().st_size > 0
