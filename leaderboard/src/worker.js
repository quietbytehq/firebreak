// Firebreak global top 100.
//   GET  /                 the scoreboard page
//   GET  /api/top          top 100 as JSON (one campaign board)
//   POST /api/submit       {name, score, mode, version, stages} from the game
//   GET  /admin?key=       list recent entries; /admin/delete?key=&id= removes one
// The game is open source, so a submitted score cannot be proved genuine. The
// checks here keep out junk and rude names; the admin link removes the rest.

const MODES = { campaign: "Campaign" };
const BLOCKED = ["fuck", "shit", "cunt", "nigg", "fag", "bitch", "dick", "cock", "pussy", "rape", "nazi", "hitler", "porn", "sex", "whore", "slut", "arse", "wank"];
const PER_HOUR = 6;
const MIN_STAGES = 1;
const MAX_STAGES = 12;
const PER_STAGE_CAP = 40000;

const json = (data, status = 200) =>
  new Response(JSON.stringify(data), { status, headers: { "content-type": "application/json; charset=utf-8", "cache-control": "no-store" } });

function cleanName(raw) {
  const name = String(raw || "").toUpperCase().replace(/[^A-Z0-9 ._\-]/g, "").replace(/\s+/g, " ").trim().slice(0, 12);
  if (!name) return null;
  const squashed = name.toLowerCase().replace(/[^a-z]/g, "").replace(/0/g, "o").replace(/1/g, "i").replace(/3/g, "e").replace(/4/g, "a").replace(/5/g, "s");
  const plain = name.toLowerCase().replace(/0/g, "o").replace(/1/g, "i").replace(/3/g, "e").replace(/4/g, "a").replace(/5/g, "s").replace(/[^a-z]/g, "");
  if (BLOCKED.some((w) => squashed.includes(w) || plain.includes(w))) return null;
  return name;
}

/** Accept JSON integers and integer-valued floats (e.g. 6230.0). Reject 6230.1. */
function parseIntValue(raw) {
  const n = Number(raw);
  if (!Number.isFinite(n) || Math.trunc(n) !== n) return null;
  return n;
}

async function hashIp(ip, salt) {
  const data = new TextEncoder().encode(`${salt}|${ip}`);
  const digest = await crypto.subtle.digest("SHA-256", data);
  return [...new Uint8Array(digest)].slice(0, 12).map((b) => b.toString(16).padStart(2, "0")).join("");
}

async function top(env) {
  const sql = `SELECT name, score, stages, created_at FROM (
                 SELECT name, score, stages, created_at,
                        ROW_NUMBER() OVER (PARTITION BY name ORDER BY score DESC, created_at ASC) AS rn
                 FROM scores
               ) WHERE rn = 1 ORDER BY score DESC, created_at ASC LIMIT 100`;
  const { results } = await env.DB.prepare(sql).all();
  return results.map((r, i) => ({ rank: i + 1, name: r.name, score: r.score, stages: r.stages, mode: "campaign", at: r.created_at }));
}

async function submit(request, env) {
  let body;
  try {
    body = await request.json();
  } catch {
    return json({ ok: false, error: "bad request" }, 400);
  }
  const min = parseInt(env.MIN_SCORE || "2000", 10);
  const max = parseInt(env.MAX_SCORE || "5000000", 10);
  const score = parseIntValue(body.score);
  const stages = parseIntValue(body.stages);
  const mode = String(body.mode || "");
  const name = cleanName(body.name);
  if (!name) return json({ ok: false, error: "name not allowed" }, 400);
  if (!(mode in MODES)) return json({ ok: false, error: "unknown mode" }, 400);
  if (score === null || score < min || score > max || score % 10 !== 0) return json({ ok: false, error: "score not accepted" }, 400);
  if (stages === null || stages < MIN_STAGES || stages > MAX_STAGES || score > PER_STAGE_CAP * stages) {
    return json({ ok: false, error: "score not accepted" }, 400);
  }
  const ip = request.headers.get("cf-connecting-ip") || "local";
  const ipHash = await hashIp(ip, env.IP_SALT || "firebreak");
  const now = Math.floor(Date.now() / 1000);
  const recent = await env.DB.prepare("SELECT COUNT(*) AS n FROM scores WHERE ip_hash = ?1 AND created_at > ?2").bind(ipHash, now - 3600).first();
  if (recent && recent.n >= PER_HOUR) return json({ ok: false, error: "too many scores, try later" }, 429);
  await env.DB.prepare("INSERT INTO scores (name, score, table_id, version, stages, ip_hash, created_at) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7)")
    .bind(name, score, mode, String(body.version || "").slice(0, 16), stages, ipHash, now).run();
  const better = await env.DB.prepare("SELECT COUNT(*) AS n FROM (SELECT MAX(score) AS s FROM scores GROUP BY name) WHERE s > ?1").bind(score).first();
  return json({ ok: true, rank: (better ? better.n : 0) + 1 });
}

