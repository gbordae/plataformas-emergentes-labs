---
name: Warm Civic M3
colors:
  surface: '#fff8f5'
  surface-dim: '#e8d7ca'
  surface-bright: '#fff8f5'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#fff1e8'
  surface-container: '#fdebde'
  surface-container-high: '#f7e5d8'
  surface-container-highest: '#f1dfd2'
  on-surface: '#231a12'
  on-surface-variant: '#45483b'
  inverse-surface: '#392e26'
  inverse-on-surface: '#ffeee1'
  outline: '#76796a'
  outline-variant: '#c6c8b7'
  surface-tint: '#52651e'
  primary: '#52651e'
  on-primary: '#ffffff'
  primary-container: '#abc270'
  on-primary-container: '#3d5008'
  inverse-primary: '#b8d07c'
  secondary: '#7d5700'
  on-secondary: '#ffffff'
  secondary-container: '#ffc969'
  on-secondary-container: '#775300'
  tertiary: '#8f4d17'
  on-tertiary: '#ffffff'
  tertiary-container: '#fba567'
  on-tertiary-container: '#753901'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#d4ec95'
  primary-fixed-dim: '#b8d07c'
  on-primary-fixed: '#151f00'
  on-primary-fixed-variant: '#3b4d06'
  secondary-fixed: '#ffdeaa'
  secondary-fixed-dim: '#f3be5f'
  on-secondary-fixed: '#271900'
  on-secondary-fixed-variant: '#5f4100'
  tertiary-fixed: '#ffdcc6'
  tertiary-fixed-dim: '#ffb785'
  on-tertiary-fixed: '#301400'
  on-tertiary-fixed-variant: '#713700'
  background: '#fff8f5'
  on-background: '#231a12'
  surface-variant: '#f1dfd2'
typography:
  display-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 34px
    fontWeight: '800'
    lineHeight: 42px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 26px
    fontWeight: '700'
    lineHeight: 34px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 22px
    fontWeight: '700'
    lineHeight: 28px
    letterSpacing: -0.01em
  headline-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 18px
    fontWeight: '700'
    lineHeight: 24px
  title-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '700'
    lineHeight: 22px
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
  label-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '700'
    lineHeight: 20px
    letterSpacing: 0.01em
  label-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.02em
  label-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 11px
    fontWeight: '600'
    lineHeight: 14px
    letterSpacing: 0.02em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  margin: 1.25rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

## Brand & Style

The design system establishes a warm, organic, and civic-minded digital environment built for university students (17–25 years old) in Arequipa, Peru. It translates civic participation, volunteering, academic congresses, and student hackathons into an approachable, transparent, and encouraging experience.

### Aesthetic Paradigm
- **Material 3 Humanist & Organic:** Rooted in Google Material 3 structures (tonal containers, standardized navigation bars, pill shapes), but softened through an earthy, artisanal palette inspired by southern Peruvian warmth.
- **Warm Minimalism:** Prioritizes generous negative space, crisp typographic hierarchy, and structural cards over heavy embellishments or artificial decorative textures.
- **Honest & Grounded:** Strictly avoids generic stock photos and loud commercial gradients. Graphic weight relies on high-legibility geometric typography, clean functional badges, subtle borders, and contextual metadata.
- **Emotional Intent:** Cultivates trust, civic agency, belonging, and academic momentum without bureaucratic visual friction.

## Colors

The palette balances warm earth tones with organic freshness, strictly steering clear of cold corporate slates and harsh pure blacks.

### Roles & Semantic Mapping
- **Primary (`#ABC270` - Verde Sabio):** Civic identity, top app headers, primary container indicators.
  - *Primary Container:* `#EEF3DC` (used for filter chips, active bottom navigation pills, card highlights).
  - *On-Primary Rule:* Text and icons over `#ABC270` must always be `#473C33` (Café Expreso). Never use white (`#FFFFFF`). Never use `#ABC270` for body or label text over light surfaces due to contrast limitations.
- **Secondary / Main CTA (`#FEC868` - Mostaza Claro):** Primary actions, major conversion buttons, highlighted submission steps.
  - *Secondary Container:* `#FFF0CF` (idle submission states, warm tonal containers).
  - *On-Secondary Rule:* Always paired with `#473C33` text/icons.
