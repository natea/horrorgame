# Horror Game GOAP Implementation Plan

## Executive Summary

This Goal-Oriented Action Plan (GOAP) outlines the systematic implementation of a multi-room horror game mansion based on hand-drawn design specifications. The plan transforms the current single-room prototype into a fully-featured horror experience with multiple interconnected rooms, improved AI, key-based progression, and enhanced environmental storytelling.

---

## Current State Assessment

### Existing Systems (Verified)
- **Player Controller**: First-person movement with sprint, stamina system, head bob
- **Flashlight System**: Battery-based with drain mechanics, flickering at low battery, pickup system
- **Enemy AI**: Crawling zombie "George" with basic chase behavior
- **Hiding Mechanic**: Closet-based hiding zone with interaction
- **Door System**: Interactive doors with area-based interaction
- **Sound Design**: Ambient horror audio, background drone, creaking sounds
- **Death/Jumpscare**: Full death sequence with jumpscare image, screen shake, sound effect
- **Environment**: 30x20 unit CSG mansion structure with basic props (bookshelf, candle table, grandfather clock, pictures, mirror)
- **Navigation**: NavigationMesh system for AI pathfinding

### Current Limitations
- Single large room (living room area)
- Simple zombie AI that moves through walls
- No room-to-room progression system
- No key/unlock mechanics
- CSG geometry lacks visual polish (no textures)
- No visible flashlight model in hand
- No upstairs/basement areas
- Limited environmental interactivity

---

## Goal State Definition

Transform the game into a multi-room mansion horror experience where:
- Players navigate 8+ distinct interconnected rooms across multiple floors
- Key collection unlocks progression through locked doors
- Enhanced zombie AI with proper wall avoidance and improved jumpscares
- Visually polished environments with proper materials and textures
- Visible flashlight model for immersion
- Respawn system for player death
- Interactive environmental objects (oven, sink, fridge, toilet)
- Atmospheric multi-level exploration with basement and upstairs areas

---

## GOAP Plan Structure

This plan uses the Goal-Oriented Action Planning approach:
- **Preconditions**: Required state before action can execute
- **Effects**: State changes after action completes
- **Cost**: Relative implementation complexity (1-10)
- **Dependencies**: Related actions that must complete first
- **Success Criteria**: Measurable completion indicators
- **Tool Groups**: Godot 4.5 tools and techniques required

---

## Phase 1: Foundation - Core Architecture (Priority: CRITICAL)

### Action 1.1: Mansion Layout Restructure
**Goal**: Transform single-room structure into multi-room layout matching hand-drawn plan

**Preconditions**:
- Current mansion.tscn accessible
- CSG geometry system in place
- NavigationRegion3D configured

**Implementation Steps**:
1. Create room division planning (room boundaries, doorway positions)
2. Add interior walls for 8 primary rooms:
   - Kitchen (top area, ~6x8 units)
   - Dining Room (connected to kitchen, ~6x6 units)
   - Living Room (existing area, redesign ~8x10 units)
   - Bathroom (~4x4 units)
   - Bedroom (~7x8 units with "cave texture" note)
   - Basement (accessible via stairs, ~12x8 units)
   - Random Room with stairs (left side, ~5x6 units)
   - Upstairs area (right side, ~10x12 units)
3. Create hallway/corridor system connecting rooms
4. Add doorway openings (2.5 units high, 1.2 units wide)
5. Update NavigationMesh to include all rooms
6. Add floor level variations (basement at y=-4, upstairs at y=+4)

**Effects**:
- `multi_room_layout: true`
- `room_count: 8`
- `navigation_updated: true`
- `floor_levels: 3`

**Cost**: 8
**Execution**: Code (deterministic CSG construction)
**Tools**: CSGBox3D, NavigationRegion3D, scene tree manipulation

**Success Criteria**:
- Player can physically walk between all 8 rooms
- Each room has distinct boundaries and purpose
- NavigationMesh covers all accessible areas
- No floating geometry or gaps in walls

---

### Action 1.2: Staircase System Implementation
**Goal**: Add functional stairs connecting basement, main floor, and upstairs

**Preconditions**:
- `multi_room_layout: true`
- Floor height differences established

**Implementation Steps**:
1. Create staircase prefab/component:
   - CSGBox steps (0.3 height, 0.8 depth per step)
   - Collision shapes for each step
   - Ramp collision option for smooth movement
2. Add basement stairs in "Random Room"
3. Add upstairs stairs on right side
4. Configure NavigationMesh to handle vertical movement
5. Add railings for visual clarity

**Effects**:
- `stairs_functional: true`
- `vertical_navigation: true`
- `basement_accessible: true`
- `upstairs_accessible: true`

**Cost**: 5
**Execution**: Hybrid (code for generation, manual for positioning)
**Tools**: CSGBox3D, StaticBody3D, NavigationMesh agent_max_climb

**Success Criteria**:
- Player can traverse stairs smoothly without getting stuck
- AI can navigate stairs via NavigationAgent3D
- No clipping through stair geometry

---

### Action 1.3: Door System Upgrade
**Goal**: Implement locked/unlocked door mechanics with key requirement

**Preconditions**:
- `multi_room_layout: true`
- Existing interactive_door.gd script

**Implementation Steps**:
1. Extend `interactive_door.gd` to support:
   - `locked` state boolean
   - `required_key_id` string property
   - `try_unlock(key_id)` method
   - Visual locked indicator (red vs green interaction prompt)
