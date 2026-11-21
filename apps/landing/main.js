// MealMate landing: print-feed receipt, waitlist (Supabase REST), packaging demo.
document.documentElement.classList.add('js');
const reduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

/* ── signature: the receipt prints once, then the highlighter swipes ── */
const receipt = document.getElementById('hero-receipt');
if (receipt && !reduced) {
  receipt.classList.add('printing');
  receipt.addEventListener(
    'animationend',
    () => {
      receipt.classList.remove('printing');
      receipt.classList.add('printed');
    },
    { once: true },
  );
}

/* ── signature: REST line → arrow to the meal it feeds ── */
const hero = document.querySelector('.hero');
const layer = document.querySelector('.link-layer');
const linkPath = document.getElementById('link-path');
function link(line) {
  const target = document.getElementById(line.dataset.target);
  if (!target || !target.offsetParent) return;
  const h = hero.getBoundingClientRect();
  const a = line.getBoundingClientRect();
  const b = target.getBoundingClientRect();
  const x1 = a.right - h.left + 6;
  const y1 = a.top + a.height / 2 - h.top;
  const x2 = b.left - h.left - 4;
  const y2 = b.top + b.height / 2 - h.top;
  const dx = Math.max(40, (x2 - x1) * 0.5);
  linkPath.setAttribute('d', `M${x1} ${y1} C${x1 + dx} ${y1}, ${x2 - dx} ${y2}, ${x2} ${y2}`);
  layer.style.setProperty('--len', String(Math.ceil(linkPath.getTotalLength())));
  layer.classList.remove('on');
  void layer.getBoundingClientRect();
  layer.classList.add('on');
  target.classList.add('lit');
}
function unlink() {
  layer.classList.remove('on');
  document.querySelectorAll('.ph-day.lit').forEach((el) => el.classList.remove('lit'));
}
document.querySelectorAll('.r-line.rest').forEach((line) => {
  line.addEventListener('mouseenter', () => link(line));
  line.addEventListener('focus', () => link(line));
  line.addEventListener('mouseleave', unlink);
  line.addEventListener('blur', unlink);
});

/* ── waitlist ── */
const form = document.querySelector('.waitlist');
const input = document.getElementById('email');
const msg = form?.querySelector('.form-msg');
const button = form?.querySelector('button');
const cfg = window.MEALMATE_CONFIG || {};

function say(text, kind) {
  msg.textContent = text;
  msg.className = `form-msg ${kind}`;
}

form?.addEventListener('submit', async (e) => {
  e.preventDefault();
  const email = input.value.trim().toLowerCase();
  if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) {
    input.setAttribute('aria-invalid', 'true');
    input.focus();
    return say('Bitte gib eine gültige E-Mail-Adresse ein.', 'err');
  }
  input.removeAttribute('aria-invalid');
  if (!cfg.supabaseUrl || !cfg.supabaseKey) return say('Die Warteliste ist gerade nicht erreichbar. Versuch es später noch einmal.', 'err');
  button.disabled = true;
  button.textContent = 'Wird eingetragen …';
  try {
    const res = await fetch(`${cfg.supabaseUrl}/rest/v1/waitlist`, {
      method: 'POST',
      headers: { apikey: cfg.supabaseKey, 'Content-Type': 'application/json', Prefer: 'return=minimal' },
      body: JSON.stringify({ email, source: 'landing' }),
    });
    if (res.ok) {
      say('Du stehst auf der Liste. Wir melden uns zum Teststart.', 'ok');
      form.reset();
    } else if (res.status === 409) {
      say('Diese Adresse steht schon auf der Liste.', 'ok');
    } else {
      say('Das hat nicht geklappt. Prüf die Adresse und versuch es noch einmal.', 'err');
    }
  } catch {
    say('Keine Verbindung. Prüf dein Internet und versuch es noch einmal.', 'err');
  } finally {
    button.disabled = false;
    button.textContent = 'Auf die Warteliste';
  }
});

/* ── demo: a 450 g bag of spinach ── */
const BAG = 450;
const NEED = { pasta: 200, gnocchi: 250, dal: 100, curry: 100 };
const NAMES = { pasta: 'Spinat-Feta-Pasta', gnocchi: 'Gnocchi mit Rahmspinat', dal: 'Linsen-Dal mit Spinat', curry: 'Kichererbsen-Curry' };
const boxes = [...document.querySelectorAll('.picks input')];
const $ = (id) => document.getElementById(id);

function bestFit(rest, chosen) {
  // the unchosen recipe that uses the leftover most completely without exceeding it
  return Object.keys(NEED)
    .filter((k) => !chosen.includes(k) && NEED[k] <= rest)
    .sort((a, b) => NEED[b] - NEED[a])[0];
}

function update() {
  const chosen = boxes.filter((b) => b.checked).map((b) => b.value);
  const need = chosen.reduce((s, k) => s + NEED[k], 0);
  const bags = Math.max(need > 0 ? 1 : 0, Math.ceil(need / BAG));
  const rest = bags * BAG - need;
  $('d-need').textContent = `${need} g`;
  $('d-buy').textContent = bags ? `${bags} × 450 g` : '–';
  $('d-rest').textContent = `${rest} g`;
  const fill = $('bag-fill');
  fill.style.width = bags ? `${Math.min(100, ((need - (bags - 1) * BAG) / BAG) * 100)}%` : '0%';
  fill.classList.toggle('over', bags > 1);
  const line = $('d-rest-line');
  const fit = rest > 0 ? bestFit(rest, chosen) : null;
  line.classList.toggle('has-rest', rest > 0);
  $('d-rest-label').firstChild.textContent = rest > 0 ? `REST ${rest} g` : 'Rest';
  $('d-rest-hint').textContent = rest > 0 ? (fit ? `→ passt in: ${NAMES[fit]}` : '→ kein Rezept passt genau') : 'alles verbraucht';
  $('d-verdict').textContent = !chosen.length
    ? 'Wähl ein Rezept aus.'
    : rest === 0
      ? `Der Beutel${bags > 1 ? '' : ''} ist leer. Nichts landet im Müll.`
      : fit
        ? `Noch ${rest} g übrig. Tipp: Nimm „${NAMES[fit]}“ dazu.`
        : `Noch ${rest} g übrig. MealMate sucht dafür ein passendes Rezept.`;
}
boxes.forEach((b) => b.addEventListener('change', update));
update();
