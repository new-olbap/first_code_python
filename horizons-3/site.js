(() => {
  const hdr = document.querySelector('header');
  addEventListener('scroll', () => hdr && hdr.classList.toggle('scrolled', scrollY > 8), { passive: true });
  const io = new IntersectionObserver(es => es.forEach(e => { if (e.isIntersecting) { e.target.classList.add('in'); io.unobserve(e.target); } }), { threshold: .1 });
  document.querySelectorAll('.reveal').forEach(el => io.observe(el));
  document.querySelectorAll('[data-rail]').forEach(nav => {
    const rail = document.getElementById(nav.dataset.rail), [p, n] = nav.querySelectorAll('button');
    const step = () => rail.firstElementChild.getBoundingClientRect().width + 16;
    p.onclick = () => rail.scrollBy({ left: -step(), behavior: 'smooth' });
    n.onclick = () => rail.scrollBy({ left: step(), behavior: 'smooth' });
  });
  const f = document.getElementById('devis-form');
  if (f) f.addEventListener('submit', e => {
    e.preventDefault();
    const body = `Bonjour, je souhaite un devis.\nProjet : ${f.p.value}\nNom : ${f.n.value}\nTéléphone : ${f.t.value}`;
    location.href = 'sms:+33685213497?&body=' + encodeURIComponent(body);
  });

  // Ruban d'eau vivant (WebGL), très lent : une bande courbe aux couleurs du bassin
  if (matchMedia('(prefers-reduced-motion: reduce)').matches) return;
  document.querySelectorAll('.ribbon canvas').forEach(cv => {
    const gl = cv.getContext('webgl', { premultipliedAlpha: true, alpha: true });
    if (!gl) return;
    const flat = cv.dataset.mode === 'band';
    const fs = `precision mediump float;uniform vec2 r;uniform float t;
    float h(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
    float n(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);return mix(mix(h(i),h(i+vec2(1,0)),f.x),mix(h(i+vec2(0,1)),h(i+1.),f.x),f.y);}
    void main(){vec2 uv=gl_FragCoord.xy/r;float s=t*.05;
      vec3 deep=vec3(.04,.37,.62),teal=vec3(0.,.72,.74),aqua=vec3(.55,.88,.9),sand=vec3(.95,.86,.66),white=vec3(1.);
      float a;
      ${flat ? `a=smoothstep(.0,.25,uv.y)*smoothstep(1.,.62,uv.y+ (uv.x-.5)*.55);` :
      `float c=.55+.18*sin(uv.y*3.2+s*2.)+.08*sin(uv.y*7.-s*3.);
       float w=.17+.07*sin(uv.y*2.3-s*1.7);
       float d=abs(uv.x-c+ (uv.y-.5)*.35);
       a=smoothstep(w,w*.35,d);`}
      float k=n(uv*vec2(3.,5.)+vec2(s,-s*.7)), k2=n(uv*vec2(6.,2.5)-vec2(s*.6,s*.4)+7.);
      vec3 col=mix(deep,teal,smoothstep(.15,.75,k+uv.y*.3));
      col=mix(col,aqua,smoothstep(.45,.95,k2)*.8);
      col=mix(col,sand,smoothstep(.7,1.,k*k2*1.9)*.8);
      col=mix(col,white,pow(smoothstep(.55,1.,k2),3.)*.5);
      gl_FragColor=vec4(col*a,a);}`;
    const mk = (ty, src) => { const o = gl.createShader(ty); gl.shaderSource(o, src); gl.compileShader(o); return o; };
    const pr = gl.createProgram(); gl.attachShader(pr, mk(gl.VERTEX_SHADER, 'attribute vec2 p;void main(){gl_Position=vec4(p,0.,1.);}')); gl.attachShader(pr, mk(gl.FRAGMENT_SHADER, fs)); gl.linkProgram(pr);
    if (!gl.getProgramParameter(pr, gl.LINK_STATUS)) return;
    gl.useProgram(pr); gl.bindBuffer(gl.ARRAY_BUFFER, gl.createBuffer()); gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([-1,-1,3,-1,-1,3]), gl.STATIC_DRAW);
    gl.enableVertexAttribArray(0); gl.vertexAttribPointer(0, 2, gl.FLOAT, false, 0, 0);
    const uR = gl.getUniformLocation(pr, 'r'), uT = gl.getUniformLocation(pr, 't');
    const size = () => { cv.width = cv.clientWidth * .5 | 0; cv.height = cv.clientHeight * .5 | 0; gl.viewport(0, 0, cv.width, cv.height); };
    size(); addEventListener('resize', size);
    let vis = true; new IntersectionObserver(([e]) => vis = e.isIntersecting).observe(cv);
    const t0 = performance.now();
    const loop = now => { if (vis) { gl.uniform2f(uR, cv.width, cv.height); gl.uniform1f(uT, (now - t0) / 1000); gl.clearColor(0,0,0,0); gl.clear(gl.COLOR_BUFFER_BIT); gl.drawArrays(gl.TRIANGLES, 0, 3); } requestAnimationFrame(loop); };
    requestAnimationFrame(loop); cv.classList.add('on');
  });
})();
