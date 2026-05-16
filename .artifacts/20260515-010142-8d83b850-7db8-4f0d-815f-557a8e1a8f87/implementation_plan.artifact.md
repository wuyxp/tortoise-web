# Implementation Plan - Story Module & Rich Resource Exhibition

This plan outlines the steps to integrate the new "Tortoise Explorer" story architecture and visual resources into the `tortoise-web` website.

## User Review Required (Meeting Points)

- **Story Page Location**: Should the story be a standalone page (e.g., `/story`) or integrated into the documentation? I recommend a standalone page with an immersive UI for parents.
- **Content Translation**: The story text is currently in Chinese. Should we provide an English version now, or focus on the Chinese version first?
- **Story UI Theme**: Should it follow the current light documentation theme, or have a unique "Deep Sea" / "Night" theme to match the narrative vibe?
- **Gallery Categories**: Proposing new categories: `Chapters` (for story backgrounds), `Routes` (for exploration maps), and `Characters`.

## Proposed Changes

### [Web Content & UI]

#### [NEW] [story.astro](file:///Users/wuyang/code/tortoise-web/src/pages/story.astro)
- Create an immersive narrative page showcasing the Y1~Y7 story arcs.
- Include a "Soul of the Story" introduction based on the Story Bible.
- Implement a chapter-based layout using the new chapter images from the Android project.

#### [drawables.ts](file:///Users/wuyang/code/tortoise-web/src/data/drawables.ts)
- Add new assets found in the Android project:
    - `chapter_y1_ch1` to `chapter_y1_finale`
    - `route_shallow_sea`, `route_starfield_sea`, `route_mistedge_entry`
    - `captain_tort_waiting`, `captain_tort_listening`, `explorer_prologue_bg`
- Introduce new categories: `Chapters`, `Routes`.

#### [ui.ts](file:///Users/wuyang/code/tortoise-web/src/i18n/ui.ts)
- Add navigation links for "Story".
- Add localized titles and descriptions for all new gallery assets.

---

### [Assets]

#### [Asset Sync]
- Copy missing `.webp` assets from `/Users/wuyang/code/AndroidStudioProjects/MyKotlin/feature/explorer/src/main/res/drawable` to `public/images/drawables/`.

## Verification Plan

### Automated Tests
- `npm run build`: Ensure no broken links or missing assets during SSG.
- `npm run dev`: Manually verify the new `/story` page and updated gallery.

### Manual Verification
- Check if all new images load correctly in the gallery.
- Verify the story page layout on both desktop and mobile (70% users are on mobile).
- Check English/Chinese toggling for the new sections.
