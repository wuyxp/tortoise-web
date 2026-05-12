export interface DrawableAsset {
  id: string;
  category: 'Creatures' | 'Environment' | 'Items' | 'Story';
  title: string;
  description: string;
  filename: string;
}

export const drawables: DrawableAsset[] = [
  // Creatures
  { id: 'eel-shy', category: 'Creatures', title: 'Shy Eel', description: 'A timid creature from the deep reefs.', filename: 'y1_eel_shy.webp' },
  { id: 'jelly-fae', category: 'Creatures', title: 'Jelly Fae', description: 'Bioluminescent jellyfish with a magical glow.', filename: 'y1_jelly_fae.webp' },
  { id: 'turtle-kin', category: 'Creatures', title: 'Turtle Kin', description: 'Ancient guardians of the sea floor.', filename: 'y1_turtle_kin.webp' },
  { id: 'fish-tropic', category: 'Creatures', title: 'Tropical Fish', description: 'Vibrant inhabitants of the coral gardens.', filename: 'y1_fish_tropic.webp' },
  { id: 'crab-curious', category: 'Creatures', title: 'Curious Crab', description: 'Always investigating the ocean floor.', filename: 'y1_crab_curious.webp' },
  { id: 'octopus-smart', category: 'Creatures', title: 'Smart Octopus', description: 'Highly intelligent and master of camouflage.', filename: 'y1_octopus_smart.webp' },
  { id: 'seahorse-gold', category: 'Creatures', title: 'Golden Seahorse', description: 'A rare and elegant swimmer.', filename: 'y1_seahorse_gold.webp' },
  { id: 'squid-lorewhale', category: 'Creatures', title: 'Lorewhale Squid', description: 'A massive squid from the legends.', filename: 'y1_squid_lorewhale.webp' },

  // Environment
  { id: 'sandbell', category: 'Environment', title: 'Sandbell', description: 'Small bell-shaped flowers that grow on beaches.', filename: 'y1_sandbell.webp' },
  { id: 'coral-fan', category: 'Environment', title: 'Coral Fan', description: 'Delicate fan-like structures in the reef.', filename: 'y1_coral_fan.webp' },
  { id: 'grass-sea', category: 'Environment', title: 'Sea Grass', description: 'Flowing underwater meadows.', filename: 'y1_grass_sea.webp' },
  { id: 'kelp-long', category: 'Environment', title: 'Long Kelp', description: 'Towering kelp forests of the shallows.', filename: 'y1_kelp_long.webp' },
  { id: 'coral-dawn', category: 'Environment', title: 'Dawn Coral', description: 'Coral that glows with the morning light.', filename: 'y1_coral_dawn.webp' },
  { id: 'kelp-drift', category: 'Environment', title: 'Drifting Kelp', description: 'Free-floating kelp that travels with currents.', filename: 'y1_kelp_drift.webp' },
  { id: 'anemone-dawn', category: 'Environment', title: 'Dawn Anemone', description: 'Radiant anemones found in the sunrise pools.', filename: 'y1_anemone_dawn.webp' },
  { id: 'spineback-tree-autumn', category: 'Environment', title: 'Spineback Tree (Autumn)', description: 'The Spineback tree in its golden autumn colors.', filename: 'spineback_tree_autumn.webp' },
  { id: 'spineback-tree-spring', category: 'Environment', title: 'Spineback Tree (Spring)', description: 'Fresh blooms on the Spineback tree.', filename: 'spineback_tree_spring.webp' },
  { id: 'spineback-tree-summer', category: 'Environment', title: 'Spineback Tree (Summer)', description: 'Full green canopy of the Spineback tree.', filename: 'spineback_tree_summer.webp' },
  { id: 'spineback-tree-winter', category: 'Environment', title: 'Spineback Tree (Winter)', description: 'The skeletal beauty of the Spineback tree in winter.', filename: 'spineback_tree_winter.webp' },
  { id: 'mistedge-entry', category: 'Environment', title: 'Mistedge Entry', description: 'The mysterious entrance to the Mistedge region.', filename: 'route_mistedge_entry.webp' },

  // Items
  { id: 'coin-eon', category: 'Items', title: 'Eon Coin', description: 'Ancient currency from a bygone era.', filename: 'y1_coin_eon.webp' },
  { id: 'sand-coin', category: 'Items', title: 'Sand Coin', description: 'Currency often found buried in the dunes.', filename: 'y1_sand_coin.webp' },
  { id: 'glass-blue', category: 'Items', title: 'Blue Glass Piece', description: 'A polished fragment of sapphire glass.', filename: 'y1_glass_blue.webp' },
  { id: 'pearl-dawn', category: 'Items', title: 'Dawn Pearl', description: 'A lustrous pearl with a warm glow.', filename: 'y1_pearl_dawn.webp' },
  { id: 'shell-curl', category: 'Items', title: 'Curled Shell', description: 'A perfectly spiraled sea shell.', filename: 'y1_shell_curl.webp' },
  { id: 'bottle-drift', category: 'Items', title: 'Drift Bottle', description: 'A message from far away.', filename: 'y1_bottle_drift.webp' },
  { id: 'spiral-snail', category: 'Items', title: 'Spiral Snail Shell', description: 'An intricate snail shell.', filename: 'y1_spiral_snail.webp' },
  { id: 'compass-relic', category: 'Items', title: 'Relic Compass', description: 'A navigational tool from the old explorers.', filename: 'y1_compass_relic.webp' },
  { id: 'shell-rainbow', category: 'Items', title: 'Rainbow Shell', description: 'A shell that shimmers with all colors.', filename: 'y1_shell_rainbow.webp' },
  { id: 'singing-scale', category: 'Items', title: 'Singing Scale', description: 'A scale that hums when the wind blows.', filename: 'singing_scale.webp' },
  { id: 'ocean-heart', category: 'Items', title: 'Ocean Heart', description: 'A rare gemstone found in the deepest abyss.', filename: 'y1_ocean_heart.webp' },

  // Story
  { id: 'lil-tan-awake', category: 'Story', title: 'Lil Tan Awake', description: 'Lil Tan beginning the day.', filename: 'lil_tan_awake.webp' },
  { id: 'lil-tan-returned', category: 'Story', title: 'Lil Tan Returned', description: 'Homecoming after a long voyage.', filename: 'lil_tan_returned.webp' },
  { id: 'lil-tan-voyaging', category: 'Story', title: 'Lil Tan Voyaging', description: 'Setting sail across the vast ocean.', filename: 'lil_tan_voyaging.webp' },
  { id: 'lil-tan-resting', category: 'Story', title: 'Lil Tan Resting', description: 'A well-earned break after arrival.', filename: 'lil_tan_resting_arrival.webp' },
  { id: 'captain-tort-letter', category: 'Story', title: 'Captain Tort Letter', description: 'A mysterious correspondence from Captain Tort.', filename: 'captain_tort_letter.webp' },
  { id: 'family-emblem-echo', category: 'Story', title: 'Echo Family Emblem', description: 'The crest of the Echo family.', filename: 'family_emblem_echo.webp' },
  { id: 'family-emblem-umbra', category: 'Story', title: 'Umbra Family Emblem', description: 'The crest of the Umbra family.', filename: 'family_emblem_umbra.webp' },
  { id: 'family-emblem-lumina', category: 'Story', title: 'Lumina Family Emblem', description: 'The crest of the Lumina family.', filename: 'family_emblem_lumina.webp' },
  { id: 'island-awakened', category: 'Story', title: 'Island Awakened', description: 'The island pulses with life.', filename: 'island_awakened.webp' },
  { id: 'island-sleeping', category: 'Story', title: 'Island Sleeping', description: 'Peaceful rest under the stars.', filename: 'island_sleeping.webp' },
  { id: 'three-turtles-lighthouse', category: 'Story', title: 'Three Turtles Lighthouse', description: 'The guiding light of the three turtles.', filename: 'three_turtles_lighthouse.webp' },
  { id: 'old-star-keepers', category: 'Story', title: 'Old Star Keepers', description: 'The mysterious silhouettes of the star keepers.', filename: 'old_star_keepers_silhouettes.webp' },
];
