# Mockup Reference

Source: `b28-prototyping/poster-print-shine` (Lovable/React prototype)
Live: https://poster-print-shine.lovable.app/

Stack: React + Vite + Tailwind + shadcn/ui. **Not carried forward** — design only.

## Typography

- **Display**: Oswald (Google Fonts) — all headings, uppercase, `letter-spacing: 0.02em`
- **Body**: Source Sans 3 (Google Fonts)
- Import: `@import url('https://fonts.googleapis.com/css2?family=Oswald:wght@400;500;600;700&family=Source+Sans+3:wght@400;600;700&display=swap')`

## Color System (HSL, dark theme is default)

| Token | Dark | Light |
|-------|------|-------|
| background | 0 0% 6% | 0 0% 100% |
| foreground | 0 0% 92% | 0 0% 8% |
| muted-foreground | 0 0% 55% | 0 0% 40% |
| border | 0 0% 22% | 0 0% 75% |
| card | 0 0% 10% | 0 0% 100% |

All pure grayscale. `--radius: 0rem` (no rounded corners).

## Page Sections

### 1. Hero
- Eyebrow: `text-xs font-semibold tracking-[0.4em] uppercase` — "Licensed & Insured · Serving Your Area"
- H1: `text-6xl md:text-8xl lg:text-9xl font-bold leading-[0.82]` — "Junk Hauling"
- Subtitle: `text-3xl md:text-4xl lg:text-5xl font-normal text-muted-foreground tracking-wide` — "& Handyman Services"
- Tagline: `text-lg md:text-xl max-w-lg mx-auto leading-relaxed` — "Fast, honest, affordable..."
- Phone label: `text-[10px] tracking-[0.3em] uppercase` — "Call for a free estimate"
- Phone: `text-5xl md:text-7xl font-bold tracking-wider` as `tel:` link
- Contact row: email (Mail icon) + location (MapPin icon), `text-sm`

### 2. Services Grid
- Heading: "What We Do" — `text-3xl md:text-4xl font-bold text-center`
- Grid: `grid-cols-2 md:grid-cols-3 gap-6`
- Each item: icon (`w-7 h-7 strokeWidth={1.2}`), title (`text-base md:text-lg font-bold`), desc (`text-xs md:text-sm text-muted-foreground`)
- Services: Junk Removal (Truck), Cleanouts (Trash2), Yard Waste (TreePine), Repairs (Wrench), Assembly (Hammer), Moving Help (Package)

### 3. Why Hire Us
- Heading: "Why Hire Us" — same as services heading
- Layout: `grid-cols-1 sm:grid-cols-2 gap-x-10 gap-y-2 max-w-2xl mx-auto`
- Each item: `"— " + text`, `text-base md:text-lg`
- Items: Same-day & next-day availability, Upfront pricing — no hidden fees, Licensed insured & background-checked, We clean up before we leave, Locally owned & operated, Free estimates always

### 4. Footer
- **Screen**: "Ready to Get Started?" heading + "Call now for a free, no-obligation estimate." + phone button (variant=poster) + "Print as Poster" button (variant=posterOutline) + small tagline
- **Print only — Tear-off strip**: dashed cut line, 8 flex tabs filling page width. Each tab: `writing-mode: vertical-rl`, contains "JUNK & HANDY" (8px Oswald), "10% OFF" (15px Oswald), phone (8px Source Sans 3). Tabs separated by dashed borders.

## Print Styles

```css
body { background: white; color: black; font: 11pt 'Source Sans 3'; line-height: 1.3; margin: 0; }
h1 { font: 700 42pt 'Oswald'; letter-spacing: 0.04em; }
h2 { font: 700 22pt 'Oswald'; }
.no-print { display: none; }
section, footer, div { background: transparent; }
* { border-color: rgba(0,0,0,0.35); }
@page { margin: 0.3in; size: letter; }
```
