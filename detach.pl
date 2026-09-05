#!/usr/bin/perl
use strict;
use warnings;

my ($in, $out) = @ARGV;
die "usage: detach.pl in.html out.html\n" unless $in && $out;

local $/;
open(my $fh, '<', $in) or die $!;
my $html = <$fh>;
close $fh;

# --- font-size scaling (piecewise-linear over hand-picked control points) ---
my @pts = ([0,0],[12,12],[14,14],[16,16],[18,17],[20,18],[24,20],[28,24],
           [40,32],[48,38],[58,46],[72,56],[80,60],[88,64],[172,110],[288,180]);

sub scale_size {
    my ($v) = @_;
    for my $i (0 .. $#pts - 1) {
        my ($x0, $y0) = @{$pts[$i]};
        my ($x1, $y1) = @{$pts[$i + 1]};
        if ($v >= $x0 && $v <= $x1) {
            my $t = ($x1 == $x0) ? 0 : ($v - $x0) / ($x1 - $x0);
            return int($y0 + $t * ($y1 - $y0) + 0.5);
        }
    }
    my ($x0, $y0) = @{$pts[-2]};
    my ($x1, $y1) = @{$pts[-1]};
    my $slope = ($y1 - $y0) / ($x1 - $x0);
    return int($y1 + ($v - $x1) * $slope + 0.5);
}

$html =~ s/(font-size:\s*)(\d+)px/$1 . scale_size($2) . "px"/ge;

# --- laptop breakpoint: 1400px desktop threshold -> 1024px ---
$html =~ s/(min-width:\s*)1400px/$1 . "1024px"/ge;
$html =~ s/(max-width:\s*)1399\.98px/$1 . "1023.98px"/ge;
$html =~ s/(max-width:\s*)1399px/$1 . "1023px"/ge;

