export interface DrawableAsset {
  id: string;
  category: 'Creatures' | 'Environment' | 'Items' | 'Story' | 'Chapters' | 'Routes';
  filename: string;
}

export const drawables: DrawableAsset[] = [
  // Creatures
  { id: 'eel-shy', category: 'Creatures', filename: 'y1_eel_shy.webp' },
  { id: 'jelly-fae', category: 'Creatures', filename: 'y1_jelly_fae.webp' },
  { id: 'turtle-kin', category: 'Creatures', filename: 'y1_turtle_kin.webp' },
  { id: 'fish-tropic', category: 'Creatures', filename: 'y1_fish_tropic.webp' },
  { id: 'crab-curious', category: 'Creatures', filename: 'y1_crab_curious.webp' },
  { id: 'octopus-smart', category: 'Creatures', filename: 'y1_octopus_smart.webp' },
  { id: 'seahorse-gold', category: 'Creatures', filename: 'y1_seahorse_gold.webp' },
  { id: 'squid-lorewhale', category: 'Creatures', filename: 'y1_squid_lorewhale.webp' },

  // Environment
  { id: 'sandbell', category: 'Environment', filename: 'y1_sandbell.webp' },
  { id: 'coral-fan', category: 'Environment', filename: 'y1_coral_fan.webp' },
  { id: 'grass-sea', category: 'Environment', filename: 'y1_grass_sea.webp' },
  { id: 'kelp-long', category: 'Environment', filename: 'y1_kelp_long.webp' },
  { id: 'coral-dawn', category: 'Environment', filename: 'y1_coral_dawn.webp' },
  { id: 'kelp-drift', category: 'Environment', filename: 'y1_kelp_drift.webp' },
  { id: 'anemone-dawn', category: 'Environment', filename: 'y1_anemone_dawn.webp' },

  // Items
  { id: 'coin-eon', category: 'Items', filename: 'y1_coin_eon.webp' },
  { id: 'sand-coin', category: 'Items', filename: 'y1_sand_coin.webp' },
  { id: 'glass-blue', category: 'Items', filename: 'y1_glass_blue.webp' },
  { id: 'pearl-dawn', category: 'Items', filename: 'y1_pearl_dawn.webp' },
  { id: 'shell-curl', category: 'Items', filename: 'y1_shell_curl.webp' },
  { id: 'bottle-drift', category: 'Items', filename: 'y1_bottle_drift.webp' },
  { id: 'spiral-snail', category: 'Items', filename: 'y1_spiral_snail.webp' },
  { id: 'compass-relic', category: 'Items', filename: 'y1_compass_relic.webp' },
  { id: 'shell-rainbow', category: 'Items', filename: 'y1_shell_rainbow.webp' },
  { id: 'ocean-heart', category: 'Items', filename: 'y1_ocean_heart.webp' },
  { id: 'wood-dawn', category: 'Items', filename: 'y1_wood_dawn.webp' },
  { id: 'stone-round', category: 'Items', filename: 'y1_stone_round.webp' },
  { id: 'star-orange', category: 'Items', filename: 'y1_star_orange.webp' },
  { id: 'star-purple', category: 'Items', filename: 'y1_star_purple.webp' },

  // Story (V2)
  { id: 'mori-solo', category: 'Story', filename: '/v2/characters/character_mori_solo.webp' },
  { id: 'mora-listening', category: 'Story', filename: '/v2/scenes/captain_mora_listening.webp' },
  { id: 'mori-at-island', category: 'Story', filename: '/v2/scenes/mori_at_island.webp' },
  { id: 'mori-lighthouse', category: 'Story', filename: '/v2/scenes/mori_lighthouse.webp' },
  { id: 'mori-resting', category: 'Story', filename: '/v2/scenes/mori_resting.webp' },
  { id: 'mori-returning', category: 'Story', filename: '/v2/scenes/mori_returning.webp' },
  { id: 'mori-swimming', category: 'Story', filename: '/v2/scenes/mori_swimming.webp' },
  { id: 'island-awakened', category: 'Story', filename: 'island_awakened.webp' },
  { id: 'island-sleeping', category: 'Story', filename: 'island_sleeping.webp' },

  // Chapters (V2)
  { id: 'chapter-y1-prologue', category: 'Chapters', filename: '/v2/chapters/chapter_y1_prologue.webp' },
  { id: 'chapter-y2-prologue', category: 'Chapters', filename: '/v2/chapters/chapter_y2_prologue.webp' },
  { id: 'chapter-y3-prologue', category: 'Chapters', filename: '/v2/chapters/chapter_y3_prologue.webp' },
  { id: 'chapter-y4-prologue', category: 'Chapters', filename: '/v2/chapters/chapter_y4_prologue.webp' },
  { id: 'chapter-y5-prologue', category: 'Chapters', filename: '/v2/chapters/chapter_y5_prologue.webp' },
  { id: 'chapter-y6-prologue', category: 'Chapters', filename: '/v2/chapters/chapter_y6_prologue.webp' },
  { id: 'chapter-y7-prologue', category: 'Chapters', filename: '/v2/chapters/chapter_y7_prologue.webp' },

  // Routes
  { id: 'route-shallow-sea', category: 'Routes', filename: 'route_shallow_sea.webp' },
  { id: 'route-starfield-sea', category: 'Routes', filename: 'route_starfield_sea.webp' },
  { id: 'route-mistedge-entry', category: 'Routes', filename: 'route_mistedge_entry.webp' },
];
