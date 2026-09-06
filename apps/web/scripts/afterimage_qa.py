import os
from pathlib import Path
from playwright.sync_api import sync_playwright

BASE = os.environ.get('AUDIT_BASE_URL', 'http://localhost:3000').rstrip('/')
OUT = Path(__file__).resolve().parents[3] / 'docs' / 'afterimage-qa' / 'final'
OUT.mkdir(parents=True, exist_ok=True)

def load(page, route):
    page.goto(f'{BASE}{route}', wait_until='domcontentloaded', timeout=30_000)
    page.wait_for_timeout(1100)

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True, channel='chrome')
    errors = []
    desktop = browser.new_context(viewport={'width': 1440, 'height': 1024}, device_scale_factor=1, permissions=['clipboard-read', 'clipboard-write'])
    page = desktop.new_page()
    page.on('console', lambda msg: errors.append(f'{page.url}: {msg.text}') if msg.type == 'error' else None)

    load(page, '/')
    assert page.locator('.afterimage-hero').count() == 1
    assert page.locator('.afterimage-media video').get_attribute('autoplay') is not None
    page.screenshot(path=str(OUT / '01-home-desktop.png'))
    page.get_by_role('button', name='Switch to Chinese').click()
    assert page.locator('html').get_attribute('lang') == 'zh-CN'
    page.get_by_role('button', name='切换至英文').click()
    page.get_by_role('button', name='Use dark theme').click()
    assert page.locator('html').get_attribute('data-theme') == 'dark'
    page.screenshot(path=str(OUT / '14-home-dark.png'))
    load(page, '/market')
    page.screenshot(path=str(OUT / '15-market-dark.png'))
    load(page, '/market/chemistry-formulas')
    page.locator('.market-preview-card').click()
    page.wait_for_timeout(700)
    page.screenshot(path=str(OUT / '16-market-detail-dark.png'))
    load(page, '/tools')
    page.screenshot(path=str(OUT / '17-tools-dark.png'))
    load(page, '/blog')
    page.screenshot(path=str(OUT / '18-journal-dark.png'))
    load(page, '/')
    page.get_by_role('button', name='Use light theme').click()
    page.locator('#why').scroll_into_view_if_needed()
    page.screenshot(path=str(OUT / '02-home-story.png'))
    page.locator('.memory-stage').scroll_into_view_if_needed()
    page.screenshot(path=str(OUT / '03-home-study-stage.png'))

    load(page, '/market')
    page.screenshot(path=str(OUT / '04-market-desktop.png'))
    page.get_by_role('button', name='Science').click()
    assert page.locator('.deck-tile').count() >= 6
    page.get_by_role('button', name='All decks').click()
    page.locator('.market-search input').fill('astronomy')
    page.wait_for_timeout(500)
    assert page.locator('.deck-tile').count() == 1
    page.screenshot(path=str(OUT / '05-market-filtered.png'))

    load(page, '/market/chemistry-formulas')
    assert page.get_by_role('link', name='Profile').count() == 1
    preview_card = page.locator('.market-preview-card')
    assert preview_card.get_attribute('aria-pressed') == 'false'
    page.screenshot(path=str(OUT / '06-market-detail-front.png'))
    preview_card.click()
    assert preview_card.get_attribute('aria-pressed') == 'true'
    if page.locator('.preview-tabs button').count() > 1:
        page.locator('.preview-tabs button').nth(1).click()
    page.get_by_role('button', name='Next card').click()
    assert page.locator('.preview-status span').first.inner_text().startswith('02')
    page.wait_for_timeout(100)
    preview_card.click()
    page.wait_for_timeout(700)
    page.screenshot(path=str(OUT / '07-market-detail-back.png'))

    load(page, '/tools')
    page.locator('#source-notes').fill('')
    assert page.locator('.tool-import').get_attribute('aria-disabled') == 'true'
    page.locator('#source-notes').fill('Alpha\nAlpha\nBeta')
    page.get_by_role('button', name='Remove duplicates').click()
    assert page.locator('.tool-card-list article').count() == 2
    page.get_by_role('button', name='Reverse order').click()
    page.get_by_role('button', name='Copy outline').click()
    page.screenshot(path=str(OUT / '08-tools-state.png'))

    load(page, '/app/study/preview')
    card = page.locator('.study-card')
    card.focus()
    card.press('Enter')
    assert card.get_attribute('class').find('is-flipped') >= 0
    page.screenshot(path=str(OUT / '09-study-back.png'))
    page.locator('.study-card-actions button').click()
    page.locator('.study-actions button').first.click()

    mobile = browser.new_context(viewport={'width': 390, 'height': 844}, device_scale_factor=1)
    mobile_page = mobile.new_page()
    mobile_page.on('console', lambda msg: errors.append(f'{mobile_page.url}: {msg.text}') if msg.type == 'error' else None)
    load(mobile_page, '/')
    assert mobile_page.locator('.afterimage-media video').evaluate("el => getComputedStyle(el).display") == 'none'
    mobile_page.locator('.mobile-menu summary').click()
    assert mobile_page.locator('.mobile-menu').get_attribute('open') is not None
    mobile_page.screenshot(path=str(OUT / '10-home-mobile.png'))
    load(mobile_page, '/market')
    mobile_page.screenshot(path=str(OUT / '11-market-mobile.png'))
    load(mobile_page, '/market/chemistry-formulas')
    mobile_page.locator('.market-preview-card').click()
    mobile_page.wait_for_timeout(700)
    mobile_page.screenshot(path=str(OUT / '12-market-detail-mobile.png'), full_page=True)
    load(mobile_page, '/tools')
    mobile_page.screenshot(path=str(OUT / '13-tools-mobile.png'))

    reduced = browser.new_context(viewport={'width': 1440, 'height': 1024}, reduced_motion='reduce')
    reduced_page = reduced.new_page()
    load(reduced_page, '/')
    assert reduced_page.locator('.afterimage-media video').evaluate("el => getComputedStyle(el).display") == 'none'

    if errors:
        raise AssertionError('Console errors:\n' + '\n'.join(errors))
    print(f'passed screenshots=18 output={OUT}')
    browser.close()
