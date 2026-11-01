// Parity screenshot tool: for each route in routes.json, loads the HTML
// prototype (served at PROTO_URL) and the Flutter web build (served at
// APP_URL) at a 390x844 viewport and saves a screenshot pair to
// out/<route-slug>-{proto,app}.png.
//
// Usage: node shoot.js [routeFilter]
//   routeFilter: optional substring to only shoot matching routes.
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const PROTO_URL = process.env.PROTO_URL || 'http://localhost:8801';
const APP_URL = process.env.APP_URL || 'http://localhost:8802';
const OUT_DIR = path.join(__dirname, 'out');
const ROUTES_FILE = process.env.ROUTES_FILE || 'routes.json';
const routes = JSON.parse(fs.readFileSync(path.join(__dirname, ROUTES_FILE), 'utf8'));

function slug(route) {
  return route.replace(/^\//, '') || 'root';
}

async function shootProto(browser, route) {
  const page = await browser.newPage({ viewport: { width: 390, height: 844 } });
  await page.goto(PROTO_URL + '/index.html', { waitUntil: 'load' });
  // Prototype is a classic-script SPA exposing a global `go(routeName)`.
  const routeName = route.replace(/^\//, '');
  await page.evaluate((r) => {
    // eslint-disable-next-line no-undef
    go(r);
  }, routeName);
  await page.waitForTimeout(400);
  await page.screenshot({ path: path.join(OUT_DIR, `${slug(route)}-proto.png`) });
  await page.close();
}

async function shootApp(browser, route) {
  const page = await browser.newPage({ viewport: { width: 390, height: 844 } });
  await page.goto(`${APP_URL}/#${route}`, { waitUntil: 'load' });
  // Flutter web shows a #splash picture until the engine renders its first
  // frame; wait for it to be removed (flutter_bootstrap.js calls
  // removeSplashFromWeb()) before screenshotting, then give widgets/async
  // state (e.g. the 1150ms generating/analyzing screens) time to settle.
  await page
    .waitForSelector('#splash', { state: 'detached', timeout: 15000 })
    .catch(() => {});
  await page.waitForTimeout(1500);
  await page.screenshot({ path: path.join(OUT_DIR, `${slug(route)}-app.png`) });
  await page.close();
}

(async () => {
  fs.mkdirSync(OUT_DIR, { recursive: true });
  const filter = process.argv[2];
  const targets = filter
    ? routes.filter((r) => slug(r).includes(filter.replace(/^\//, '')))
    : routes;
  const browser = await chromium.launch();
  for (const route of targets) {
    try {
      await shootProto(browser, route);
    } catch (e) {
      console.error(`proto ${route} failed:`, e.message);
    }
    try {
      await shootApp(browser, route);
    } catch (e) {
      console.error(`app ${route} failed:`, e.message);
    }
    console.log(`shot ${route}`);
  }
  await browser.close();
})();
