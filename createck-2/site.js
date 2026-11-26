(() => {
  const io = new IntersectionObserver(es => es.forEach(e => { if (e.isIntersecting) { e.target.classList.add('in'); io.unobserve(e.target); } }), { threshold: .12 });
  document.querySelectorAll('.reveal').forEach(el => io.observe(el));

  // Onglets avec fenêtre (section « services » et bande sombre)
  document.querySelectorAll('[data-tabs]').forEach(box => {
    const btns = box.querySelectorAll('.tablist button'), imgs = box.querySelectorAll('.stage img'), cap = box.querySelector('.stage .cap');
    btns.forEach((b, i) => b.onclick = () => {
      btns.forEach(x => x.setAttribute('aria-selected', x === b));
      imgs.forEach((im, k) => im.classList.toggle('on', k === i));
      if (cap) cap.innerHTML = b.dataset.cap;
    });
  });

  // Bande témoignage : un avis par personne
  const tabs = document.querySelectorAll('.who-tabs button'), q = document.getElementById('story-q'), src = document.getElementById('story-src');
  tabs.forEach(b => b.onclick = () => {
    tabs.forEach(x => x.setAttribute('aria-selected', x === b));
    q.style.opacity = 0;
    setTimeout(() => { q.textContent = b.dataset.q; src.textContent = b.dataset.s; q.style.opacity = 1; }, 250);
  });

  const more = document.getElementById('more-rv');
  if (more) more.onclick = () => { more.closest('.rv-wrap').classList.add('open'); more.remove(); };

  // Filtres de la page Réalisations
  const fb = document.querySelectorAll('.filters button');
  fb.forEach(b => b.onclick = () => {
    fb.forEach(x => x.setAttribute('aria-pressed', x === b));
    document.querySelectorAll('.story-card').forEach(c => c.classList.toggle('hide', b.dataset.f !== 'all' && !c.dataset.cat.includes(b.dataset.f)));
  });

  const f = document.getElementById('devis');
  if (f) f.addEventListener('submit', e => {
    e.preventDefault();
    const t = [...f.querySelectorAll('[name=t]:checked')].map(i => i.value).join(', ');
    const body = `Projet : ${t || '-'}\n\n${f.m.value}\n\nNom : ${f.n.value}\nTéléphone : ${f.p.value}`;
    location.href = 'mailto:contact@createck-paysage.com?subject=' + encodeURIComponent('Demande de devis') + '&body=' + encodeURIComponent(body);
  });
})();
