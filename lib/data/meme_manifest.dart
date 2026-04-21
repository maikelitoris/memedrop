import '../models/meme_data.dart';
import '../models/meme.dart';

const List<MemeData> kMemeManifest = [
  // LEGENDARY
  MemeData(
    id: 'distracted_boyfriend',
    assetPath: 'assets/memes/legendary/distracted_boyfriend.png',
    rarity: Rarity.sigma,
    name: 'Distracted Boyfriend',
    era: '2017 – PEAK INTERNET',
    origin:
        'A stock photo by Antonio Guillem titled "Disloyal man walking with his girlfriend and looking amazed at another woman," sold on iStock for commercial licensing before the internet had other plans.',
    lore:
        'No meme has more efficiently mapped the human condition of wanting what you don\'t have. By late 2017 it had been deployed by the EU Parliament, philosophy departments, and at least three breakup texts. The girlfriend became a symbol of everything neglected — commitments, healthy habits, actual work — while the new woman represented every shiny distraction. Guillem himself, a Spanish photographer working out of Barcelona, had no idea the image would define an era. The photo has since been used in over 40 countries\' national news cycles.',
    peakEvent:
        'r/me_irl template post, August 21, 2017 — 180,000 upvotes in 24 hours',
    tags: ['template', 'relatable', 'stock-photo', 'universal'],
    isPlaceholder: false,
  ),

  // EPIC
  MemeData(
    id: 'drake_pointing',
    assetPath: 'assets/memes/epic/drake_pointing.png',
    rarity: Rarity.based,
    name: 'Drake Approves',
    era: '2016 – THE FORMAT WARS',
    origin:
        'Screenshots from Drake\'s 2015 "Hotline Bling" music video, specifically two frames: one where he recoils with disgust, another where he points approvingly.',
    lore:
        'The two-panel approval/disapproval format became the dominant meme template of 2016-2018, outlasting every competitor through sheer versatility. What makes it work is the physicality — Drake\'s expression in the reject panel is visceral revulsion, while the approve panel radiates warm satisfaction. It maps onto any preference statement with perfect clarity. In 2021, researchers studying internet linguistics cited it as the meme format most successful at encoding complex preference hierarchies in a single image. It has been used to explain quantum mechanics, geopolitical conflicts, and which pasta shape is superior.',
    peakEvent:
        'First major deployment on Twitter, January 2016, reaching 50k retweets within 48 hours',
    tags: ['format', 'approval', 'template', 'versatile'],
    isPlaceholder: false,
  ),
  MemeData(
    id: 'this_is_fine',
    assetPath: 'assets/memes/epic/this_is_fine.png',
    rarity: Rarity.based,
    name: 'This Is Fine',
    era: '2013 – ETERNAL RELEVANCE',
    origin:
        'A two-panel excerpt from KC Green\'s 2013 webcomic "Gunshow," originally titled "On Fire." The dog sits in a burning room sipping coffee, saying "This is fine."',
    lore:
        'Few memes have aged as well as This Is Fine, because the situation it describes has not improved. Originally a meditation on willful ignorance, it became the defining image of collective denial in the face of systemic problems. It appeared on the front page of major newspapers during the 2016 election, the COVID pandemic, multiple climate reports, and every financial crisis since 2013. KC Green maintained ownership of the image and licensed an official plush toy, one of the rare cases of a meme creator achieving financial recognition for their work. The dog has no name. The dog is all of us.',
    peakEvent: 'New York Times front-page editorial illustration, November 9, 2016',
    tags: ['existential', 'denial', 'eternal', 'relatable'],
    isPlaceholder: false,
  ),

  // RARE
  MemeData(
    id: 'surprised_pikachu',
    assetPath: 'assets/memes/rare/surprised_pikachu.png',
    rarity: Rarity.mid,
    name: 'Surprised Pikachu',
    era: '2018 – THE SCREENSHOT AGE',
    origin:
        'A screenshot from the Pokémon animated series, Season 1, Episode 10, capturing Pikachu\'s mouth-agape expression of shock during a completely mundane moment.',
    lore:
        'The format thrives on caused-and-then-surprised-by consequences — specifically the human tendency to create a situation and then be shocked when it unfolds exactly as expected. Its genius is accusatory: the person posting it is usually implicating themselves or someone else in spectacular self-unawareness. It spread rapidly through Tumblr in 2018 before colonizing Twitter, where its sharp edges suited the platform\'s culture of dunking. The irony of a children\'s cartoon character becoming a vehicle for adult cynicism was not lost on anyone.',
    peakEvent:
        'Tumblr post by user "pixelated-nightmare," October 2018 — 300k notes in a week',
    tags: ['reaction', 'irony', 'consequences', 'pokemon'],
    isPlaceholder: false,
  ),
  MemeData(
    id: 'grus_plan',
    assetPath: 'assets/memes/rare/grus_plan.png',
    rarity: Rarity.mid,
    name: "Gru's Plan",
    era: '2017 – FOUR PANELS OF TRUTH',
    origin:
        'Four screenshots from Despicable Me (2010) showing Gru presenting a plan on a whiteboard, where the final panel reveals the plan\'s flaw by repeating the third panel.',
    lore:
        'The brilliance of Gru\'s Plan is structural: it promises a four-step resolution and delivers a loop. The fourth panel always shows that step three — the problem — is also the outcome. It is the meme format most loved by programmers, economists, and anyone who has ever watched a meeting conclude with the same problem it started with. It encodes the tragedy of circular logic in a single image without requiring any text explanation. The format has been used to explain everything from procrastination to geopolitical policy failures.',
    peakEvent: 'Reddit r/dankmemes crosspost, March 2017 — 200k upvotes',
    tags: ['logic', 'circular', 'planning', 'four-panel'],
    isPlaceholder: false,
  ),
  MemeData(
    id: 'woman_yelling_cat',
    assetPath: 'assets/memes/rare/woman_yelling_cat.png',
    rarity: Rarity.mid,
    name: 'Woman Yelling at Cat',
    era: '2019 – THE DINNER TABLE',
    origin:
        'A composite of two separate images: a screengrab from The Real Housewives of Beverly Hills (2011) showing Taylor Armstrong mid-confrontation, paired with a 2018 photo of Smudge the cat sitting at a dinner table looking unimpressed.',
    lore:
        'The format\'s power comes from the collision of incompatible energies: maximum human emotional intensity versus complete feline indifference. Taylor Armstrong\'s visible distress was extracted from a serious argument; Smudge was just a cat at a table. Together they became the internet\'s premier shorthand for asymmetric conflict — usually deployed to describe being passionately wrong about something mundane. Smudge (real name: Smudge Lord) continued to live an uneventful life in Ottawa, unaware of his cultural footprint.',
    peakEvent:
        'Twitter viral composite post, May 2019 — 100k+ retweets overnight',
    tags: ['reaction', 'conflict', 'cat', 'two-part'],
    isPlaceholder: false,
  ),
  MemeData(
    id: 'two_buttons',
    assetPath: 'assets/memes/rare/two_buttons.png',
    rarity: Rarity.mid,
    name: 'Two Buttons',
    era: '2016 – THE SWEATING BEGINS',
    origin:
        'A webcomic panel by artist Jake Clark showing a man in a suit sweating profusely while hovering his finger between two large red buttons.',
    lore:
        'Two Buttons mapped perfectly onto the internet\'s experience of decision paralysis — specifically the kind where both options are bad, contradictory, or absurd. It became the dominant format for expressing cognitive dissonance: wanting two mutually exclusive things simultaneously. It was widely deployed during platform migrations, election seasons, and every time a TV show released two episodes on the same night. The sweating man became a mascot for a generation that was perpetually overwhelmed by choices designed to feel consequential.',
    peakEvent: 'Reddit front page, r/me_irl, February 2016',
    tags: ['decision', 'panic', 'two-options', 'relatable'],
    isPlaceholder: false,
  ),
  MemeData(
    id: 'expanding_brain',
    assetPath: 'assets/memes/rare/expanding_brain.png',
    rarity: Rarity.mid,
    name: 'Expanding Brain',
    era: '2017 – ENLIGHTENMENT TIERS',
    origin:
        'A four-to-eight panel format using a stock image series of a brain glowing progressively brighter, originally sourced from a neuroscience visualization.',
    lore:
        'Expanding Brain satirizes the human tendency to treat increasingly absurd or contrarian positions as signs of intellectual superiority. The format escalates from sensible to insane, with the most galaxy-brained take presented as cosmic enlightenment. It was adopted by philosophers, satirists, and irony-poisoned Twitter users who understood that sometimes the most sophisticated position is deliberately stupid. It spawned dozens of variants including the "galaxy brain" format and became a key text in discussions of online epistemology.',
    peakEvent:
        'r/MemeEconomy analysis post, April 2017 declaring it "the format of the year"',
    tags: ['irony', 'escalation', 'philosophy', 'tiers'],
    isPlaceholder: false,
  ),

  // COMMON
  MemeData(
    id: 'doge',
    assetPath: 'assets/memes/common/doge.png',
    rarity: Rarity.normie,
    name: 'Doge',
    era: '2013 – SUCH ORIGINS',
    origin:
        'A photo of Kabosu, a Shiba Inu rescue dog owned by Japanese kindergarten teacher Atsuko Sato, posted to her blog in 2010 with an expression of bemused sideways judgment.',
    lore:
        'Doge broke several rules of meme formation: it spawned its own dialect ("much wow," "so amaze," "very doge"), its own cryptocurrency (Dogecoin, which reached a \$85 billion market cap), and remained culturally legible for over a decade. Kabosu herself became one of the most photographed dogs in history. The internal monologue format — Comic Sans floating around the dog\'s head — was simple enough to be universal. In 2021 it became an NFT that sold for \$4 million. Kabosu died in May 2024, and the internet mourned genuinely.',
    peakEvent: 'Reddit r/pics post, October 2013 — front page within hours',
    tags: ['dog', 'dialect', 'cryptocurrency', 'iconic'],
    isPlaceholder: false,
  ),
  MemeData(
    id: 'grumpy_cat',
    assetPath: 'assets/memes/common/grumpy_cat.png',
    rarity: Rarity.normie,
    name: 'Grumpy Cat',
    era: '2012 – THE OG DISPLEASED',
    origin:
        'A photo of Tardar Sauce, a cat with feline dwarfism whose facial structure produced a permanently unhappy expression, posted to Reddit by her owner in September 2012.',
    lore:
        'Grumpy Cat became the first meme to achieve genuine mainstream celebrity status — TV appearances, a movie deal, merchandise empire, and a reported \$100 million in licensing revenue for her owner Tabatha Bundesen. Her expression, a product of biology rather than mood, became the internet\'s premier symbol of refusal: "No." She appeared on Time magazine and the cover of New York magazine. Tardar Sauce died in May 2019, and the outpouring of genuine grief confirmed she had crossed from meme to cultural institution.',
    peakEvent:
        'Good Morning America appearance, December 2012 — first meme on broadcast morning television',
    tags: ['cat', 'grumpy', 'no', 'classic'],
    isPlaceholder: false,
  ),
  MemeData(
    id: 'hide_pain_harold',
    assetPath: 'assets/memes/common/hide_pain_harold.png',
    rarity: Rarity.normie,
    name: 'Hide the Pain Harold',
    era: '2011 – STOCK PHOTO UPRISING',
    origin:
        'András Arató, a Hungarian electrical engineer, modeled for stock photos in Budapest and was later discovered on Facebook by meme creators who noticed his uncanny fixed smile masking evident inner turmoil.',
    lore:
        'What makes Harold extraordinary is the collaboration between subject and internet: after being discovered, Arató embraced the meme completely, giving interviews about it, appearing in commercials referencing it, and becoming a minor celebrity. The format — stock photo background, normal situation, Harold\'s haunted grin — described the particular exhaustion of performing happiness. It spread beyond English-speaking internet because the expression needs no translation. Harold is not hiding pain. Harold has simply accepted it.',
    peakEvent: 'Facebook group "Hide the Pain Harold" reaching 1 million members, 2015',
    tags: ['stock-photo', 'relatable', 'stoic', 'hungarian'],
    isPlaceholder: false,
  ),
  MemeData(
    id: 'mocking_spongebob',
    assetPath: 'assets/memes/common/mocking_spongebob.png',
    rarity: Rarity.normie,
    name: 'Mocking SpongeBob',
    era: '2017 – aLtErNaTiNg CaPs',
    origin:
        'A screenshot from SpongeBob SquarePants Season 9, Episode "Little Yellow Book" (2012), showing SpongeBob walking like a chicken — paired with alternating caps text to indicate a mocking repetition of someone\'s words.',
    lore:
        'The alternating capitals format (ThIs Is WhAt YoU sOuNd LiKe) predated the SpongeBob image but found its perfect visual partner in 2017. The format encodes contempt with a specific register: not aggressive anger but theatrical disdain. It spread fastest on Black Twitter before becoming universal. The chicken-walk pose contributed meaningfully — it implies the target is being imitated as something ridiculous. It remains one of the most easily readable formats because the visual grammar (alternating case = mockery) became genuinely codified in internet communication.',
    peakEvent:
        'Twitter viral deployment, May 5, 2017 — 200k retweets in two days',
    tags: ['mocking', 'spongebob', 'alternating-caps', 'contempt'],
    isPlaceholder: false,
  ),
  MemeData(
    id: 'left_exit_highway',
    assetPath: 'assets/memes/common/left_exit_highway.png',
    rarity: Rarity.normie,
    name: 'Left Exit 12',
    era: '2018 – THE TURN',
    origin:
        'A dashcam photo of a car swerving across lanes to take a highway exit at the last second, posted to Reddit and immediately recognized as a template for impulsive decisions.',
    lore:
        'The format captures a specific behavioral mode: knowing the correct path, then abandoning it for something irresistible at the last moment. The car becomes the ego; the exits become competing options. It works particularly well for describing addictions, procrastination, and irrational preferences because the reckless lane change implies physical urgency. The original photo was taken in Baltimore. Nobody knows who the driver is. They may not know they are famous.',
    peakEvent:
        'r/dankmemes crosspost chain, January 2018 — 15 variant posts in the top 50 simultaneously',
    tags: ['decision', 'impulsive', 'highway', 'template'],
    isPlaceholder: false,
  ),
  MemeData(
    id: 'galaxy_brain',
    assetPath: 'assets/memes/common/galaxy_brain.png',
    rarity: Rarity.normie,
    name: 'Galaxy Brain',
    era: '2017 – CURSED LOGIC',
    origin:
        'A derivative of the Expanding Brain format, "galaxy brain" became its own concept: a chain of technically-valid logical steps that arrives at an absurd or monstrous conclusion.',
    lore:
        'Galaxy brain is less a meme format than a diagnostic term. To say someone has "galaxy-brained" themselves into a position means they have followed logic so far it looped back to nonsense. It became a crucial piece of internet epistemology vocabulary, deployed in arguments about AI alignment, political philosophy, and why the protagonist of any given story made a terrible decision. The meme predates the term: any argument that sounds sophisticated until you reach its endpoint has galaxy brain energy.',
    peakEvent:
        'LessWrong community post coining the phrase, 2017, immediately adopted by rationalist Twitter',
    tags: ['logic', 'cursed', 'philosophy', 'reasoning'],
    isPlaceholder: false,
  ),
  MemeData(
    id: 'disaster_girl',
    assetPath: 'assets/memes/common/disaster_girl.png',
    rarity: Rarity.normie,
    name: 'Disaster Girl',
    era: '2004 – THE ORIGINAL CHAOS AGENT',
    origin:
        'Taken by Dave Roth in 2004 at a controlled house fire drill in Mebane, North Carolina, the image shows his four-year-old daughter Zoë Roth smirking at the camera while flames consume a house behind her.',
    lore:
        'What makes Disaster Girl endure is the purity of the expression: not malice, but complete satisfaction. Zoë Roth — now an adult — sold the original JPEG as an NFT in 2021 for \$500,000, achieving the rare feat of a meme subject reclaiming their own story and profiting from it. Her father Dave has spoken warmly about how the image changed their lives. The photo was actually taken during a community fire department training exercise; no one was in danger. The chaos is entirely aesthetic. Zoë is, and forever will be, the patron saint of controlled chaos.',
    peakEvent:
        'Something Awful forums discovery, 2008 — four years after the photo was taken',
    tags: ['chaos', 'classic', 'iconic', 'NFT-history'],
    isPlaceholder: false,
  ),
];

const kFallbackMeme = MemeData(
  id: '',
  assetPath: '',
  rarity: Rarity.normie,
  name: 'UNKNOWN',
  era: '???',
  origin: '',
  lore: '',
  peakEvent: '',
  tags: [],
  isPlaceholder: true,
);
