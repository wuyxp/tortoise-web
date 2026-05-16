# UI/UX Design Review - Story & Resource Modules

This document serves as the "Senior UI/UX Review" to ensure the new Story page and Gallery enhancements align with the existing Tortoise brand and high-quality standards.

## 1. Design Tokens & Visual DNA

To maintain consistency, the new modules MUST adhere to these established patterns:

- **Typography**: Primary font is `LXGW WenKai`. Use `font-black` for headlines to achieve the "Bold/Kid-friendly yet Premium" look.
- **Color Palette**:
    - `brand-blue` (#5B6CF6) for "Narrative/Hope" elements.
    - `brand-green` (#3DAA6A) for "Action/Growth" elements.
    - Dark mode uses a deep navy background (`#050b1d`) with soft lavender/blue glows.
- **Glassmorphism**: Use the `glass` and `glass-darker` utilities for all containers to create a "Crystal/Ocean" feel.
- **Shapes**: Use the `organic-radius` utility (blobs) for secondary image containers and decorative elements.

## 2. Story Page (Immersive Narrative)

### Concept: "The Seven Tides"
Instead of a flat list, the Story page will be a vertical journey through the seven years (Y1-Y7).

- **Hero Area**: Large `explorer_prologue_bg` with a "Soul of the Story" quote.
- **Chapter Cards**:
    - Left/Right staggered layout (Bento-style but more flowy).
    - Each card uses a `glass` container.
    - Images use the `glass-frame` wrapper with the `fade-mask`.
- **Interactions**:
    - Hover effects on cards (subtle scale-up and glow intensity increase).
    - Intersection Observer for "fade-in" animations as the user scrolls.

## 3. Gallery Enhancements

### Categorization Refinement
- **New Categories**: `Chapters` (Narrative art), `Routes` (Map exploration), `Characters` (Story figures).
- **UX Fix**: The Lightbox should support a "Deep Mode" where the background is completely black to highlight the artwork.

## 4. i18n Strategy

- **Bilingual Content**: Every story chapter must have a high-quality English translation that captures the "Fatherly/Wise" tone of Captain Tort.
- **Tone**: Avoid technical terms; use poetic, action-oriented language.

## 5. Review Checklist

- [ ] Does it use `glass` utilities?
- [ ] Are the radii consistent with `organic-radius` or rounded-3xl?
- [ ] Is the "Brand Blue" to "Brand Green" gradient applied to key headings?
- [ ] Is it responsive (70% mobile focus)?
- [ ] Is the loading state smooth?

---
*Prepared by Gemini (UI/UX Responsibility AI)*
