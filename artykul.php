<?php
require_once __DIR__ . '/../cms-silnik/silnik.php';

$slug = $_GET['slug'] ?? '';
$a = pobierz_artykul('protvdo', $slug);

if (!$a || $a['status'] !== 'opublikowany') {
    http_response_code(404);
    echo 'Artykuł nie znaleziony. <a href="blog.php">Wróć do bloga</a>.';
    exit;
}
?>
<!doctype html>
<html lang="pl">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title><?= htmlspecialchars($a['tytul']) ?> | ProTVDO</title>
  <meta name="description" content="<?= htmlspecialchars($a['zajawka']) ?>" />
  <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="css/style.css" />
  <style>
    .artykul-wrap { max-width:760px; margin:0 auto; }
    .artykul-wrap .kategoria { color:var(--primary); font-weight:700; font-size:0.8rem; text-transform:uppercase; letter-spacing:0.06em; margin-bottom:14px; display:inline-block; }
    .artykul-wrap h1 { font-size:clamp(1.8rem,4vw,2.6rem); font-weight:800; margin-bottom:16px; letter-spacing:-0.02em; }
    .artykul-wrap .data { color:var(--text-muted); font-size:0.9rem; margin-bottom:32px; }
    .artykul-wrap img.okladka { width:100%; border-radius:var(--radius-lg); margin-bottom:32px; }
    .artykul-tresc { color:var(--text); font-size:1.05rem; line-height:1.75; }
    .artykul-tresc h2 { font-size:1.5rem; margin:36px 0 16px; font-weight:700; }
    .artykul-tresc h3 { font-size:1.2rem; margin:28px 0 12px; font-weight:700; }
    .artykul-tresc p { margin-bottom:18px; }
    .artykul-tresc ul { margin:0 0 18px 20px; }
    .wroc { display:inline-block; margin-top:32px; color:var(--primary); font-weight:700; }
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
    <div class="container artykul-wrap">
      <span class="kategoria"><?= htmlspecialchars($a['kategoria']) ?></span>
      <h1><?= htmlspecialchars($a['tytul']) ?></h1>
      <div class="data"><?= htmlspecialchars(date('d.m.Y', strtotime($a['data_publikacji']))) ?></div>
      <?php if ($a['okladka']): ?>
        <img class="okladka" src="<?= htmlspecialchars($a['okladka']) ?>" alt="<?= htmlspecialchars($a['tytul']) ?>">
      <?php endif; ?>
      <div class="artykul-tresc"><?= artykul_html($a) ?></div>
      <a href="blog.php" class="wroc">← Wróć do bloga</a>
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
