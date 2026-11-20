// Vidéos de démonstration (une par fonctionnalité), pour les réseaux sociaux.
// Prérequis : l'app lancée en local (npm run build && npm start -- -p 3100), Playwright et ffmpeg installés,
// et le compte de démonstration remis à zéro juste avant (node --env-file=.env.local scripts/demo.mjs).
// Usage : LANG=fr_FR.UTF-8 node --env-file=.env.local scripts/videos.cjs <dossier> [nom-de-video ...]
const { chromium, devices } = require('playwright');
const fs = require('fs'), path = require('path'), { execFileSync } = require('child_process');
const OUT = process.argv[2], ONLY = process.argv.slice(3), B = 'http://localhost:3100';
const { DEMO_EMAIL: EMAIL, DEMO_PASSWORD: PW } = process.env;

// Curseur orange, légende en bas (ordinateur) ou en haut (téléphone). Survit aux changements de page.
const OVERLAY = `(() => {
  const S = sessionStorage;
  const put = (x, y) => { const c = document.getElementById('__cur'); if (c) c.style.transform = 'translate(' + x + 'px,' + y + 'px)'; };
  const init = () => {
    if (document.getElementById('__cur')) return;
    const mob = innerWidth < 600; // calculé après lecture de la balise viewport
    const cur = document.createElement('div'); cur.id = '__cur';
    cur.style.cssText = 'position:fixed;left:0;top:0;width:28px;height:28px;margin:-14px 0 0 -14px;border:3px solid #ff5a1f;background:rgba(255,90,31,.28);border-radius:50%;z-index:2147483647;pointer-events:none;transition:width .1s,height .1s,margin .1s';
    document.documentElement.appendChild(cur);
    const p = JSON.parse(S.getItem('__pos') || '[-100,-100]'); put(p[0], p[1]);
    const cap = document.createElement('div'); cap.id = '__cap';
    cap.style.cssText = 'position:fixed;left:50%;' + (mob ? 'top:14px' : 'bottom:26px') + ';transform:translateX(-50%);width:max-content;max-width:' + (mob ? '92%' : '80%') + ';background:#000;color:#f5f5f5;font:700 ' + (mob ? 19 : 26) + 'px/1.3 Inter,system-ui,sans-serif;padding:' + (mob ? '10px 14px' : '16px 26px') + ';border-left:6px solid #ff5a1f;z-index:2147483646;pointer-events:none;box-shadow:0 10px 40px rgba(0,0,0,.7)';
    document.documentElement.appendChild(cap);
    window.__cap = (t) => { S.setItem('__captext', t || ''); cap.textContent = t || ''; cap.style.display = t ? 'block' : 'none';
      const m = innerWidth < 600; cap.style.top = m ? '14px' : 'auto'; cap.style.bottom = m ? 'auto' : '26px'; cap.style.fontSize = (m ? 19 : 26) + 'px'; cap.style.maxWidth = m ? '92%' : '80%'; };
    window.__cap(S.getItem('__captext'));
  };
  addEventListener('mousemove', (e) => { S.setItem('__pos', JSON.stringify([e.clientX, e.clientY])); put(e.clientX, e.clientY); }, true);
  const size = (n) => () => { const c = document.getElementById('__cur'); if (c) { c.style.width = c.style.height = n + 'px'; c.style.margin = (-n / 2) + 'px 0 0 ' + (-n / 2) + 'px'; } };
  addEventListener('mousedown', size(18), true); addEventListener('mouseup', size(28), true);
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init); else init();
})();`;

const FR = { locale: 'fr-FR', timezoneId: 'Europe/Paris' };
const wait = (p, ms) => p.waitForTimeout(ms);
const cap = async (p, t, ms = 0) => { await p.evaluate((x) => window.__cap && window.__cap(x), t); if (ms) await wait(p, ms); };
const moveTo = async (p, loc) => {
  await loc.scrollIntoViewIfNeeded(); await wait(p, 150);
  const b = await loc.boundingBox();
  await p.mouse.move(b.x + b.width / 2, b.y + b.height / 2, { steps: 22 }); await wait(p, 250);
};
const click = async (p, loc) => { await moveTo(p, loc); await p.mouse.down(); await wait(p, 90); await p.mouse.up(); await wait(p, 300); };
const type = async (p, loc, text) => { await click(p, loc); await p.keyboard.type(text, { delay: 45 }); await wait(p, 200); };
const scroll = async (p, dy) => { for (let i = 0; i < 12; i++) { await p.mouse.wheel(0, dy / 12); await wait(p, 35); } await wait(p, 400); };
const settle = (p) => p.waitForLoadState('networkidle').catch(() => {});

