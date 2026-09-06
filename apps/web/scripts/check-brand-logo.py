from playwright.sync_api import sync_playwright

with sync_playwright() as playwright:
    browser = playwright.chromium.launch(headless=True)
    for name, width, height in (("desktop", 1440, 900), ("mobile", 390, 844)):
        page = browser.new_page(viewport={"width": width, "height": height})
        page.goto("http://localhost:3000", wait_until="networkidle")
        logo = page.locator(".site-header .logo-mark")
        assert logo.get_attribute("src") == "/brand/loopcard-logo-96.webp"
        assert logo.evaluate("element => element.complete && element.naturalWidth === 1254")
        assert logo.bounding_box()["width"] in (34, 35)
        page.screenshot(path=f"/tmp/loopcard-logo-{name}.png", full_page=False)
        page.close()
    browser.close()