2. Create door placement for each room transition
3. Designate specific doors as locked by default
4. Implement UI feedback for locked doors ("This door is locked")
5. Add door swing animation or slide animation

**Effects**:
- `door_system_enhanced: true`
- `locked_doors_exist: true`
- `key_requirement_functional: true`

**Cost**: 4
**Execution**: Code (GDScript extension)
**Tools**: Area3D, AnimationPlayer, signal system

**Success Criteria**:
- Doors show locked/unlocked state visually
- Locked doors prevent passage without correct key
- Interaction prompts update based on lock state
- Doors can be unlocked with correct key item

---

## Phase 2: Progression Systems (Priority: HIGH)

### Action 2.1: Key Inventory System
**Goal**: Implement player inventory for collecting and storing keys

**Preconditions**:
- Player controller exists
- Door system supports key checks

**Implementation Steps**:
1. Create `InventoryComponent.gd`:
   - `keys: Array[String]` to track collected keys
   - `add_key(key_id: String)` method
   - `has_key(key_id: String) -> bool` method
   - Signal `key_collected(key_id)`
2. Add inventory component to player.gd
3. Create UI display for collected keys (simple list or icon display)
4. Integrate with door unlock system

**Effects**:
- `inventory_system: true`
- `key_tracking: true`
- `player_can_collect_items: true`

**Cost**: 3
**Execution**: Code (GDScript component)
**Tools**: GDScript signals, UI CanvasLayer

**Success Criteria**:
- Keys persist after collection
- UI updates when keys are collected
- Doors can query player inventory for keys
- Keys don't duplicate in inventory

---

### Action 2.2: Key Spawning System
**Goal**: Place collectible keys in designated spawn locations throughout mansion

**Preconditions**:
- `inventory_system: true`
- `multi_room_layout: true`

**Implementation Steps**:
1. Create `Key.tscn` pickup item:
   - Area3D for detection
   - MeshInstance3D for visual (CSG key shape or imported model)
   - `key_id` export property
   - Pickup script with player detection
   - Floating/rotating animation for visibility
2. Place keys according to hand-drawn plan notes:
   - Kitchen: Kitchen key (access to pantry/basement)
   - Living room: Study key
   - Bedroom: Master key
   - Random room: Basement key
   - Hidden spots near furniture
3. Implement randomization option (optional advanced feature)
4. Add pickup sound effect
5. Create visual sparkle/glow effect on keys

**Effects**:
- `keys_spawned: true`
- `collectible_items_exist: true`
- `progression_gated: true`

**Cost**: 4
**Execution**: Hybrid (code for Key.tscn, manual placement)
**Tools**: Area3D, AnimationPlayer, CSGCombiner3D

**Success Criteria**:
- Keys are visible and clearly marked
- Player can collect keys via interaction
- Keys disappear after collection
- Each key has unique identifier matching door requirements

---

### Action 2.3: Respawn System
**Goal**: Implement player respawn at designated checkpoint locations

**Preconditions**:
- Death system functional (already exists)
- Multiple rooms available for spawn points

**Implementation Steps**:
1. Create `RespawnPoint.gd` component:
   - `spawn_position: Vector3`
   - `spawn_rotation: Vector3`
   - `is_active: bool`
2. Create `RespawnManager.gd` autoload singleton:
   - Track active respawn point
   - `set_respawn_point(point: RespawnPoint)` method
   - `respawn_player()` method
3. Place respawn points in "Random Room" (as noted in drawing)
4. Modify player death sequence to use respawn system instead of `reload_current_scene()`
5. Add checkpoint activation visual feedback
6. Preserve inventory/keys on respawn

**Effects**:
- `respawn_system: true`
- `checkpoint_system: true`
- `player_death_handled: true`

**Cost**: 5
**Execution**: Code (GDScript with autoload)
**Tools**: Autoload singleton, Node3D markers

**Success Criteria**:
- Player respawns at last checkpoint after death
- Keys and progress are preserved
- Respawn position/rotation are correct
- No duplicate player instances created

---

## Phase 3: Room Implementation (Priority: HIGH)

### Action 3.1: Kitchen Implementation
**Goal**: Build fully functional kitchen with interactive appliances

**Preconditions**:
- `multi_room_layout: true`
- Room boundaries defined

**Implementation Steps**:
1. Create kitchen props using CSG:
   - Oven (CSGBox with door, burners on top)
   - Sink (CSGBox counter with cylinder basin)
   - Fridge (tall CSGBox with double doors)
   - Table with chairs (4 chairs around table)
   - Countertops along walls
2. Add basic materials/colors to differentiate objects
3. Implement interactive scripts:
   - `InteractiveOven.gd` - door opens/closes, interior light
   - `InteractiveSink.gd` - water sound on interaction
   - `InteractiveFridge.gd` - door opens, light turns on
4. Place key spawn location (on counter or in cabinet)
5. Add kitchen-specific lighting (ceiling light, under-cabinet lights)
6. Add ambient sound (refrigerator hum)

**Effects**:
- `kitchen_complete: true`
- `interactive_appliances: 3`
- `kitchen_key_accessible: true`

**Cost**: 6
**Execution**: Hybrid (CSG construction + interaction scripts)
**Tools**: CSGBox3D, Area3D interaction, AudioStreamPlayer3D

**Success Criteria**:
- All appliances have collision
- Oven, sink, and fridge respond to player interaction
- Visual feedback on interaction (doors open, lights activate)
- Kitchen feels distinct from other rooms