// Images d'écran (CDP) → MP4 H.264 à 30 i/s.
async function record(p, name, width, fn) {
  const cdp = await p.context().newCDPSession(p), frames = [];
  cdp.on('Page.screencastFrame', async (f) => { frames.push({ data: f.data, t: f.metadata.timestamp }); cdp.send('Page.screencastFrameAck', { sessionId: f.sessionId }).catch(() => {}); });
  await cdp.send('Page.startScreencast', { format: 'jpeg', quality: 90, maxWidth: 4000, maxHeight: 4000 });
  await fn(); await wait(p, 1800);
  await cdp.send('Page.stopScreencast');
  const dir = path.join(OUT, '.frames-' + name); fs.rmSync(dir, { recursive: true, force: true }); fs.mkdirSync(dir, { recursive: true });
  let list = '';
  frames.forEach((f, i) => {
    fs.writeFileSync(path.join(dir, i + '.jpg'), Buffer.from(f.data, 'base64'));
    const d = i + 1 < frames.length ? Math.max(frames[i + 1].t - f.t, 1 / 60) : 1.5;
    list += `file '${i}.jpg'\nduration ${d.toFixed(4)}\n`;
  });
  list += `file '${frames.length - 1}.jpg'\n`;
  fs.writeFileSync(path.join(dir, 'list.txt'), list);
  const out = path.join(OUT, name + '.mp4');
  execFileSync('ffmpeg', ['-loglevel', 'error', '-y', '-f', 'concat', '-safe', '0', '-i', path.join(dir, 'list.txt'),
    '-vf', `scale=${width}:-2:flags=lanczos${width === 1080 ? ',pad=1080:1920:(ow-iw)/2:(oh-ih)/2:color=0x0a0a0a' : ''},fps=30,format=yuv420p`, '-c:v', 'libx264', '-preset', 'slow', '-crf', '19', '-movflags', '+faststart', out]);
  const dur = execFileSync('ffprobe', ['-v', 'error', '-show_entries', 'format=duration:stream=width,height', '-of', 'csv=p=0', out]).toString().trim().replace(/\n/g, ' · ');
  fs.rmSync(dir, { recursive: true, force: true });
  console.log(`vidéo ${name}.mp4 : ${frames.length} images, ${dur}`);
}

async function login(ctx) {
  const p = await ctx.newPage(); await p.goto(B + '/connexion');
  await p.fill('input[name=email]', EMAIL); await p.fill('input[name=password]', PW);
  await Promise.all([p.waitForURL(B + '/'), p.click('button:has-text("Se connecter")')]);
  await p.close();
}

const day = (n) => { const d = new Date(new Intl.DateTimeFormat('en-CA', { timeZone: 'Europe/Paris' }).format(new Date()) + 'T12:00:00Z'); d.setUTCDate(d.getUTCDate() + n); return d.toISOString().slice(0, 10); };
const nextSaturday = () => [...Array(14).keys()].map((i) => i + 2).find((n) => new Date(day(n) + 'T12:00:00Z').getUTCDay() === 6);
const shared = {}; // créneau choisi par Marc, d'une vidéo à l'autre

