document.addEventListener('DOMContentLoaded', () => {

  /* ─── SCROLL PROGRESS BAR ─── */
  const progressBar = document.getElementById('scrollProgress');
  if (progressBar) {
    window.addEventListener('scroll', () => {
      const total = document.documentElement.scrollHeight - window.innerHeight;
      progressBar.style.width = total > 0 ? (window.scrollY / total * 100) + '%' : '0%';
    }, { passive: true });
  }

  /* ─── NAVBAR SCROLL ─── */
  const navbar = document.querySelector('.navbar');
  if (navbar) {
    window.addEventListener('scroll', () => {
      navbar.style.background = window.scrollY > 50
        ? 'rgba(8,8,8,0.98)'
        : 'rgba(8,8,8,0.8)';
    }, { passive: true });
  }

  /* ─── HAMBURGER ─── */
  const hamburger = document.getElementById('hamburger');
  const navLinks  = document.getElementById('navLinks');
  if (hamburger && navLinks) {
    hamburger.addEventListener('click', () => {
      const isOpen = navLinks.classList.toggle('active');
      hamburger.classList.toggle('open', isOpen);
      hamburger.setAttribute('aria-expanded', isOpen);
      hamburger.setAttribute('aria-label', isOpen ? 'Zamknij menu' : 'Otwórz menu');
    });
    document.querySelectorAll('.nav-links a').forEach(link => {
      link.addEventListener('click', () => {
        navLinks.classList.remove('active');
        hamburger.classList.remove('open');
        hamburger.setAttribute('aria-expanded', 'false');
        hamburger.setAttribute('aria-label', 'Otwórz menu');
      });
    });
  }

  /* ─── ACTIVE NAV LINK ─── */
  const sections   = document.querySelectorAll('section[id]');
  const navAnchors = document.querySelectorAll('.nav-links a[href^="#"]');
  if (sections.length && navAnchors.length) {
    const sectionObs = new IntersectionObserver(entries => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          navAnchors.forEach(a => a.classList.remove('active'));
          const active = document.querySelector(`.nav-links a[href="#${entry.target.id}"]`);
          if (active) active.classList.add('active');
        }
      });
    }, { rootMargin: '-40% 0px -55% 0px' });
    sections.forEach(s => sectionObs.observe(s));
  }

  /* ─── REVEAL ON SCROLL ─── */
  const revealEls = document.querySelectorAll(
    '[data-reveal], .reveal-up, .reveal-left, .reveal-right'
  );
  if (revealEls.length) {
    const revealObs = new IntersectionObserver(entries => {
      entries.forEach(entry => {
        if (!entry.isIntersecting) return;
        const el    = entry.target;
        const delay = parseInt(el.getAttribute('data-reveal-delay') || 0);
        setTimeout(() => el.classList.add('visible'), delay);
        revealObs.unobserve(el);
      });
    }, { threshold: 0.1 });
    revealEls.forEach(el => revealObs.observe(el));
  }

  /* ─── COUNTER ANIMATION ─── */
  document.querySelectorAll('.counter[data-target]').forEach(el => {
    const obs = new IntersectionObserver(entries => {
      if (!entries[0].isIntersecting) return;
      const target = parseInt(el.dataset.target);
      const dur    = 1600;
      const start  = performance.now();
      const tick   = now => {
        const ease = 1 - Math.pow(1 - Math.min((now - start) / dur, 1), 3);
        el.textContent = Math.round(ease * target);
        if (ease < 1) requestAnimationFrame(tick);
      };
      requestAnimationFrame(tick);
      obs.unobserve(el);
    }, { threshold: 0.5 });
    obs.observe(el);
  });

  /* ─── FLOATING CTA ─── */
  const floatingCta = document.getElementById('floatingCta');
  const heroSection = document.getElementById('start');
  if (floatingCta && heroSection) {
    new IntersectionObserver(entries => {
      floatingCta.classList.toggle('visible', !entries[0].isIntersecting);
    }, { threshold: 0.3 }).observe(heroSection);
  }

  /* ─── SCROLL TO TOP ─── */
  const scrollTopBtn = document.getElementById('scrollTop');
  if (scrollTopBtn) {
    window.addEventListener('scroll', () => {
      scrollTopBtn.classList.toggle('visible', window.scrollY > 400);
    }, { passive: true });
    scrollTopBtn.addEventListener('click', () => {
      window.scrollTo({ top: 0, behavior: 'smooth' });
    });
  }

  /* ─── MAGNETIC BUTTONS ─── */
  if (window.matchMedia('(hover: hover) and (pointer: fine)').matches) {
    document.querySelectorAll('.magnetic').forEach(btn => {
      btn.addEventListener('mousemove', e => {
        const r  = btn.getBoundingClientRect();
        const dx = (e.clientX - r.left - r.width  / 2) * 0.28;
        const dy = (e.clientY - r.top  - r.height / 2) * 0.28;
        btn.style.transform = `translate(${dx}px,${dy}px)`;
      });
      btn.addEventListener('mouseleave', () => { btn.style.transform = ''; });
    });
  }

  /* ─── FORMULARZ KONTAKTOWY ─── */
  const form = document.getElementById('contactForm');
  if (form) {
    let submitting  = false;
    let lastSubmit  = 0;
    const RATE_LIMIT = 60 * 1000; // 60 sekund między wysłaniami

    /* Usuń błąd pola przy wpisywaniu */
    form.querySelectorAll('input, textarea').forEach(field => {
      field.addEventListener('input', () => {
        field.classList.remove('field-error');
        field.closest('.form-group')?.classList.remove('has-error');
      });
    });

    form.addEventListener('submit', async e => {
      e.preventDefault();

      /* Honeypot — jeśli wypełniony, to bot */
      const botCheck  = form.querySelector('[name="botcheck"]');
      const honeyText = form.querySelector('[name="_honey"]');
      if ((botCheck && botCheck.checked) || (honeyText && honeyText.value)) return;

      /* Rate limit */
      if (submitting || (Date.now() - lastSubmit < RATE_LIMIT)) {
        showFormStatus(form, 'warning', 'Zaczekaj chwilę przed ponownym wysłaniem.');
        return;
      }

      /* Referencje do przycisku — MUSZĄ być przed walidacją */
      const btn          = form.querySelector('#submitBtn');
      const originalHTML = btn ? btn.innerHTML : '';

      /* Walidacja pól wymaganych */
      let valid = true;
      form.querySelectorAll('[required]').forEach(field => {
        if (!field.value.trim()) {
          field.classList.add('field-error');
          field.closest('.form-group')?.classList.add('has-error');
          valid = false;
        }
      });

      /* Walidacja formatu email */
      const emailField = form.querySelector('[name="email"]');
      if (emailField && emailField.value.trim() && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(emailField.value)) {
        emailField.classList.add('field-error');
        emailField.closest('.form-group')?.classList.add('has-error');
        valid = false;
      }

      if (!valid) {
        showFormStatus(form, 'error', 'Uzupełnij wszystkie wymagane pola.');
        form.querySelector('.field-error')?.focus();
        return;
      }

      /* Tryb demo — klucz Web3Forms nie jest jeszcze ustawiony */
      const keyField = form.querySelector('[name="access_key"]');
      if (!keyField || keyField.value === 'TWOJ_KLUCZ_WEB3FORMS') {
        console.warn('[ProTVDO] Ustaw klucz Web3Forms w index.html — pobierz bezpłatnie na web3forms.com');
        simulateSuccess(form, btn, originalHTML);
        return;
      }

      /* Wyślij do Web3Forms */
      clearFormStatus(form);
      submitting    = true;
      btn.innerHTML = '<i class="fas fa-spinner fa-spin" aria-hidden="true"></i> Wysyłanie...';
      btn.disabled  = true;

      try {
        const res  = await fetch('https://api.web3forms.com/submit', {
          method:  'POST',
          headers: { 'Accept': 'application/json' },
          body:    new FormData(form)
        });
        const data = await res.json();

        if (res.ok && data.success) {
          form.reset();
          lastSubmit        = Date.now();
          submitting        = false;
          btn.innerHTML     = '<i class="fas fa-check" aria-hidden="true"></i> Wysłano! Odpiszemy w 24h.';
          btn.style.cssText = 'background:#1a8a3c;box-shadow:0 4px 20px rgba(26,138,60,0.4)';
          showFormStatus(form, 'success', 'Dziękujemy! Wiadomość dotarła. Odezwiemy się w ciągu 24 godzin roboczych.');
          setTimeout(() => {
            btn.innerHTML     = originalHTML;
            btn.disabled      = false;
            btn.style.cssText = '';
          }, 6000);
        } else {
          throw new Error(data.message || 'Błąd serwera');
        }
      } catch (err) {
        submitting        = false;
        btn.innerHTML     = originalHTML;
        btn.disabled      = false;
        showFormStatus(form, 'error',
          'Wystąpił błąd wysyłania. Zadzwoń do nas: <a href="tel:+48784195290">+48 784 195 290</a>');
      }
    });
  }

  /* ─── COOKIES ─── */
  const cookieBanner = document.getElementById('cookie-banner');
  const COOKIE_KEY   = 'protvdo_cookies_v3';

  function hideCookieBanner() {
    cookieBanner.classList.remove('visible');
  }

  function saveConsent(analytics, marketing) {
    localStorage.setItem(COOKIE_KEY, JSON.stringify({ ts: Date.now(), analytics, marketing }));
    hideCookieBanner();
  }

  if (cookieBanner) {
    if (!localStorage.getItem(COOKIE_KEY)) {
      setTimeout(() => cookieBanner.classList.add('visible'), 1200);
    }

    const manageBtn  = document.getElementById('cookie-manage-btn');
    const managePanel = document.getElementById('cookie-manage-panel');

    manageBtn?.addEventListener('click', () => {
      const hidden = managePanel.hasAttribute('hidden');
      hidden ? managePanel.removeAttribute('hidden') : managePanel.setAttribute('hidden', '');
      manageBtn.textContent = hidden ? 'Zwiń' : 'Zarządzaj';
    });

    document.getElementById('cookie-reject-btn')?.addEventListener('click', () => saveConsent(false, false));

    document.getElementById('cookie-accept-btn')?.addEventListener('click', () => {
      const analytics = document.getElementById('cookie-analytics')?.checked ?? true;
      const marketing = document.getElementById('cookie-marketing')?.checked ?? true;
      saveConsent(analytics, marketing);
    });
  }

  /* ─── ROK W STOPCE ─── */
  document.querySelectorAll('.footer-year').forEach(el => {
    el.textContent = new Date().getFullYear();
  });

});

