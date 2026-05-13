export interface DrawableAsset {
  id: string;
  category: 'Creatures' | 'Environment' | 'Items' | 'Story';
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
  { id: 'spineback-tree-autumn', category: 'Environment', filename: 'spineback_tree_autumn.webp' },
  { id: 'spineback-tree-spring', category: 'Environment', filename: 'spineback_tree_spring.webp' },
  { id: 'spineback-tree-summer', category: 'Environment', filename: 'spineback_tree_summer.webp' },
  { id: 'spineback-tree-winter', category: 'Environment', filename: 'spineback_tree_winter.webp' },
  { id: 'mistedge-entry', category: 'Environment', filename: 'route_mistedge_entry.webp' },

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
  { id: 'singing-scale', category: 'Items', filename: 'singing_scale.webp' },
  { id: 'ocean-heart', category: 'Items', filename: 'y1_ocean_heart.webp' },

  // Story
  { id: 'lil-tan-awake', category: 'Story', filename: 'lil_tan_awake.webp' },
  { id: 'lil-tan-returned', category: 'Story', filename: 'lil_tan_returned.webp' },
  { id: 'lil-tan-voyaging', category: 'Story', filename: 'lil_tan_voyaging.webp' },
  { id: 'lil-tan-resting', category: 'Story', filename: 'lil_tan_resting_arrival.webp' },
  { id: 'captain-tort-letter', category: 'Story', filename: 'captain_tort_letter.webp' },
  { id: 'family-emblem-echo', category: 'Story', filename: 'family_emblem_echo.webp' },
  { id: 'family-emblem-umbra', category: 'Story', filename: 'family_emblem_umbra.webp' },
  { id: 'family-emblem-lumina', category: 'Story', filename: 'family_emblem_lumina.webp' },
  { id: 'island-awakened', category: 'Story', filename: 'island_awakened.webp' },
  { id: 'island-sleeping', category: 'Story', filename: 'island_sleeping.webp' },
  { id: 'three-turtles-lighthouse', category: 'Story', filename: 'three_turtles_lighthouse.webp' },
  { id: 'old-star-keepers', category: 'Story', filename: 'old_star_keepers_silhouettes.webp' },
];