---

### Action 3.2: Bathroom Implementation
**Goal**: Create functional bathroom with toilet interaction

**Preconditions**:
- `multi_room_layout: true`

**Implementation Steps**:
1. Create bathroom props:
   - Toilet (CSGBox base + cylinder bowl + tank)
   - Sink with mirror above
   - Bathtub/shower area
   - Towel rack
2. Add `InteractiveToilet.gd`:
   - Flush animation
   - Flush sound effect
   - Easter egg potential (jumpscare option)
3. Add lighting (single overhead light, dim)
4. Optional: Flickering light for horror effect
5. Add small hiding spot (behind shower curtain)

**Effects**:
- `bathroom_complete: true`
- `toilet_interactive: true`
- `additional_hiding_spot: true`

**Cost**: 4
**Execution**: Hybrid (CSG + scripts)
**Tools**: CSGCombiner3D, AnimationPlayer, AudioStreamPlayer3D

**Success Criteria**:
- Toilet provides interactive feedback
- Room feels claustrophobic and vulnerable
- Lighting contributes to atmosphere

---

### Action 3.3: Bedroom Implementation
**Goal**: Create bedroom with "cave texture" aesthetic and save door

**Preconditions**:
- `multi_room_layout: true`
- Door system enhanced

**Implementation Steps**:
1. Create bedroom props:
   - Bed (CSGBox frame + mattress + pillows)
   - Nightstands (both sides of bed)
   - Wardrobe/closet
   - Dresser with mirror
2. Implement "cave texture" note:
   - Darker, rougher wall materials
   - Weathered/damaged appearance
   - Potentially cracked walls
3. Add "save door" functionality:
   - Special door that triggers checkpoint/save
   - Visual indicator (glowing outline, different color)
   - Auto-save on entering bedroom
4. Add bedroom-specific lighting (lamp, moonlight through window)
5. Potential hiding spots under bed or in wardrobe

**Effects**:
- `bedroom_complete: true`
- `save_door_functional: true`
- `safe_zone_exists: true`

**Cost**: 5
**Execution**: Hybrid (CSG + materials + scripts)
**Tools**: CSGBox3D, StandardMaterial3D, RespawnPoint

**Success Criteria**:
- Bedroom provides sense of safety/checkpoint
- Cave texture creates unique visual identity
- Save door clearly communicates its function
- Master key accessible in bedroom

---

### Action 3.4: Dining Room Implementation
**Goal**: Create dining room connected to kitchen

**Preconditions**:
- `multi_room_layout: true`
- Kitchen complete (adjacency)

**Implementation Steps**:
1. Create dining room props:
   - Large dining table (6-8 units long)
   - 6-8 chairs around table
   - China cabinet/hutch
   - Chandelier overhead
2. Add table settings (plates, candles optional)
3. Set atmospheric lighting (chandelier as primary source)
4. Connect to kitchen via doorway or open archway
5. Add creepy details (one chair pulled out, place settings disturbed)

**Effects**:
- `dining_room_complete: true`
- `kitchen_connection: true`

**Cost**: 3
**Execution**: Hybrid (CSG construction)
**Tools**: CSGBox3D, OmniLight3D

**Success Criteria**:
- Clear connection to kitchen
- Feels like formal dining space
- Props create environmental storytelling

---

### Action 3.5: Basement Implementation
**Goal**: Create basement area accessible via stairs with horror atmosphere

**Preconditions**:
- `stairs_functional: true`
- `multi_room_layout: true`

**Implementation Steps**:
1. Create basement space (y=-4 level):
   - Larger open area than upstairs rooms
   - Lower ceiling (claustrophobic)
   - Support pillars/columns
2. Add basement-specific props:
   - Storage boxes/crates
   - Old furniture
   - Cobwebs (particle effects or meshes)
   - Flickering light bulbs
3. Add environmental hazards/tension:
   - Very limited lighting
   - Zombie spawn point possibility
   - Hidden key location
4. Add water puddles on floor (visual only or with sound)
5. Connect to "Random Room" stairs

**Effects**:
- `basement_complete: true`
- `basement_horror_atmosphere: true`
- `high_tension_area: true`

**Cost**: 6
**Execution**: Hybrid (CSG + lighting + atmosphere)
**Tools**: CSGBox3D, OmniLight3D, GPUParticles3D

**Success Criteria**:
- Basement feels dangerous and oppressive
- Navigation is possible but challenging
- Lighting creates deep shadows
- Player feels vulnerable

---

### Action 3.6: Upstairs Area Implementation
**Goal**: Create second floor with additional rooms

**Preconditions**:
- `stairs_functional: true`
- `multi_room_layout: true`

**Implementation Steps**:
1. Create upstairs floor layout (y=+4 level):
   - Hallway connecting rooms
   - 2-3 smaller rooms (study, spare bedroom, storage)
   - Overlooks main floor (optional railing/balcony)
2. Add upstairs props:
   - Bookshelves in study
   - Desk with papers
   - Additional beds
3. Add windows marked as "new windows" in drawing:
   - CSGBox frames with transparent interior
   - Moonlight streaming through
   - View to exterior (skybox or black void)
4. Create distinct layout from ground floor

**Effects**:
- `upstairs_complete: true`
- `windows_added: true`
- `multi_floor_gameplay: true`