- **Tertiary / Accent (`#FDA769` - Coral Suave):** Urgency tags, category markers (hackathons, deadlines), dynamic badges.
  - *Accent Container:* `#FBE3DC`.
  - *On-Tertiary Rule:* Paired with `#473C33`.
- **Neutral Dark (`#473C33` - Café Expreso):** Foundation for all headlines, high-contrast labels, primary copy, and prominent numerical values. Pure black (`#000000`) is strictly forbidden across the system.
- **Muted Text (`#6B5F54`):** Secondary metadata, subheadings, supporting context, timestamps.
- **Canvas / Background (`#FBF8F1`):** Warm cream base layer for screens.
- **Surface / Cards (`#FFFFFF`):** High-clarity white surfaces for content cards, sheets, and dialogs.
- **Outlines / Dividers (`#E5E0D3`):** Subtle boundaries separating tonal surfaces and cards.

### Application Status Badges (Always Icon + Text + Container)
- **Aceptada (Accepted):** Container `#E3EFCB`, Text/Icon `#2F6B2F`, Icon `check_circle`.
- **Rechazada (Rejected):** Container `#FBE3DC`, Text/Icon `#A8321F`, Icon `cancel`.
- **Enviada / En espera (Pending):** Container `#FFF0CF`, Text/Icon `#7A5200`, Icon `schedule`.

## Typography

The typographic hierarchy utilizes **Plus Jakarta Sans** across all roles, taking advantage of its rounded geometric forms to retain both contemporary warmth and academic authority.

### Hierarchy & Usage
- **Display & Headlines (Weights 700–800):** Used for view titles, event header banners, and high-impact numerical statistics. Tight negative tracking creates unified visual anchoring.
- **Titles & Labels (Weights 600–700):** Applied to card titles, buttons, status pill badges, and input titles. Ensures instantaneous scannability when scanning event feeds.
- **Body Text (Weights 400–500):** Dedicated to event abstracts, requirement lists, organizational descriptions, and post-submission instructions. Generous line heights maintain comfortable reading on 390px mobile screens.

## Layout & Spacing

The layout is optimized for single-hand mobile interactions (target viewport: 390 × 844 pt), standardizing on an 8pt base grid with a 4pt sub-grid for badges and compact elements.

### Layout Model
- **Outer Canvas Margins:** `1.25rem` (20px) on mobile horizontal boundaries provides breathing room against screen edges.
- **Column Gutter:** `1rem` (16px) fluid separation for internal grid lists or two-column event cards.
- **Component Padding Rhythms:**
  - `space-xs` (4px): Inner badge padding, micro gaps between icon and text.
  - `space-sm` (8px): Chip vertical padding, internal spacing between consecutive metadata lines.
  - `space-md` (16px): Internal padding for cards, text fields, bottom sheets, and dialogs.
  - `space-lg` (24px): Vertical spacing separating logical card groups and filter segments.
  - `space-xl` (32px): Section breaks between top navigation banners and content feeds.
- **Safe Area Insets:** Account for standard dynamic island/notch at top (`47px` min) and home navigation indicator at bottom (`34px` padding above fixed navigation bar).

## Elevation & Depth

In alignment with clean, warm minimalism and Material 3's tonal philosophy, visual depth is achieved via surface juxtaposition, tonal color containers, and ghost borders, avoiding muddy or heavy drop shadows.

### Elevation Levels
- **Level 0 (Flat Canvas):** `#FBF8F1` background canvas. Base resting layer.
- **Level 1 (Cards & Inputs):** Pure `#FFFFFF` surface resting on `#FBF8F1`, bounded by a crisp 1px `#E5E0D3` structural border. No cast shadow.
- **Level 2 (Active Filters, Floating Contexts):** Tonal fills (`#EEF3DC` or `#FFF0CF`) without borders, indicating interactive readiness.
- **Level 3 (Modal Bottom Sheets, Sticky Navigation):** `#FFFFFF` surfaces with a 1px top border in `#E5E0D3` and an ultra-diffused warm ambient shadow: `0px -4px 16px rgba(71, 60, 51, 0.04)`.

