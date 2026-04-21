# Phase 4 — Leveling, Rarity Rework & Opening Experience

---

## 1. Rarity Tier Rename

Replace all existing rarity labels across the codebase, UI, and database:

| Old Name       | New Name  | Vibe                                                                 |
|----------------|-----------|----------------------------------------------------------------------|
| Common         | **Normie**  | Default, everywhere, no sauce. Basic as hell.                     |
| Rare/Uncommon  | **Mid**     | Kinda okay, gets a chuckle, dies fast.                            |
| Epic           | **Based**   | Solid, hits different, has spice. People respect it.              |
| Unique         | **Dank**    | Smooth, charismatic, pulls hard. Rare enough to make you go "damn". |
| Legendary      | **Sigma**   | Absolute peak. Lone wolf energy. Timeless, mythical. Almost never drops. |

### Rarity Color Palette

```
Normie  →  #9E9E9E  (grey)
Mid     →  #4FC3F7  (light blue)
Based   →  #AB47BC  (purple)
Dank    →  #FF7043  (deep orange)
Sigma   →  #FFD700  (gold)
```

---

## 2. Card Leveling System

### 2.1 Overview

Each card has **5 levels** (1–5). Leveling requires collecting duplicate copies of the same card. The number of duplicates needed per level **increases with level** but **decreases with rarity** — rarer cards level up faster.

### 2.2 Copies Required Per Level Transition

| Level Transition | Normie | Mid | Based | Dank | Sigma |
|-----------------|--------|-----|-------|------|-------|
| Lv 1 → 2       | 6      | 4   | 3     | 2    | 1     |
| Lv 2 → 3       | 8      | 6   | 4     | 3    | 2     |
| Lv 3 → 4       | 12     | 8   | 6     | 4    | 2     |
| Lv 4 → 5       | 18     | 12  | 8     | 5    | 3     |

### 2.3 Data Model

```ts
interface CardInstance {
  cardId: string;           // base meme ID
  rarity: Rarity;           // 'normie' | 'mid' | 'based' | 'dank' | 'sigma'
  level: number;            // 1–5
  experience: number;       // duplicate copies accumulated (resets per level)
  experienceToNext: number; // copies needed to reach next level (null at lv 5)
  acquiredAt: string;       // ISO timestamp
  unlockedLoreSegments: number[]; // indices of revealed lore sections (see §3)
}
```

### 2.4 Auto-Collection Logic

When a player opens a pack and receives a card:

1. **Check gallery** — does `cardId` already exist for this player?
2. **No** → Create new `CardInstance` at `level: 1, experience: 0`.
3. **Yes** → Increment `experience` by 1. If `experience >= experienceToNext`:
   - Increment `level` (cap at 5).
   - Reset `experience` to overflow (`experience - experienceToNext`).
   - Update `experienceToNext` from the table above.
   - Trigger level-up animation + unlock next lore segment.

```ts
function addCardToGallery(playerId: string, cardId: string, rarity: Rarity) {
  const existing = db.getCardInstance(playerId, cardId);

  if (!existing) {
    db.createCardInstance({ playerId, cardId, rarity, level: 1, experience: 0 });
    return { isNew: true, levelUp: false };
  }

  if (existing.level === 5) {
    // Max level — still track as "stash bonus" or convert to currency
    return { isNew: false, levelUp: false, maxLevel: true };
  }

  const threshold = LEVEL_THRESHOLDS[rarity][existing.level]; // existing.level is current (1-4)
  const newExp = existing.experience + 1;

  if (newExp >= threshold) {
    const newLevel = existing.level + 1;
    const overflow = newExp - threshold;
    db.updateCardInstance(playerId, cardId, {
      level: newLevel,
      experience: overflow,
      unlockedLoreSegments: getLoreSegmentsForLevel(newLevel),
    });
    return { isNew: false, levelUp: true, newLevel };
  }

  db.updateCardInstance(playerId, cardId, { experience: newExp });
  return { isNew: false, levelUp: false };
}

const LEVEL_THRESHOLDS: Record<Rarity, Record<number, number>> = {
  normie: { 1: 6,  2: 8,  3: 12, 4: 18 },
  mid:    { 1: 4,  2: 6,  3: 8,  4: 12 },
  based:  { 1: 3,  2: 4,  3: 6,  4: 8  },
  dank:   { 1: 2,  2: 3,  3: 4,  4: 5  },
  sigma:  { 1: 1,  2: 2,  3: 2,  4: 3  },
};
```

