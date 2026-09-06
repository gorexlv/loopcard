from pathlib import Path

from playwright.sync_api import sync_playwright


BASE = "http://127.0.0.1:3000"
SHOTS = Path(__file__).resolve().parents[3] / "docs" / "screenshots"
SHOTS.mkdir(parents=True, exist_ok=True)


def wait(page, path):
    page.goto(f"{BASE}{path}", wait_until="networkidle")
    page.wait_for_timeout(400)


with sync_playwright() as playwright:
    browser = playwright.chromium.launch(headless=True, channel="chrome")
    desktop = browser.new_context(viewport={"width": 1440, "height": 1000}, device_scale_factor=1)
    page = desktop.new_page()
    errors = []
    missing = []
    page.on("console", lambda msg: errors.append(msg.text) if msg.type == "error" else None)
    page.on("response", lambda response: missing.append(response.url) if response.status == 404 else None)

    wait(page, "/")
    assert page.locator("h1").inner_text().startswith("Keep ideas")
    assert page.locator('script[type="application/ld+json"]').count() == 1
    page.screenshot(path=str(SHOTS / "web-01-landing.png"))

    page.locator(".download-cta").scroll_into_view_if_needed()
    page.wait_for_timeout(250)
    page.screenshot(path=str(SHOTS / "web-02-install-cta.png"))

    wait(page, "/market")
    assert page.locator(".deck-tile").count() == 4
    page.screenshot(path=str(SHOTS / "web-03-market.png"))

    wait(page, "/market/chinese-zodiac-origins")
    assert page.locator(".card-list-preview article").count() == 12

    wait(page, "/tools")
    page.locator("textarea").fill("Mercury is closest to the Sun.\nVenus has a dense atmosphere.")
    assert page.locator(".tool-output li").count() == 2

    wait(page, "/blog")
    assert page.locator(".article-card").count() == 4
    assert not errors, f"Browser console errors: {errors}; missing={missing}"
    desktop.close()

    mobile = browser.new_context(viewport={"width": 390, "height": 844}, device_scale_factor=1)
    app = mobile.new_page()
    wait(app, "/app")
    assert app.locator(".study-prompt").inner_text() == "子鼠"
    app.locator(".study-card").click()
    assert app.locator(".study-tabs button").first.inner_text() == "来历"
    app.screenshot(path=str(SHOTS / "web-04-study-mobile.png"))
    app.get_by_role("button", name="Crystal clear").click()
    assert app.locator(".study-prompt").inner_text() == "丑牛"
    mobile.close()
    browser.close()

print("verified routes=7 screenshots=4 study_interaction=pass console_errors=0")