## Shapes

The interface embraces organic curvature without sacrificing functional structure.

- **Cards & Sheets (`16px` / `rounded-lg`):** Event cards, verification cards, and detail bottom sheets use 16px radius corners to communicate friendliness while holding structured data.
- **Controls & Form Inputs (`12px`):** Text entry boxes, dropdown triggers, and standard buttons feature 12px corner rounding for a tactile, touch-friendly presence.
- **Full Pills (`9999px`):** Used exclusively for filter chips, M3 active navigation indicators, and postulation status badges to make them visually distinct from cards and inputs.

## Components

### 1. Primary Action Buttons (CTA)
- **Geometry:** 48px height, 12px corner radius or full pill depending on contextual hierarchy.
- **Colorway:** Fill in Mostaza Claro `#FEC868`. Text and icons strictly in Café Expreso `#473C33` with weight 700.
- **Interactive State:** Pressed state darkens to `#E8B355`. Disabled state uses `#E5E0D3` with `#6B5F54` text.

### 2. Event Cards
- **Geometry:** Surface `#FFFFFF`, 16px rounded corners, 1px uniform border in `#E5E0D3`. Internal padding of 16px.
- **Content Flow:**
  - Header: Category tag (e.g., "Voluntariado" or "Hackathon" on `#FBE3DC` accent container) + Bookmark icon button.
  - Title: Plus Jakarta Sans Bold, `#473C33`.
  - Metadata Rows: Date, campus/location, and organizer icons (Material Symbols Rounded) in `#6B5F54` alongside body-sm copy.
  - Footer: Available slots or application deadline pill badge + Secondary button or tap trigger.

### 3. Filter Chips (Material 3)
- **Shape:** Pill shape (full rounded). Height 32px.
- **Idle State:** Surface `#FFFFFF`, 1px border `#E5E0D3`, text `#473C33`.
- **Selected State:** Fill `#EEF3DC`, 1px border `#ABC270`, text `#473C33`, prepended with a 16px `check` icon.

### 4. Text Input Fields
- **Geometry:** 52px height, 12px rounded corners, fill `#FFFFFF`, 1px border `#E5E0D3`.
- **States:**
  - Idle: Border `#E5E0D3`, placeholder `#6B5F54`.
  - Focused: 2px border `#ABC270`, label floats or rests above in `#473C33`.
  - Error: 1.5px border `#A8321F`, caption text in `#A8321F`.

### 5. Application Status Badges (Postulaciones)
- **Geometry:** Height 28px, pill shape, internal padding `4px 10px`.
- **Compositions (Icon 16px + Label 12px weight 600):**
  - *Aceptada:* Container `#E3EFCB`, text/icon `#2F6B2F`, icon `check_circle`.
  - *Rechazada:* Container `#FBE3DC`, text/icon `#A8321F`, icon `cancel`.
  - *En espera:* Container `#FFF0CF`, text/icon `#7A5200`, icon `schedule`.

### 6. App Header (Top App Bar)
- **Background:** Verde Sabio `#ABC270` tonal banner or `#FBF8F1` with an `#ABC270` brand badge.
- **Typography:** Display title in `#473C33` (never white).
- **Actions:** Icon buttons (notifications, search) rendered in `#473C33` on subtle circle taps.

### 7. Bottom Navigation Bar (Fixed 390px Mobile)
- **Structure:** Height 72px (excluding bottom safe area), background `#FFFFFF`, border-top 1px `#E5E0D3`.
- **Destinations (3 Items):**
  1. *Explorar* (Icon: `explore`)
  2. *Mis postulaciones* (Icon: `assignment_turned_in`)
  3. *Perfil* (Icon: `person`)
- **Active Destination Indicator:** Material 3 pill shape (`#EEF3DC`, width 64px, height 32px) behind active icon in `#473C33`, with label underneath in `#473C33` (weight 700). Inactive items use `#6B5F54` with weight 500.

### 8. Iconography Rules
- **Library:** Material Symbols Rounded.
- **Styling:** Filled variant for active tab states; outlined/rounded for cards and idle states. Stroke weight 2px equivalent. Pure black icons are forbidden.