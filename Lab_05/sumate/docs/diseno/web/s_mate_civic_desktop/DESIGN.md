---
name: Súmate Civic Desktop
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
    fontSize: 3rem
    fontWeight: '800'
    lineHeight: 3.5rem
    letterSpacing: -0.02em
  display-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 2.25rem
    fontWeight: '800'
    lineHeight: 2.75rem
    letterSpacing: -0.015em
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 1.75rem
    fontWeight: '700'
    lineHeight: 2.25rem
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 1.375rem
    fontWeight: '700'
    lineHeight: 1.875rem
    letterSpacing: 0em
  headline-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 1.125rem
    fontWeight: '700'
    lineHeight: 1.625rem
    letterSpacing: 0em
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 1rem
    fontWeight: '500'
    lineHeight: 1.5rem
    letterSpacing: 0.01em
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 0.875rem
    fontWeight: '400'
    lineHeight: 1.375rem
    letterSpacing: 0em
  body-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 0.75rem
    fontWeight: '400'
    lineHeight: 1.125rem
    letterSpacing: 0.01em
  label-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 0.875rem
    fontWeight: '700'
    lineHeight: 1.25rem
    letterSpacing: 0.02em
  label-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 0.75rem
    fontWeight: '600'
    lineHeight: 1rem
    letterSpacing: 0.03em
  label-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 0.6875rem
    fontWeight: '700'
    lineHeight: 0.875rem
    letterSpacing: 0.05em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1.5rem
  margin: 2rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

## Brand & Style

This design system establishes an authentic, community-driven civic identity tailored for university students in Arequipa, Peru. It fuses Google's Material 3 philosophy with a sun-warmed, collegiate, and volcanic stone aesthetic derived from the local regional heritage. Rather than adopting an austere bureaucratic tone or an aggressive corporate SaaS palette, the interface feels welcoming, approachable, transparent, and vibrant.

The target audience comprises young academic leaders, student volunteers, university club coordinators, and student union representatives navigating opportunities, democratic civic initiatives, and funding pipelines. Visual energy stems from balanced earthy pastels paired strictly with deep roasted espresso typography. The visual hierarchy utilizes soft layered containers, intentional tactile warmth, and distinct state tags that offer immediate clarity without inducing anxiety.

## Colors

The color palette is deliberately calibrated for high legibility, warmth, and civic optimism under daylight desktop conditions.

### Core Functional Rules
1. **The Dark Neutral Mandate**: Pure black (`#000000`) is strictly forbidden across all text, borders, and visual assets. All headings, display types, high-emphasis text, and dark iconography must use Espresso Coffee (`#473C33`). Secondary text uses `#6B5F54` to maintain soft hierarchy.
2. **Text Over Tinted Fills**: High-luminance brand fills—Sage Green (`#ABC270`), Light Mustard (`#FEC868`), Soft Coral (`#FDA769`), and all tonal surface containers—must strictly take Espresso Coffee (`#473C33`) for typography and icons. White text is never permitted over these hues.
3. **Sage Green Usage Restrictions**: Sage Green (`#ABC270`) serves exclusively as an active structural background fill (active nav pills, toggle rails, segmented tabs, section chips). It must never be used as a standalone text color, uncontained icon color, or input focus stroke against light backgrounds (`#FBF8F1` or `#FFFFFF`).

### Surface & Border Foundations
- **Canvas Background**: `#FBF8F1` (warm parchment civic backdrop)
- **Cards & Surfaces**: `#FFFFFF` (crisp elevated content containers)
- **Tonal Primary Container**: `#EEF3DC` (soft sage background for highlights, secondary navigation cards, and subtle alerts)
- **Structural Outlines & Dividers**: `#E5E0D3` (organic warm borders, 1px default)

### Action & Accent Architecture
- **Primary CTAs & FABs**: Light Mustard (`#FEC868`), text and icons `#473C33`.
- **Badges, Notifications & Accents**: Soft Coral (`#FDA769`), text `#473C33`. The accent tilde in the brand wordmark ("Súmate") is always rendered in Soft Coral.

### Civic Application Status Tokens
Status indicators use designated semantic pairs with enforced AAA/AA accessible contrast:
- **Accepted / Aprobado**: Deep Forest `#2F6B2F` text/icon on `#E3EFCB` background.
- **Rejected / No Seleccionado**: Rust Red `#A8321F` text/icon on `#FBE3DC` background.
- **Pending / En Trámite / Sent**: Dark Ochre `#7A5200` text/icon on `#FFF0CF` background.

## Typography

The typography is built around Plus Jakarta Sans, conveying contemporary academic rigor paired with organic, rounded geometries. 

- **Display & Headings**: Styled with heavier weights (`700` and `800`) to anchor desktop layouts and project civic authority. Color is always `#473C33`.
- **Body & Information**: Rendered in `400` (Regular) and `500` (Medium) weights. Primary text is set to `#473C33`, with secondary descriptors and metadata in `#6B5F54`.
- **Interactive Labels**: CTAs, badges, and table headers use weights `600` and `700` with open letter spacing for scan-friendly readability.
- **Iconography**: Accompanied by **Material Symbols Rounded** with variable font properties matching typography sizes (20px, 24px) using optical sizes 20-24 and fill 0 or 1 depending on active hierarchy.

## Layout & Spacing

Designed specifically for desktop viewport dimensions of **1440x900px**:

### Desktop Grid Framework
- **Persistent Left Navigation Rail**: A fixed 240px wide sidebar positioned along the entire left edge. Background is `#FFFFFF` with a 1px solid right border of `#E5E0D3`.
- **Content Area Canvas**: Operates across the remaining 1200px viewport width, with a maximum centered container width of 1200px and outer margin of `2rem` (32px).
- **12-Column Responsive Grid**: Content inside the canvas utilizes a 12-column layout with fixed `1.5rem` (24px) gutters.
  - Profile & metric overview: 3-column or 4-column spans.
  - Civic initiative and opportunity cards: 4-column span (3 cards per row).
  - Main application detail flow: 8-column primary card with a 4-column contextual sidebar.

### Click & Tap Target Metrics
All clickable elements (navigation items, buttons, form controls, chips, status pills) adhere strictly to a **minimum dimension of 44x44px** to ensure ergonomic accessibility on touch-enabled laptops, tablets, and mouse-driven desktop environments.

## Elevation & Depth

Visual hierarchy uses a refined Material 3 tonal layering model reinforced with crisp, low-contrast borders and sunlit ambient shadows rather than harsh artificial drop shadows.

- **Level 0 (Flat Canvas)**: Canvas surface `#FBF8F1` with zero elevation.
- **Level 1 (Card & Content Containers)**: Background `#FFFFFF` framed by a 1px solid outline `#E5E0D3`. Ambient shadow: `0px 2px 6px -1px rgba(71, 60, 51, 0.05), 0px 1px 3px 0px rgba(71, 60, 51, 0.03)`.
- **Level 2 (Hovered Cards & Dropdowns)**: Background `#FFFFFF` with outline `#E5E0D3` and an expanded warm-tinted shadow: `0px 6px 16px -2px rgba(71, 60, 51, 0.08), 0px 2px 6px 0px rgba(71, 60, 51, 0.04)`.
- **Level 3 (Floating Action Button & Modals)**: FABs `#FEC868` and dialogs elevated with `0px 12px 28px -4px rgba(71, 60, 51, 0.12), 0px 4px 10px 0px rgba(71, 60, 51, 0.06)`.

## Shapes

The geometric personality balances structured editorial alignment with friendly, student-centered curves:

- **Large Content Cards & Modals**: Fixed 16px (`1rem`) border radius (`rounded-lg`).
- **Form Controls & Inputs**: Standardized at 12px (`0.75rem`) border radius for text inputs, select dropdowns, search bars, and date pickers.
- **Navigation Indicators & Badges**: Fully pill-shaped (`9999px`) for active rail indicators, category tags, interactive chips, and application status pills.
- **Buttons**: 12px (`0.75rem`) for secondary/tertiary standard buttons; primary FABs maintain an asymmetric soft rounded shape (16px).

## Components

### Navigation Rail (Desktop)
- **Width**: Fixed 240px, full height (900px minimum), background `#FFFFFF`, border-right `1px solid #E5E0D3`.
- **Header Section**: Features the "Súmate" civic wordmark (`#473C33`, bold) with the accent over the "ú" in Soft Coral (`#FDA769`), followed by university campus switchers.
- **Navigation Item**: 44px height minimum, horizontal padding 16px, 12px radius.
  - *Inactive*: Text `#6B5F54`, Material Symbol Rounded `#6B5F54`, transparent fill.
  - *Hover*: Background `#EEF3DC` at 50% opacity, text `#473C33`.
  - *Active*: Full Sage Green (`#ABC270`) pill fill with text `#473C33` (semi-bold) and filled icon `#473C33`. Never white text.

### Buttons & Call to Action (CTA)
- **Primary CTA / Floating Action Button**: Background Light Mustard (`#FEC868`), border none, text `#473C33`, font weight 700. Minimum height 48px, horizontal padding 24px. Hover shifts background to `#F5BF5D`.
- **Secondary Button**: Background `#EEF3DC`, text `#473C33`, border `1px solid transparent`, font weight 600. Hover shifts background to `#E3EFCB`.
- **Outlined / Tertiary Button**: Background transparent, border `1px solid #E5E0D3`, text `#473C33`. Hover background `#FBF8F1`.

### Status Badges & Pills
- Built with a full pill radius (`9999px`), padding `6px 14px`, `label-md` (bold).
- **Accepted**: Fill `#E3EFCB`, Text `#2F6B2F`, Icon `check_circle` (16px).
- **Rejected**: Fill `#FBE3DC`, Text `#A8321F`, Icon `cancel` (16px).
- **Pending/Sent**: Fill `#FFF0CF`, Text `#7A5200`, Icon `schedule` (16px).
- **Notification Counters**: Fill Soft Coral (`#FDA769`), text `#473C33`, font weight 700, pill shape.

### Input Fields & Controls
- **Text Inputs**: Height 48px, radius 12px. Background `#FFFFFF`, border `1px solid #E5E0D3`. Text `#473C33`, placeholder `#A59B90`.
- **Focus State**: Border `2px solid #473C33` (Espresso) with a 2px outer ring in `#FEC868`. Green is never used for input focus rings.
- **Checkboxes & Radios**: 20px size, resting border `2px solid #6B5F54`. Checked state uses Mustard (`#FEC868`) fill with Espresso `#473C33` checkmark.
- **Switches / Toggles**: Track is 52x32px, 16px radius. Inactive track `#E5E0D3` with `#6B5F54` thumb. Active track is Sage Green (`#ABC270`) with Espresso Coffee `#473C33` thumb.

### Cards
- **Opportunity & Initiative Cards**: Background `#FFFFFF`, border `1px solid #E5E0D3`, 16px radius, padding 20px. Includes top status badge, headline in `headline-md`, supporting civic category tag in `#EEF3DC` with `#473C33` text, and bottom action tray with a minimum 44px click target.