from playwright.sync_api import sync_playwright


with sync_playwright() as playwright:
    browser = playwright.chromium.launch(headless=True)
    page = browser.new_page(viewport={"width": 1440, "height": 900})
    page.goto("http://127.0.0.1:3000", wait_until="networkidle")
    assert page.locator(".hero-particles i").count() == 24
    page.wait_for_timeout(1800)
    animation = page.locator(".aurora-teal").evaluate(
        "element => getComputedStyle(element).animationName"
    )
    assert animation == "auroraTeal"
    page.locator(".hero").screenshot(path="/tmp/loopcard-hero-desktop.png")

    page.set_viewport_size({"width": 390, "height": 844})
    page.reload(wait_until="networkidle")
    assert page.evaluate("document.documentElement.scrollWidth <= innerWidth")
    page.locator(".hero").screenshot(path="/tmp/loopcard-hero-mobile.png")

    reduced = browser.new_page(viewport={"width": 1200, "height": 800})
    reduced.emulate_media(reduced_motion="reduce")
    reduced.goto("http://127.0.0.1:3000", wait_until="networkidle")
    duration = reduced.locator(".aurora-teal").evaluate(
        "element => getComputedStyle(element).animationDuration"
    )
    assert duration in ("0s", "1e-05s", "0.00001s")
    reduced.close()
    browser.close()
