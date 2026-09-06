from playwright.sync_api import sync_playwright

with sync_playwright() as playwright:
    browser = playwright.chromium.launch(headless=True)
    page = browser.new_page(viewport={"width": 1440, "height": 1000}, color_scheme="light")
    page.goto("http://localhost:3000", wait_until="networkidle")
    assert page.locator("h1").inner_text().startswith("Keep ideas")
    page.get_by_role("button", name="Switch to Chinese").click()
    assert page.locator("h1").inner_text().startswith("让想法")
    assert page.evaluate("document.documentElement.lang") == "zh-CN"
    page.get_by_role("button", name="切换深色主题").click()
    assert page.evaluate("document.documentElement.dataset.theme") == "dark"
    page.reload(wait_until="networkidle")
    assert page.locator("h1").inner_text().startswith("让想法")
    assert page.evaluate("document.documentElement.dataset.theme") == "dark"
    page.screenshot(path="/tmp/loopcard-home-dark-zh.png", full_page=True)

    mobile = browser.new_page(viewport={"width": 390, "height": 844}, color_scheme="light")
    mobile.goto("http://localhost:3000", wait_until="networkidle")
    assert mobile.evaluate("document.documentElement.scrollWidth <= document.documentElement.clientWidth")
    assert mobile.get_by_role("button", name="Switch to Chinese").is_visible()
    assert mobile.get_by_role("button", name="Use dark theme").is_visible()
    mobile.screenshot(path="/tmp/loopcard-home-preferences-mobile.png", full_page=False)
    browser.close()
