document.addEventListener('DOMContentLoaded', function () {
  // Mobile hamburger menu toggle (replaces Framer's live interactive component)
  document.querySelectorAll('[data-framer-name="Menu Black"]').forEach(function (btn) {
    var nav = btn.closest('nav');
    var panel = nav ? nav.querySelector('[data-framer-name="Pages links"]') : null;
    if (!panel) return;

    // the nav clips its own overflow; the dropdown panel is absolutely
    // positioned just below it, so it gets cut off unless we allow overflow
    nav.style.overflow = 'visible';
    panel.style.display = 'none';
    var open = false;

    function setOpen(next) {
      open = next;
      panel.style.display = open ? 'flex' : 'none';
      btn.setAttribute('aria-expanded', open ? 'true' : 'false');
    }

    btn.addEventListener('click', function (e) {
      e.stopPropagation();
      setOpen(!open);
    });
    document.addEventListener('click', function (e) {
      if (open && !nav.contains(e.target)) setOpen(false);
    });
  });

  // Newsletter forms have no backend attached yet — keep them visible but inert
  document.querySelectorAll('form.framer-1lnssmz').forEach(function (form) {
    form.addEventListener('submit', function (e) {
      e.preventDefault();
    });
    var input = form.querySelector('input[type="email"]');
    if (input) {
      input.disabled = true;
      input.placeholder = 'Coming soon';
    }
  });

  // "0+" stat counter: count up to its target when it scrolls into view
  var counters = document.querySelectorAll('.js-counter');
  if ('IntersectionObserver' in window && counters.length) {
    var counterIO = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (!entry.isIntersecting) return;
        var el = entry.target;
        counterIO.unobserve(el);
        var target = parseInt(el.getAttribute('data-counter-target'), 10) || 0;
        var duration = 1500;
        var start = null;
        function step(ts) {
          if (start === null) start = ts;
          var progress = Math.min((ts - start) / duration, 1);
          var eased = 1 - Math.pow(1 - progress, 3);
          el.textContent = Math.round(eased * target);
          if (progress < 1) requestAnimationFrame(step);
        }
        requestAnimationFrame(step);
      });
    }, { threshold: 0.4 });
    counters.forEach(function (el) { counterIO.observe(el); });
  } else {
    counters.forEach(function (el) {
      el.textContent = el.getAttribute('data-counter-target') || el.textContent;
    });
  }

  // FAQ accordion: click a question to expand/collapse its answer.
  // Only one item stays open at a time within the same question list.
  document.querySelectorAll('[data-faq-question]').forEach(function (question) {
    var item = question.closest('[data-framer-name="Open"], [data-framer-name="Closed"]');
    var list = question.closest('.framer-1frezyv');
    if (!item || !list) return;
    var answer = item.querySelector('[data-faq-answer]');
    var icon = item.querySelector('.framer-K144P, .framer-ojRBg');

    function setExpanded(el, expanded) {
      var a = el.querySelector('[data-faq-answer]');
      var i = el.querySelector('.framer-K144P, .framer-ojRBg');
      if (a) a.style.display = expanded ? '' : 'none';
      if (i) i.classList.toggle('framer-K144P', expanded);
      if (i) i.classList.toggle('framer-ojRBg', !expanded);
      el.setAttribute('data-framer-name', expanded ? 'Open' : 'Closed');
    }

    // click anywhere on the whole item container to toggle (not just the
    // question text) — but ignore clicks inside the expanded answer itself
    item.style.cursor = 'pointer';
    item.addEventListener('click', function (e) {
      if (answer && answer.contains(e.target)) return;
      var isOpen = answer && answer.style.display !== 'none';
      list.querySelectorAll('[data-framer-name="Open"], [data-framer-name="Closed"]').forEach(function (el) {
        setExpanded(el, false);
      });
      setExpanded(item, !isOpen);
    });
  });

  // Background videos (Why Us / Challenge / Solution): play while on screen,
  // pause when off screen — replaces the play/pause Framer's runtime handled.
  var bgVideos = document.querySelectorAll('video[data-bg-video]');
  if ('IntersectionObserver' in window && bgVideos.length) {
    var videoIO = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        var v = entry.target;
        if (entry.isIntersecting) {
          var p = v.play();
          if (p && p.catch) p.catch(function () {});
        } else {
          v.pause();
        }
      });
    }, { threshold: 0.25 });
    bgVideos.forEach(function (v) { videoIO.observe(v); });
  } else {
    bgVideos.forEach(function (v) { v.setAttribute('autoplay', ''); });
  }

  // Solutions page "wheel": the ring of 4 services rotates 270 degrees (one
  // stop per item) while its section is pinned (position: sticky) in view.
  // Framer already ships 4 empty 100vh spacer elements ("Solution Scroll 01-04")
  // inside this section to provide the scroll room for that pin — we just
  // need to drive the rotation off how far we've scrolled through them.
  var wheel = document.querySelector('[data-framer-name="Solutions"] .framer-1ebab65');
  var wheelPin = wheel ? wheel.closest('.framer-1nkyupv') : null;
  var wheelSection = wheel ? wheel.closest('section') : null;
  if (wheel && wheelPin && wheelSection) {
    var STICKY_OFFSET = 130; // matches the sticky element's CSS `top: 130px`

    var wheelTicking = false;
    function updateWheel() {
      var sectionRect = wheelSection.getBoundingClientRect();
      var pinRange = wheelSection.offsetHeight - wheelPin.offsetHeight;
      var scrolledIntoPin = STICKY_OFFSET - sectionRect.top;
      var progress = pinRange > 0 ? scrolledIntoPin / pinRange : 0;
      progress = Math.max(0, Math.min(1, progress));
      wheel.style.transform = 'rotate(' + (progress * -270).toFixed(2) + 'deg)';
      wheelTicking = false;
    }
    window.addEventListener('scroll', function () {
      if (!wheelTicking) {
        requestAnimationFrame(updateWheel);
        wheelTicking = true;
      }
    }, { passive: true });
    window.addEventListener('resize', updateWheel);
    updateWheel();
  }
});