**Cost**: 7
**Execution**: Hybrid (CSG + lighting)
**Tools**: CSGBox3D, DirectionalLight3D for moonlight

**Success Criteria**:
- Upstairs feels spatially distinct
- Windows provide atmospheric lighting
- Players can orient themselves relative to ground floor
- Additional exploration/hiding opportunities

---

### Action 3.7: Random Room with Respawn Implementation
**Goal**: Create the "Random Room" with stairs and respawn functionality

**Preconditions**:
- `multi_room_layout: true`
- `respawn_system: true`

**Implementation Steps**:
1. Create room on left side of mansion
2. Add staircase going down to basement
3. Place primary respawn point (marked "respawning place" in drawing)
4. Add visual indicator for respawn point (glowing circle, particle effect)
5. Add note about "fallen" - potentially area where player starts or falls into
6. Keep relatively empty for clarity of purpose

**Effects**:
- `random_room_complete: true`
- `primary_respawn_active: true`
- `basement_access_point: true`

**Cost**: 3
**Execution**: Hybrid (CSG + respawn marker)
**Tools**: CSGBox3D, RespawnPoint, GPUParticles3D

**Success Criteria**:
- Respawn point is clearly visible
- Stairs to basement are functional
- Room purpose is clear to player

---

### Action 3.8: Living Room Redesign
**Goal**: Enhance existing living room with proper furniture layout

**Preconditions**:
- `multi_room_layout: true`
- Existing props can be repositioned

**Implementation Steps**:
1. Reposition existing props to match drawing:
   - Couch facing TV location
   - TV stand/entertainment center
   - Bookcase (already exists, reposition)
   - Coffee table
2. Add carpet area (CSGBox with different material, slightly elevated)
3. Add TV screen (CSGBox with emissive material)
4. Improve lighting (table lamps, TV glow)
5. Add more pictures on walls
6. Create clear pathways to other rooms

**Effects**:
- `living_room_redesigned: true`
- `carpet_areas_added: true`
- `furniture_layout_optimized: true`

**Cost**: 4
**Execution**: Manual (scene repositioning)
**Tools**: Godot editor, StandardMaterial3D

**Success Criteria**:
- Living room feels cohesive and lived-in
- Furniture placement makes spatial sense
- Carpet areas are visible
- TV creates focal point

---

## Phase 4: Environmental Polish (Priority: MEDIUM)

### Action 4.1: House Texturing System
**Goal**: Replace CSG default materials with proper textures

**Preconditions**:
- All rooms constructed
- CSG geometry finalized

**Implementation Steps**:
1. Create/acquire texture assets:
   - Wood floor texture (seamless)
   - Wall plaster/wallpaper texture
   - Ceiling texture
   - Wood grain for furniture
   - Metal textures for appliances
   - Carpet texture
2. Create StandardMaterial3D presets:
   - Floor material (wood with normal map)
   - Wall material (plaster with subtle detail)
   - Furniture material (painted wood)
3. Apply materials to CSG objects:
   - Use material override per object
   - Configure UV scaling for proper tiling
4. Add normal maps for depth
5. Adjust roughness/metallic properties for realism

**Effects**:
- `house_textured: true`
- `visual_quality_improved: true`
- `csg_materials_applied: true`

**Cost**: 7
**Execution**: Hybrid (asset import + manual application)
**Tools**: StandardMaterial3D, texture import, UV mapping

**Success Criteria**:
- All major surfaces have appropriate textures
- Textures tile seamlessly without obvious repetition
- Materials respond appropriately to lighting
- Performance remains stable (texture resolution optimized)

---

### Action 4.2: Carpet Areas Implementation
**Goal**: Add carpet areas as marked in hand-drawn plan

**Preconditions**:
- Rooms constructed
- Floor materials configured

**Implementation Steps**:
1. Identify carpet placement from drawing:
   - Living room (central area)
   - Bedroom (beside bed)
   - Dining room (under table)
   - Upstairs hallway (runner)
2. Create carpet meshes:
   - CSGBox slightly above floor level (0.01 units)
   - Soft fabric material (high roughness)
   - Darker colors for contrast
3. Add subtle height variation for realism
4. Optional: Add sound effect variation when walking on carpet vs. floor

**Effects**:
- `carpet_areas_complete: true`
- `floor_variation_added: true`

**Cost**: 3
**Execution**: Hybrid (CSG + materials)
**Tools**: CSGBox3D, StandardMaterial3D

**Success Criteria**:
- Carpets are visually distinct from wood floors
- No z-fighting between carpet and floor
- Carpets enhance room identity

---

### Action 4.3: Window System
**Goal**: Add windows with exterior views and lighting

**Preconditions**:
- Rooms have exterior walls
- Lighting system configured

**Implementation Steps**:
1. Create window cutouts in exterior walls (CSG subtraction)
2. Add window frame meshes (CSGBox painted wood)
3. Add glass panes (MeshInstance3D with transparent material)
4. Configure exterior view options:
   - Option A: Black void with fog
   - Option B: Simple exterior skybox
   - Option C: Fake exterior using distant meshes
5. Add moonlight streaming through windows (DirectionalLight3D)
6. Add curtains/blinds to some windows (partially closed for variety)
7. Add reflections to glass using environment settings

**Effects**:
- `windows_functional: true`
- `exterior_lighting_enhanced: true`
- `spatial_awareness_improved: true`

**Cost**: 6
**Execution**: Hybrid (CSG + lighting + materials)
**Tools**: CSGCombiner3D with subtraction, StandardMaterial3D transparency

