# PharmaCore Design System & UI Specification

This document details the complete design tokens, component architecture, and responsive guidelines implemented across PharmaCore Flutter SaaS (Web, Android, iOS), matching the reference design in `/design/pharmacy-dashboard.html`.

---

## 1. Design Tokens

All design tokens are defined centrally in [`tokens.dart`](file:///Users/khushalkhan/personal%20projects/pharmcysas/lib/core/theme/tokens.dart) and accessed anywhere via `context.tokens`.

### 1.1 Color Palettes

#### Canvas & Neutrals
| Token | Light Mode | Dark Mode | Usage |
|---|---|---|---|
| `bgTop` | `#F4F9F8` | `#0A1314` | Top vertical gradient background |
| `bgBottom` | `#E0F3F1` | `#0E1E20` | Bottom vertical gradient background |
| `card` | `rgba(255, 255, 255, 0.88)` | `rgba(20, 38, 40, 0.90)` | Surfaces, cards, search bars |
| `line` / `border` | `#DFECEB` | `#1F3739` | 1px card borders, table dividers |
| `ink` | `#06292B` | `#E8F5F3` | Headings, primary text, dark icons |
| `muted` | `#4B6567` | `#9BB8B6` | Secondary labels, captions, metadata |
| `track` | `#E6EFEE` | `#1B3234` | Progress tracks, icon backdrops |
| `shadow` | `0 10px 30px rgba(5,52,58,0.07)` | `0 10px 30px rgba(0,0,0,0.35)` | Elevation on cards and floating bars |

#### Brand Gradients & Accents
- **Brand Primary**: `#0B5D5A`
- **Brand Gradient (135°)**: `#0F766E` $\rightarrow$ `#064E4B`
- **Active Pill Gradient (135°)**: `#0F766E` $\rightarrow$ `#05343A`
- **Focus Ring**: `#0F766E` (with 25% opacity glow)

#### Pastel Palette (KPIs, Charts & Badges)
- **Lime**: `#DDF2B0`
- **Mint**: `#9AD9D0`
- **Peach**: `#F5D5AE`
- **Lavender**: `#C3C6F3`
- **Rose**: `#F4B9BD`

#### Semantic Colors
- **Success**: `#16A34A` (Trend-green text: `#15803D`)
- **Amber**: `#F59E0B` (Text: `#B45309`)
- **Orange**: `#EA580C` (Text: `#C2410C`)
- **Danger**: `#DC2626`
- **Info**: `#2563EB`

#### Hero Extras
- **Radial Glow**: `#2BB5A8`
- **Status Dot**: `#4ADE80` (with 2s pulsing ring)
- **Dark Tooltip**: `#05343A`

---

## 2. Typography

Primary typeface: **Plus Jakarta Sans** (`GoogleFonts.plusJakartaSans`).  
**Crucial Requirement**: All numerical values, currencies, percentages, dates, and metric counters utilize **Tabular Figures** (`FontFeature.tabularFigures()`) to prevent layout shift during updates.

| Style | Size / Weight | Letter Spacing | Usage |
|---|---|---|---|
| `pageTitle` | 26px / 800 | -0.01em | App shell top bar & page headings |
| `heroTitle` | 34px / 800 | -0.02em | Hero welcome banner |
| `cardTitle` | 17px / 800 | Normal | Section card headings |
| `cardSubtitle` | 13px / 400 | Normal | Subheadings, descriptions |
| `kpiValue` | 24px / 800 | -0.02em | Metric highlights, KPI cards |
| `kpiLabel` | 12px / 600 | Normal | KPI subtitles and category labels |
| `navItem` | 14px / 500 (active 700) | Normal | Sidebar and bottom navigation |
| `navGroupLabel` | 12px / 600 | Normal | Sentence-case navigation group headers |
| `body` | 14px / 400 | Normal | Form inputs, table cells, descriptions |
| `tableHeader` | 13px / 600 | Normal | Data table headers |
| `badge` | 12px / 700 | Normal | Status indicators |
| `trendBadge` | 11px / 700 | Normal | KPI +/- delta badges |

---

## 3. Shapes, Radii & Spacing

### Radii Scale
- **`pill` (999px)**: Buttons, search inputs, badges, category filters, active nav pills
- **`hero` (28px)**: Dashboard hero banner
- **`largeCard` (24px)**: Section cards, chart containers, auth modals
- **`kpi` (22px)**: Metric KPI cards
- **`planCard` (20px)**: Sidebar subscription card
- **`tile` / `alert` (16px)**: Metric mini-tiles, alert warning rows
- **`logo` (14px)**: PharmaCore logo mark
- **`iconSquare` (12px)**: KPI and list icon containers

### Spacing Scale
`4px`, `8px`, `12px`, `16px`, `22px`, `24px`, `28px`, `32px`.

---

## 4. Component Library (`lib/shared/widgets/`)

1. **`AppButton`** (`app_button.dart`):
   - Pill radius (999), 10px-12px padding.
   - Variants: `primary` (brand gradient + soft teal shadow), `white` (hero action button), `ghost` (translucent backdrop), `secondary`, and `danger`.
   - Subtle scale feedback animation (0.98x) on tap.

2. **`HeroBanner`** (`hero_banner.dart`):
   - Radius 28, radial glow (`#2BB5A8`) superimposed over 120° linear gradient (`#0F766E` $\rightarrow$ `#064E4B`).
   - Pulsing live status dot (2s loop expanding 4px $\rightarrow$ 8px), action buttons, inline metric pill, and rotated 45° translucent pill watermark.

3. **`KPICard`** (`kpi_card.dart`):
   - Radius 22, 1px border, 4px top accent bar, 38x38 rounded icon square.
   - Trend delta pill with up/down indicator.
   - Includes custom `SparklinePainter` rendering 34px smooth Bezier curves with soft gradient fills.
   - Available in both standard and `.pastel` tinted variants.

4. **`AreaChartCard`** (`area_chart_card.dart`):
   - 4-column metric strip with 16px mini-tiles.
   - 220px smooth spline area chart with `fl_chart`, dashed subtle horizontal grids, hollow data markers, and dark tooltip `#05343A`.

5. **`DonutChartCard`** (`donut_chart_card.dart`):
   - 170px outer diameter, 112px inner hole diameter.
   - Displays 5 categorical segments with custom pastel mapping.
   - Centered total units summary with tabular figures and detailed legend with percent badges.

6. **`PillBarChart`** (`pill_bar_chart.dart`):
   - 7 fully rounded vertical pill bars inside full-height background tracks.
   - Striped pastel fills (135° diagonal stripes, 3px white at 35% every 7px via `StripedOverlayPainter`).
   - Selected bar emphasized in solid deep teal with dark tooltip.

7. **`AlertRow`** (`alert_row.dart`):
   - Radius 16, 11% tinted background, 28% colored border.
   - Alert count badge in bold tabular figures (20/700) with chevron drill-down.

8. **`AppDataTable`** (`app_data_table.dart`):
   - Clean tabular display with 13/600 muted headers and 14/400 body cells.
   - Alternating hover row highlights and divider lines.
   - Automatic responsive fallback to card list on small screens.

9. **`AppSearchField`** (`app_search_field.dart`):
   - Pill radius (999), search icon, clear button, and `⌘K` keyboard shortcut badge.
   - Smooth focus ring with 2px accent border and glow shadow.

10. **`AppScaffold`, `AppSidebar` & `AppTopBar`**:
    - **Desktop ($\ge 1024\text{px}$)**: 264px persistent sidebar, logo with bold `+` mark, sentence-case nav groups, active pill gradient, and plan renewal card.
    - **Tablet ($600\text{px} - 1024\text{px}$)**: 80px collapsed rail with centered circular icon holders.
    - **Mobile ($< 600\text{px}$)**: Hidden sidebar with floating rounded bottom navigation bar (max 5 tabs) and elevated center POS action.

---

## 5. Screen Implementation Guide

Every screen in the application adheres to the unified design language:
- **Authentication**: Split-screen with branded emerald illustration hero on desktop; centered pill forms on mobile.
- **Registration**: 4-step interactive progress stepper with animated indicators and review summary.
- **Approval Status**: Timeline status card with support drill-downs and active tenant lock.
- **POS**: 2-column workstation with instant category chips, grid of medicines with stock badges, and an active order card with quantity steppers and discount calculations.
- **Inventory & Purchases**: Search pill, filter chips, stock status pills, and responsive data tables.
- **Staff & Settings**: Role tags, receipt customization, security settings, and plan subscription managers.

---

## 6. Verifying & Running

```bash
# Verify static analysis
flutter analyze

# Run all test suites
flutter test
```

