# ClipNotch User Guide & Customization Reference

ClipShot transforms the physical MacBook display notch (or standard menu bar on external monitors) into **ClipNotch**: a fluid, tactile status capsule running at 120Hz ProMotion speeds.

---

## 🌟 Interactive Capsules

ClipNotch dynamically shifts states based on what you are doing:

1. **Idle Capsule**: A discreet pill matching the display notch contour. Features subtle breathing pulses or ambient Album Aura when music is playing.
2. **Screenshot Capsule**: Expands the moment a screenshot is captured. Provides an instant thumbnail preview, copy confirmation indicator, one-click OCR extraction, and markup launcher.
3. **Music & Now Playing Capsule**: Shows live track title, artist name, interactive play/pause and skip controls, and an interactive seek scrubber. Supports Apple Music, Spotify, Podcasts, and Web browsers.
4. **Recent Captures Shelf**: Displays a horizontal carousel of recent screenshots for quick drag-and-drop into apps like Slack, Notion, or Figma.
5. **Screen Recording Capsule**: Shows an elapsed duration timer, live audio wave animation, and a quick-stop action button during screen captures.
6. **Video Capsule (Picture-in-Picture)**: Embeds compact video playback streams directly within the notch contour.

---

## 🎨 Themes & Customization

ClipNotch can be fully tailored in **ClipShot Settings → ClipNotch**.

### 1. Curated Colorways (14 Palettes)
Each colorway provides an energetic 3-color palette driving the notch's glowing rail and interactive controls:

| Colorway | Key Tones | Feel |
| :--- | :--- | :--- |
| **Prism** (Default) | Sky Blue (`#64D8FF`), Violet (`#A78BFA`), Rose (`#FB7185`) | Crisp, vibrant, modern macOS feel |
| **Aurora** | Mint (`#5EF2C2`), Azure (`#39C6FF`), Indigo (`#7C83FF`) | Northern lights atmospheric glow |
| **Ember** | Coral (`#FFB45E`), Salmon (`#FF6B7A`), Purple (`#C86BFF`) | Warm, sunset-inspired contrast |
| **Tidal** | Teal (`#4DE1E8`), Cerulean (`#72A7FF`), Cobalt (`#465BFF`) | Deep oceanic gradients |
| **Cyberpunk** | Neon Green (`#00F5D4`), Magenta (`#F72585`), Violet (`#7209B7`) | High-contrast neon nightscape |
| **Solaris** | Amber (`#FFD166`), Sunset Red (`#FF6B6B`), Crimson (`#D11149`) | Golden solar flair |
| **Matrix** | Terminal Green (`#00FF87`), Cyan (`#60EFFF`), Blue (`#0061FF`) | Retro digital terminal aesthetic |
| **Cosmic** | Indigo (`#818CF8`), Orchid (`#C084FC`), Pink (`#F472B6`) | Interstellar nebular glow |
| **Synthwave** | Yellow (`#FEE140`), Pink (`#FA709A`), Purple (`#9B51E0`) | 80s retro-futuristic arcade |
| **Sakura** | Cherry Blossom (`#FF9A9E`), Blush (`#FECFEF`), Lavender (`#A18CD1`) | Gentle pastel floral tones |
| **Arctic** | Ice Blue (`#A1C4FD`), Frost (`#C2E9FB`), Lilac (`#E0C3FC`) | Clean cool winter tones |
| **Champagne** | Gold (`#F6D365`), Peach (`#FDA085`), Bronze (`#D4AF37`) | Luxurious warm metallic tones |
| **Monochrome** | Pure White (`#F5F7FA`), Slate (`#AAB3C2`), Charcoal (`#687386`) | Minimalist, distraction-free neutral |
| **Album Aura** | Dynamic (Sampled from Album Art) | Automatically samples 3 colors from active music |

### 2. Tactile Finishes (6 Materials)
- **Obsidian**: Deep pitch-black background with subtle high-contrast borders.
- **Glass**: Translucent frosted glass effect blending into wallpaper.
- **Bloom**: Soft radiant back-glow expanding beyond the capsule outline.
- **Titanium**: Matte metallic texture inspired by Apple hardware.
- **Neon Aura**: High-energy perimeter neon tube lighting.
- **Frosted**: Heavy blur acrylic material.

### 3. Spring Motion Profiles
- **Fluid** (Default): Balanced spring tuned for natural macOS feel (120Hz ProMotion optimized).
- **Calm**: Gentle, relaxed easing for minimal distraction.
- **Snappy**: Instantaneous, punchy response for high-speed workflows.
- **Pulse**: Rhythmic breathing feedback on interactions.
- **Bouncy**: Playful elastic overshoot.

### 4. Sizing Presets
- **Compact**: Tight pill footprint matching narrow display bezels.
- **Normal**: Standard MacBook Pro 14" & 16" notch width.
- **Large**: Extended width with wider title and scrubber readout.
- **Extra Large**: Spacious view for multi-action controls.
- **Ultra Wide**: Broad horizontal command station.
- **Studio / Max**: Maximum canvas for Studio Display and external 4K/5K monitors.

### 5. Placement Options
- **Top Header**: Anchored to the top bezel, aligning seamlessly with the hardware camera notch.
- **Below Menu Bar**: Sits directly underneath the system menu bar.
- **Free Floating Island**: Detached floating pill that can be positioned anywhere on screen.

---

## 🖥️ Multi-Display & External Monitors

ClipShot includes an intelligent **`DisplayTrackingService`** that tracks active screen geometry across hot-plugged displays:

- **Built-in MacBook Display**: If the active screen has a physical camera notch, ClipNotch anchors inside the hardware notch housing.
- **External Monitors (Studio Display, Pro Display XDR, Ultrawide)**: When active on non-notch displays, ClipNotch smoothly transitions into a floating menu bar pill or centered header dock.
- **Cursor Tracking**: ClipNotch can follow your active display based on mouse cursor focus or user configuration.

---

## 🎵 Album Aura Extraction

When playing music in Apple Music or Spotify, the **Album Aura** colorway dynamically extracts a harmonized palette:
1. **Dominant Tone**: Primary hue identified from artwork pixel distribution, applied to the main glowing rail.
2. **Complementary Accent**: High-contrast secondary hue applied to action buttons and scrubbers.
3. **Ambient Halo**: Desaturated warm or cool undertone illuminating the capsule backdrop.

---

## 👆 Gestures & Interaction Shortcuts

- **Hover**: Expands idle notch to show full media title and playback controls.
- **Click Preview**: Immediately launches the full Annotation & Markup studio.
- **Drag & Drop**: Grab the screenshot thumbnail directly from the notch shelf and drag into Slack, Figma, Mail, or Finder.
- **Escape / Click Outside**: Smoothly collapses the notch back to its idle state.