async function admin(url, env) {
  if (!env.ADMIN_KEY || url.searchParams.get("key") !== env.ADMIN_KEY) return new Response("Not found", { status: 404 });
  if (url.pathname === "/admin/delete") {
    const id = parseInt(url.searchParams.get("id") || "0", 10);
    await env.DB.prepare("DELETE FROM scores WHERE id = ?1").bind(id).run();
    return Response.redirect(`${url.origin}/admin?key=${encodeURIComponent(env.ADMIN_KEY)}`, 302);
  }
  const { results } = await env.DB.prepare("SELECT id, name, score, table_id, version, stages, created_at FROM scores ORDER BY created_at DESC LIMIT 300").all();
  const esc = (s) => String(s).replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c]));
  const rows = results.map((r) => `<tr><td>${r.id}</td><td>${esc(r.name)}</td><td>${r.score.toLocaleString("en-GB")}</td><td>${esc(r.table_id)}</td><td>${r.stages}</td><td>${esc(r.version)}</td><td>${new Date(r.created_at * 1000).toISOString().slice(0, 16).replace("T", " ")}</td><td><a href="/admin/delete?key=${encodeURIComponent(env.ADMIN_KEY)}&id=${r.id}">delete</a></td></tr>`).join("");
  return new Response(`<!doctype html><meta charset="utf-8"><title>Firebreak scores admin</title><style>body{font:14px system-ui;margin:24px;background:#14110c;color:#f3ead4}td,th{padding:4px 10px;text-align:left;border-bottom:1px solid #3d3426}a{color:#e6b35c}</style><h1>Firebreak scores (latest 300)</h1><table><tr><th>id</th><th>name</th><th>score</th><th>mode</th><th>stages</th><th>version</th><th>when (UTC)</th><th></th></tr>${rows}</table>`,
    { headers: { "content-type": "text/html; charset=utf-8", "cache-control": "no-store" } });
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    try {
      if (url.pathname === "/api/top" && request.method === "GET") {
        return json({ ok: true, min: parseInt(env.MIN_SCORE || "2000", 10), mode: "campaign", scores: await top(env) });
      }
      if (url.pathname === "/api/submit" && request.method === "POST") return await submit(request, env);
      if (url.pathname.startsWith("/admin")) return await admin(url, env);
      if (url.pathname === "/" || url.pathname === "/index.html") {
        return new Response(PAGE, { headers: { "content-type": "text/html; charset=utf-8", "cache-control": "public, max-age=300" } });
      }
      return new Response("Not found", { status: 404 });
    } catch (err) {
      return json({ ok: false, error: "server error" }, 500);
    }
  },
};

