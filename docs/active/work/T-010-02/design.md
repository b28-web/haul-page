# T-010-02 Design: Gallery Placeholders

## Options Evaluated

### Option A: Solid-color SVG files with text overlay

- Create 6 SVG files with "BEFORE" / "AFTER" text
- Use junk-removal-themed colors (muted earth tones)
- ~1KB per file, no binary bloat
- Works in `<img>` tags, scales perfectly
- Must update seed YAML to reference `.svg` extension

### Option B: Small JPEG placeholder images

- Generate via ImageMagick or similar
- Adds binary files to repo (even at 50KB each = 300KB total)
- Requires build tool to generate, or commit binary blobs
- Native format matches current `.jpg` references

### Option C: Use a placeholder service URL

- e.g., `https://placehold.co/800x600/333/fff?text=Before`
- Zero local files
- Breaks offline dev, adds external dependency
- Not acceptable for production

## Decision: Option A — SVG placeholders

**Rationale:**
- Lightest weight (< 1KB each, text-only in git)
- No binary blobs in repo
- SVGs render perfectly in `<img>` tags at any aspect ratio
- Easy to replace later with real customer photos
- Visually meaningful — shows "BEFORE" / "AFTER" text so the gallery layout is clearly communicating its purpose

**Trade-off:** Must update seed YAML paths from `.jpg` to `.svg`. This is a one-line change per file and the seeder matches on `before_image_url` for upsert, so existing DB records need re-seeding. Acceptable since this is dev/seed data.

## SVG Design

- 800×600 viewBox (4:3 aspect ratio matching the template's `aspect-[4/3]`)
- Dark background (#1a1a1a for "before", #2a2a2a for "after") — matches dark theme
- White text label centered ("BEFORE" / "AFTER")
- Subtle icon or visual differentiator (cluttered pattern for before, clean for after)