**Success Criteria**:
- Windows provide sense of exterior world
- Moonlight creates atmospheric lighting
- Glass appears translucent and reflective
- Windows don't break immersion

---

## Phase 5: AI and Enemy Improvements (Priority: HIGH)

### Action 5.1: Zombie Wall Avoidance
**Goal**: Fix zombie AI to properly avoid walls using NavigationAgent3D

**Preconditions**:
- NavigationRegion3D configured for all rooms
- Zombie enemy exists

**Implementation Steps**:
1. Update `crawling_zombie.gd` or create new `zombie_navigation.gd`:
   - Replace direct movement with NavigationAgent3D.get_next_path_position()
   - Remove current direct position movement
   - Add velocity-based movement toward nav target
2. Configure NavigationAgent3D properties:
   - `path_desired_distance = 0.5`
   - `target_desired_distance = 1.0`
   - `max_speed = 2.0`
   - `avoidance_enabled = true`
3. Update navigation target to player position each frame
4. Add smoothing to rotation when following path
5. Implement stuck detection and recovery:
   - Track if zombie hasn't moved significantly in N seconds
   - Request new path if stuck
6. Add debug visualization (optional, can be toggled)

**Effects**:
- `zombie_navigation_improved: true`
- `wall_collision_avoided: true`
- `pathfinding_functional: true`

**Cost**: 5
**Execution**: Code (GDScript AI improvement)
**Tools**: NavigationAgent3D, NavigationRegion3D

**Success Criteria**:
- Zombie navigates around walls and furniture
- Zombie follows player through doorways
- Zombie uses stairs correctly
- No wall penetration or stuck behavior

---

### Action 5.2: Enhanced Jumpscare System
**Goal**: Improve monster jumpscare as noted in drawing

**Preconditions**:
- Zombie AI functional
- Death system exists

**Implementation Steps**:
1. Create jumpscare trigger conditions:
   - Proximity-based (within 1.5 units)
   - Line of sight check (zombie sees player)
   - Cooldown timer (prevent spam)
2. Enhance jumpscare sequence:
   - Rapid camera shake (higher intensity)
   - Zoom in on zombie face
   - Multiple layered sounds (scream + growl + bass drop)
   - Flash of bright light followed by darkness
3. Add jumpscare variations:
   - Different zombie poses (T-pose, reaching, screaming)
   - Random rotation offsets
   - Varied timing
4. Improve zombie positioning:
   - Instant teleport directly in front of camera
   - Ensure zombie face is at eye level
   - Lock zombie rotation to face player
5. Add post-jumpscare effect (screen distortion, color desaturation)

**Effects**:
- `jumpscare_enhanced: true`
- `horror_impact_increased: true`
- `zombie_presentation_improved: true`

**Cost**: 6
**Execution**: Code (GDScript + animation)
**Tools**: AnimationPlayer, Camera3D, AudioStreamPlayer

**Success Criteria**:
- Jumpscare feels sudden and shocking
- Zombie is clearly visible and threatening
- Sound design amplifies scare factor
- Jumpscare doesn't feel repetitive after multiple deaths

---

### Action 5.3: Multiple Zombie Spawns
**Goal**: Add multiple zombie spawn points for variety

**Preconditions**:
- `multi_room_layout: true`
- `zombie_navigation_improved: true`

**Implementation Steps**:
1. Create `ZombieSpawner.gd` component:
   - `spawn_position: Vector3`
   - `spawn_delay: float`
   - `max_zombies: int`
   - `spawn_conditions: Dictionary` (player in certain room, key collected, etc.)
2. Place spawners in strategic locations:
   - Basement (high threat area)
   - Upstairs hallway
   - Kitchen (when player grabs key)
   - Behind player in previously cleared rooms
