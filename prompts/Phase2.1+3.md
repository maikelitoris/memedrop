You are working on the Daily Meme Drop Flutter app. I have watched the live recording.
Here is exactly what the app looks like right now — use this as ground truth, not 
assumptions. Then implement Phase 2 polish and Phase 3.

---

### WHAT THE VIDEO SHOWS (live app state — read carefully)

HOME SCREEN:
- "DROP." title renders in a thin, elegant font (~w100), letterSpacing wide, 
  positioned roughly 1/3 down the screen — visually there is a LOT of dead black 
  space both above the title AND between the title and the vault container.
- Vault container: dark #141414 card, ~82% width, takes up the middle third of 
  the screen. Shows inventory_2_outlined icon + "SEALED" micro-text. 
  The breathing animation is working.
- "NEXT DROP: 06H 41M" shows in small caps below the container, correct.
- Settings icon (tune_rounded / sliders icon) is top-LEFT. Gallery grid icon top-RIGHT.
- NO streak badge visible (streak is 0/1, so correctly hidden).
- Dead space below the countdown to the bottom of screen is large — roughly 30% 
  of viewport is wasted empty black below the countdown text.

GALLERY ("THE HOARD"):
- "THE HOARD" title centered, back arrow top-left — correct.
- Stats pills ("1 STASHED", "1 • COMMON") appear as separate dark pill containers 
  BELOW the app bar, floating before the grid. They look disconnected — gap between 
  AppBar and pills, then another gap before the thumbnail grid starts.
- Thumbnail: shows a dark gray outer card with a lighter gray inner rectangle 
  (this is the placeholder image inside the card frame). The rarity border IS 
  visible as a thin white/gray glow but it's very faint — almost invisible.
- The thumbnail card appears to have padding/margin inside it showing the gray 
  background before the actual image placeholder begins. This inner/outer gray 
  nested look is unintentional — the card background bleeds around the image.

MEME VIEW SCREEN (after tapping through gallery):
- Black screen, "COMMON" badge top-right in a dark pill. Back arrow top-left.
- The meme placeholder (gray square) is TINY — roughly 160x140px, centered 
  vertically slightly above midpoint. Way too small relative to screen real estate.
- "SAVE TO CAMERA ROLL" button at very bottom — full width, dark background. 
  Correct styling.
- "ACQUIRED 04.19.26" micro-text below the button. Correct.
- No stash button visible (this was accessed from gallery, so correct behavior).
- The placeholder is far too small — should fill most of the screen width.

SETTINGS SCREEN:
- "SETTINGS" centered, back arrow top-left. Correct.
- All items visible: HAPTICS (toggle ON/right = white), CRT EFFECT (toggle ON), 
  DROP WINDOWS, ANONYMOUS ID (truncated), YOUR STREAK (shows "—"), 
  LONGEST STREAK "0 DAYS", TOTAL STASHED "1", STASH RATE "0%"
- "PURGE THE HOARD" button: correct red border, correct typography.
- STASH RATE shows "0%" despite 1 item stashed — this is the bug from Phase 2 
  polish fix #5 (stash flag not updating correctly). Confirm and fix.
- No HISTORY navigation row exists yet (Phase 3 feature — add it).
- Large empty space below PURGE THE HOARD — minor, acceptable.
- CRT EFFECT toggle shows ON (enabled) — scanlines should be visible on home 
  screen but aren't obviously rendering. Verify CRT overlay is actually applying.

---

### PHASE 2 POLISH — FIXES BASED ON VIDEO

**Fix 1 — Home screen vertical rhythm is broken:**
The layout currently stacks: [dead space] → [DROP.] → [dead space] → [vault] → 
[countdown] → [huge dead space].

Replace this with a Column inside a SafeArea using Spacer widgets:
```dart
Column(children: [
  SizedBox(height: 24),               // tight top breathing room
  _buildTitle(),                       // "DROP."
  SizedBox(height: 8),                // minimal gap
  _buildStreakBadge(),                 // zero-height if streak <= 1
  Spacer(flex: 2),                    // push vault toward center
  _buildVaultContainer(),             // the sealed/ready card
  Spacer(flex: 1),                    // smaller space below vault
  _buildCountdownOrTapLabel(),         // "NEXT DROP: Xh Ym" or "TAP TO OPEN"
  SizedBox(height: 48),               // comfortable bottom breathing room
])
```
This eliminates the huge dead zone below the countdown and vertically centers 
the vault with intentional asymmetry (more weight above than below).

**Fix 2 — Gallery stats pills look disconnected:**
The pills are floating between the AppBar and the grid with inconsistent spacing.
Move them into the AppBar's bottom property as a PreferredSize widget:
```dart
AppBar(
  title: Text("THE HOARD", ...),
  bottom: PreferredSize(
    preferredSize: Size.fromHeight(44),
    child: _buildStatsPillRow(),   // SingleChildScrollView horizontal pills
  ),
)
```
The pills should sit flush against the AppBar bottom edge with padding: 
EdgeInsets.fromLTRB(12, 0, 12, 8).
Remove the standalone pills row that currently floats above the grid.

**Fix 3 — Gallery thumbnail has nested gray-on-gray box visual:**
The card widget wraps the placeholder image in a Container with its own 
background, then the image placeholder ALSO has a gray background — creating 
a dark gray outer frame with lighter gray inner square.