/* ═══ POMOCNICZE FUNKCJE FORMULARZA ═══ */

function showFormStatus(form, type, msg) {
  clearFormStatus(form);
  const el  = document.createElement('div');
  el.className = `form-status form-status--${type}`;
  el.setAttribute('role', type === 'error' ? 'alert' : 'status');
  const icons = { success: 'check-circle', error: 'exclamation-circle', warning: 'info-circle' };
  el.innerHTML = `<i class="fas fa-${icons[type] || 'info-circle'}" aria-hidden="true"></i> ${msg}`;
  const btn = form.querySelector('#submitBtn');
  if (btn) form.insertBefore(el, btn);
  else form.appendChild(el);
}

function clearFormStatus(form) {
  form.querySelectorAll('.form-status').forEach(el => el.remove());
}

function simulateSuccess(form, btn, originalHTML) {
  clearFormStatus(form);
  const submitBtn = btn || form.querySelector('#submitBtn');
  const orig = originalHTML || (submitBtn ? submitBtn.innerHTML : '');
  if (submitBtn) {
    submitBtn.innerHTML  = '<i class="fas fa-check" aria-hidden="true"></i> Wysłano (tryb demo)';
    submitBtn.style.cssText = 'background:#1a8a3c';
    submitBtn.disabled   = true;
  }
  form.reset();
  showFormStatus(form, 'success',
    'Formularz działa poprawnie (tryb demo). Ustaw klucz Web3Forms w index.html, aby odbierać wiadomości na e-mail.');
  setTimeout(() => {
    if (submitBtn) {
      submitBtn.innerHTML  = orig;
      submitBtn.disabled   = false;
      submitBtn.style.cssText = '';
    }
  }, 6000);
}