const VIDEOS = {
  async '1-tableau-de-bord'(pc) {
    const p = await pc.newPage();
    await p.goto(B + '/'); await settle(p);
    await record(p, '1-tableau-de-bord', 1920, async () => {
      await cap(p, 'Flo : votre journée en un coup d’œil', 2200);
      await cap(p, 'Rendez-vous du mois, nouveaux prospects, demandes à confirmer');
      for (const t of ['RDV ce mois', 'Nouveaux prospects', 'À confirmer', 'Annulations']) { await moveTo(p, p.getByText(t, { exact: true }).first()); await wait(p, 450); }
      await cap(p, 'Votre activité sur 7 ou 30 jours');
      await click(p, p.getByRole('button', { name: '30 jours' })); await wait(p, 1200);
      await click(p, p.getByRole('button', { name: '7 jours' })); await wait(p, 600);
      await cap(p, 'Vos prochains rendez-vous, avec qui et pour quoi');
      await moveTo(p, p.getByText('Prochains rendez-vous').first()); await wait(p, 1600);
      await cap(p, 'Le chiffre orange : les demandes à traiter');
      await moveTo(p, p.locator('nav a[href="/demandes"]').first()); await wait(p, 1800);
    });
    await p.close();
  },

  async '2-agenda'(pc) {
    const p = await pc.newPage(), sam = day(nextSaturday());
    await p.goto(B + '/agenda?vue=semaine'); await settle(p);
    await record(p, '2-agenda', 1920, async () => {
      await cap(p, 'L’agenda de toute l’équipe', 2000);
      await cap(p, 'Au jour, à la semaine ou au mois');
      for (const v of ['Jour', 'Mois', 'Semaine']) { await click(p, p.getByRole('link', { name: v, exact: true })); await settle(p); await wait(p, 1100); }
      await cap(p, 'Nouveau rendez-vous en quelques secondes');
      await click(p, p.getByRole('link', { name: 'Nouveau RDV' }).last()); await settle(p); await wait(p, 600);
      const form = p.locator('form:has(select[name=client])').last();
      await moveTo(p, form.locator('select[name=client]')); await form.locator('select[name=client]').selectOption({ label: 'Jean Morel' }); await wait(p, 400);
      await moveTo(p, form.locator('select[name=service]')); await form.locator('select[name=service]').selectOption({ label: 'Dépannage fuite (60 min)' }); await wait(p, 400);
      await moveTo(p, form.locator('input[name=date]')); await form.locator('input[name=date]').fill(sam); await wait(p, 300);
      await moveTo(p, form.locator('input[name=time]')); await form.locator('input[name=time]').fill('10:00'); await wait(p, 300);
      await type(p, form.locator('textarea[name=notes]'), 'Robinet de cuisine qui fuit');
      await click(p, form.getByRole('button', { name: /Enregistrer/ })); await settle(p); await wait(p, 1500);
      await cap(p, 'Deux rendez-vous au même moment ? Impossible.');
      await click(p, p.getByRole('link', { name: 'Nouveau RDV' }).last()); await settle(p); await wait(p, 500);
      const f2 = p.locator('form:has(select[name=client])').last();
      await f2.locator('select[name=client]').selectOption({ label: 'Pierre Blanc' }); await f2.locator('select[name=service]').selectOption({ label: 'Débouchage canalisation (60 min)' });
      await f2.locator('input[name=date]').fill(sam); await f2.locator('input[name=time]').fill('10:30'); await wait(p, 500);
      await click(p, f2.getByRole('button', { name: /Enregistrer/ })); await settle(p); await wait(p, 2600);
    });
    await p.close();
  },

  async '3-email-vers-demande'(pc) {
    const p = await pc.newPage();
    await p.goto(B + '/demandes'); await settle(p);
    await record(p, '3-email-vers-demande', 1920, async () => {
      await cap(p, 'Un client vous écrit par e-mail…', 1800);
      await cap(p, 'Collez son e-mail dans Flo');
      await click(p, p.locator('summary:has-text("Ajouter une demande reçue par e-mail")')); await wait(p, 400);
      await moveTo(p, p.locator('textarea[name=texte]'));
      await p.fill('textarea[name=texte]', 'De : Marc Lefort <marc.lefort@example.com>\nObjet : Chauffe-eau en panne\n\nBonjour,\nMon chauffe-eau ne chauffe plus depuis hier soir. Vous pourriez passer quand ?\nMarc Lefort\n06 39 98 00 95');
      await wait(p, 1400);
      await click(p, p.getByRole('button', { name: 'Ajouter la demande' })); await settle(p); await wait(p, 600);
      await cap(p, 'Fiche client créée : nom, e-mail, téléphone');
      const card = p.locator('section', { has: p.locator('h2', { hasText: 'Marc Lefort' }) });
      await moveTo(p, card.locator('h2')); await wait(p, 1600);
      await cap(p, 'Répondez en un clic : le message est déjà écrit');
      const btn = card.getByRole('link', { name: 'Répondre par e-mail' });
      await moveTo(p, btn); await p.mouse.down(); await wait(p, 90); await p.mouse.up();
      const body = decodeURIComponent((await btn.getAttribute('href')).split('body=')[1]).replace('http://localhost:3100', 'https://flo…');
      await p.evaluate((t) => { // aperçu de la fenêtre de rédaction qui s'ouvre dans la messagerie
        const d = document.createElement('div'); d.id = '__mail';
        d.style.cssText = 'position:fixed;right:40px;bottom:120px;width:560px;background:#fff;color:#111;font:16px/1.5 Inter,system-ui,sans-serif;z-index:2147483645;box-shadow:0 20px 60px rgba(0,0,0,.6)';
        d.innerHTML = '<div style="background:#222;color:#fff;padding:10px 16px;font-weight:600">Nouveau message</div><div style="padding:10px 16px;border-bottom:1px solid #ddd">À : marc.lefort@example.com</div><div style="padding:10px 16px;border-bottom:1px solid #ddd">Objet : Votre demande — Plomberie Martin</div><pre style="padding:14px 16px;margin:0;white-space:pre-wrap;font:inherit"></pre>';
        d.querySelector('pre').textContent = t; document.body.appendChild(d);
      }, body);
      await wait(p, 4200);
      await cap(p, 'Votre client choisit lui-même son créneau', 2000);
    });
    await p.close();
  },

  async '4-reservation-client-mobile'(_, b) {
    const ctx = await b.newContext({ ...devices['iPhone 13'], ...FR }); await ctx.addInitScript(OVERLAY);
    const p = await ctx.newPage();
    await p.goto(B + '/r/plomberie-martin-demo'); await settle(p);
    await record(p, '4-reservation-client-mobile', 1080, async () => {
      await cap(p, 'Côté client : il ouvre votre lien', 1800);
      await cap(p, 'Il choisit la prestation');
      await click(p, p.getByText('Installation chauffe-eau')); await settle(p); await wait(p, 700);
      await cap(p, 'Il ne voit que vos créneaux libres');
      await click(p, p.locator('a[href*="&date="]').nth(1)); await settle(p); await wait(p, 700);
      await click(p, p.locator('a[href*="&time="]').first()); await settle(p); await wait(p, 700);
      const u = new URL(p.url()); shared.date = u.searchParams.get('date');
      await cap(p, 'Il laisse ses coordonnées');
      await type(p, p.locator('input[name=first_name]'), 'Marc'); await type(p, p.locator('input[name=last_name]'), 'Lefort');
      await type(p, p.locator('input[name=phone]'), '06 39 98 00 95'); await type(p, p.locator('input[name=email]'), 'marc.lefort@example.com');
      await type(p, p.locator('textarea[name=message]'), 'Plutôt le matin si possible.');
      await click(p, p.locator('input[name=consent]'));
      await click(p, p.getByRole('button', { name: 'Demander ce rendez-vous' })); await settle(p); await wait(p, 800);
      await cap(p, 'Envoyé. Le créneau est bloqué pour vous.', 2400);
    });
    await ctx.close();
  },

  async '5-confirmer-rendez-vous'(pc) {
    const p = await pc.newPage();
    await p.goto(`${B}/agenda?vue=jour&date=${shared.date ?? day(3)}`); await settle(p);
    await record(p, '5-confirmer-rendez-vous', 1920, async () => {
      await cap(p, 'Le rendez-vous arrive dans votre agenda, en orange', 2200);
      await cap(p, 'Un clic pour l’ouvrir…');
      await click(p, p.locator('a', { hasText: 'Marc Lefort' }).first()); await settle(p); await wait(p, 1000);
      await cap(p, '…et un clic pour le confirmer');
      await click(p, p.getByRole('button', { name: 'Confirmer' })); await settle(p); await wait(p, 900);
      await p.goto(`${B}/agenda?vue=jour&date=${shared.date ?? day(3)}`); await settle(p);
      await cap(p, 'Confirmé : il passe en blanc dans l’agenda', 2600);
    });
    await p.close();
  },

  async '6-clients'(pc) {
    const p = await pc.newPage();
    await p.goto(B + '/clients'); await settle(p);
    await record(p, '6-clients', 1920, async () => {
      await cap(p, 'Tous vos clients et prospects', 1800);
      await cap(p, 'Retrouvez un client en tapant son nom ou son téléphone');
      await type(p, p.locator('input[name=q]').last(), 'Roux'); await p.keyboard.press('Enter'); await settle(p); await wait(p, 900);
      await click(p, p.getByRole('link', { name: /Martine Roux/ }).first()); await settle(p); await wait(p, 800);
      await cap(p, 'Coordonnées, notes et historique des rendez-vous');
      await scroll(p, 500); await wait(p, 1400); await scroll(p, -500);
      await cap(p, 'Importez vos contacts : Excel, Google ou téléphone');
      await p.goto(B + '/clients?import=1'); await settle(p); await wait(p, 2600);
    });
    await p.close();
  },

  async '7-reservation-et-equipe'(pc) {
    const p = await pc.newPage();
    await p.goto(B + '/reservations'); await settle(p);
    await record(p, '7-reservation-et-equipe', 1920, async () => {
      await cap(p, 'Votre page de réservation : un lien à partager partout', 1800);
      await moveTo(p, p.getByRole('button', { name: /Copier/ }).first()); await wait(p, 1600);
      await cap(p, 'Équipe : horaires et absences de chacun');
      await click(p, p.locator('nav a[href="/equipe"]').first()); await settle(p); await wait(p, 900);
      await scroll(p, 600); await wait(p, 1200); await scroll(p, 600); await wait(p, 1400);
      await cap(p, 'Pendant une absence, aucun rendez-vous possible', 2200);
    });
    await p.close();
  },

  async '8-statistiques'(pc) {
    const p = await pc.newPage();
    await p.goto(B + '/statistiques'); await settle(p);
    await record(p, '8-statistiques', 1920, async () => {
      await cap(p, 'Vos chiffres, sans tableur', 1800);
      await cap(p, 'Rendez-vous, heures travaillées, chiffre d’affaires, annulations', 2400);
      await scroll(p, 500); await wait(p, 1800); await scroll(p, -500); await wait(p, 600);
    });
    await p.close();
  },

  async '9-flo-sur-telephone'(_, b) {
    const ctx = await b.newContext({ ...devices['iPhone 13'], ...FR }); await ctx.addInitScript(OVERLAY); await login(ctx);
    const p = await ctx.newPage();
    await p.goto(B + '/'); await settle(p);
    await record(p, '9-flo-sur-telephone', 1080, async () => {
      await cap(p, 'Flo dans votre poche, sur le chantier', 1800);
      await scroll(p, 700); await wait(p, 900); await scroll(p, -700);
      await cap(p, 'Votre agenda, toujours avec vous');
      await click(p, p.locator('nav a[href="/agenda"]').last()); await settle(p); await wait(p, 1400);
      await cap(p, 'Vos demandes, où que vous soyez');
      await click(p, p.getByRole('button', { name: 'Plus' })); await wait(p, 700);
      await click(p, p.locator('[role=dialog] a[href="/demandes"]')); await p.waitForURL(/\/demandes/, { timeout: 8000 }).catch(() => p.goto(B + '/demandes')); await settle(p); await wait(p, 1200);
      console.log('  page affichée :', p.url());
      await scroll(p, 600); await wait(p, 1600);
    });
    await ctx.close();
  },
};

(async () => {
  fs.mkdirSync(OUT, { recursive: true });
  const b = await chromium.launch({ args: ['--lang=fr-FR'] });
  const pc = await b.newContext({ viewport: { width: 1280, height: 720 }, deviceScaleFactor: 2, ...FR });
  await pc.addInitScript(OVERLAY); await login(pc);
  for (const [name, fn] of Object.entries(VIDEOS)) {
    if (ONLY.length && !ONLY.includes(name)) continue;
    try { await fn(pc, b); } catch (e) { console.error(`ÉCHEC ${name} :`, e.message.split('\n')[0]); }
  }
  await b.close();
})();
