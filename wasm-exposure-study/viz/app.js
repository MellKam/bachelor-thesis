/* Wasm Exposure Ratings: charts over results/rating/rating.json (via data.js).
 * Plain D3 v7, classic scripts so it opens from file://. Every number on the page
 * comes from window.RATING; headlines that quote numbers are built from it too. */
(() => {
  'use strict';
  const R = window.RATING;

  // ---------------------------------------------------------------- data
  const NF = R.features.length;
  const langs = [...R.languages].sort((a, b) => b.score - a.score); // one fixed order everywhere
  const NL = langs.length;
  const LANG = new Map(R.languages.map((l) => [l.id, l]));
  const FEAT = new Map(R.features.map((f) => [f.id, f]));
  const CELL = new Map(R.cells.map((c) => [`${c.language}:${c.feature}`, c]));
  const cellOf = (lang, feat) => CELL.get(`${lang}:${feat}`);
  const VERSIONS = ['1.0', '2.0', '3.0'];
  const clean = (s) => s.replace(/`/g, '');
  const f2 = d3.format('.2f');
  const f0 = d3.format(',d');
  const num = (v) => (v == null ? '–' : f2(v));
  const joinNames = (xs) => (xs.length < 2 ? xs.join('') : `${xs.slice(0, -1).join(', ')} and ${xs[xs.length - 1]}`);
  const totalWeight = d3.sum(R.features, (f) => f.weight);

  // Where each language's points go. Per cell the ideal is 1; the shortfall is
  // absent (all of it), partial reach, or obstacles (what is left of what was reached).
  function decompose(l) {
    let kept = 0, partial = 0, obstacles = 0, absent = 0;
    for (const f of R.features) {
      const c = cellOf(l.id, f.id);
      if (c.status === 'reached') {
        kept += f.weight * c.score;
        partial += f.weight * (1 - c.support);
        obstacles += f.weight * c.support * (1 - c.directness);
      } else absent += f.weight;
    }
    const s = (v) => v / totalWeight;
    return { kept: s(kept), partial: s(partial), obstacles: s(obstacles), absent: s(absent) };
  }
  const LOSS = new Map(langs.map((l) => [l.id, decompose(l)]));
  for (const l of langs) {
    if (Math.abs(LOSS.get(l.id).kept - l.score) > 2e-3) console.warn('score mismatch for', l.id, LOSS.get(l.id).kept, l.score);
  }

  const obstacleKinds = R.coefficients.obstacles; // already ordered mild -> harsh
  const obstacleCells = (langId, kind) =>
    R.cells.filter((c) => c.language === langId && c.status === 'reached' && c.obstacles.includes(kind));

  // ---------------------------------------------------------------- dom helpers
  const $ = (sel) => document.querySelector(sel);
  const el = (tag, cls, text) => {
    const n = document.createElement(tag);
    if (cls) n.className = cls;
    if (text != null) n.textContent = text;
    return n;
  };
  const css = (name) => getComputedStyle(document.documentElement).getPropertyValue(name).trim();
  const setText = (sel, text) => { $(sel).textContent = text; };

  function lum(c) {
    const f = (v) => { v /= 255; return v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4; };
    return 0.2126 * f(c.r) + 0.7152 * f(c.g) + 0.0722 * f(c.b);
  }
  // white or near-black text, whichever reads better on the fill
  function inkOn(fill) {
    const L = lum(d3.rgb(fill));
    return (1.05) / (L + 0.05) > (L + 0.05) / 0.056 ? '#ffffff' : '#0b0b0b';
  }

  // ---------------------------------------------------------------- tooltip
  const tip = $('#tip');
  function tipShow(c, x, y) {
    tip.replaceChildren(el('div', 't-title', c.title));
    for (const r of c.rows || []) {
      const row = el('div', 't-row');
      row.append(el('b', null, r.v), el('span', null, r.l));
      tip.append(row);
    }
    if (c.note) tip.append(el('div', 't-note', c.note));
    tip.hidden = false;
    const w = tip.offsetWidth, h = tip.offsetHeight;
    let tx = x + 14, ty = y + 14;
    if (tx + w > innerWidth - 8) tx = Math.max(8, x - w - 14);
    if (ty + h > innerHeight - 8) ty = Math.max(8, y - h - 14);
    tip.style.left = `${tx}px`;
    tip.style.top = `${ty}px`;
  }
  const tipHide = () => { tip.hidden = true; };
  // Hover and keyboard focus show the same thing.
  function tipBind(sel, fn) {
    sel
      .on('pointerenter pointermove', (ev, d) => tipShow(fn(d), ev.clientX, ev.clientY))
      .on('pointerleave', tipHide)
      .on('focus', function (ev, d) {
        const r = this.getBoundingClientRect();
        tipShow(fn(d), r.left + r.width / 2, r.bottom - 6);
      })
      .on('blur', tipHide);
  }

  // ---------------------------------------------------------------- shared pieces
  function makeSvg(host, w, h, label) {
    return d3.select(host).append('svg')
      .attr('width', w).attr('height', h).attr('viewBox', `0 0 ${w} ${h}`)
      .attr('role', 'img').attr('aria-label', label);
  }

  function legend(host, items) {
    host.replaceChildren();
    for (const it of items) {
      const s = el('span');
      const sw = el('i', it.kind || '');
      if (it.fill) sw.style.background = it.fill;
      if (it.ramp) sw.style.background = it.ramp;
      if (it.pattern) sw.style.background = `url("data:image/svg+xml,${encodeURIComponent(it.pattern)}")`;
      if (it.border) sw.style.boxShadow = `inset 0 0 0 1px ${it.border}`;
      s.append(sw, document.createTextNode(it.label));
      host.append(s);
    }
  }
  const patternSwatch = (kind) =>
    kind === 'dots'
      ? `<svg xmlns="http://www.w3.org/2000/svg" width="6" height="6"><rect width="6" height="6" fill="${css('--surface')}"/><circle cx="3" cy="3" r="1.2" fill="${css('--hatch')}"/></svg>`
      : `<svg xmlns="http://www.w3.org/2000/svg" width="6" height="6"><rect width="6" height="6" fill="${css('--surface')}"/><path d="M-1 1L1 -1M0 6L6 0M5 7L7 5" stroke="${css('--hatch')}" stroke-width="2"/></svg>`;

  function tableView(host, caption, headers, rows) {
    host.replaceChildren();
    const d = el('details', 'tv');
    d.append(el('summary', null, 'View as table'));
    const scroll = el('div', 'tv-scroll');
    const t = el('table');
    t.append(el('caption', 'vh', caption));
    const head = el('tr');
    for (const h of headers) { const th = el('th', null, h); th.scope = 'col'; head.append(th); }
    const thead = el('thead');
    thead.append(head);
    t.append(thead);
    const body = el('tbody');
    for (const r of rows) {
      const tr = el('tr');
      r.forEach((v, i) => {
        const td = el(i === 0 ? 'th' : 'td', null, String(v));
        if (i === 0) td.scope = 'row';
        tr.append(td);
      });
      body.append(tr);
    }
    t.append(body);
    scroll.append(t);
    d.append(scroll);
    host.append(d);
  }

  const roundedRight = (x, y, w, h, r) => {
    r = Math.min(r, w, h / 2);
    return `M${x},${y}H${x + w - r}A${r},${r} 0 0 1 ${x + w},${y + r}V${y + h - r}A${r},${r} 0 0 1 ${x + w - r},${y + h}H${x}Z`;
  };

  // Horizontal stack: 2px surface gap between fills, 4px rounded data-end.
  function drawStack(g, segs, x0, y, h, unit) {
    const live = segs.filter((s) => s.value > 0);
    let x = x0;
    live.forEach((s, i) => {
      const full = s.value * unit;
      const w = i === live.length - 1 ? full : Math.max(0, full - 2);
      if (w <= 0) { x += full; return; }
      g.append('path').attr('d', roundedRight(x, y, w, h, i === live.length - 1 ? 4 : 0)).attr('fill', s.fill);
      const text = s.label ?? '';
      if (text && w >= text.length * 7 + 12) {
        const t = g.append('text').attr('x', x + w / 2).attr('y', y + h / 2 + 4).attr('text-anchor', 'middle')
          .style('font-weight', 600).text(text);
        if (s.halo) t.style('fill', css('--ink')).style('paint-order', 'stroke').style('stroke', css('--surface')).style('stroke-width', '3px');
        else t.style('fill', inkOn(s.fill));
      }
      x += full;
    });
  }

  // ---------------------------------------------------------------- language filter (emphasis, not filtering)
  const focusStyle = document.head.appendChild(el('style'));
  function setFocus(id) {
    focusStyle.textContent = id ? `svg [data-lang]:not([data-lang="${id}"]) { opacity: 0.2; }` : '';
    for (const b of document.querySelectorAll('.chip')) b.setAttribute('aria-pressed', String((b.dataset.id || '') === (id || '')));
  }
  function buildChips() {
    const host = $('#chips');
    host.append(el('span', 'chips-label', 'Highlight'));
    for (const l of [{ id: '', name: 'All' }, ...langs]) {
      const b = el('button', 'chip', l.name);
      b.type = 'button';
      b.dataset.id = l.id;
      b.setAttribute('aria-pressed', l.id === '' ? 'true' : 'false');
      b.addEventListener('click', () => setFocus(b.getAttribute('aria-pressed') === 'true' ? '' : l.id));
      host.append(b);
    }
  }

  // ---------------------------------------------------------------- 1 · coverage (counts)
  const BUCKETS = [
    { key: 'noObstacle', label: 'Reached, no obstacle', fill: () => css('--ord-0') },
    { key: 'oneObstacle', label: 'Reached, 1 obstacle', fill: () => css('--ord-1') },
    { key: 'twoOrMoreObstacles', label: 'Reached, 2+ obstacles', fill: () => css('--ord-2') },
    { key: 'absentConfirmed', label: 'Absent, confirmed', fill: () => css('--absent') },
    { key: 'absentNotFound', label: 'Absent, not found', fill: () => 'url(#hatch)', halo: true },
  ];

  function renderCoverage() {
    const host = $('#chart-coverage');
    host.replaceChildren();
    legend($('#leg-coverage'), [
      { label: BUCKETS[0].label, fill: css('--ord-0') },
      { label: BUCKETS[1].label, fill: css('--ord-1') },
      { label: BUCKETS[2].label, fill: css('--ord-2') },
      { label: BUCKETS[3].label, fill: css('--absent') },
      { label: 'Absent, not found (uncertain)', pattern: patternSwatch('hatch'), border: css('--axis') },
    ]);
    const w = host.clientWidth;
    const labelW = Math.min(118, Math.max(78, w * 0.2));
    const rightW = w < 520 ? 0 : 78;
    const rowH = 40, barH = 24;
    const x0 = labelW, x1 = w - rightW - 4;
    const svg = makeSvg(host, w, rowH * NL, 'Stacked bars: each language\'s 30 features by outcome');
    const unit = (x1 - x0) / NF;
    langs.forEach((l, i) => {
      const g = svg.append('g').attr('transform', `translate(0,${i * rowH})`).attr('data-lang', l.id)
        .attr('class', 'hover-row').attr('tabindex', 0)
        .attr('aria-label', `${l.name}: ${l.counts.reached} of ${NF} reached, ${l.counts.noObstacle} without obstacle, ${l.counts.absentConfirmed + l.counts.absentNotFound} absent`);
      g.append('rect').attr('class', 'hit').attr('x', 0).attr('y', 0).attr('width', w).attr('height', rowH).attr('rx', 6);
      g.append('text').attr('class', 't-strong').attr('x', 8).attr('y', rowH / 2 + 4).text(l.name);
      drawStack(g, BUCKETS.map((b) => ({
        value: l.counts[b.key], fill: b.fill(), label: String(l.counts[b.key]), halo: b.halo,
      })), x0, (rowH - barH) / 2, barH, unit);
      if (rightW) g.append('text').attr('x', w - 4).attr('y', rowH / 2 + 4).attr('text-anchor', 'end')
        .text(`${l.counts.reached} reached`);
      tipBind(g.datum(l), (d) => ({
        title: `${d.name} · ${NF} features probed`,
        rows: [
          { v: d.counts.noObstacle, l: 'reached, no obstacle' },
          { v: d.counts.oneObstacle, l: 'reached, one obstacle' },
          { v: d.counts.twoOrMoreObstacles, l: 'reached, two or more obstacles' },
          { v: d.counts.absentConfirmed, l: 'absent, confirmed' },
          { v: d.counts.absentNotFound, l: 'absent, not found' },
        ],
        note: `${d.counts.full} reached in full, ${d.counts.checked} checked by the compiler. Of the ${d.counts.absentNotFound} not-found cells, ${d.counts.neverProbed} rest on an ABSENT.md and were never probed.`,
      }));
    });
  }

  // ---------------------------------------------------------------- 2 · score + rank robustness
  function renderScore() {
    const hostS = $('#chart-score'), hostR = $('#chart-rank');
    hostS.replaceChildren(); hostR.replaceChildren();
    const rowH = 40, barH = 22, axisH = 40;
    const wide = matchMedia('(min-width: 760px)').matches;
    const s1 = css('--s1');

    // score bars
    {
      const w = hostS.clientWidth;
      const labelW = Math.min(118, Math.max(78, w * 0.22));
      const x = d3.scaleLinear([0, 1], [labelW, w - 44]);
      const svg = makeSvg(hostS, w, rowH * NL + axisH, 'Bar chart: score per language');
      for (const t of [0, 0.25, 0.5, 0.75, 1]) {
        svg.append('line').attr('class', 'grid').attr('x1', x(t)).attr('x2', x(t)).attr('y1', 0).attr('y2', rowH * NL);
        svg.append('text').attr('class', 't-muted').attr('x', x(t)).attr('y', rowH * NL + 18).attr('text-anchor', 'middle').text(t === 0 || t === 1 ? t : f2(t));
      }
      svg.append('line').attr('class', 'axis').attr('x1', x(0)).attr('x2', x(0)).attr('y1', 0).attr('y2', rowH * NL);
      langs.forEach((l, i) => {
        const g = svg.append('g').attr('transform', `translate(0,${i * rowH})`).attr('data-lang', l.id)
          .attr('class', 'hover-row').attr('tabindex', 0).attr('aria-label', `${l.name}: score ${num(l.score)}`);
        g.append('rect').attr('class', 'hit').attr('width', w).attr('height', rowH).attr('rx', 6);
        g.append('text').attr('class', 't-strong').attr('x', 8).attr('y', rowH / 2 + 4).text(l.name);
        g.append('path').attr('d', roundedRight(x(0), (rowH - barH) / 2, x(l.score) - x(0), barH, 4)).attr('fill', s1);
        g.append('text').attr('class', 't-ink').attr('x', x(l.score) + 8).attr('y', rowH / 2 + 4).style('font-weight', 600).text(num(l.score));
        tipBind(g.datum(l), scoreTip);
      });
    }

    // rank range
    {
      const w = hostR.clientWidth;
      const labelW = wide ? 6 : Math.min(118, Math.max(78, w * 0.22));
      const x = d3.scaleLinear([0.5, NL + 0.5], [labelW, w - 8]);
      const svg = makeSvg(hostR, w, rowH * NL + axisH, 'Range of ranks each language took across 2000 perturbed runs');
      for (let r = 1; r <= NL; r++) {
        svg.append('line').attr('class', 'grid').attr('x1', x(r)).attr('x2', x(r)).attr('y1', 0).attr('y2', rowH * NL);
        svg.append('text').attr('class', 't-muted').attr('x', x(r)).attr('y', rowH * NL + 18).attr('text-anchor', 'middle').text(r);
      }
      langs.forEach((l, i) => {
        const g = svg.append('g').attr('transform', `translate(0,${i * rowH})`).attr('data-lang', l.id)
          .attr('class', 'hover-row').attr('tabindex', 0)
          .attr('aria-label', `${l.name}: rank ${l.scoreRank.best} to ${l.scoreRank.worst}, mean ${l.scoreRank.mean.toFixed(1)}`);
        g.append('rect').attr('class', 'hit').attr('width', w).attr('height', rowH).attr('rx', 6);
        if (!wide) g.append('text').attr('class', 't-strong').attr('x', 8).attr('y', rowH / 2 + 4).text(l.name);
        const a = x(l.scoreRank.best - 0.34), b = x(l.scoreRank.worst + 0.34);
        g.append('rect').attr('x', a).attr('y', rowH / 2 - 7).attr('width', b - a).attr('height', 14).attr('rx', 7)
          .attr('fill', s1).attr('fill-opacity', 0.3);
        g.append('circle').attr('cx', x(l.scoreRank.mean)).attr('cy', rowH / 2).attr('r', 5).attr('fill', s1)
          .style('stroke', css('--surface')).style('stroke-width', '2px');
        tipBind(g.datum(l), scoreTip);
      });
      svg.append('text').attr('class', 't-muted').attr('x', (x(0.5) + x(NL + 0.5)) / 2).attr('y', rowH * NL + 36).attr('text-anchor', 'middle')
        .text('rank (1 = highest score) · bar = best to worst · dot = mean');
    }
  }
  function scoreTip(l) {
    return {
      title: l.name,
      rows: [
        { v: num(l.score), l: 'score' },
        { v: l.scoreRank.best === l.scoreRank.worst ? `${l.scoreRank.best}` : `${l.scoreRank.best}–${l.scoreRank.worst}`, l: 'rank over 2,000 perturbed runs' },
        { v: l.scoreRank.mean.toFixed(2), l: 'mean rank' },
      ],
    };
  }

  // ---------------------------------------------------------------- 3 · where the points go
  const LOSS_PARTS = [
    { key: 'kept', label: 'Kept: the score', fill: () => css('--s1') },
    { key: 'obstacles', label: 'Lost to obstacles', fill: () => css('--s2') },
    { key: 'partial', label: 'Lost to partial reach', fill: () => css('--s3') },
    { key: 'absent', label: 'Lost to absence', fill: () => css('--absent') },
  ];
  function renderLoss() {
    const host = $('#chart-loss');
    host.replaceChildren();
    legend($('#leg-loss'), LOSS_PARTS.map((p) => ({ label: p.label, fill: p.fill() })));
    const w = host.clientWidth;
    const labelW = Math.min(118, Math.max(78, w * 0.2));
    const rowH = 40, barH = 24;
    const x1 = w - 8;
    const svg = makeSvg(host, w, rowH * NL, 'Stacked bars: score kept and points lost to obstacles, partial reach and absence');
    langs.forEach((l, i) => {
      const d = LOSS.get(l.id);
      const g = svg.append('g').attr('transform', `translate(0,${i * rowH})`).attr('data-lang', l.id)
        .attr('class', 'hover-row').attr('tabindex', 0)
        .attr('aria-label', `${l.name}: keeps ${num(d.kept)}, loses ${num(d.obstacles)} to obstacles, ${num(d.partial)} to partial reach, ${num(d.absent)} to absence`);
      g.append('rect').attr('class', 'hit').attr('width', w).attr('height', rowH).attr('rx', 6);
      g.append('text').attr('class', 't-strong').attr('x', 8).attr('y', rowH / 2 + 4).text(l.name);
      drawStack(g, LOSS_PARTS.map((p) => ({ value: d[p.key], fill: p.fill(), label: f2(d[p.key]) })),
        labelW, (rowH - barH) / 2, barH, x1 - labelW);
      tipBind(g.datum(l), () => ({
        title: `${l.name}: where the points went`,
        rows: LOSS_PARTS.map((p) => ({ v: f2(d[p.key]), l: p.label.replace('Kept: the score', 'kept (the score)').replace('Lost', 'lost') })),
        note: 'Shares of the best possible weighted result; the four add up to 1.',
      }));
    });
  }

  // ---------------------------------------------------------------- 4 · trade-offs
  function placeLabels(items, dots, W) {
    const placed = dots.map((d) => ({ x: d.x - 8, y: d.y - 8, w: 16, h: 16 }));
    const offs = [[11, 4, 'start'], [-11, 4, 'end'], [0, -11, 'middle'], [0, 20, 'middle']];
    const hit = (a, b) => a.x < b.x + b.w && b.x < a.x + a.w && a.y < b.y + b.h && b.y < a.y + a.h;
    for (const it of items) {
      const tw = it.text.length * 6.6 + 4;
      let chosen = null;
      for (const [dx, dy, anchor] of offs) {
        const bx = anchor === 'start' ? it.x + dx : anchor === 'end' ? it.x + dx - tw : it.x + dx - tw / 2;
        const box = { x: bx, y: it.y + dy - 11, w: tw, h: 14 };
        if (bx < 0 || bx + tw > W) continue;
        if (!placed.some((p) => hit(p, box))) { chosen = { dx, dy, anchor, box }; break; }
      }
      chosen = chosen || { dx: 11, dy: 4, anchor: 'start', box: { x: it.x + 11, y: it.y - 7, w: tw, h: 14 } };
      placed.push(chosen.box);
      it.dx = chosen.dx; it.dy = chosen.dy; it.anchor = chosen.anchor;
    }
  }

  function scatter(host, o) {
    host.replaceChildren();
    const w = host.clientWidth, h = Math.min(360, Math.max(280, w * 0.78));
    const m = { l: 44, r: 14, t: o.iso ? 40 : 26, b: 42 };
    const x = d3.scaleLinear(o.xDomain, [m.l, w - m.r]);
    const y = d3.scaleLinear(o.yDomain, [h - m.b, m.t]);
    const svg = makeSvg(host, w, h, o.label);
    for (const t of o.yTicks) {
      svg.append('line').attr('class', 'grid').attr('x1', m.l).attr('x2', w - m.r).attr('y1', y(t)).attr('y2', y(t));
      svg.append('text').attr('class', 't-muted').attr('x', m.l - 8).attr('y', y(t) + 4).attr('text-anchor', 'end').text(f2(t));
    }
    for (const t of o.xTicks) {
      svg.append('line').attr('class', 'grid').attr('x1', x(t)).attr('x2', x(t)).attr('y1', m.t).attr('y2', h - m.b);
      svg.append('text').attr('class', 't-muted').attr('x', x(t)).attr('y', h - m.b + 16).attr('text-anchor', 'middle').text(f2(t));
    }
    svg.append('line').attr('class', 'axis').attr('x1', m.l).attr('x2', w - m.r).attr('y1', h - m.b).attr('y2', h - m.b);
    svg.append('line').attr('class', 'axis').attr('x1', m.l).attr('x2', m.l).attr('y1', m.t).attr('y2', h - m.b);
    svg.append('text').attr('class', 't-muted').attr('x', (m.l + w - m.r) / 2).attr('y', h - 6).attr('text-anchor', 'middle').text(o.xTitle);
    svg.append('text').attr('class', 't-muted').attr('x', 0).attr('y', 11).text(o.yTitle);
    if (o.iso) o.iso(svg, x, y, m);
    const pts = langs.map((l) => ({ l, x: x(l.support), y: y(o.yOf(l)), text: l.name }));
    placeLabels(pts, pts, w - 4);
    for (const p of pts) {
      const g = svg.append('g').attr('data-lang', p.l.id).attr('class', 'dot').attr('tabindex', 0)
        .attr('aria-label', `${p.l.name}: support ${num(p.l.support)}, ${o.yName} ${num(o.yOf(p.l))}`);
      g.append('circle').attr('class', 'hit').attr('cx', p.x).attr('cy', p.y).attr('r', 14);
      g.append('circle').attr('class', 'mark').attr('cx', p.x).attr('cy', p.y).attr('r', 5.5).attr('fill', css('--s1'))
        .style('stroke', css('--surface')).style('stroke-width', '2px');
      g.append('text').attr('class', 't-ink').attr('x', p.x + p.dx).attr('y', p.y + p.dy).attr('text-anchor', p.anchor)
        .style('font-weight', 600).text(p.text);
      tipBind(g.datum(p.l), (l) => ({
        title: l.name,
        rows: [
          { v: num(l.support), l: 'support' },
          { v: num(o.yOf(l)), l: o.yName },
          { v: num(l.score), l: 'score' },
        ],
      }));
    }
  }

  function renderTradeoffs() {
    scatter($('#chart-sd'), {
      label: 'Scatter: support against directness, with curves of equal score',
      xDomain: [0.2, 1], yDomain: [0.7, 1], xTicks: [0.2, 0.4, 0.6, 0.8, 1], yTicks: [0.7, 0.8, 0.9, 1],
      xTitle: 'Support: how much of the feature set it can produce →', yTitle: '↑ Directness (axis starts at 0.70)',
      yName: 'directness', yOf: (l) => l.directness,
      iso(svg, x, y, m) {
        for (const s of [0.3, 0.4, 0.5, 0.6, 0.7]) {
          const pts = d3.range(s, Math.min(1, s / 0.7) + 1e-9, 0.005).map((xv) => [x(xv), y(s / xv)]);
          svg.append('path').attr('d', d3.line()(pts)).attr('fill', 'none').attr('class', 'axis').style('stroke-width', '1px');
          svg.append('text').attr('class', 't-muted').attr('x', x(s)).attr('y', m.t - 7).attr('text-anchor', 'middle').text(s === 0.3 ? `score ${f2(s)}` : f2(s));
        }
      },
    });
    scatter($('#chart-sc'), {
      label: 'Scatter: support against the share of reached features checked by the compiler',
      xDomain: [0.2, 1], yDomain: [0.4, 1], xTicks: [0.2, 0.4, 0.6, 0.8, 1], yTicks: [0.4, 0.6, 0.8, 1],
      xTitle: 'Support: how much of the feature set it can produce →', yTitle: '↑ Checked (axis starts at 0.40)',
      yName: 'checked', yOf: (l) => l.checked,
    });
  }

  // ---------------------------------------------------------------- 5 · spec versions
  function seqScale(prefix) {
    const stops = [0, 1, 2, 3, 4].map((i) => css(`--${prefix}-${i}`));
    return d3.scaleLinear().domain([0, 0.25, 0.5, 0.75, 1]).range(stops).interpolate(d3.interpolateRgb).clamp(true);
  }
  function rampCss(prefix) {
    return `linear-gradient(90deg, ${[0, 1, 2, 3, 4].map((i) => css(`--${prefix}-${i}`)).join(', ')})`;
  }

  function renderVersions() {
    const host = $('#chart-versions');
    host.replaceChildren();
    const lg = $('#leg-versions');
    lg.replaceChildren();
    const lo = el('span', null, '0'), hi = el('span', null, '1 (score)');
    const r = el('i', 'ramp'); r.style.background = rampCss('blue');
    lg.append(lo, r, hi);

    const scale = seqScale('blue');
    const w = host.clientWidth;
    const labelW = Math.min(118, Math.max(78, w * 0.2));
    const cols = [...VERSIONS.map((v) => ({ id: v, title: `Spec ${v}` })), { id: 'all', title: 'All 30' }];
    const gap = 6;
    const colW = (w - labelW - gap * (cols.length - 1) - 4) / cols.length;
    const headH = 44, rowH = 52, cellH = 46;
    const svg = makeSvg(host, w, headH + rowH * NL, 'Heatmap: score per language and spec version');
    cols.forEach((c, j) => {
      const cx = labelW + j * (colW + gap) + colW / 2;
      svg.append('text').attr('class', 't-strong').attr('x', cx).attr('y', 16).attr('text-anchor', 'middle').text(c.title);
      const n = c.id === 'all' ? NF : R.features.filter((f) => f.since === c.id).length;
      svg.append('text').attr('class', 't-muted').attr('x', cx).attr('y', 32).attr('text-anchor', 'middle').text(`${n} features`);
    });
    langs.forEach((l, i) => {
      const g = svg.append('g').attr('transform', `translate(0,${headH + i * rowH})`).attr('data-lang', l.id);
      g.append('text').attr('class', 't-strong').attr('x', 8).attr('y', cellH / 2 + 4).text(l.name);
      cols.forEach((c, j) => {
        const d = c.id === 'all' ? l : { ...l.bySpecVersion[c.id] };
        const reached = d.reached, features = d.features;
        const fill = scale(d.score);
        const ink = inkOn(fill);
        const cell = g.append('g').attr('class', 'cell').attr('tabindex', 0)
          .attr('aria-label', `${l.name}, ${c.title}: score ${num(d.score)}, ${reached} of ${features} features reached`);
        const cx0 = labelW + j * (colW + gap);
        cell.append('rect').attr('class', 'fill').attr('x', cx0).attr('y', 0).attr('width', colW).attr('height', cellH).attr('rx', 6).attr('fill', fill);
        cell.append('text').attr('x', cx0 + colW / 2).attr('y', cellH / 2 - 1).attr('text-anchor', 'middle')
          .style('font-size', '16px').style('font-weight', 650).style('fill', ink).text(num(d.score));
        cell.append('text').attr('x', cx0 + colW / 2).attr('y', cellH / 2 + 15).attr('text-anchor', 'middle')
          .style('font-size', '11px').style('fill', ink).text(`${reached}/${features} reached`);
        tipBind(cell.datum({ l, c, d }), ({ l, c, d }) => ({
          title: `${l.name} · ${c.title}`,
          rows: [
            { v: num(d.score), l: 'score' },
            { v: num(d.support), l: 'support' },
            { v: num(d.checked), l: 'checked' },
            { v: num(d.directness), l: 'directness' },
          ],
          note: `${d.reached} of ${d.features} features reached.`,
        }));
      });
    });
  }

  // ---------------------------------------------------------------- 6 · feature x language matrix
  const ABSENT_GLYPH = { confirmed: '×', 'not found': '?', never: '○' };
  const absentKind = (c) => (c.absent === 'confirmed' ? 'confirmed' : c.neverProbed ? 'never' : 'not found');
  const ABSENT_TEXT = {
    confirmed: 'Absent: confirmed, the language has no way to express it',
    'not found': 'Absent: probed, no way found (could still exist)',
    never: 'Absent: never probed, rests on an ABSENT.md only',
  };

  function cellTip(c) {
    const l = LANG.get(c.language), title = `${l.name} · ${clean(c.featureName)}`;
    if (c.status !== 'reached') {
      const k = absentKind(c);
      return { title, rows: [{ v: ABSENT_GLYPH[k], l: ABSENT_TEXT[k] }], note: `Spec ${c.since} · importance ${c.weight}` };
    }
    const rows = [
      { v: num(c.score), l: 'cell score' },
      { v: c.support === 1 ? 'full' : 'partial', l: 'reach' },
      { v: c.checked ? 'yes' : 'no', l: 'checked by the compiler' },
      { v: c.expressedAs, l: `expressed as (variant: ${c.variant})` },
      { v: String(c.obstacles.length), l: c.obstacles.length ? `obstacles: ${c.obstacles.join(', ')}` : 'obstacles' },
    ];
    return { title, rows, note: [c.partial, `Spec ${c.since} · importance ${c.weight}`].filter(Boolean).join(' · ') };
  }

  function renderMatrix() {
    const host = $('#chart-matrix');
    host.replaceChildren();
    const scale = seqScale('blue');
    {
      const lg = $('#leg-matrix');
      lg.replaceChildren();
      const r = el('i', 'ramp'); r.style.background = rampCss('blue');
      lg.append(el('span', null, 'Cell score 0'), r, el('span', null, '1'));
      for (const [k, label, pat] of [
        ['confirmed', '× absent, confirmed', null],
        ['not found', '? absent, not found', 'hatch'],
        ['never', '○ absent, never probed', 'dots'],
      ]) {
        const s = el('span'), i = el('i');
        if (pat) i.style.background = `url("data:image/svg+xml,${encodeURIComponent(patternSwatch(pat))}")`;
        else i.style.background = css('--absent');
        i.style.boxShadow = `inset 0 0 0 1px ${css('--axis')}`;
        s.append(i, document.createTextNode(label));
        lg.append(s);
      }
    }

    const W = Math.max(host.clientWidth, 700);
    const labelW = Math.min(320, Math.max(210, W * 0.27));
    const reachW = 104;
    const colW = (W - labelW - reachW - 6) / NL;
    const slant = colW < 84;
    const headH = slant ? 66 : 38, rowH = 27, groupH = 34;

    // vertical layout
    let y = headH;
    const rows = [];
    for (const v of VERSIONS) {
      rows.push({ type: 'group', v, y });
      y += groupH;
      for (const f of R.features.filter((f) => f.since === v)) { rows.push({ type: 'feat', f, y }); y += rowH; }
    }
    const H = y + 4;
    const svg = makeSvg(host, W, H, 'Heatmap of cell scores: 30 features by 7 languages');

    // column headers + cells, one group per language so highlighting works
    const grid = [];
    langs.forEach((l, j) => {
      const cx = labelW + j * colW;
      const g = svg.append('g').attr('data-lang', l.id);
      const lab = g.append('text').attr('class', 't-strong');
      if (slant) lab.attr('transform', `translate(${cx + colW / 2 + 4},${headH - 10}) rotate(-38)`).text(l.name);
      else lab.attr('x', cx + colW / 2).attr('y', headH - 12).attr('text-anchor', 'middle').text(l.name);
      for (const r of rows.filter((r) => r.type === 'feat')) {
        const c = cellOf(l.id, r.f.id);
        const reached = c.status === 'reached';
        const kind = reached ? null : absentKind(c);
        const fill = reached ? scale(c.score) : kind === 'confirmed' ? css('--absent') : kind === 'not found' ? 'url(#hatch)' : 'url(#dots)';
        const cell = g.append('g').attr('class', 'cell').attr('tabindex', -1)
          .attr('aria-label', `${l.name}, ${clean(r.f.name)}: ${reached ? `score ${num(c.score)}` : ABSENT_TEXT[kind]}`);
        cell.append('rect').attr('class', 'fill').attr('x', cx + 1).attr('y', r.y + 1).attr('width', colW - 2).attr('height', rowH - 2).attr('rx', 4).attr('fill', fill);
        const t = cell.append('text').attr('x', cx + colW / 2).attr('y', r.y + rowH / 2 + 4).attr('text-anchor', 'middle').style('font-size', '11px');
        if (reached) t.style('fill', inkOn(scale(c.score))).text(c.score === 1 ? '1' : f2(c.score).replace(/^0/, ''));
        else t.style('fill', css('--ink')).style('font-weight', 600).style('paint-order', 'stroke')
          .style('stroke', kind === 'confirmed' ? 'none' : css('--surface')).style('stroke-width', '3px').text(ABSENT_GLYPH[kind]);
        tipBind(cell.datum(c), cellTip);
        (grid[r.f.id - 1] = grid[r.f.id - 1] || [])[j] = cell.node();
      }
    });

    // row labels, group headers, reach counts
    const reachX = labelW + NL * colW + 14;
    const rx = d3.scaleLinear([0, NL], [0, reachW - 50]);
    svg.append('text').attr('class', 't-muted').attr('x', 8).attr('y', headH - 12).text('Feature · importance');
    svg.append('text').attr('class', 't-muted').attr('x', reachX).attr('y', headH - 12).text('Reached by');
    const chars = Math.floor((labelW - 46) / 5.8);
    for (const r of rows) {
      if (r.type === 'group') {
        const n = R.features.filter((f) => f.since === r.v).length;
        svg.append('text').attr('class', 't-strong').attr('x', 8).attr('y', r.y + 22).text(`Spec ${r.v}`)
          .append('tspan').attr('class', 't-muted').attr('dx', 8).style('font-weight', 400).text(`${n} features`);
        svg.append('line').attr('class', 'grid').attr('x1', 0).attr('x2', W).attr('y1', r.y + 4).attr('y2', r.y + 4);
        continue;
      }
      const f = r.f, name = clean(f.name);
      for (let k = 0; k < 3; k++) {
        svg.append('circle').attr('cx', 12 + k * 9).attr('cy', r.y + rowH / 2).attr('r', 2.6)
          .attr('fill', k < f.weight ? css('--ink-3') : css('--grid'));
      }
      const row = svg.append('g').datum(f).attr('class', 'hover-row-label');
      row.append('title').text(`${name} (spec ${f.since}, importance ${f.weight} of 3)`);
      row.append('text').attr('x', 46).attr('y', r.y + rowH / 2 + 4).text(name.length > chars ? `${name.slice(0, chars - 1)}…` : name);
      const n = langs.filter((l) => cellOf(l.id, f.id).status === 'reached').length;
      svg.append('rect').attr('x', reachX).attr('y', r.y + rowH / 2 - 4).attr('width', Math.max(0, rx(n))).attr('height', 8).attr('rx', 2).attr('fill', css('--s1')).attr('fill-opacity', n ? 0.55 : 0);
      svg.append('text').attr('class', 't-muted').attr('x', reachX + rx(n) + 6).attr('y', r.y + rowH / 2 + 4).text(`${n}/${NL}`);
    }

    // roving tabindex: arrows move between cells
    const flat = grid.filter(Boolean);
    const spots = new Map();
    flat.forEach((row, i) => row.forEach((node, j) => spots.set(node, [i, j])));
    const first = flat[0][0];
    first.setAttribute('tabindex', 0);
    svg.node().addEventListener('keydown', (ev) => {
      const at = spots.get(ev.target);
      if (!at) return;
      const [i, j] = at;
      const d = { ArrowUp: [-1, 0], ArrowDown: [1, 0], ArrowLeft: [0, -1], ArrowRight: [0, 1] }[ev.key];
      if (!d) return;
      const next = flat[i + d[0]]?.[j + d[1]];
      if (!next) return;
      ev.preventDefault();
      ev.target.setAttribute('tabindex', -1);
      next.setAttribute('tabindex', 0);
      next.focus();
    });
  }

  // ---------------------------------------------------------------- 7 · obstacles
  function renderObstacles() {
    const host = $('#chart-obstacles');
    host.replaceChildren();
    const scale = seqScale('orange');
    const lg = $('#leg-obstacles');
    lg.replaceChildren();
    const r = el('i', 'ramp'); r.style.background = rampCss('orange');
    lg.append(el('span', null, 'Fewer features'), r, el('span', null, 'More features'));

    const W = Math.max(host.clientWidth, 660);
    const labelW = Math.min(230, Math.max(170, W * 0.25));
    const colW = (W - labelW - 4) / NL;
    const slant = colW < 84;
    const headH = slant ? 66 : 38, rowH = 36;
    const counts = obstacleKinds.map((k) => langs.map((l) => obstacleCells(l.id, k.kind)));
    const max = d3.max(counts.flat(), (a) => a.length) || 1;
    const svg = makeSvg(host, W, headH + rowH * obstacleKinds.length, 'Heatmap: number of reached features carrying each obstacle, per language');
    svg.append('text').attr('class', 't-muted').attr('x', 8).attr('y', headH - 12).text('Obstacle · factor on a cell\'s score');
    obstacleKinds.forEach((k, i) => {
      const row = svg.append('g').attr('class', 'hover-row').attr('tabindex', 0).datum(k)
        .attr('aria-label', `${k.kind}, factor ${k.factor}. ${k.why}`);
      row.append('rect').attr('class', 'hit').attr('x', 0).attr('y', headH + i * rowH).attr('width', labelW - 8).attr('height', rowH).attr('rx', 6);
      row.append('text').attr('class', 't-strong').attr('x', 8).attr('y', headH + i * rowH + rowH / 2 + 4).text(k.kind)
        .append('tspan').attr('class', 't-muted').attr('dx', 6).style('font-weight', 400).text(`×${k.factor.toFixed(2)}`);
      tipBind(row, (d) => ({ title: `${d.kind} · ×${d.factor.toFixed(2)}`, note: d.why }));
    });
    langs.forEach((l, j) => {
      const cx = labelW + j * colW;
      const g = svg.append('g').attr('data-lang', l.id);
      const lab = g.append('text').attr('class', 't-strong');
      if (slant) lab.attr('transform', `translate(${cx + colW / 2 + 4},${headH - 10}) rotate(-38)`).text(l.name);
      else lab.attr('x', cx + colW / 2).attr('y', headH - 12).attr('text-anchor', 'middle').text(l.name);
      obstacleKinds.forEach((k, i) => {
        const hits = counts[i][j], n = hits.length;
        const fill = n ? scale(0.12 + 0.88 * (n / max)) : 'none';
        const cell = g.append('g').attr('class', 'cell').attr('tabindex', 0)
          .attr('aria-label', `${l.name}, ${k.kind}: ${n} reached features`);
        cell.append('rect').attr('class', 'fill').attr('x', cx + 1).attr('y', headH + i * rowH + 1).attr('width', colW - 2).attr('height', rowH - 2).attr('rx', 4)
          .attr('fill', fill).style('stroke', n ? 'none' : css('--grid')).style('stroke-width', '1px');
        cell.append('text').attr('x', cx + colW / 2).attr('y', headH + i * rowH + rowH / 2 + 4).attr('text-anchor', 'middle')
          .style('font-size', '12px').style('font-weight', n ? 600 : 400).style('fill', n ? inkOn(fill) : css('--ink-3')).text(n || '');
        tipBind(cell.datum({ l, k, hits }), ({ l, k, hits }) => ({
          title: `${l.name} · ${k.kind}`,
          rows: [{ v: String(hits.length), l: `of ${l.counts.reached} reached features` }],
          note: hits.length ? hits.map((c) => clean(c.featureName)).join(' · ') : 'None.',
        }));
      });
    });
  }

  // ---------------------------------------------------------------- copy built from the data
  function writeCopy() {
    const maxReached = d3.max(langs, (l) => l.counts.reached);
    const leaders = langs.filter((l) => l.counts.reached === maxReached).map((l) => l.name);
    const second = d3.max(langs.filter((l) => l.counts.reached < maxReached), (l) => l.counts.reached);
    const minReached = d3.min(langs, (l) => l.counts.reached);
    setText('#lede', `${NL} languages, ${NF} WebAssembly features, ${f0(R.cells.length)} judged language–feature pairs. For each pair the study asks three things: can the language produce the feature at all, does its compiler check it, and what stands between the developer and it?`);
    const tiles = [
      ['Languages', NL, langs.map((l) => l.name).join(', ')],
      ['Features', NF, VERSIONS.map((v) => `${R.features.filter((f) => f.since === v).length} from spec ${v}`).join(' · ')],
      ['Judged cells', f0(R.cells.length), `${f0(R.cells.filter((c) => c.status === 'reached').length)} reached, ${f0(R.cells.filter((c) => c.status !== 'reached').length)} absent`],
      ['Perturbed runs', f0(R.comparison.perturbation.draws), 'to test how stable the ranking is'],
    ];
    const th = $('#tiles');
    for (const [k, v, n] of tiles) {
      const t = el('div', 'tile');
      t.append(el('div', 'k', k), el('div', 'v', String(v)), el('div', 'n', n));
      th.append(t);
    }

    setText('#h-coverage', `${joinNames(leaders)} reach ${maxReached} of ${NF} features; everyone else reaches ${minReached} to ${second}`);
    const cov = $('#cap-coverage');
    cov.replaceChildren();
    const clean0 = langs.slice().sort((a, b) => b.counts.noObstacle - a.counts.noObstacle)[0];
    const totalUnknown = d3.sum(langs, (l) => l.counts.absentNotFound);
    const neverProbed = d3.sum(langs, (l) => l.counts.neverProbed);
    cov.append(
      para(`<b>${clean0.name}</b> has the most features reached with no obstacle (${clean0.counts.noObstacle}). `
        + `Hatched segments are the uncertainty: the language <i>might</i> reach those features, but no way was found. Across all languages that is ${totalUnknown} cells, ${neverProbed} of them never probed (they rest on an ABSENT.md only). Hover a bar for the exact split.`),
    );

    // score
    const notRobust = R.comparison.pairs.filter((p) => !p.robust);
    const top = langs[0];
    setText('#h-score', notRobust.length
      ? `${top.name} comes out on top, and the order holds everywhere except ${joinNames(notRobust.map((p) => `${LANG.get(p.higher).name} vs. ${LANG.get(p.lower).name}`))}`
      : `${top.name} comes out on top, and the whole order holds under perturbation`);
    const cs = $('#cap-score');
    cs.replaceChildren();
    const borderline = R.comparison.pairs.filter((p) => p.robust && p.share < 0.97);
    cs.append(para(`A language counts as ahead of another only if it was ahead in at least 95% of the ${f0(R.comparison.perturbation.draws)} runs. `
      + (notRobust.length ? `${joinNames(notRobust.map((p) => `<b>${LANG.get(p.higher).name} above ${LANG.get(p.lower).name}</b> held in only ${Math.round(p.share * 100)}%`))}, so quote that pair as a tie. ` : '')
      + (borderline.length ? `Closest passes: ${joinNames(borderline.map((p) => `${LANG.get(p.higher).name} over ${LANG.get(p.lower).name} (${Math.round(p.share * 1000) / 10}%)`))}.` : '')));
    cs.append(para('The score is the author\'s judgement made explicit (see the method notes): quote the order, not the third decimal.'));

    // loss
    const dominant = (l) => { const d = LOSS.get(l.id); return ['absent', 'obstacles', 'partial'].sort((a, b) => d[b] - d[a])[0]; };
    const byAbsent = langs.filter((l) => dominant(l) === 'absent').map((l) => l.name);
    const byObst = langs.filter((l) => dominant(l) === 'obstacles').map((l) => l.name);
    const close = langs.filter((l) => dominant(l) === 'absent' && LOSS.get(l.id).obstacles >= 0.9 * LOSS.get(l.id).absent).map((l) => l.name);
    setText('#h-loss', byObst.length
      ? `Absence is the biggest loss for ${joinNames(byAbsent)}; for ${joinNames(byObst)} it is obstacles`
      : close.length
        ? `Absence is the biggest loss for every language, and for ${joinNames(close)} obstacles cost almost as much`
        : `Absence is the biggest loss for every language`);
    const cl = $('#cap-loss');
    cl.replaceChildren();
    const mostObst = langs.slice().sort((a, b) => LOSS.get(b.id).obstacles - LOSS.get(a.id).obstacles)[0];
    cl.append(para(`Obstacles cost <b>${mostObst.name}</b> the most: ${f2(LOSS.get(mostObst.id).obstacles)} of a possible 1.00, against ${f2(d3.min(langs, (l) => LOSS.get(l.id).obstacles))} for the language with the least. `
      + 'Shares use the importance weights, so one missing core feature costs more than one missing specialised feature.'));

    // trade-offs
    const reach = langs.slice().sort((a, b) => b.support - a.support)[0];
    const chk = langs.slice().sort((a, b) => b.checked - a.checked)[0];
    const dir = langs.slice().sort((a, b) => b.directness - a.directness)[0];
    const ct = $('#cap-tradeoffs');
    ct.replaceChildren();
    ct.append(para(`<b>${reach.name}</b> has the highest support (${num(reach.support)}) but only ${num(reach.checked)} of what it reaches is checked and its directness is ${num(reach.directness)}. `
      + `<b>${chk.name}</b> checks ${num(chk.checked)} of what it reaches, but reaches only ${num(chk.support)} of the set. <b>${dir.name}</b> is the most direct (${num(dir.directness)}).`));
    ct.append(para('Curves in the left chart join points of equal score (score = support × directness, roughly), so a point further up-right is better. Both axes are zoomed in to where the data lies; a dot\'s position, not a bar\'s length, carries the value. Directness and checked are averages over reached features only, so a language that reaches little can still look clean.'));

    // versions
    const weakest = langs.filter((l) => { const s = VERSIONS.map((v) => l.bySpecVersion[v].score); return s[2] === d3.min(s); });
    setText('#h-versions', `Spec 3.0 is the lowest-scoring release for ${weakest.length} of ${NL} languages`);
    const cv = $('#cap-versions');
    cv.replaceChildren();
    const exceptions = langs.filter((l) => !weakest.includes(l)).map((l) => {
      const worst = VERSIONS.slice().sort((a, b) => l.bySpecVersion[a].score - l.bySpecVersion[b].score)[0];
      return `${l.name} (lowest on ${worst})`;
    });
    cv.append(para(`${exceptions.length ? `The exception${exceptions.length > 1 ? 's' : ''}: ${joinNames(exceptions)}. ` : ''}Spec 3.0 is also where the most features are still new, and where "not found" matters most: a missing 3.0 feature may simply not be implemented yet. Read cells with few reached features as "little is possible", not "what is possible is poor".`));

    // matrix
    const reachedBy = R.features.map((f) => langs.filter((l) => cellOf(l.id, f.id).status === 'reached').length);
    const all = R.features.filter((f, i) => reachedBy[i] === NL).length;
    const few = R.features.filter((f, i) => reachedBy[i] <= 1);
    setText('#h-matrix', `${all} of ${NF} features are reached by every language; ${few.length} by one or none`);
    setText('#sub-matrix', 'Each tile is one language–feature pair, shaded by its cell score. Dots on the left show the feature\'s importance weight (1–3); the bars on the right count how many of the languages reach it. Use the arrow keys to move between tiles.');
    const cm = $('#cap-matrix');
    cm.replaceChildren();
    cm.append(para(`Features reached by one language or none: ${few.length ? joinNames(few.map((f) => `<b>${clean(f.name)}</b> (${reachedBy[f.id - 1]})`)) : 'none'}. A low tile is either a partial reach or a path with obstacles; open its tooltip for the variant and the reason.`));

    // obstacles
    const totals = obstacleKinds.map((k) => ({ k, n: d3.sum(langs, (l) => obstacleCells(l.id, k.kind).length) }));
    const worst = totals.slice().sort((a, b) => b.n - a.n)[0];
    setText('#h-obstacles', `${worst.k.kind} is the most common obstacle, in ${worst.n} reached cells`);
    const co = $('#cap-obstacles');
    co.replaceChildren();
    const harsh = totals.filter((t) => t.k.factor <= 0.5 && t.n);
    co.append(para('A cell can carry several obstacles, so the rows do not add up to the number of obstructed cells. '
      + (harsh.length ? `The harshest kind, <b>${harsh[0].k.kind}</b> (×${harsh[0].k.factor.toFixed(2)}), appears in ${harsh[0].n} cells. ` : '')
      + 'Hover a tile to list the features behind it, or a row name for the reasoning behind its factor.'));

    // method
    const absentTotal = d3.sum(langs, (l) => l.counts.absentNotFound + l.counts.absentConfirmed);
    const wlist = $('#method-list');
    const items = [
      '<b>The score is a summary, not a measurement.</b> Per feature: reach (full 1, partial 0.5, absent 0) times the factor of every obstacle on it; then a weighted mean over all features. The obstacle factors and the 1–3 importance weights are the author\'s judgement, written down in <code>weights.json</code>.',
      `<b>Rankings are tested, not asserted.</b> The ${f0(R.comparison.perturbation.draws)} perturbed runs move partial reach by ±0.2, every obstacle factor by ±0.15 and each importance weight between half and double. "Robust" means the order held in at least 95% of them.`,
      `<b>Absent is not the same as impossible.</b> ${absentTotal} cells are absent; ${d3.sum(langs, (l) => l.counts.absentNotFound)} of them are "not found", meaning the probe did not find a way, and ${d3.sum(langs, (l) => l.counts.neverProbed)} of those were never probed at all. A language that is better studied can look better.`,
      '<b>Checked means type-checked by the compiler</b> (native syntax or an annotation). It does not mean memory-safe; that would need its own coded dimension.',
      '<b>One column, two backends (MoonBit).</b> A cell takes the better of the <code>wasm</code> and <code>wasm-gc</code> backends, and a feature available on only one gets the harsh <code>other-backend</code> factor, because a module uses a single backend.',
      '<b>Equal weighting is a choice.</b> A feature a few programs need counts as much as its importance weight says, no more; the spec-version view lets you read the core features apart from the recent ones.',
    ];
    wlist.replaceChildren();
    for (const t of items) { const li = el('li'); li.innerHTML = t; wlist.append(li); }
    setText('#foot', `${R.about} · Visualisation: D3 v7, no build step. Run node viz/build-data.mjs after the ratings change.`);
  }
  // Prose is assembled as HTML strings with <b>/<i>; the names it interpolates come from
  // rating.json, so refuse to start if any of them could carry markup.
  const SAFE = /^[\w .\/+`,:()'-]+$/;
  for (const s of [...R.languages.map((l) => l.name), ...R.features.map((f) => f.name), ...obstacleKinds.map((k) => k.kind)]) {
    if (!SAFE.test(s)) throw new Error(`unexpected characters in name: ${s}`);
  }
  function para(html) { const p = el('p'); p.innerHTML = html; return p; }

  // ---------------------------------------------------------------- table twins
  function writeTables() {
    tableView($('#tv-coverage'), 'Feature outcome counts per language',
      ['Language', 'Reached', 'Full', 'Checked', 'No obstacle', '1 obstacle', '2+ obstacles', 'Absent (confirmed)', 'Absent (not found)', 'of which never probed'],
      langs.map((l) => [l.name, l.counts.reached, l.counts.full, l.counts.checked, l.counts.noObstacle, l.counts.oneObstacle, l.counts.twoOrMoreObstacles, l.counts.absentConfirmed, l.counts.absentNotFound, l.counts.neverProbed]));
    tableView($('#tv-score'), 'Score and rank range per language',
      ['Language', 'Score', 'Best rank', 'Worst rank', 'Mean rank'],
      langs.map((l) => [l.name, num(l.score), l.scoreRank.best, l.scoreRank.worst, l.scoreRank.mean.toFixed(2)]));
    tableView($('#tv-loss'), 'Share of the best possible result kept or lost, per language',
      ['Language', 'Kept (score)', 'Lost to obstacles', 'Lost to partial reach', 'Lost to absence'],
      langs.map((l) => { const d = LOSS.get(l.id); return [l.name, f2(d.kept), f2(d.obstacles), f2(d.partial), f2(d.absent)]; }));
    tableView($('#tv-tradeoffs'), 'Support, directness and checked per language',
      ['Language', 'Support', 'Directness', 'Checked', 'Score'],
      langs.map((l) => [l.name, num(l.support), num(l.directness), num(l.checked), num(l.score)]));
    tableView($('#tv-versions'), 'Score per language and spec version',
      ['Language', ...VERSIONS.map((v) => `Spec ${v} score`), ...VERSIONS.map((v) => `Spec ${v} reached`)],
      langs.map((l) => [l.name, ...VERSIONS.map((v) => num(l.bySpecVersion[v].score)), ...VERSIONS.map((v) => `${l.bySpecVersion[v].reached}/${l.bySpecVersion[v].features}`)]));
    tableView($('#tv-matrix'), 'Cell score for every feature and language',
      ['Feature', 'Spec', 'Weight', ...langs.map((l) => l.name)],
      R.features.map((f) => [clean(f.name), f.since, f.weight, ...langs.map((l) => {
        const c = cellOf(l.id, f.id);
        return c.status === 'reached' ? `${num(c.score)}${c.support < 1 ? ' (partial)' : ''}` : `absent (${absentKind(c) === 'confirmed' ? 'confirmed' : absentKind(c) === 'never' ? 'never probed' : 'not found'})`;
      })]));
    tableView($('#tv-obstacles'), 'Reached features carrying each obstacle, per language',
      ['Obstacle', 'Factor', ...langs.map((l) => l.name)],
      obstacleKinds.map((k) => [k.kind, k.factor.toFixed(2), ...langs.map((l) => obstacleCells(l.id, k.kind).length)]));
  }

  // ---------------------------------------------------------------- theme + lifecycle
  const THEMES = ['auto', 'light', 'dark'];
  let theme = 'auto';
  try { theme = THEMES.includes(localStorage.getItem('theme')) ? localStorage.getItem('theme') : 'auto'; } catch (_) { /* storage can be blocked */ }
  function applyTheme() {
    if (theme === 'auto') document.documentElement.removeAttribute('data-theme');
    else document.documentElement.setAttribute('data-theme', theme);
    $('#theme').textContent = `Theme: ${theme}`;
  }
  $('#theme').addEventListener('click', () => {
    theme = THEMES[(THEMES.indexOf(theme) + 1) % THEMES.length];
    try { localStorage.setItem('theme', theme); } catch (_) { /* optional */ }
    applyTheme();
    renderAll();
  });
  matchMedia('(prefers-color-scheme: dark)').addEventListener('change', () => theme === 'auto' && renderAll());

  function renderAll() {
    tipHide();
    renderCoverage(); renderScore(); renderLoss(); renderTradeoffs();
    renderVersions(); renderMatrix(); renderObstacles();
  }

  applyTheme();
  buildChips();
  writeCopy();
  writeTables();
  renderAll();

  let lastW = innerWidth, timer = 0;
  addEventListener('resize', () => {
    if (innerWidth === lastW) return; // ignore height-only changes (mobile URL bar)
    lastW = innerWidth;
    clearTimeout(timer);
    timer = setTimeout(renderAll, 120);
  });
})();