const PAGE = `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Firebreak - Global Top 100</title>
<meta name="description" content="The global top 100 players of Firebreak, the gallery shooter by QuietByte.">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Oswald:wght@500;700&family=Special+Elite&display=swap" rel="stylesheet">
<style>
  :root { --ink: #f4ecd8; --dim: #b9a07a; --gold: #e6b35c; --ember: #c45a2a; --leaf: #6d8a4e; }
  * { box-sizing: border-box; }
  body { margin: 0; min-height: 100vh; color: var(--ink); font-family: "Oswald", system-ui, sans-serif;
    background:
      radial-gradient(900px 500px at 50% -10%, rgba(196, 90, 42, 0.28) 0%, transparent 55%),
      radial-gradient(800px 600px at 100% 100%, rgba(40, 70, 28, 0.45) 0%, transparent 50%),
      #12100b; }
  .wrap { max-width: 880px; margin: 0 auto; padding: 36px 18px 60px; }
  header { text-align: center; }
  h1 { font-family: "Special Elite", "Oswald", serif; font-size: clamp(48px, 11vw, 100px); line-height: 0.95; margin: 0; letter-spacing: 4px;
    color: var(--gold); text-shadow: 0 3px 0 #3a220c, 0 0 22px rgba(196, 90, 42, 0.45); }
  .sub { font-family: "Special Elite", serif; font-size: clamp(16px, 3.4vw, 24px); color: var(--leaf); letter-spacing: 4px; margin-top: 8px; }
  .rule { height: 3px; border-radius: 3px; margin: 18px auto 28px; width: min(520px, 80%);
    background: linear-gradient(90deg, transparent, var(--ember), var(--gold), var(--leaf), transparent); }
  ol { list-style: none; margin: 0; padding: 0; display: grid; gap: 8px; }
  li { display: grid; grid-template-columns: 64px 1fr auto; align-items: center; gap: 12px; padding: 10px 16px; border-radius: 6px;
    background: linear-gradient(90deg, rgba(196, 90, 42, 0.16), rgba(109, 138, 78, 0.08)); border: 1px solid rgba(230, 179, 92, 0.28); }
  .rank { font-family: "Special Elite", serif; font-size: 22px; color: var(--dim); }
  .who { min-width: 0; }
  .name { font-size: 20px; letter-spacing: 1px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
  .stage { font-size: 12px; color: var(--dim); letter-spacing: 1px; margin-top: 2px; }
  .score { font-family: "Special Elite", serif; font-size: 24px; color: var(--gold); font-variant-numeric: tabular-nums; text-shadow: 0 0 12px rgba(230, 179, 92, 0.35); }
  li.top1 { border-color: var(--gold); background: linear-gradient(90deg, rgba(230, 179, 92, 0.28), rgba(196, 90, 42, 0.14)); box-shadow: 0 0 26px rgba(230, 179, 92, 0.22); }
  li.top1 .rank, li.top1 .score { color: var(--gold); }
  li.top2 { border-color: #c8c0b0; } li.top2 .rank { color: #e6e0d4; }
  li.top3 { border-color: #c47a3a; } li.top3 .rank { color: #e39a5a; }
  li.top1 .name { font-size: 26px; } li.top1 .score { font-size: 32px; }
  .empty, .note { text-align: center; color: var(--dim); font-size: 14px; line-height: 1.7; font-family: "Special Elite", serif; }
  .empty { padding: 40px 10px; font-size: 16px; }
  .note { margin-top: 30px; }
  a { color: var(--gold); }
  @media (max-width: 520px) { li { grid-template-columns: 44px 1fr auto; padding: 9px 12px; } .score { font-size: 18px; } .name { font-size: 16px; } li.top1 .score { font-size: 22px; } li.top1 .name { font-size: 19px; } }
  @media (prefers-reduced-motion: no-preference) { li.top1 { animation: glow 2.4s ease-in-out infinite; }
    @keyframes glow { 50% { box-shadow: 0 0 40px rgba(230, 179, 92, 0.4); } } }
</style>
</head>
<body>
<div class="wrap">
  <header>
    <h1>FIREBREAK</h1>
    <div class="sub">GLOBAL TOP 100</div>
    <div class="rule"></div>
  </header>
  <main><ol id="list" aria-live="polite"></ol><div class="empty" id="empty" hidden></div></main>
  <p class="note" id="note"></p>
  <p class="note">Firebreak is a free gallery shooter by QuietByte for Linux.
    <a href="https://github.com/quietbytehq/firebreak/releases">Download it</a> and put your name here.<br>
    Only the name a player types and their campaign score are shown. Scores are not verified.</p>
</div>
<script>
  const list = document.getElementById("list"), empty = document.getElementById("empty"), note = document.getElementById("note");
  async function load() {
    try {
      const res = await fetch("/api/top");
      const data = await res.json();
      list.replaceChildren(...data.scores.map((s) => {
        const li = document.createElement("li");
        if (s.rank <= 3) li.className = "top" + s.rank;
        const rank = document.createElement("div"); rank.className = "rank"; rank.textContent = "#" + s.rank;
        const who = document.createElement("div"); who.className = "who";
        const name = document.createElement("div"); name.className = "name"; name.textContent = s.name;
        const stage = document.createElement("div"); stage.className = "stage";
        stage.textContent = "STAGE " + String(s.stages);
        who.append(name, stage);
        const score = document.createElement("div"); score.className = "score"; score.textContent = s.score.toLocaleString("en-GB");
        li.append(rank, who, score);
        return li;
      }));
      empty.hidden = data.scores.length > 0;
      empty.textContent = "No scores here yet. Be the first!";
      note.textContent = "Score " + data.min.toLocaleString("en-GB") + " or more in the game to get on the board.";
    } catch (e) {
      empty.hidden = false; empty.textContent = "The scoreboard could not be loaded. Please try again in a moment.";
    }
  }
  load();
  setInterval(load, 60000);
</script>
</body>
</html>`;