Fix: the card Container background should be Colors.transparent or the rarity 
color only via border/shadow. The placeholder widget (when isPlaceholder is true 
in Phase 3, or the current gray square) should fill the card 100% with no inner 
padding. Use ClipRRect with the card's borderRadius on the image so it fills 
edge-to-edge.

The rarity glow border is too subtle (video confirms barely visible).
Increase: BoxShadow(color: rarityColor.withOpacity(0.5), blurRadius: 12, 
spreadRadius: 2) AND Border.all(color: rarityColor, width: 2.0).
For Common (#808080) this will still be subtle — that's intentional. Rare/Epic/
Legendary must be clearly visible.

**Fix 4 — Meme view placeholder is tiny:**
The meme placeholder/image in MemeViewScreen (soon to be MemeCardScreen) renders 
at ~160px. It should be treated like a full trading card:
- Width: MediaQuery.of(context).size.width * 0.82
- Aspect ratio: maintain 2.5:3.5 (portrait card ratio)
- This means on a 390px wide phone: card is ~320px wide, ~448px tall
- Center it vertically in the available space between AppBar and action bar

**Fix 5 — Stash rate shows 0% despite stashed items:**
Confirmed in video: Settings shows STASH RATE "0%" with TOTAL STASHED "1".
The drop history 'stashed' flag is not being updated to true when user stashes.

Fix in reveal_screen.dart / collection_service.dart:
- When "STASH TO GALLERY" is tapped: iterate drop_history list, find entry 
  matching the current drop's opened_at timestamp (within ±2 seconds tolerance), 
  set stashed: true, write back to prefs immediately.
- Stash rate formula: filter entries where stashed == true, divide by total 
  entries count. If total is 0: return null and display "—" not "0%".
- Add a debug log to verify the update is firing.

**Fix 6 — CRT scanlines may not be applying:**
Video shows CRT toggle is ON but no visible scanlines on home screen.
Verify CRTOverlay widget is in the widget tree ABOVE the scaffold content 
(wrapping the entire app, not just one screen). It should be in main.dart 
or the root widget, reading crt_effect_enabled from prefs via a provider.
If it's currently only on one screen, move it to wrap MaterialApp's home.

---

### PHASE 3: 3D MEME CARDS + MEME LORE

**Overview:**
Every meme is now a physical card — two-sided, draggable in 3D space.
Front: the meme (image or placeholder). Back: the Meme's Lore.
This replaces the current flat MemeViewScreen (frame_010 in the video — the tiny 
gray square on black) with a proper card experience.

---

**STEP 1: Meme Data Model + Manifest**

Create lib/models/meme_data.dart:
```dart
enum RarityTier { common, rare, epic, legendary }

class MemeData {
  final String id;
  final String assetPath;
  final RarityTier rarity;
  final String name;
  final String era;         // "2017 – PEAK INTERNET"
  final String origin;      // 1-2 sentences
  final String lore;        // 3-5 sentences, museum placard voice
  final String peakEvent;   // the moment it went nuclear
  final List<String> tags;  // ['relatable', 'template']
  final bool isPlaceholder; // true until real images are dropped in

  const MemeData({...});
}
```

Create lib/data/meme_manifest.dart with exactly 15 entries:

LEGENDARY (1):
```dart
MemeData(
  id: 'distracted_boyfriend',
  assetPath: 'assets/memes/legendary/distracted_boyfriend.png',
  rarity: RarityTier.legendary,
  name: 'Distracted Boyfriend',
  era: '2017 – PEAK INTERNET',
  origin: 'A stock photo by Antonio Guillem titled "Disloyal man walking with his girlfriend and looking amazed at another woman," sold on iStock for commercial licensing before the internet had other plans.',
  lore: 'No meme has more efficiently mapped the human condition of wanting what you don\'t have. By late 2017 it had been deployed by the EU Parliament, philosophy departments, and at least three breakup texts. The girlfriend became a symbol of everything neglected — commitments, healthy habits, actual work — while the new woman represented every shiny distraction. Guillem himself, a Spanish photographer working out of Barcelona, had no idea the image would define an era. The photo has since been used in over 40 countries\' national news cycles.',
  peakEvent: 'r/me_irl template post, August 21, 2017 — 180,000 upvotes in 24 hours',
  tags: ['template', 'relatable', 'stock-photo', 'universal'],
  isPlaceholder: true,
),
```

EPIC (2):
```dart
MemeData(
  id: 'drake_pointing',
  rarity: RarityTier.epic,
  name: 'Drake Approves',
  era: '2016 – THE FORMAT WARS',
  origin: 'Screenshots from Drake\'s 2015 "Hotline Bling" music video, specifically two frames: one where he recoils with disgust, another where he points approvingly.',
  lore: 'The two-panel approval/disapproval format became the dominant meme template of 2016-2018, outlasting every competitor through sheer versatility. What makes it work is the physicality — Drake\'s expression in the reject panel is visceral revulsion, while the approve panel radiates warm satisfaction. It maps onto any preference statement with perfect clarity. In 2021, researchers studying internet linguistics cited it as the meme format most successful at encoding complex preference hierarchies in a single image. It has been used to explain quantum mechanics, geopolitical conflicts, and which pasta shape is superior.',
  peakEvent: 'First major deployment on Twitter, January 2016, reaching 50k retweets within 48 hours',
  tags: ['format', 'approval', 'template', 'versatile'],
  isPlaceholder: true,
),

MemeData(
  id: 'this_is_fine',
  rarity: RarityTier.epic,
  name: 'This Is Fine',
  era: '2013 – ETERNAL RELEVANCE',
  origin: 'A two-panel excerpt from KC Green\'s 2013 webcomic "Gunshow," originally titled "On Fire." The dog sits in a burning room sipping coffee, saying "This is fine."',
  lore: 'Few memes have aged as well as This Is Fine, because the situation it describes has not improved. Originally a meditation on willful ignorance, it became the defining image of collective denial in the face of systemic problems. It appeared on the front page of major newspapers during the 2016 election, the COVID pandemic, multiple climate reports, and every financial crisis since 2013. KC Green maintained ownership of the image and licensed an official plush toy, one of the rare cases of a meme creator achieving financial recognition for their work. The dog has no name. The dog is all of us.',
  peakEvent: 'New York Times front-page editorial illustration, November 9, 2016',
  tags: ['existential', 'denial', 'eternal', 'relatable'],
  isPlaceholder: true,
),
```

RARE (5):
```dart
MemeData(
  id: 'surprised_pikachu',
  rarity: RarityTier.rare,
  name: 'Surprised Pikachu',
  era: '2018 – THE SCREENSHOT AGE',
  origin: 'A screenshot from the Pokémon animated series, Season 1, Episode 10, capturing Pikachu\'s mouth-agape expression of shock during a completely mundane moment.',
  lore: 'The format thrives on caused-and-then-surprised-by consequences — specifically the human tendency to create a situation and then be shocked when it unfolds exactly as expected. Its genius is accusatory: the person posting it is usually implicating themselves or someone else in spectacular self-unawareness. It spread rapidly through Tumblr in 2018 before colonizing Twitter, where its sharp edges suited the platform\'s culture of dunking. The irony of a children\'s cartoon character becoming a vehicle for adult cynicism was not lost on anyone.',
  peakEvent: 'Tumblr post by user "pixelated-nightmare," October 2018 — 300k notes in a week',
  tags: ['reaction', 'irony', 'consequences', 'pokemon'],
  isPlaceholder: true,
),

MemeData(
  id: 'grus_plan',
  rarity: RarityTier.rare,
  name: "Gru's Plan",
  era: '2017 – FOUR PANELS OF TRUTH',
  origin: 'Four screenshots from Despicable Me (2010) showing Gru presenting a plan on a whiteboard, where the final panel reveals the plan\'s flaw by repeating the third panel.',
  lore: 'The brilliance of Gru\'s Plan is structural: it promises a four-step resolution and delivers a loop. The fourth panel always shows that step three — the problem — is also the outcome. It is the meme format most loved by programmers, economists, and anyone who has ever watched a meeting conclude with the same problem it started with. It encodes the tragedy of circular logic in a single image without requiring any text explanation. The format has been used to explain everything from procrastination to geopolitical policy failures.',
  peakEvent: 'Reddit r/dankmemes crosspost, March 2017 — 200k upvotes',
  tags: ['logic', 'circular', 'planning', 'four-panel'],
  isPlaceholder: true,
),

MemeData(
  id: 'woman_yelling_cat',
  rarity: RarityTier.rare,
  name: 'Woman Yelling at Cat',
  era: '2019 – THE DINNER TABLE',
  origin: 'A composite of two separate images: a screengrab from The Real Housewives of Beverly Hills (2011) showing Taylor Armstrong mid-confrontation, paired with a 2018 photo of Smudge the cat sitting at a dinner table looking unimpressed.',
  lore: 'The format\'s power comes from the collision of incompatible energies: maximum human emotional intensity versus complete feline indifference. Taylor Armstrong\'s visible distress was extracted from a serious argument; Smudge was just a cat at a table. Together they became the internet\'s premier shorthand for asymmetric conflict — usually deployed to describe being passionately wrong about something mundane. Smudge (real name: Smudge Lord) continued to live an uneventful life in Ottawa, unaware of his cultural footprint.',
  peakEvent: 'Twitter viral composite post, May 2019 — 100k+ retweets overnight',
  tags: ['reaction', 'conflict', 'cat', 'two-part'],
  isPlaceholder: true,
),

MemeData(
  id: 'two_buttons',
  rarity: RarityTier.rare,
  name: 'Two Buttons',
  era: '2016 – THE SWEATING BEGINS',
  origin: 'A webcomic panel by artist Jake Clark showing a man in a suit sweating profusely while hovering his finger between two large red buttons.',
  lore: 'Two Buttons mapped perfectly onto the internet\'s experience of decision paralysis — specifically the kind where both options are bad, contradictory, or absurd. It became the dominant format for expressing cognitive dissonance: wanting two mutually exclusive things simultaneously. It was widely deployed during platform migrations, election seasons, and every time a TV show released two episodes on the same night. The sweating man became a mascot for a generation that was perpetually overwhelmed by choices designed to feel consequential.',
  peakEvent: 'Reddit front page, r/me_irl, February 2016',
  tags: ['decision', 'panic', 'two-options', 'relatable'],
  isPlaceholder: true,
),

MemeData(
  id: 'expanding_brain',
  rarity: RarityTier.rare,
  name: 'Expanding Brain',
  era: '2017 – ENLIGHTENMENT TIERS',
  origin: 'A four-to-eight panel format using a stock image series of a brain glowing progressively brighter, originally sourced from a neuroscience visualization.',
  lore: 'Expanding Brain satirizes the human tendency to treat increasingly absurd or contrarian positions as signs of intellectual superiority. The format escalates from sensible to insane, with the most galaxy-brained take presented as cosmic enlightenment. It was adopted by philosophers, satirists, and irony-poisoned Twitter users who understood that sometimes the most sophisticated position is deliberately stupid. It spawned dozens of variants including the "galaxy brain" format and became a key text in discussions of online epistemology.',
  peakEvent: 'r/MemeEconomy analysis post, April 2017 declaring it "the format of the year"',
  tags: ['irony', 'escalation', 'philosophy', 'tiers'],
  isPlaceholder: true,
),
```

COMMON (7):
```dart
MemeData(
  id: 'doge',
  rarity: RarityTier.common,
  name: 'Doge',
  era: '2013 – SUCH ORIGINS',
  origin: 'A photo of Kabosu, a Shiba Inu rescue dog owned by Japanese kindergarten teacher Atsuko Sato, posted to her blog in 2010 with an expression of bemused sideways judgment.',
  lore: 'Doge broke several rules of meme formation: it spawned its own dialect ("much wow," "so amaze," "very doge"), its own cryptocurrency (Dogecoin, which reached a $85 billion market cap), and remained culturally legible for over a decade. Kabosu herself became one of the most photographed dogs in history. The internal monologue format — Comic Sans floating around the dog\'s head — was simple enough to be universal. In 2021 it became an NFT that sold for $4 million. Kabosu died in May 2024, and the internet mourned genuinely.',
  peakEvent: 'Reddit r/pics post, October 2013 — front page within hours',
  tags: ['dog', 'dialect', 'cryptocurrency', 'iconic'],
  isPlaceholder: true,
),

MemeData(
  id: 'grumpy_cat',
  rarity: RarityTier.common,
  name: 'Grumpy Cat',
  era: '2012 – THE OG DISPLEASED',
  origin: 'A photo of Tardar Sauce, a cat with feline dwarfism whose facial structure produced a permanently unhappy expression, posted to Reddit by her owner in September 2012.',
  lore: 'Grumpy Cat became the first meme to achieve genuine mainstream celebrity status — TV appearances, a movie deal, merchandise empire, and a reported $100 million in licensing revenue for her owner Tabatha Bundesen. Her expression, a product of biology rather than mood, became the internet\'s premier symbol of refusal: "No." She appeared on Time magazine and the cover of New York magazine. Tardar Sauce died in May 2019, and the outpouring of genuine grief confirmed she had crossed from meme to cultural institution.',
  peakEvent: 'Good Morning America appearance, December 2012 — first meme on broadcast morning television',
  tags: ['cat', 'grumpy', 'no', 'classic'],
  isPlaceholder: true,
),

MemeData(
  id: 'hide_pain_harold',
  rarity: RarityTier.common,
  name: 'Hide the Pain Harold',
  era: '2011 – STOCK PHOTO UPRISING',
  origin: 'András Arató, a Hungarian electrical engineer, modeled for stock photos in Budapest and was later discovered on Facebook by meme creators who noticed his uncanny fixed smile masking evident inner turmoil.',
  lore: 'What makes Harold extraordinary is the collaboration between subject and internet: after being discovered, Arató embraced the meme completely, giving interviews about it, appearing in commercials referencing it, and becoming a minor celebrity. The format — stock photo background, normal situation, Harold\'s haunted grin — described the particular exhaustion of performing happiness. It spread beyond English-speaking internet because the expression needs no translation. Harold is not hiding pain. Harold has simply accepted it.',
  peakEvent: 'Facebook group "Hide the Pain Harold" reaching 1 million members, 2015',
  tags: ['stock-photo', 'relatable', 'stoic', 'hungarian'],
  isPlaceholder: true,
),

MemeData(
  id: 'mocking_spongebob',
  rarity: RarityTier.common,
  name: 'Mocking SpongeBob',
  era: '2017 – aLtErNaTiNg CaPs',
  origin: 'A screenshot from SpongeBob SquarePants Season 9, Episode "Little Yellow Book" (2012), showing SpongeBob walking like a chicken — paired with alternating caps text to indicate a mocking repetition of someone\'s words.',
  lore: 'The alternating capitals format (ThIs Is WhAt YoU sOuNd LiKe) predated the SpongeBob image but found its perfect visual partner in 2017. The format encodes contempt with a specific register: not aggressive anger but theatrical disdain. It spread fastest on Black Twitter before becoming universal. The chicken-walk pose contributed meaningfully — it implies the target is being imitated as something ridiculous. It remains one of the most easily readable formats because the visual grammar (alternating case = mockery) became genuinely codified in internet communication.',
  peakEvent: 'Twitter viral deployment, May 5, 2017 — 200k retweets in two days',
  tags: ['mocking', 'spongebob', 'alternating-caps', 'contempt'],
  isPlaceholder: true,
),

MemeData(
  id: 'left_exit_highway',
  rarity: RarityTier.common,
  name: 'Left Exit 12',
  era: '2018 – THE TURN',
  origin: 'A dashcam photo of a car swerving across lanes to take a highway exit at the last second, posted to Reddit and immediately recognized as a template for impulsive decisions.',
  lore: 'The format captures a specific behavioral mode: knowing the correct path, then abandoning it for something irresistible at the last moment. The car becomes the ego; the exits become competing options. It works particularly well for describing addictions, procrastination, and irrational preferences because the reckless lane change implies physical urgency. The original photo was taken in Baltimore. Nobody knows who the driver is. They may not know they are famous.',
  peakEvent: 'r/dankmemes crosspost chain, January 2018 — 15 variant posts in the top 50 simultaneously',
  tags: ['decision', 'impulsive', 'highway', 'template'],
  isPlaceholder: true,
),

MemeData(
  id: 'galaxy_brain',
  rarity: RarityTier.common,
  name: 'Galaxy Brain',
  era: '2017 – CURSED LOGIC',
  origin: 'A derivative of the Expanding Brain format, "galaxy brain" became its own concept: a chain of technically-valid logical steps that arrives at an absurd or monstrous conclusion.',
  lore: 'Galaxy brain is less a meme format than a diagnostic term. To say someone has "galaxy-brained" themselves into a position means they have followed logic so far it looped back to nonsense. It became a crucial piece of internet epistemology vocabulary, deployed in arguments about AI alignment, political philosophy, and why the protagonist of any given story made a terrible decision. The meme predates the term: any argument that sounds sophisticated until you reach its endpoint has galaxy brain energy.',
  peakEvent: 'LessWrong community post coining the phrase, 2017, immediately adopted by rationalist Twitter',
  tags: ['logic', 'cursed', 'philosophy', 'reasoning'],
  isPlaceholder: true,
),

MemeData(
  id: 'disaster_girl',
  rarity: RarityTier.common,
  name: 'Disaster Girl',
  era: '2004 – THE ORIGINAL CHAOS AGENT',
  origin: 'Taken by Dave Roth in 2004 at a controlled house fire drill in Mebane, North Carolina, the image shows his four-year-old daughter Zoë Roth smirking at the camera while flames consume a house behind her.',
  lore: 'What makes Disaster Girl endure is the purity of the expression: not malice, but complete satisfaction. Zoë Roth — now an adult — sold the original JPEG as an NFT in 2021 for $500,000, achieving the rare feat of a meme subject reclaiming their own story and profiting from it. Her father Dave has spoken warmly about how the image changed their lives. The photo was actually taken during a community fire department training exercise; no one was in danger. The chaos is entirely aesthetic. Zoë is, and forever will be, the patron saint of controlled chaos.',
  peakEvent: 'Something Awful forums discovery, 2008 — four years after the photo was taken',
  tags: ['chaos', 'classic', 'iconic', 'NFT-history'],
  isPlaceholder: true,
),
```

---

**STEP 2: Placeholder Asset Generation**

Run this script to create placeholder PNG files so flutter can reference them:
```bash
#!/bin/bash
mkdir -p assets/memes/legendary assets/memes/epic assets/memes/rare assets/memes/common

# Create 1x1 pixel PNG placeholders (actual rendering is done in code)
python3 -c "
import struct, zlib

def make_png(r, g, b):
    def chunk(name, data):
        c = zlib.crc32(name + data) & 0xffffffff
        return struct.pack('>I', len(data)) + name + data + struct.pack('>I', c)
    sig = b'\x89PNG\r\n\x1a\n'
    ihdr = chunk(b'IHDR', struct.pack('>IIBBBBB', 1, 1, 8, 2, 0, 0, 0))
    raw = b'\x00' + bytes([r, g, b])
    idat = chunk(b'IDAT', zlib.compress(raw))
    iend = chunk(b'IEND', b'')
    return sig + ihdr + idat + iend

files = {
    'assets/memes/legendary/distracted_boyfriend.png': (255, 215, 0),
    'assets/memes/epic/drake_pointing.png': (155, 89, 182),
    'assets/memes/epic/this_is_fine.png': (155, 89, 182),
    'assets/memes/rare/surprised_pikachu.png': (0, 212, 170),
    'assets/memes/rare/grus_plan.png': (0, 212, 170),
    'assets/memes/rare/woman_yelling_cat.png': (0, 212, 170),
    'assets/memes/rare/two_buttons.png': (0, 212, 170),
    'assets/memes/rare/expanding_brain.png': (0, 212, 170),
    'assets/memes/common/doge.png': (42, 42, 42),
    'assets/memes/common/grumpy_cat.png': (42, 42, 42),
    'assets/memes/common/hide_pain_harold.png': (42, 42, 42),
    'assets/memes/common/mocking_spongebob.png': (42, 42, 42),
    'assets/memes/common/left_exit_highway.png': (42, 42, 42),
    'assets/memes/common/galaxy_brain.png': (42, 42, 42),
    'assets/memes/common/disaster_girl.png': (42, 42, 42),
}

for path, (r, g, b) in files.items():
    with open(path, 'wb') as f:
        f.write(make_png(r, g, b))
    print(f'Created {path}')
"
```

Add all asset paths to pubspec.yaml assets section.

When isPlaceholder is true, render the card front as a colored Container 
(NOT Image.asset) — this avoids decode errors on the 1x1 PNGs:
- Legendary: #FFD700 bg, #000000 text
- Epic: #9B59B6 bg, #FFFFFF text
- Rare: #00D4AA bg, #000000 text
- Common: #2A2A2A bg, #808080 text

The placeholder Container shows: meme name in center (fontSize: 14, letterSpacing: 2, 
fontWeight: w600) + era text below (fontSize: 9, letterSpacing: 3, opacity: 0.6).

---

**STEP 3: 3D Card Widget**

Create lib/widgets/meme_card_3d.dart

The current MemeViewScreen (video: frame_010) shows a tiny gray square floating 
in a black void. Replace the ENTIRE meme viewing experience with this widget.

```dart
import 'dart:math' show pi;

class MemeCard3D extends StatefulWidget {
  final MemeData meme;
  final int acquiredAt;        // unix timestamp
  final bool viewOnly;         // true when opened from gallery (no stash button)
  final VoidCallback? onStash;
}

class _MemeCard3DState extends State<MemeCard3D> with TickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnim;
  bool _isFlipped = false;
  bool _isPanning = false;
  
  double _dragX = 0.0;   // Y-axis rotation from pan
  double _dragY = 0.0;   // X-axis rotation from pan
  
  late AnimationController _snapController;
  late Tween<double> _snapXTween;
  late Tween<double> _snapYTween;
  
  // Legendary glow pulse
  late AnimationController _glowController;
  
  static const double _maxTilt = 0.25;
  static const double _perspective = 0.0008;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 550),
    );
    _flipAnim = CurvedAnimation(
      parent: _flipController, 
      curve: Curves.easeInOutCubic,
    );
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _snapController.addListener(() {
      setState(() {
        _dragX = _snapXTween.evaluate(_snapController);
        _dragY = _snapYTween.evaluate(_snapController);
      });
    });
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  void _flip() {
    if (_isFlipped) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    _isFlipped = !_isFlipped;
    HapticFeedback.lightImpact();
  }

  void _onPanStart(DragStartDetails _) {
    _snapController.stop();
    setState(() => _isPanning = true);
  }

  void _onPanUpdate(DragUpdateDetails d) {
    setState(() {
      _dragX = (_dragX + d.delta.dx * 0.012).clamp(-_maxTilt, _maxTilt);
      _dragY = (_dragY - d.delta.dy * 0.012).clamp(-_maxTilt, _maxTilt);
    });
  }

  void _onPanEnd(DragEndDetails _) {
    setState(() => _isPanning = false);
    _snapXTween = Tween(begin: _dragX, end: 0.0);
    _snapYTween = Tween(begin: _dragY, end: 0.0);
    _snapController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final cardWidth = MediaQuery.of(context).size.width * 0.82;
    final rarityColor = AppColors.forRarity(widget.meme.rarity);
    
    return GestureDetector(
      onTap: _flip,
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: AnimatedBuilder(
        animation: Listenable.merge([_flipAnim, _glowController]),
        builder: (context, _) {
          final totalYRotation = _dragX + (_flipAnim.value * pi);
          final showBack = (totalYRotation % (2 * pi)).abs() > pi / 2 &&
                           (totalYRotation % (2 * pi)).abs() < 3 * pi / 2;
          
          final matrix = Matrix4.identity()
            ..setEntry(3, 2, _perspective)
            ..rotateX(_dragY)
            ..rotateY(totalYRotation);
          
          // Specular highlight position based on tilt
          final specX = (_dragX / _maxTilt + 1) / 2;
          final specY = (_dragY / _maxTilt + 1) / 2;
          
          // Legendary glow intensity
          double glowOpacity = 0;
          if (widget.meme.rarity == RarityTier.legendary) {
            glowOpacity = 0.3 + (_glowController.value * 0.4);
          }
          
          return Transform(
            transform: matrix,
            alignment: Alignment.center,
            child: SizedBox(
              width: cardWidth,
              child: AspectRatio(
                aspectRatio: 2.5 / 3.5,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: _buildBorder(rarityColor),
                    boxShadow: _buildShadow(rarityColor, glowOpacity),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Stack(
                      children: [
                        // Card face (front or back)
                        showBack
                          ? Transform(
                              transform: Matrix4.rotationY(pi),
                              alignment: Alignment.center,
                              child: _buildBackFace(),
                            )
                          : _buildFrontFace(),
                        // Specular overlay (only when panning)
                        if (_isPanning)
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  center: Alignment(
                                    specX * 2 - 1, 
                                    specY * 2 - 1,
                                  ),
                                  radius: 0.8,
                                  colors: [
                                    Colors.white.withOpacity(0.10),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Border _buildBorder(Color rarityColor) {
    return Border.all(
      color: rarityColor.withOpacity(
        widget.meme.rarity == RarityTier.common ? 0.4 : 0.8
      ),
      width: widget.meme.rarity == RarityTier.legendary ? 2.0 : 1.5,
    );
  }

  List<BoxShadow> _buildShadow(Color rarityColor, double glowOpacity) {
    if (widget.meme.rarity == RarityTier.common) return [];
    final baseOpacity = {
      RarityTier.rare: 0.4,
      RarityTier.epic: 0.5,
      RarityTier.legendary: glowOpacity,
    }[widget.meme.rarity] ?? 0.4;
    final blurRadius = {
      RarityTier.rare: 10.0,
      RarityTier.epic: 14.0,
      RarityTier.legendary: 24.0,
    }[widget.meme.rarity] ?? 10.0;
    return [
      BoxShadow(
        color: rarityColor.withOpacity(baseOpacity),
        blurRadius: blurRadius,
        spreadRadius: 2,
      ),
    ];
  }

  Widget _buildFrontFace() {
    final meme = widget.meme;
    return Stack(
      children: [
        // Meme content — fills entire card
        Positioned.fill(
          child: meme.isPlaceholder
            ? _buildPlaceholder()
            : Image.asset(meme.assetPath, fit: BoxFit.cover),
        ),
        // Bottom strip — name + rarity (gradient overlay)
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.85)],
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  meme.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9, letterSpacing: 2,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                // Rarity dot
                Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.forRarity(meme.rarity),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    final colors = {
      RarityTier.legendary: (const Color(0xFFFFD700), Colors.black),
      RarityTier.epic: (const Color(0xFF9B59B6), Colors.white),
      RarityTier.rare: (const Color(0xFF00D4AA), Colors.black),
      RarityTier.common: (const Color(0xFF2A2A2A), const Color(0xFF808080)),
    }[widget.meme.rarity]!;
    
    return Container(
      color: colors.$1,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.meme.name.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14, letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                  color: colors.$2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.meme.era,
                style: TextStyle(
                  fontSize: 9, letterSpacing: 3,
                  color: colors.$2.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackFace() {
    final meme = widget.meme;
    final rarityColor = AppColors.forRarity(meme.rarity);
    final acquired = DateTime.fromMillisecondsSinceEpoch(
      widget.acquiredAt * 1000,
    );
    final dateStr = 
      '${acquired.month.toString().padLeft(2,'0')}.'
      '${acquired.day.toString().padLeft(2,'0')}.'
      '${acquired.year.toString().substring(2)}';
    
    return Container(
      color: const Color(0xFF0D0D0D),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: rarityColor, width: 1),
                ),
                child: Text(
                  meme.rarity.name.toUpperCase(),
                  style: TextStyle(fontSize: 7, letterSpacing: 3, 
                    color: rarityColor),
                ),
              ),
              Text(
                meme.era,
                style: const TextStyle(fontSize: 7, letterSpacing: 2, 
                  color: Color(0xFF555555)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Name
          Text(
            meme.name.toUpperCase(),
            style: const TextStyle(fontSize: 15, letterSpacing: 2, 
              fontWeight: FontWeight.w700, color: Colors.white),
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            height: 1,
            color: rarityColor.withOpacity(0.4),
          ),
          // Origin
          _loreSection('ORIGIN', meme.origin, rarityColor),
          const SizedBox(height: 10),
          // Lore
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: _loreSection('LORE', meme.lore, rarityColor),
            ),
          ),
          const SizedBox(height: 8),
          // Peak moment
          _loreSection('PEAK MOMENT', meme.peakEvent, rarityColor, 
            italic: true),
          const SizedBox(height: 10),
          // Tags
          Wrap(
            spacing: 4, runSpacing: 4,
            children: meme.tags.map((t) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                t.toUpperCase(),
                style: const TextStyle(fontSize: 7, letterSpacing: 2, 
                  color: Color(0xFF555555)),
              ),
            )).toList(),
          ),
          const SizedBox(height: 10),
          // Acquired date
          Text(
            'ACQUIRED $dateStr',
            style: const TextStyle(fontSize: 7, letterSpacing: 2, 
              color: Color(0xFF3A3A3A)),
          ),
        ],
      ),
    );
  }

  Widget _loreSection(String label, String content, Color labelColor, 
      {bool italic = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 7, letterSpacing: 4, 
          color: labelColor)),
        const SizedBox(height: 4),
        Text(
          content,
          style: TextStyle(
            fontSize: 10, color: const Color(0xFFAAAAAA), height: 1.55,
            fontStyle: italic ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      ],
    );
  }
  
  @override
  void dispose() {
    _flipController.dispose();
    _snapController.dispose();
    _glowController.dispose();
    super.dispose();
  }
}
```

---

**STEP 4: MemeCardScreen (replaces MemeViewScreen)**

Create lib/screens/meme_card_screen.dart

This replaces the screen seen in the video (frame_010: tiny gray square on black).

```dart
class MemeCardScreen extends StatefulWidget {
  final MemeData meme;
  final CollectionItem item;
  final bool viewOnly;
  final bool isFirstView; // true = coming from reveal (show stash button)
}
```

Layout:
SafeArea
└── Column
├── _AppBar (transparent, back + rarity badge)  [56px]
├── Spacer
├── MemeCard3D(meme, acquiredAt, viewOnly)       [82% width, 2.5:3.5 ratio]
├── SizedBox(16)
├── _flipHintText()   ("TAP TO REVEAL LORE" — hidden after first flip)
├── Spacer
└── _actionBar()      [if !viewOnly: STASH button + acquired date]
[if viewOnly: just acquired date]

Flip hint: read pref 'has_flipped_card'. Show if false. On first flip detected 
(listen to MemeCard3D via callback or GlobalKey), set pref to true and 
AnimatedOpacity to 0. Never show again.

Action bar (only when !viewOnly):
```dart
Padding(
  padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
  child: Column(children: [
    GestureDetector(
      onTap: widget.onStash,
      child: Container(
        width: double.infinity, height: 48,
        color: const Color(0xFF1A1A1A),
        child: Center(child: Text(
          isLegendary ? '⚡ LEGENDARY ACQUIRED' : 'STASH TO GALLERY',
          style: TextStyle(
            fontSize: 11, letterSpacing: 3,
            color: isLegendary ? const Color(0xFFFFD700) : Colors.white,
          ),
        )),
      ),
    ),
    SizedBox(height: 8),
    Text('ACQUIRED $dateStr', 
      style: TextStyle(fontSize: 8, letterSpacing: 2, 
        color: const Color(0xFF444444))),
  ]),
)
```

Navigation from reveal: push with SlideTransition from bottom (500ms, easeOutCubic).
Navigation from gallery: push with Hero wrapping the card — Hero tag: 'meme_${meme.id}'.

---

**STEP 5: Gallery Hero + Long Press**

Wrap each gallery thumbnail's outer Container in:
```dart
Hero(
  tag: 'meme_${item.memeId}',
  child: _buildThumbnail(item),
)
```

Thumbnail long-press bottom sheet (replaces current if any):
```dart
showModalBottomSheet(
  context: context,
  backgroundColor: const Color(0xFF111111),
  builder: (_) => SafeArea(child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      _sheetButton('VIEW CARD', () { 
        Navigator.pop(context);
        // navigate to MemeCardScreen viewOnly
      }),
      Divider(color: const Color(0xFF1F1F1F), height: 1),
      _sheetButton('DELETE FROM HOARD', 
        color: const Color(0xFFFF3333), 
        onTap: () => _confirmDelete(context, item)),
    ],
  )),
);
```

---

**STEP 6: Asset Service Wiring**

Update AssetService (or DropService) to select memes from the manifest:
```dart
MemeData selectRandomMeme() {
  final rand = Random();
  final roll = rand.nextDouble();
  
  RarityTier tier;
  if (roll < 0.01) tier = RarityTier.legendary;       // 1%
  else if (roll < 0.05) tier = RarityTier.epic;        // 4%
  else if (roll < 0.30) tier = RarityTier.rare;        // 25%
  else tier = RarityTier.common;                        // 70%
  
  final pool = kMemeManifest.where((m) => m.rarity == tier).toList();
  return pool[rand.nextInt(pool.length)];
}
```

CollectionItem needs a memeId field added (String). On stash, store item.memeId = meme.id. In gallery and history, look up MemeData by id: `kMemeManifest.firstWhere((m) => m.id == item.memeId)`.

---

**STEP 7: Meme History Screen ("THE LOG")**

Create lib/screens/meme_history_screen.dart

Access from Settings — add before PURGE THE HOARD:
```dart
_settingsNavRow('HISTORY', 'THE LOG', Icons.chevron_right, () {
  Navigator.push(context, MaterialPageRoute(
    builder: (_) => const MemeHistoryScreen()
  ));
}),
```

Screen layout:
- Title: "THE LOG", subtitle: "EVERY DROP. EVEN THE ONES YOU LET GO."
- Empty: "Nothing has been dropped yet.\nThe void stares back."
- ListView.builder (newest first) from drop_history prefs

Each row (height: 56px):
Row(children: [
// Rarity dot
Container(width: 6, height: 6, shape: circle, color: rarityColor),
SizedBox(width: 12),
// Name + timestamp
Column(crossAxisAlignment: start, children: [
Text(memeName, 12sp, white, letterSpacing:1),
Text('$dateFormatted · $timeFormatted', 9sp, #444444),
]),
Spacer(),
// Status
Text(
entry.stashed ? 'STASHED' : 'LOST',
style: TextStyle(
fontSize: 8, letterSpacing: 2,
color: entry.stashed ? rarityColor : const Color(0xFF333333),
),
),
])

Tap any row → MemeCardScreen in viewOnly mode. Look up MemeData by 
entry.memeId from the manifest.

---

**IMPLEMENTATION ORDER:**

1. Run placeholder PNG generation script
2. pubspec.yaml — add asset paths, verify packages
3. lib/models/meme_data.dart
4. lib/data/meme_manifest.dart (all 15, full lore — do not skip any fields)
5. Update CollectionItem to include memeId: String
6. Update AssetService — selectRandomMeme() from manifest
7. lib/widgets/meme_card_3d.dart
8. lib/screens/meme_card_screen.dart
9. Wire reveal → MemeCardScreen transition
10. Gallery Hero tags + long-press sheet
11. lib/screens/meme_history_screen.dart
12. Settings HISTORY nav row
13. Phase 2 polish fixes (all 6, in order)
14. flutter analyze — zero warnings
15. Manual test path: open drop → reveal → card → flip → lore → stash → 
    gallery → tap → Hero → card view → Settings → History → see entry

**DO NOT:**
- Use any 3D Flutter package — pure Matrix4 only
- Use real meme images — placeholder system only
- Alter the time-gating or UTC drop logic
- Add any border-radius > 12px anywhere
- Add any networking, accounts, or cloud features
- Rename existing screen files that are working — extend them