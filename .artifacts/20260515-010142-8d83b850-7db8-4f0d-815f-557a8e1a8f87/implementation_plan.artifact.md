# Implementation Plan - Story Module & Rich Resource Exhibition

This plan outlines the steps to integrate the new "Tortoise Explorer" story architecture and visual resources into the `tortoise-web` website, ensuring UI/UX consistency and bilingual support.

## UI/UX Review & Standards

- **Consistency**: All new UI components will use the `glass` and `organic-radius` Tailwind utilities defined in `global.css`.
- **Exquisiteness**: Use multi-layered shadows and brand gradients (`text-gradient`) for headings.
- **Narrative Vibe**: The Story page will feature a "Deep Sea" ambient glow (using radial gradients) to differentiate it from the clean documentation style.

## Proposed Changes

### [Web Content & UI]

#### [NEW] [story.astro](file:///Users/wuyang/code/tortoise-web/src/pages/story.astro)
- **Structure**: An immersive landing page for the "Seven Tides" narrative.
- **Components**:
    - **Hero**: Immersive background with the "Soul of the Story" (MEETING-2026-05-15-03).
    - **Timeline**: Staggered cards for Y1-Y7 chapters using `chapter_y1_...` assets.
    - **i18n**: Full support for `zh` and `en` routes.

#### [NEW] [y1-y7.en.md](file:///Users/wuyang/code/tortoise-web/src/data/story/y1-y7.en.md)
- **Task**: Translate the complete story text from Chinese to English, maintaining the "陪伴与传承" (Companion and Heritage) emotional tone.

#### [drawables.ts](file:///Users/wuyang/code/tortoise-web/src/data/drawables.ts)
- Add 15+ new assets including Chapters, Routes, and Story items.
- Update `category` enum to include `Chapters` and `Routes`.

#### [ui.ts](file:///Users/wuyang/code/tortoise-web/src/i18n/ui.ts)
- Add navigation: `nav.story`: "岛屿故事" / "Island Story".
- Add metadata for all new assets.

---

### [Assets]

#### [Asset Sync] [COMPLETED]
- Missing `.webp` assets have been synced from the Android project.

## Verification Plan

### Automated Tests
- `npm run build`: Verify SSG output.
- `grep` check: Ensure no missing translation keys in the new Story page.

### Manual Verification
- **Visual Audit**: Compare the new Story page against the [ui_ux_review.artifact.md](file:///Users/wuyang/code/tortoise-web/.artifacts/20260515-010142-8d83b850-7db8-4f0d-815f-557a8e1a8f87/ui_ux_review.artifact.md).
- **Mobile Check**: Test on responsive breakpoints.
- **Language Toggle**: Ensure seamless switching between ZH and EN on the Story page.