3. Implement spawn logic:
   - Distance check (don't spawn if player can see)
   - Sound cue (distant growl before spawn)
   - Gradual reveal (crawl from dark corner)
4. Add zombie pooling system (reuse instances)
5. Limit total active zombies (2-3 max for performance/balance)

**Effects**:
- `multiple_zombies: true`
- `dynamic_threat: true`
- `spawn_system_active: true`

**Cost**: 7
**Execution**: Code (GDScript spawning system)
**Tools**: Node instantiation, Timer, detection areas

**Success Criteria**:
- Zombies spawn without player seeing the spawn
- Spawn frequency feels balanced (not overwhelming)
- Multiple zombies don't stack on same position
- Performance remains stable with multiple zombies

---

## Phase 6: Immersion and Polish (Priority: MEDIUM)

### Action 6.1: Visible Flashlight Model
**Goal**: Add 3D flashlight model in player's hand

**Preconditions**:
- Player controller exists
- Camera configured

**Implementation Steps**:
1. Create flashlight 3D model:
   - Option A: CSG construction (cylinder body, cone head)
   - Option B: Import simple flashlight .glb model
2. Add to player scene:
   - Parent to Camera3D
   - Position in lower-right of viewport (hand position)
   - Rotation to match camera forward direction
3. Add animations:
   - Equip/unequip animation when toggling
   - Idle sway/bob synchronized with head bob
   - Battery shake when low battery
4. Synchronize with flashlight state:
   - Hide model when flashlight is off
   - Show model when flashlight is on
   - Dim model material when battery low
5. Add emissive material to flashlight lens

**Effects**:
- `flashlight_visible: true`
- `player_immersion_increased: true`
- `visual_feedback_improved: true`

**Cost**: 5
**Execution**: Hybrid (model creation + scripting)
**Tools**: MeshInstance3D or imported GLTF, AnimationPlayer

**Success Criteria**:
- Flashlight model is visible in player's view
- Model animates smoothly with movement
- Model state matches flashlight on/off status
- Performance impact is minimal

---

### Action 6.2: Enhanced Sound Design
**Goal**: Add room-specific sounds and audio cues

**Preconditions**:
- All rooms implemented
- Audio system functional

**Implementation Steps**:
1. Create room-specific ambient sounds:
   - Kitchen: refrigerator hum, faucet drip
   - Bathroom: water pipes, fan noise
   - Bedroom: wind through window, creaking bed
   - Basement: water dripping, distant groans
2. Add 3D spatial audio sources (AudioStreamPlayer3D):
   - Position sounds at source objects
   - Configure attenuation for realistic falloff
3. Add audio cues for gameplay events:
   - Door unlock sound (success chime)
   - Key pickup (metallic clink)
   - Zombie alert sound (growl when detecting player)
   - Footstep variation (wood vs. carpet)
4. Add dynamic audio mixing:
   - Muffle sounds through walls
   - Increase tension music when zombie is near
5. Create audio occlusion system (optional advanced feature)

**Effects**:
- `room_audio_enhanced: true`
- `spatial_audio_functional: true`
- `immersion_increased: true`

**Cost**: 6
**Execution**: Hybrid (audio asset creation + scripting)
**Tools**: AudioStreamPlayer3D, AudioBusLayout

**Success Criteria**:
- Each room has distinct audio identity
- 3D audio helps player locate sounds
- Audio cues provide gameplay feedback
- Sound doesn't become overwhelming or repetitive

---

### Action 6.3: UI/HUD Enhancement
**Goal**: Add clear UI for inventory, stamina, and battery

**Preconditions**:
- Player systems functional (stamina, battery, inventory)

**Implementation Steps**:
1. Create HUD CanvasLayer with UI elements:
   - Battery indicator (icon + percentage bar)
   - Stamina bar (visible when sprinting or exhausted)
   - Key inventory display (icons for collected keys)
   - Interaction prompt (E to interact, context-sensitive)
2. Design UI style:
   - Minimal and non-intrusive
   - Dark theme to match horror aesthetic
   - Subtle animations (fade in/out)
3. Add UI feedback:
   - Flash red when taking damage
   - Pulse when low on battery
   - Highlight when near interactive object
4. Add crosshair or interaction reticle
5. Create settings menu (brightness, volume, mouse sensitivity)

**Effects**:
- `hud_functional: true`
- `player_feedback_clear: true`
- `ui_polished: true`

**Cost**: 5
**Execution**: Hybrid (UI design + scripting)
**Tools**: CanvasLayer, Control nodes, ProgressBar, Label

**Success Criteria**:
- All key information is visible without cluttering screen
- UI updates in real-time
- UI is readable in dark environments
- Interaction prompts are context-appropriate

---

### Action 6.4: Environmental Storytelling
**Goal**: Add details that tell story without explicit narration

**Preconditions**:
- All rooms implemented
- Props placed

**Implementation Steps**:
1. Add environmental clues:
   - Bloodstains (decals on floor/walls)
   - Scratch marks on doors
   - Overturned furniture (already have knocked chair)
   - Notes/documents (readable text on paper meshes)
   - Family photos (on walls and tables)
2. Create narrative through object placement:
   - Medicine bottles in bathroom (illness?)
   - Boarded windows (attempted escape?)
   - Children's toys (abandoned family?)
   - Ritual symbols in basement (occult activity?)
3. Add interactive readable notes (optional):
   - Diary entries
   - Warning messages
   - Previous victim's notes
4. Create visual progression:
   - Cleaner rooms upstairs → deteriorating downstairs → horrific basement

**Effects**:
- `environmental_story: true`
- `lore_established: true`
- `immersion_deepened: true`

**Cost**: 4
**Execution**: Manual (prop placement + decal application)
**Tools**: Decal node, CSGBox for notes, Label3D

**Success Criteria**:
- Environment suggests narrative without exposition
- Details are discoverable through exploration
- Story elements enhance horror atmosphere
- Elements don't contradict or confuse

---

## Phase 7: Optimization and Testing (Priority: MEDIUM)

### Action 7.1: Navigation Mesh Optimization
**Goal**: Ensure NavMesh is performant and covers all areas

**Preconditions**:
- All rooms finalized
- NavigationRegion3D configured

**Implementation Steps**:
1. Bake final NavigationMesh for entire mansion
2. Verify coverage:
   - All walkable floors included
   - Stairs properly included
   - Doorways are traversable
3. Optimize cell size and agent parameters:
   - `cell_size = 0.25` (balance between detail and performance)
   - `cell_height = 0.2`
   - `agent_height = 1.8`
   - `agent_radius = 0.4`
4. Remove unnecessary navigation areas (inside solid objects)
5. Test with multiple zombies pathfinding simultaneously
6. Add navigation debug visualization (toggle-able)

**Effects**:
- `navmesh_optimized: true`
- `ai_performance_stable: true`

**Cost**: 3
**Execution**: Code (configuration + testing)
**Tools**: NavigationRegion3D, NavigationAgent3D

**Success Criteria**:
- AI can reach all accessible areas
- No performance drops with multiple AI agents
- NavMesh rebuild time is acceptable
- No gaps or holes in navigation coverage

---

### Action 7.2: Lighting Optimization
**Goal**: Balance atmospheric lighting with performance

**Preconditions**:
- All rooms have lighting
- Materials configured

**Implementation Steps**:
1. Optimize light sources:
   - Reduce OmniLight count by combining nearby lights
   - Use baked lightmaps for static lighting (optional advanced)
   - Disable shadows on minor light sources
2. Configure shadow settings:
   - DirectionalLight (moon): shadow_enabled = true, high quality
   - OmniLights: shadow_enabled only for key lights
   - Adjust shadow_bias to prevent artifacts
3. Implement ReflectionProbe for reflective surfaces
4. Add LightmapGI for static baked lighting (optional):
   - Bake lighting for walls, floors, static props
   - Significantly improves performance
   - Reduces dynamic light overhead
5. Test performance in each room

**Effects**:
- `lighting_optimized: true`
- `performance_stable: true`
- `visual_quality_maintained: true`

**Cost**: 5
**Execution**: Hybrid (manual configuration + baking)
**Tools**: LightmapGI, ReflectionProbe, Light nodes

**Success Criteria**:
- Consistent 60+ FPS in all rooms
- Lighting maintains horror atmosphere
- No distracting light artifacts or popping
- Shadows render correctly

---

### Action 7.3: Collision and Physics Optimization
**Goal**: Ensure collision is accurate without performance cost

**Preconditions**:
- All rooms constructed
- All props placed

**Implementation Steps**:
1. Review collision shapes:
   - Ensure all CSG objects have `use_collision = true`
   - Simplify collision shapes where possible (use boxes instead of complex shapes)
   - Remove collision from decorative elements player can't reach
2. Organize collision layers:
   - Layer 1: Environment (walls, floors)
   - Layer 2: Props (furniture, interactive objects)
   - Layer 3: Player
   - Layer 4: Enemies
   - Layer 5: Pickups
3. Configure layer masks properly:
   - Player collides with layers 1, 2, 4
   - Enemies collide with layers 1, 2
   - Pickups only detect layer 3 (player)
4. Test for collision gaps or stuck spots
5. Add invisible collision blockers for exploit prevention

**Effects**:
- `collision_optimized: true`
- `physics_stable: true`
- `exploit_prevention: true`

**Cost**: 4
**Execution**: Manual (configuration + testing)
**Tools**: CollisionShape3D, layer/mask settings

**Success Criteria**:
- No areas where player can get stuck
- No collision gaps allowing escape from mansion
- Physics performance is stable
- Interaction detection is reliable

---

### Action 7.4: Playtesting and Balance
**Goal**: Test complete gameplay loop and adjust difficulty

**Preconditions**:
- All core systems implemented
- Game is playable end-to-end

**Implementation Steps**:
1. Define win condition (if applicable):
   - Escape through final locked door?
   - Survive for time period?
   - Collect all keys and reach safe room?
2. Playtest full game loop:
   - Start in Random Room respawn
   - Collect keys from various rooms
   - Evade zombie(s)
   - Reach bedroom safe zone
3. Balance testing:
   - Zombie speed vs. player sprint speed
   - Battery drain rate vs. flashlight necessity
   - Key placement difficulty
   - Hiding effectiveness
4. Adjust based on feedback:
   - Too easy: Add more zombies, faster movement
   - Too hard: Slow zombies, add more batteries
   - Confusing: Add better visual cues
5. Test edge cases:
   - Player dies with keys (should keep on respawn)
   - Multiple zombies active
   - Running out of battery in critical moment

**Effects**:
- `game_balanced: true`
- `playtesting_complete: true`
- `difficulty_tuned: true`

**Cost**: 6
**Execution**: Manual (playtesting + iteration)
**Tools**: Godot debug tools, performance monitor

**Success Criteria**:
- Game has clear progression path
- Difficulty feels challenging but fair
- No softlock conditions
- Average playthrough achievable in reasonable time

---

## Implementation Priority Matrix

### CRITICAL PATH (Must Complete First)
1. Action 1.1: Mansion Layout Restructure
2. Action 1.2: Staircase System
3. Action 1.3: Door System Upgrade
4. Action 2.1: Key Inventory System
5. Action 2.2: Key Spawning System
6. Action 5.1: Zombie Wall Avoidance

### HIGH PRIORITY (Core Features)
- Action 2.3: Respawn System
- All Phase 3 Room Implementations (3.1-3.8)
- Action 5.2: Enhanced Jumpscare System

### MEDIUM PRIORITY (Polish)
- All Phase 4 Environmental Polish (4.1-4.3)
- Action 6.1: Visible Flashlight Model
- Action 6.2: Enhanced Sound Design
- Action 6.3: UI/HUD Enhancement
- All Phase 7 Optimization (7.1-7.3)

### LOW PRIORITY (Nice-to-Have)
- Action 5.3: Multiple Zombie Spawns
- Action 6.4: Environmental Storytelling
- Action 7.4: Playtesting and Balance (ongoing)

---

## Parallel Execution Opportunities

These actions can be worked on simultaneously by different team members or in separate sessions:

### Parallel Group A (Environment)
- Action 3.1: Kitchen
- Action 3.2: Bathroom
- Action 3.3: Bedroom
- Action 3.4: Dining Room

### Parallel Group B (Systems)
- Action 2.1: Key Inventory
- Action 2.3: Respawn System
- Action 6.3: UI/HUD

### Parallel Group C (Visual Polish)
- Action 4.1: House Texturing
- Action 4.2: Carpet Areas
- Action 4.3: Windows

### Parallel Group D (AI/Audio)
- Action 5.1: Zombie Navigation
- Action 5.2: Enhanced Jumpscare
- Action 6.2: Sound Design

---

## Success Criteria Summary

The implementation will be considered complete when:

### Core Functionality
- Player can navigate 8+ distinct interconnected rooms across 3 floors
- Key collection system allows progression through locked doors
- Zombie AI properly navigates using NavMesh without wall clipping
- Respawn system preserves progress on death
- All rooms are accessible and serve gameplay purpose

### Visual Quality
- CSG geometry has proper materials and textures
- Windows provide atmospheric lighting
- Flashlight is visible in player's hand
- Each room has distinct visual identity
- Lighting creates horror atmosphere

### Audio Quality
- Room-specific ambient sounds
- 3D spatial audio for immersion
- Audio cues for gameplay events
- Enhanced jumpscare sound design

### Gameplay Balance
- Difficulty is challenging but fair
- Battery management creates tension
- Zombie threat is consistent
- Key locations encourage exploration
- Safe zones provide relief

### Performance
- Consistent 60+ FPS on target hardware
- No physics glitches or stuck spots
- AI pathfinding is responsive
- No memory leaks or crashes

---

## Risk Assessment and Mitigation

### High Risk Areas

**Risk**: NavigationMesh doesn't properly handle multi-floor layout
- **Mitigation**: Test stairs early, use separate NavigationRegions per floor if needed
- **Fallback**: Simplify to single floor with basement only

**Risk**: Multiple zombies cause performance issues
- **Mitigation**: Implement zombie pooling, limit active zombies
- **Fallback**: Single zombie with smarter behavior

**Risk**: CSG texturing looks poor or has UV issues
- **Mitigation**: Test material application early, use TriplanarMapping if needed
- **Fallback**: Stick with simple colored materials with good lighting

**Risk**: Room layout feels confusing or maze-like
- **Mitigation**: Add clear visual landmarks, distinctive room colors
- **Fallback**: Simplify layout to more linear progression

### Medium Risk Areas

**Risk**: Door interaction feels clunky with keys
- **Mitigation**: Clear UI feedback, generous interaction radius
- **Fallback**: Automatic unlock when player has key (no explicit unlock action)

**Risk**: Respawn system creates exploits
- **Mitigation**: Clear respawn positions away from zombies, reset zombie positions
- **Fallback**: Full scene reload on death (existing behavior)

**Risk**: Sound design becomes repetitive
- **Mitigation**: Multiple sound variations, random pitch/volume
- **Fallback**: Minimal sound design focusing only on critical cues

---

## Estimated Effort

### Time Estimates (Single Developer)

**Phase 1 (Foundation)**: 8-12 hours
- Critical path, cannot be skipped
- Layout restructure is most time-consuming

**Phase 2 (Progression)**: 4-6 hours
- Systems programming, moderate complexity
- Key and inventory systems relatively straightforward

**Phase 3 (Rooms)**: 12-16 hours
- Most time-intensive phase
- Each room: 1.5-2 hours average
- Can be parallelized

**Phase 4 (Polish)**: 6-8 hours
- Texture creation/acquisition takes time
- Material application is iterative

**Phase 5 (AI)**: 6-8 hours
- Navigation fixes are critical
- Jumpscare enhancement requires iteration

**Phase 6 (Immersion)**: 6-8 hours
- Sound design is time-consuming
- UI/HUD is straightforward

**Phase 7 (Optimization)**: 4-6 hours
- Ongoing throughout development
- Final pass for polish

**Total Estimated Time**: 46-64 hours (single developer)

With parallel execution (2-3 developers): 20-30 hours

---

## Tools and Resources Needed

### Godot 4.5 Features
- CSGCombiner3D and CSG primitives
- NavigationRegion3D and NavigationAgent3D
- AnimationPlayer
- AudioStreamPlayer3D
- CanvasLayer for UI
- Signals and autoload singletons
- StandardMaterial3D with PBR

### External Assets (Optional)
- Texture pack for wood/plaster/metal
- Flashlight 3D model (.glb)
- Additional sound effects (footsteps, ambience)
- Font for UI

### Skills Required
- GDScript programming (intermediate)
- 3D scene composition
- Material/texture application
- Audio implementation
- UI/UX design (basic)
- Playtesting and iteration

---

## Conclusion

This GOAP plan provides a comprehensive roadmap for transforming the current single-room horror game prototype into a fully-featured multi-room mansion horror experience. The plan follows Goal-Oriented Action Planning principles with clear preconditions, effects, and success criteria for each action.

The implementation is structured into 7 phases with 30+ distinct actions, prioritized from critical foundation work to optional polish. The plan accounts for parallel execution opportunities, risk mitigation, and realistic time estimates.

Key success factors:
1. **Phased approach**: Foundation first, then features, then polish
2. **Clear dependencies**: Each action builds on previous work
3. **Parallel opportunities**: Multiple developers can work simultaneously
4. **Testable milestones**: Each action has measurable success criteria
5. **Flexible prioritization**: Core features vs. nice-to-haves clearly marked

By following this plan systematically, the game will evolve from a basic prototype to a polished horror experience matching the vision in the hand-drawn design document.