# --- swap the 3 hosted background videos for the local files; site.js plays
# them when they scroll into view (Framer's JS used to do that) ---
$html =~ s{https://framerusercontent\.com/assets/iFEj7eU1hOwn5Fg3vERvSLBsxxg\.mp4}{./videos/igi-take-1.mp4}g;
$html =~ s{https://framerusercontent\.com/assets/ERvDw260O5ElOhKECHCb0w5fbs\.mp4}{./videos/igi-take-2.mp4}g;
$html =~ s{https://framerusercontent\.com/assets/ElxWAXJopNIOQUavM3kVaeMs6A\.mp4}{./videos/igi-take-3.mp4}g;
# let the first frame show before playback and mark them for site.js
$html =~ s{(<video src="\./videos/igi-take-\d\.mp4" loop )preload="none"}{$1preload="metadata" data-bg-video="1"}g;

# --- story paragraph: these <p> render with white-space:pre-wrap, so the
# newline + indentation the pretty-printer inserted shows up as a literal
# gap before two phrases. Collapse it so the text reads left-aligned ---
$html =~ s{(there a better)\s+(way to package eggs in Rwanda\?)}{$1 $2}g;
$html =~ s{(we sell is)\s+(graded, labeled, and traceable)}{$1 $2}g;
# footer "Made by <epique ai>" — same pre-wrap whitespace pushes the link onto
# its own indented line on the homepage; collapse it to a single inline space
$html =~ s{(>Made by)\s+(<!--\$--><a class="framer-text framer-styles-preset-1uyw8au"[^>]*>epique ai</a>)\s*(<!--/\$-->)\s*(</p>)}{$1 $2$3$4}gs;

# --- "What We Offer" services section: on desktop the "Packaged Eggs" image
# was a plain egg close-up while phone showed the branded shopping-cart image;
# make desktop use the same (SDsM...) image the phone does ---
$html =~ s{Kk9zZ6v2K4nty2XhLAOmYN9wu18\.png\?scale-down-to=1024&amp;width=1240&amp;height=1300}{SDsMRcRF8vopkNchUamOgcifybI.png?scale-down-to=1024&amp;width=1537&amp;height=1023}g;
$html =~ s{Kk9zZ6v2K4nty2XhLAOmYN9wu18\.png\?width=1240&amp;height=1300}{SDsMRcRF8vopkNchUamOgcifybI.png?width=1537&amp;height=1023}g;
$html =~ s{bdx4WGmbZPYCj7TcVp2y1slfkk\.jpg\?scale-down-to=512&amp;width=1200&amp;height=1200}{SDsMRcRF8vopkNchUamOgcifybI.png?scale-down-to=512&amp;width=1537&amp;height=1023}g;
$html =~ s{bdx4WGmbZPYCj7TcVp2y1slfkk\.jpg\?scale-down-to=1024&amp;width=1200&amp;height=1200}{SDsMRcRF8vopkNchUamOgcifybI.png?scale-down-to=1024&amp;width=1537&amp;height=1023}g;
$html =~ s{bdx4WGmbZPYCj7TcVp2y1slfkk\.jpg\?width=1200&amp;height=1200}{SDsMRcRF8vopkNchUamOgcifybI.png?width=1537&amp;height=1023}g;

# --- NEW: partners logo-marquee section, inserted right above "Our Services" ---
if ($html =~ /<section class="framer-sym14o" data-framer-name="Company">/ && $html !~ /class="igi-partners"/) {
    my @logos = (
        ['./logos/giz.png', 'GIZ'],
        ['./logos/bk.png', 'Bank of Kigali'],
        ['./logos/ami.jpg', 'AMI'],
        ['./logos/afr.jpg', 'Access to Finance Rwanda'],
        ['./logos/bpn.png', 'BPN'],
        ['./logos/inkomoko.jpg', 'Inkomoko'],
        ['./logos/esp.png', 'ESP'],
        ['./logos/250-brands.jpg', '250 Brands'],
    );
    my $logo_cards = join('', map { qq{<div class="igi-logo"><img src="$_->[0]" alt="$_->[1]" decoding="async"></div>} } @logos);
    my $track = $logo_cards . $logo_cards; # duplicated for a seamless loop

    my $partners_css = q{<style id="igi-partners-css">}
      . q{.igi-partners{background:#fff;padding:120px 30px;overflow:hidden;position:relative;width:100%;box-sizing:border-box;font-family:"Inter","Inter Placeholder",sans-serif;font-feature-settings:"blwf" 1,"cv09" 1,"cv03" 1,"cv04" 1,"cv11" 1;-webkit-font-smoothing:antialiased}}
      . q{.igi-partners *{box-sizing:border-box;font-family:inherit}}
      . q{.igi-partners-wrap{max-width:1360px;margin:0 auto;position:relative}}
      . q{.igi-partners-head{display:flex;justify-content:space-between;align-items:flex-end;gap:40px;flex-wrap:wrap;margin-bottom:60px}}
      . q{.igi-partners-headline{max-width:660px}}
      . q{.igi-eyebrow{display:inline-flex;align-items:center;gap:8px;background:#fdcc05;color:#fff;font-weight:500;font-size:16px;letter-spacing:-.04em;text-transform:uppercase;padding:8px;border-radius:12px;margin-bottom:24px}}
      . q{.igi-eyebrow-dot{width:8px;height:8px;border-radius:50%;background:#fff}}
      . q{.igi-partners-title{color:#122023;font-size:52px;line-height:1.05;font-weight:600;letter-spacing:-.04em;margin:0}}
      . q{.igi-partners-sub{color:#3d6a6e;font-size:18px;margin-top:18px;line-height:1.5;letter-spacing:-.04em}}
      . q{.igi-partners-stat{flex:none;text-align:right}}
      . q{.igi-stat-num{color:#122023;font-size:96px;font-weight:700;line-height:1;letter-spacing:-.04em}}
      . q{.igi-stat-label{display:block;color:#3d6a6e;font-size:16px;margin-top:8px;line-height:1.35;letter-spacing:-.04em}}
      . q{.igi-marquee{position:relative;overflow:hidden;-webkit-mask:linear-gradient(90deg,transparent,#000 7%,#000 93%,transparent);mask:linear-gradient(90deg,transparent,#000 7%,#000 93%,transparent)}}
      . q{.igi-marquee-track{display:flex;width:max-content;animation:igi-scroll 45s linear infinite}}
      . q{.igi-marquee:hover .igi-marquee-track{animation-play-state:paused}}
      . q{.igi-logo{flex:none;width:190px;height:80px;margin-right:64px;display:flex;align-items:center;justify-content:center;transition:transform .35s cubic-bezier(.22,1,.36,1),opacity .35s ease;opacity:.85}}
      . q{.igi-logo:hover{transform:scale(1.1);opacity:1}}
      . q{.igi-logo img{max-width:100%;max-height:100%;object-fit:contain;mix-blend-mode:multiply}}
      . q{@keyframes igi-scroll{to{transform:translateX(-50%)}}}
      . q{@media(max-width:809px){.igi-partners{padding:72px 20px}.igi-partners-title{font-size:32px}.igi-partners-sub{font-size:16px}.igi-stat-num{font-size:64px}.igi-partners-head{margin-bottom:40px}.igi-partners-stat{text-align:left}.igi-logo{width:130px;height:60px;margin-right:44px}}}
      . q{@media(prefers-reduced-motion:reduce){.igi-marquee-track{animation:none}}}
      . q{</style>};

    my $partners_html = q{<section class="igi-partners" data-framer-name="Partners"><div class="igi-partners-wrap"><div class="igi-partners-head"><div class="igi-partners-headline"><div class="igi-eyebrow"><span class="igi-eyebrow-dot"></span>Our Partners</div><h2 class="igi-partners-title">Trusted by those building Rwanda&rsquo;s food future.</h2><p class="igi-partners-sub">From development agencies to leading banks and business networks, we grow alongside partners who share our standards for quality and sustainability.</p></div><div class="igi-partners-stat"><div class="igi-stat-num"><span class="js-counter" data-counter-target="10">0</span>+</div><span class="igi-stat-label">organisations<br>partnered with us</span></div></div><div class="igi-marquee"><div class="igi-marquee-track">}
      . $track
      . q{</div></div></div></section>};

    $html =~ s{(<section class="framer-sym14o" data-framer-name="Company">)}{$partners_css$partners_html$1};
}

# --- homepage "supermarkets countrywide" counter: mark the digit span so
# site.js can count it up from 0 -> 100 when it scrolls into view ---
$html =~ s{<span>0</span>}{<span class="js-counter" data-counter-target="100">0</span>}g;

# --- homepage FAQ: the closed accordion items ship with NO answer markup at
# all (Framer only SSRs the currently-open item's answer). Inject the answer
# markup we scraped from the live site into each closed item, hidden by
# default, so site.js has something to expand ---
my %faq_answers = (
    q{Are you importing eggs from somewhere else?} =>
        q{We're 100% Rwandan, started after spotting a gap in how eggs were being sold (loose in paper bags!). Everything is produced and packaged locally.},
    q{Can I just buy a small pack of eggs from you, or do you only sell in bulk?} =>
        q{Right now we sell in packs of 10 and trays of 30, mostly to shops, restaurants, and hotels. We know that's not always convenient for smaller households, so a 6-egg pack is in the works.},
    q{How do I know your eggs are actually clean and safe to eat?} =>
        q{Every egg is graded, labeled, and traceable back to the farm it came from — ours or one of our partner farms, all of which follow eco-friendly practices. Nothing is treated with harmful chemicals.},
    q{I run a small shop, is my order too small for you to work with?} =>
        q{Not at all. We already supply a wide range of businesses, from big names like SPAR and Carrefour Mart down to neighborhood spots like bakeries and butcheries. We're set up to handle different order sizes.},
    q{Do you do anything with all the waste from your chickens?} =>
        q{we turn poultry waste into organic fertilizer, a chemical-free alternative that's great for farmers and cooperatives looking for a more natural way to enrich their soil.},
    q{Are you planning to grow beyond just fresh eggs?} =>
        q{Definitely. We're developing egg powder for longer shelf life and export markets, and down the line we want to add liquid eggs, salted eggs, and egg protein powder, plus offer consulting to help other poultry farmers run more sustainable operations.},
);

for my $question (keys %faq_answers) {
    my $answer = $faq_answers{$question};
    my $answer_html = qq{<div class="framer-9ueres" data-framer-name="Asnwer" data-faq-answer style="display:none"><div class="framer-1nl0n93" data-framer-name="Answer" data-framer-component-type="RichTextContainer" style="--extracted-r6o4lv:var(--token-d24e1952-4882-4f6d-9574-03d6785cd373, rgb(255, 255, 255));--framer-link-text-color:rgb(0, 153, 255);--framer-link-text-decoration:underline;transform:none"><p class="framer-text framer-styles-preset-1g5pt9p" data-styles-preset="G3Bbh42HB" dir="auto" style="--framer-text-color:var(--extracted-r6o4lv, var(--token-d24e1952-4882-4f6d-9574-03d6785cd373, rgb(255, 255, 255)))">$answer</p></div></div>};
    my $q_quoted = quotemeta($question);
    $html =~ s{(<p class="framer-text framer-styles-preset-27pney"[^>]*>$q_quoted</p>\s*</div>\s*<div class="framer-1pf8hj6" data-framer-name="Icon"[^>]*>\s*<div data-framer-name="Vector" class="framer-ojRBg framer-wgr1kf"></div>\s*</div>\s*</div>)(\s*</div>)}{$1$answer_html$2}g;
}

# mark every FAQ question row (click target) and every answer/icon for site.js
$html =~ s{(<div class="framer-1jqntqp" data-framer-name="Question")}{<div class="framer-1jqntqp" data-framer-name="Question" data-faq-question}g;
$html =~ s{(<div class="framer-9ueres" data-framer-name="Asnwer")(?! data-faq-answer)}{$1 data-faq-answer}g;

# --- gs1-workshop-2022 was the last CMS entry, so Framer left its "Next
# Article" link empty for the runtime to wrap around. Fill it in ourselves ---
$html =~ s{<a class="framer-text framer-styles-preset-1uyw8au" data-styles-preset="Wi0szOa0J"></a>}{<a class="framer-text framer-styles-preset-1uyw8au" data-styles-preset="Wi0szOa0J" href="./e-commerce-accelerator-program">E-Commerce Accelerator Program</a>};

# --- mobile menu: drop the placeholder "Projects" and "Careers" links (both
# just point at the home page) and rename "News" to "Blogs" so the mobile menu
# matches the desktop nav (About, Solutions, Blogs, Contact us) ---
$html =~ s{<div class="framer-1vpn253-container">.*?</a>\s*(?:<!--/\$-->)?\s*</div>}{}gs;
$html =~ s{<div class="framer-12x6n3x-container">.*?</a>\s*(?:<!--/\$-->)?\s*</div>}{}gs;
$html =~ s{>News</p>}{>Blogs</p>}g;

# --- footer: drop the X/Twitter icon, point Instagram/Facebook at the real
# profiles, and make "epique ai" open an email ---
$html =~ s{<a class="framer-zYxQR[^>]*href="https://x\.com/"[^>]*>\s*<img[^>]*src="[^"]*"[^>]*>\s*</a>}{}gs;
$html =~ s{(<a class="framer-zYxQR[^>]*)href="https://www\.instagram\.com/"([^>]*)>}{$1href="https://www.instagram.com/igilimited/" target="_blank" rel="noopener"$2>}g;
$html =~ s{(<a class="framer-zYxQR[^>]*)href="https://facebook\.com/"([^>]*)>}{$1href="https://www.facebook.com/p/IGI-Poultry-100082984554714/" target="_blank" rel="noopener"$2>}g;
$html =~ s{(<a class="framer-text framer-styles-preset-1uyw8au"[^>]*)href="https://www\.framer\.com/"([^>]*>epique ai</a>)}{$1href="mailto:epiqueai\@gmail.com"$2}g;

# --- hardcode nav bar surfaces to solid white ---
$html =~ s/(data-framer-name="Desktop" data-hide-scrollbars="true" style="background-color:)var\(--token-d24e1952-4882-4f6d-9574-03d6785cd373, rgb\(255, 255, 255\)\)/$1#ffffff/;
$html =~ s/(data-framer-name="Nav Block" style="background-color:)var\(--token-d24e1952-4882-4f6d-9574-03d6785cd373, rgb\(255, 255, 255\)\)/$1#ffffff/;
$html =~ s/(data-framer-name="Phone Default " data-hide-scrollbars="true" style="background-color:)var\(--token-d24e1952-4882-4f6d-9574-03d6785cd373, rgb\(255, 255, 255\)\)/$1#ffffff/;
$html =~ s/(data-framer-name="Pages links" data-highlight="true" tabindex="0" style="background-color:)var\(--token-d24e1952-4882-4f6d-9574-03d6785cd373, rgb\(255, 255, 255\)\)/$1#ffffff/;

# --- hero title: make it bigger and vertically center it in the hero area
# (home / about / solutions all share the same h1 preset + hero containers) ---
if ($html !~ /id="igi-hero-override"/) {
    my $hero_sel = q{.framer-pm057i h1.framer-styles-preset-45dtz8,.framer-aqcw9y h1.framer-styles-preset-45dtz8};
    my $hero_css = q{<style id="igi-hero-override">}
      . q{:root,html{color-scheme:light only !important}}
      . q{img,video{color-scheme:light only}}
      . qq{${hero_sel}{font-size:clamp(64px,6.86vw,96px) !important;line-height:1.02em !important}}
      . q{.framer-pm057i,.framer-aqcw9y{place-content:center !important;align-items:center !important;padding-top:120px !important}}
      . q{section[data-framer-name="Hero"] [data-framer-background-image-wrapper]{filter:brightness(0.5) !important}}
      . q{video[data-bg-video]{filter:brightness(0.5)}}
      . q{section[data-framer-name="Team"] [data-framer-name="Image Wrap"]>div{top:0 !important;bottom:auto !important;transform:none !important}}
      . q{section[data-framer-name="Team"] img{object-fit:cover !important;object-position:center top !important}}
      . q{[data-framer-name="Pages links"] .framer-sePGo p{font-size:18px !important}}
      . q{[data-framer-name="Pages links"] [data-framer-name="Links"]{gap:20px !important}}
      . qq{\@media (min-width:810px) and (max-width:1023.98px){${hero_sel}{font-size:74px !important}}}
      . qq{\@media (max-width:809.98px){${hero_sel}{font-size:46px !important}}}
      . q{</style>};
    $html =~ s{</head>}{$hero_css\n</head>};
}

# --- creative button hover: lift + glow + a light shine sweeping across ---
if ($html !~ /id="igi-btn-hover"/) {
    my $btn_css = q{<style id="igi-btn-hover">}
      . q{.framer-LbxYV{position:relative;overflow:hidden;transition:transform .35s cubic-bezier(.22,1,.36,1),box-shadow .35s ease,filter .3s ease}}
      . q{.framer-LbxYV::before{content:"";position:absolute;top:0;left:-90%;width:60%;height:100%;background:linear-gradient(120deg,transparent,rgba(255,255,255,.6),transparent);transform:skewX(-22deg);pointer-events:none;z-index:6;opacity:0}}
      . q{.framer-LbxYV:hover{transform:translateY(-4px) scale(1.04);box-shadow:0 16px 34px rgba(253,204,5,.45);filter:brightness(1.05)}}
      . q{.framer-LbxYV:hover::before{opacity:1;animation:igi-shine .8s cubic-bezier(.4,0,.2,1)}}
      . q{.framer-LbxYV:active{transform:translateY(-1px) scale(1)}}
      . q{@keyframes igi-shine{0%{left:-90%}100%{left:140%}}}
      . q{@media(prefers-reduced-motion:reduce){.framer-LbxYV,.framer-LbxYV:hover{transform:none;transition:none}.framer-LbxYV:hover::before{animation:none;opacity:0}}}
      . q{</style>};
    $html =~ s{</head>}{$btn_css\n</head>};
}

# --- theme-color meta (only if not already present) ---
if ($html !~ /name="theme-color"/) {
    $html =~ s/(<meta name="viewport" content="width=device-width">)/$1\n    <meta name="theme-color" content="#ffffff">\n    <meta name="color-scheme" content="light only">\n    <meta name="apple-mobile-web-app-status-bar-style" content="default">/;
}

# --- strip Framer's live runtime: analytics beacon, module preloads, main bundle ---
$html =~ s{<script async src="https://events\.framer\.com/script\?v=2"[^>]*></script>}{}g;
$html =~ s{<link rel="modulepreload"[^>]*>}{}g;
$html =~ s{<script type="module" async data-framer-bundle="main"[^>]*>\s*</script>}{}g;

# --- strip Framer's inline bootstrap scripts (editor-bar check, modulepreload
# polyfill, variant-from-URL reader, appear-animation engine, date polyfills,
# process.env stub) -- none of them do anything useful without the removed
# main bundle to drive them, and one has a pre-existing syntax error ---
$html =~ s{<script>.*?</script>}{}gs;

# --- reveal sections that were left at opacity:0 waiting for Framer's
# scroll-triggered appear animation (that JS is gone now) ---
$html =~ s{style="([^"]*)"}{
    my $s = $1;
    if ($s =~ /opacity:0\.001(?![0-9])/ || $s =~ /opacity:0(?![.\d])/) {
        $s =~ s/opacity:0\.001(?![0-9])/opacity:1/;
        $s =~ s/opacity:0(?![.\d])/opacity:1/;
        $s =~ s/transform:[^;"]*/transform:none/;
    }
    qq{style="$s"};
}ge;

# --- add our own vanilla-JS menu toggle / form disable, if not already present ---
if ($html !~ /site\.js/) {
    $html =~ s{</body>}{    <script src="/site.js" defer></script>\n</body>};
}

open(my $out_fh, '>', $out) or die $!;
print $out_fh $html;
close $out_fh;

print "done: $in -> $out\n";
