/* ============================================================
   LiquidTasks Landing — script.js
   GSAP entry + idle floats + mouse parallax + scroll triggers
   ============================================================ */

(() => {
  const prefersReduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  const isTouch = window.matchMedia('(hover: none) and (pointer: coarse)').matches;

  /* ---------- Lenis smooth scroll ---------- */
  if (!prefersReduced && window.Lenis) {
    const lenis = new Lenis({
      duration: 1.2,
      easing: t => Math.min(1, 1.001 - Math.pow(2, -10 * t)),
      smoothWheel: true,
      wheelMultiplier: 1,
      touchMultiplier: 2,
      smoothTouch: false, // native iOS/Android scroll feels better
    });

    if (window.gsap && window.ScrollTrigger) {
      lenis.on('scroll', ScrollTrigger.update);
      gsap.ticker.add((time) => lenis.raf(time * 1000));
      gsap.ticker.lagSmoothing(0);
    } else {
      function raf(time) { lenis.raf(time); requestAnimationFrame(raf); }
      requestAnimationFrame(raf);
    }
  }

  if (!window.gsap) return;
  gsap.registerPlugin(ScrollTrigger);
  ScrollTrigger.config({ fastScrollEnd: true });

  /* ============================================================
     PHONE STATE — single source of truth for transform
     Composition: idle.y + parallax.rx/ry + entry.* + base side-tilt
     ============================================================ */
  const phoneEls = Array.from(document.querySelectorAll('.phone'));

  // Per-phone base configuration (side tilt + z-depth)
  phoneEls.forEach((phone) => {
    let baseRY = 0, baseZ = 0, baseScale = 1, baseX = 0;
    if (phone.classList.contains('phone--left'))  { baseRY = -15; baseZ = -60; baseScale = 0.92; baseX = 40; }
    if (phone.classList.contains('phone--right')) { baseRY =  15; baseZ = -60; baseScale = 0.92; baseX = -40; }
    if (phone.classList.contains('phone--center')) { baseScale = 1; }

    phone._state = {
      baseRY, baseZ, baseScale, baseX,
      // Entry-driven
      entryY: 80, entryScale: baseScale * 0.85, entryOpacity: 0,
      // Idle
      idleY: 0,
      // Parallax
      pRX: 0, pRY: 0,
      // Scroll-out
      scrollY: 0, scrollScale: 1, scrollOpacity: 1, scrollRX: 0,
    };
    apply(phone);
  });

  function apply(phone) {
    const s = phone._state;
    const y = s.entryY + s.idleY + s.scrollY;
    const scale = s.entryScale * s.scrollScale;
    const rx = s.pRX + s.scrollRX;
    const ry = s.baseRY + s.pRY;

    phone.style.transform =
      `translate3d(${s.baseX}px, ${y}px, ${s.baseZ}px) ` +
      `rotateX(${rx}deg) rotateY(${ry}deg) ` +
      `scale(${scale})`;
    phone.style.opacity = String(s.entryOpacity * s.scrollOpacity);
  }

  // Global per-frame apply — all transforms compose every tick.
  gsap.ticker.add(() => phoneEls.forEach(apply));

  /* ============================================================
     HERO ENTRY ANIMATION
     ============================================================ */
  const heroTL = gsap.timeline({ delay: 0.25 });

  heroTL.to('.hero-word', {
    opacity: 1, y: 0,
    duration: 0.9,
    ease: 'power3.out',
    stagger: 0.08,
  });

  heroTL.to('.hero-sub', {
    opacity: 1, y: 0,
    duration: 0.7,
    ease: 'power2.out',
  }, '-=0.3');

  heroTL.to('.hero-cta-wrap', {
    opacity: 1, y: 0,
    duration: 0.6,
    ease: 'power3.out',
    onComplete: () => {
      // Clear will-change after entry to free GPU layer memory
      const w = document.querySelector('.hero-cta-wrap');
      if (w) w.style.willChange = 'auto';
    },
  }, '+=0.05');

  // Phone entry — staggered, with order center → left → right
  const orderedPhones = [
    phoneEls.find(p => p.classList.contains('phone--center')),
    phoneEls.find(p => p.classList.contains('phone--left')),
    phoneEls.find(p => p.classList.contains('phone--right')),
  ].filter(Boolean);

  orderedPhones.forEach((phone, i) => {
    heroTL.to(phone._state, {
      entryY: 0,
      entryScale: phone._state.baseScale,
      entryOpacity: 1,
      duration: 1.15,
      ease: 'back.out(1.6)',
    }, `-=${i === 0 ? 0.4 : 1.0}`);
  });

  heroTL.add(() => {
    // Idle floats + parallax need transform updates, so re-promote selectively
    phoneEls.forEach(p => { p.style.willChange = 'transform'; });
    startIdleFloats();
  }, '-=0.4');

  /* ============================================================
     IDLE FLOAT — gentle, desynced per phone
     ============================================================ */
  function startIdleFloats() {
    if (prefersReduced) return;

    const durations = [5.2, 4.4, 6.0];
    const yAmps     = [9, 10, 7];

    phoneEls.forEach((phone, i) => {
      gsap.to(phone._state, {
        idleY: -yAmps[i % yAmps.length],
        duration: durations[i % durations.length],
        repeat: -1,
        yoyo: true,
        ease: 'sine.inOut',
      });
    });

    initMouseParallax();
  }

  /* ============================================================
     MOUSE PARALLAX — smooth lerp tilt
     ============================================================ */
  function initMouseParallax() {
    if (prefersReduced) return;
    const stage = document.getElementById('phones-stage');
    if (!stage) return;

    const target = { x: 0, y: 0 };
    const current = { x: 0, y: 0 };
    const DAMP = 0.08;
    const MAX = 8;

    window.addEventListener('mousemove', (e) => {
      const rect = stage.getBoundingClientRect();
      const cx = rect.left + rect.width / 2;
      const cy = rect.top + rect.height / 2;
      target.x = ((e.clientX - cx) / rect.width)  * 2;
      target.y = ((e.clientY - cy) / rect.height) * 2;
    });

    gsap.ticker.add(() => {
      current.x += (target.x - current.x) * DAMP;
      current.y += (target.y - current.y) * DAMP;
      phoneEls.forEach((phone) => {
        phone._state.pRY = current.x * MAX;
        phone._state.pRX = -current.y * MAX;
      });
    });
  }

  /* ============================================================
     HERO SCROLL-OUT — cinematic transition
     ============================================================ */
  if (!prefersReduced) {
    ScrollTrigger.create({
      trigger: '#hero',
      start: 'top top',
      end: 'bottom top',
      scrub: 0.6,
      onUpdate: (self) => {
        const p = self.progress;
        phoneEls.forEach((phone) => {
          phone._state.scrollY = -80 * p;
          phone._state.scrollScale = 1 - 0.15 * p;
          phone._state.scrollOpacity = 1 - 0.8 * p;
          phone._state.scrollRX = 12 * p;
        });
      },
    });

    gsap.to('.hero-h1, .hero-sub', {
      scrollTrigger: {
        trigger: '#hero',
        start: 'top top',
        end: 'bottom top',
        scrub: 0.6,
      },
      y: -60,
      opacity: 0,
      ease: 'none',
    });
  }

  /* ============================================================
     SECTION 2 — features reveal
     ============================================================ */
  ScrollTrigger.batch('.reveal-word', {
    start: 'top 85%',
    onEnter: (els) => gsap.to(els, {
      opacity: 1,
      y: 0,
      duration: 0.8,
      ease: 'power3.out',
      stagger: 0.06,
    }),
  });

  ScrollTrigger.batch('.feature-card', {
    start: 'top 90%',
    onEnter: (els) => {
      gsap.to(els, {
        opacity: 1,
        y: 0,
        duration: 0.7,
        ease: 'power3.out',
        stagger: 0.08,
      });
      els.forEach(el => el.classList.add('is-visible'));
    },
  });

  ScrollTrigger.batch('.showcase-card', {
    start: 'top 88%',
    onEnter: (els) => gsap.from(els, {
      opacity: 0,
      y: 60,
      scale: 0.94,
      rotateX: 8,
      duration: 1,
      ease: 'power3.out',
      stagger: 0.15,
    }),
  });

  ScrollTrigger.create({
    trigger: '.cta-banner',
    start: 'top 85%',
    once: true,
    onEnter: () => {
      gsap.to('.cta-banner', {
        opacity: 1, y: 0,
        duration: 1,
        ease: 'power3.out',
      });
    },
  });

  /* ============================================================
     CTA BUTTON — ripple click effect (section 2)
     ============================================================ */
  const btn = document.querySelector('.appstore-btn');
  if (btn) {
    btn.addEventListener('click', () => {
      btn.classList.remove('is-rippling');
      void btn.offsetWidth;
      btn.classList.add('is-rippling');
    });
  }

  /* ============================================================
     HERO CTA — ripple + magnetic effect
     ============================================================ */
  const heroCta = document.querySelector('.hero-cta');
  if (heroCta) {
    heroCta.addEventListener('click', () => {
      heroCta.classList.remove('is-rippling');
      void heroCta.offsetWidth;
      heroCta.classList.add('is-rippling');
    });

    // Magnetic effect — disabled on touch + reduced-motion
    if (!prefersReduced && !isTouch) {
      const MAGNET_RADIUS = 100;
      const MAX_OFFSET = 8;
      const DAMP = 0.15;
      const target = { x: 0, y: 0 };
      const current = { x: 0, y: 0 };

      // Track mouse globally; only update target when within radius of button center
      let mx = 0, my = 0;
      window.addEventListener('mousemove', (e) => {
        mx = e.clientX; my = e.clientY;
      }, { passive: true });

      let lastApplied = { x: 0, y: 0 };
      gsap.ticker.add(() => {
        const rect = heroCta.getBoundingClientRect();
        const cx = rect.left + rect.width / 2;
        const cy = rect.top + rect.height / 2;
        const dx = mx - cx;
        const dy = my - cy;
        const dist = Math.hypot(dx, dy);

        if (dist < MAGNET_RADIUS) {
          const pull = 1 - dist / MAGNET_RADIUS;
          target.x = (dx / MAGNET_RADIUS) * MAX_OFFSET * pull * 1.2;
          target.y = (dy / MAGNET_RADIUS) * MAX_OFFSET * pull * 1.2;
        } else {
          target.x = 0;
          target.y = 0;
        }

        current.x += (target.x - current.x) * DAMP;
        current.y += (target.y - current.y) * DAMP;

        // Early-exit: skip CSS variable write when nothing meaningful changed
        if (Math.abs(current.x - lastApplied.x) < 0.05 &&
            Math.abs(current.y - lastApplied.y) < 0.05) return;
        lastApplied.x = current.x;
        lastApplied.y = current.y;

        heroCta.style.setProperty('--magnet-x', current.x.toFixed(2) + 'px');
        heroCta.style.setProperty('--magnet-y', current.y.toFixed(2) + 'px');
      });
    }
  }
})();
