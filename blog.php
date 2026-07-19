<?php
require_once __DIR__ . '/../cms-silnik/silnik.php';
$artykuly = pobierz_artykuly('protvdo');
?>
<!doctype html>
<html lang="pl">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Blog | ProTVDO</title>
  <meta name="description" content="Artykuły, poradniki i nowości od ProTVDO." />
  <link rel="canonical" href="https://protvdo.pl/blog.php" />
  <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="css/style.css" />
  <style>
    .blog-grid { display:grid; grid-template-columns:repeat(auto-fill,minmax(300px,1fr)); gap:28px; margin-top:48px; }
    .blog-card { background:var(--card); border:1px solid var(--card-border); border-radius:var(--radius-lg); padding:28px; transition:var(--transition); }
    .blog-card:hover { border-color: var(--primary); transform: translateY(-4px); }
    .blog-card .data { font-size:0.78rem; color:var(--primary); font-weight:700; text-transform:uppercase; letter-spacing:0.06em; }
    .blog-card h2 { font-size:1.2rem; font-weight:700; margin:10px 0 12px; }
    .blog-card p { color:var(--text-muted); font-size:0.92rem; margin-bottom:18px; }
    .blog-card a { color:var(--primary); font-weight:700; font-size:0.9rem; }
  </style>
</head>
<body>
  <nav class="navbar" role="navigation" aria-label="Nawigacja główna">
    <div class="container nav-container">
      <a href="index.html#start" class="logo" aria-label="ProTVDO — strona główna">PRO<span>TVDO</span></a>
      <ul class="nav-links" id="navLinks" role="list">
        <li><a href="index.html#start">Start</a></li>
        <li><a href="index.html#oferta">Oferta</a></li>
        <li><a href="blog.php">Blog</a></li>
        <li><a href="index.html#kontakt" class="btn-contact">Bezpłatna wycena</a></li>
      </ul>
      <button class="hamburger" id="hamburger" aria-label="Otwórz menu" aria-expanded="false" aria-controls="navLinks">
        <span class="bar"></span><span class="bar"></span><span class="bar"></span>
      </button>
    </div>
  </nav>

  <section class="section">
    <div class="container">
      <div class="section-header">
        <div class="section-label">Blog</div>
        <h2>Artykuły i poradniki</h2>
        <p>Nowości ze świata stron internetowych, wideo i AI.</p>
      </div>

      <div class="blog-grid">
        <?php foreach ($artykuly as $a): ?>
          <div class="blog-card">
            <div class="data"><?= htmlspecialchars(date('d.m.Y', strtotime($a['data_publikacji']))) ?></div>
            <h2><?= htmlspecialchars($a['tytul']) ?></h2>
            <p><?= htmlspecialchars($a['zajawka']) ?></p>
            <a href="artykul.php?slug=<?= urlencode($a['slug']) ?>">Czytaj dalej →</a>
          </div>
        <?php endforeach; ?>
        <?php if (empty($artykuly)): ?>
          <p style="color:var(--text-muted);">Wkrótce pojawią się tu pierwsze wpisy.</p>
        <?php endif; ?>
      </div>
    </div>
  </section>

  <footer role="contentinfo">
    <div class="container">
      <p style="color:var(--text-muted); text-align:center; padding:24px 0;">&copy; 2026 ProTVDO</p>
    </div>
  </footer>

  <script src="js/script.js"></script>
</body>
</html>