---

## 3. Lore Unlock System (Card Back)

The card back contains **4 information segments**. Each level unlocks the next segment progressively. At Level 1 everything is hidden/blurred. At Level 5 everything is fully revealed.

### 3.1 Segment Mapping

| Level | Unlocked Segment        | Content                             |
|-------|-------------------------|-------------------------------------|
| 1     | *(nothing revealed)*    | All sections blurred/locked         |
| 2     | **Origin**              | Where/how the meme was first posted |
| 3     | **Lore**                | Cultural meaning and behavioral mode |
| 4     | **Peak Moment**         | The moment it hit critical mass     |
| 5     | **Tags + Full Credits** | All metadata, tags, acquisition info |

### 3.2 Visual Treatment

- Locked segments: `backdrop-filter: blur(12px)` + semi-transparent overlay with a padlock icon.
- On unlock: blur dissolves with a 600ms ease-out transition + a golden shimmer sweep animation.
- Level indicator on card back shows current unlock state clearly.

```css
.lore-segment {
  transition: filter 0.6s ease-out, opacity 0.6s ease-out;
}
.lore-segment.locked {
  filter: blur(12px);
  opacity: 0.3;
  pointer-events: none;
}
.lore-segment.unlocking {
  animation: shimmer-reveal 0.8s ease-out forwards;
}

@keyframes shimmer-reveal {
  0%   { filter: blur(12px); opacity: 0.3; }
  50%  { filter: blur(4px);  opacity: 0.7; background: rgba(255,215,0,0.15); }
  100% { filter: blur(0px);  opacity: 1;   background: transparent; }
}
```

---

## 4. Gallery Card Display

Each card in the gallery grid must display:

- **Card image** (front face)
- **Rarity badge** (new label + color)
- **Level indicator**: `LV 3` in bold, positioned top-left or bottom overlay
- **XP bar**: thin progress bar at bottom of card showing `experience / experienceToNext`
  - At max level (5), bar fills fully gold with a ★ icon replacing the fraction
- **Lore unlock indicator**: small icon row showing which segments are revealed (e.g. 4 dots, some lit)

### Gallery Card Component Spec

```tsx
<CardTile>
  <RarityGlow rarity={card.rarity} />         // colored drop shadow/glow
  <CardImage src={card.imageUrl} />
  <LevelBadge>LV {card.level}</LevelBadge>
  <XPBar value={card.experience} max={card.experienceToNext} />
  <LoreProgress segments={card.unlockedLoreSegments} total={4} />
  <RarityLabel rarity={card.rarity} />         // "SIGMA", "DANK", etc.
</CardTile>
```

---

## 5. Image Size Standardization

All meme card PNGs must be exported/stored at a **unified canvas size** to prevent layout inconsistency.

### 5.1 Required Dimensions

| Asset Type        | Width | Height | Aspect Ratio | Notes                                       |
|-------------------|-------|--------|--------------|---------------------------------------------|
| Card front face   | 800px | 1120px | ~5:7         | Standard trading card ratio                 |
| Card back face    | 800px | 1120px | 5:7          | Same canvas as front                        |
| Gallery thumbnail | 400px | 560px  | 5:7          | 50% of master, used in grid                 |
| Detail view full  | 800px | 1120px | 5:7          | Full-res served on card tap                 |

### 5.2 Meme Image Placement Rules

Because meme source images vary in aspect ratio, use a **centered crop + letterbox** approach:

```
┌──────────────────────┐  ← 800px wide
│  ░░░░ padding ░░░░░  │  ← 40px top
│  ┌────────────────┐  │
│  │                │  │  ← meme image object-fit: cover
│  │   MEME IMAGE   │  │     centered, fills this zone
│  │                │  │
│  └────────────────┘  │  ← zone height: 680px
│  ░ rarity / title ░  │  ← 400px bottom info area
└──────────────────────┘
```

- Source images should be **minimum 720px wide** before processing.
- On ingest, server-side crop to fill the 800×680 image zone using `sharp` or equivalent:

```ts
await sharp(inputBuffer)
  .resize(720, 612, { fit: 'cover', position: 'center' })
  .toFile(outputPath);
```

---

## 6. CS:GO-Style Box Opening Animation

Replace the current tap-to-open animation with a **CS:GO case opening reel** — a horizontally scrolling strip of rarity tiles that decelerates and lands on the result.

### 6.1 Flow

```
[TAP TO OPEN]
     ↓
Screen dims, box pulses
     ↓
Reel appears — fast scroll of colored rarity tiles
(Normie grey, Mid blue, Based purple, Dank orange, Sigma gold)
     ↓
Reel decelerates with ease-out over ~3 seconds
     ↓
Lands on result tile — that tile scales up, glows
     ↓
Card flips in with reveal animation
     ↓
"NEW CARD" or "LV UP" state shown
```

### 6.2 Reel Generation Algorithm

```ts
function generateReel(resultRarity: Rarity): Rarity[] {
  const reel: Rarity[] = [];
  const weights = { normie: 60, mid: 25, based: 10, dank: 4, sigma: 1 };
  
  // ~28 random tiles before the result
  for (let i = 0; i < 28; i++) {
    reel.push(weightedRandom(weights));
  }
  
  // 3 tiles of tension near the end — escalating rarities
  reel.push('mid');
  reel.push('based');
  
  // The winner lands at index 31
  reel.push(resultRarity);
  
  // 3 tiles after (never shown but needed for centering)
  for (let i = 0; i < 3; i++) {
    reel.push(weightedRandom(weights));
  }
  
  return reel; // 34 tiles total, result at [31]
}
```

### 6.3 CSS Animation Spec

```css
.reel-container {
  width: 100vw;
  overflow: hidden;
  position: relative;
}

.reel-track {
  display: flex;
  gap: 8px;
  animation: reel-spin var(--spin-duration, 3.5s) cubic-bezier(0.05, 0.9, 0.3, 1) forwards;
  will-change: transform;
}

/* translateX moves the reel so tile[31] lands centered */
@keyframes reel-spin {
  from { transform: translateX(0); }
  to   { transform: translateX(calc(-1 * var(--target-offset))); }
}

.reel-tile {
  width: 80px;
  height: 110px;
  flex-shrink: 0;
  border-radius: 8px;
  border: 2px solid rgba(255,255,255,0.1);
}

/* Center indicator line */
.reel-container::after {
  content: '';
  position: absolute;
  left: 50%;
  top: 0;
  bottom: 0;
  width: 3px;
  background: rgba(255,255,255,0.9);
  box-shadow: 0 0 12px rgba(255,255,255,0.8);
  pointer-events: none;
  z-index: 10;
}
```

### 6.4 Reel Tile Colors

```ts
const RARITY_COLORS = {
  normie: { bg: '#3a3a3a', border: '#9E9E9E', glow: 'none' },
  mid:    { bg: '#0d3b52', border: '#4FC3F7', glow: '0 0 16px #4FC3F7' },
  based:  { bg: '#2d1040', border: '#AB47BC', glow: '0 0 16px #AB47BC' },
  dank:   { bg: '#3d1a00', border: '#FF7043', glow: '0 0 20px #FF7043' },
  sigma:  { bg: '#2d2000', border: '#FFD700', glow: '0 0 28px #FFD700, 0 0 56px #FFD70055' },
};
```

### 6.5 Landing State

When the reel stops, the winning tile:
1. Scales to `1.2` with a 200ms spring
2. Its glow pulses 3 times
3. After 800ms, transition to card reveal:
   - Black overlay fades in
   - Card flips from back → front (3D CSS flip)
   - Card rarity glow blooms outward

### 6.6 Box Design (Main Screen)

Replace the current archive box icon with a styled **meme drop crate**:

```
┌─────────────────────────────┐
│  ╔═══════════════════════╗  │
│  ║  D  R  O  P  .       ║  │  ← spaced monospace
│  ╚═══════════════════════╝  │
│                             │
│   ┌─────────────────────┐   │
│   │  ╔═══════════════╗  │   │
│   │  ║   ███████████ ║  │   │  ← crate graphic with
│   │  ║   ░░  MEME  ░ ║  │   │    scanline texture
│   │  ║   ███████████ ║  │   │    + pulsing rarity glow
│   │  ╚═══════════════╝  │   │    on the border
│   │    T A P  T O  O P E N  │
│   └─────────────────────┘   │
└─────────────────────────────┘
```

- Crate border should pulse slowly with a **mixed rarity gradient** (cycling through all 5 rarity colors over 4s).
- Add subtle **floating particle effect** around crate (small colored dots drifting upward).
- On tap: crate **shakes** for 300ms → **explodes outward** with a burst of particles → reel appears.

---

## 7. Max Level Handling

When a card is at **Level 5** and a duplicate is received:

- Do NOT increment experience/level.
- Award **Meme Coins** (or equivalent currency) instead:
  ```
  Normie dupe at max  →  +5 coins
  Mid dupe at max     →  +15 coins
  Based dupe at max   →  +40 coins
  Dank dupe at max    →  +100 coins
  Sigma dupe at max   →  +300 coins
  ```
- Show a toast: `"Already maxed! +X coins instead."`

---

## 8. Implementation Checklist

### Backend
- [ ] Rename rarity enum values across DB and API
- [ ] Add `level`, `experience`, `unlockedLoreSegments` to card instance schema
- [ ] Implement `addCardToGallery()` with auto-level logic
- [ ] Add `LEVEL_THRESHOLDS` config
- [ ] Add max-level coin conversion endpoint

### Frontend
- [ ] Update all rarity badge labels and color tokens
- [ ] Build `XPBar` component
- [ ] Build `LoreSegment` component with blur/unlock states
- [ ] Update `CardTile` in gallery with level + XP display
- [ ] Build CS:GO reel component (`ReelStrip`, `ReelTile`)
- [ ] Build new crate opening screen (replace archive icon)
- [ ] Add reel landing + card flip animation
- [ ] Add level-up celebration overlay

### Assets
- [ ] Define image pipeline: ingest → `sharp` resize → 800×1120 canvas
- [ ] Re-export all existing meme cards to unified size
- [ ] Create card back template with 4 segmented lore zones
- [ ] Design reel tile graphics per rarity

---

## 9. Resolved Design Decisions

| Question | Decision | Notes |
|----------|----------|-------|
| Lore authoring | **Manually curated** | All Origin, Lore, Peak Moment, and Tags copy is written by hand per card. No AI generation. Build a CMS-friendly schema so editors can fill fields easily. |
| Sigma drop frequency | **Purely weighted random** | No pity system or guaranteed floor. Sigma remains genuinely mythical — players cannot calculate or predict when one drops. |
| Reel skip | **Not skippable** | The full animation always plays. Keeps the tension and ritual consistent for every open. |
| Prestige beyond Level 5 | **None for now** | Level 5 is the hard ceiling. Max-level dupes convert to coins (see §7). Prestige can be revisited in a future phase. |

### Implications for Lore Authoring

Since lore is manually curated, the content pipeline must include:

- A **card content schema** with four required text fields: `origin`, `lore`, `peakMoment`, and `tags[]`.
- All four fields must be filled before a card can be published — no partial cards in production.
- Recommended field length limits:
  ```
  origin:     80–160 chars  (one punchy paragraph)
  lore:       160–320 chars (two paragraphs max)
  peakMoment: 60–120 chars  (one line, specific date/event)
  tags:       3–6 tags, each under 20 chars
  ```
- The card admin panel should show a **preview of the blurred card back** so editors can see exactly how each segment will look locked vs unlocked before publishing.
