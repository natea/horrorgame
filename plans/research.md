# Asset Creation Research for Horror Game

This document covers research on external platforms for creating 3D environments, characters, and animations for the Horror Game project built in Godot 4.5.

---

## Marble by World Labs (marble.worldlabs.ai)

### Overview

Marble is World Labs' first product - a **generative multimodal world model** that creates high-fidelity, persistent 3D worlds from various inputs. Founded by AI pioneer Fei-Fei Li, World Labs released Marble in general availability on November 12, 2025.

### Key Features

#### Input Methods
- **Text Prompts**: Describe your vision in natural language and Marble generates a complete 3D environment
- **Single Image**: Convert any image into a traversable 3D world
- **Multi-Image**: Provide multiple viewpoints and Marble stitches them into a unified 3D space
- **Video**: Use video clips (under 100MB) showing rotational views
- **360° Panoramas**: Upload panoramic images for precise spatial control
- **Chisel Tool**: Built-in 3D modeling tool to block out geometric layouts and architectural structures as foundation for AI generation
- **Preset Templates**: Quick generation from pre-made starting points

#### Editing Capabilities
- **Pano Edit**: Select specific areas in panoramic view and describe changes using natural language
- **Click and Expand**: Grow worlds beyond original boundaries with seamless extensions
- **Variation**: Generate alternative versions while maintaining core style
- **Compose**: Arrange multiple worlds into larger environments
- **Record**: Create cinematic camera animations and flythrough videos

### Export Formats for Game Development

| Format | Description | Use Case |
|--------|-------------|----------|
| **Gaussian Splats** | Highest-fidelity representation using semitransparent particles | Visual rendering, VR |
| **Triangle Meshes (Low-fi)** | "Collider meshes" for physics simulation | Game physics, collision |
| **Triangle Meshes (High-quality)** | Detailed meshes matching visual quality | Game environments |
| **Video** | Rendered with pixel-accurate camera control | Cinematics, trailers |
| **DCC Files** | Compatible with Blender, Maya, 3ds Max | Further editing |
| **Game Engine Compatible** | Files for Unreal Engine, Unity | Direct import |

**Note**: For Godot integration, export as mesh/GLTF via Blender workflow or use the DCC-compatible exports.

### Pricing Tiers (as of November 2025)

| Tier | Price | Generations/Month | Features |
|------|-------|-------------------|----------|
| **Free** | $0 | 4 worlds | Basic generation |
| **Standard** | $20/month | 12 worlds | More generations |
| **Pro** | $35/month | 25 worlds | Commercial rights included |
| **Max** | $95/month | 75 worlds | Full feature access |

### Generation Times

- Draft creation: ~20 seconds
- Panoramic world from text/image: ~30 seconds
- Standard world creation: ~5 minutes
- High-quality mesh export: up to 1 hour

### Horror Game Applications

Marble has demonstrated capability for creating atmospheric, dark environments suitable for horror games:

- **Haunted houses** with multiple interconnected rooms
- **Overgrown/abandoned environments** with gothic aesthetics
- **Atmospheric lighting** baked into generated scenes
- **Textured walls and floors** with realistic materials

#### Suggested Workflow for Horror Game

1. **Sketch room layouts** using Chisel tool or hand-drawn reference (like our horror-game.jpg)
2. **Generate base environment** from text prompt: "Dark Victorian mansion interior, horror atmosphere, moonlit, dusty, abandoned"
3. **Expand rooms** using Click and Expand feature
4. **Edit specific areas** with Pano Edit for custom details
5. **Export as mesh** for Godot import
6. **Apply in Godot** - may need UV/material adjustments

#### Potential Prompts for Our Horror Game Rooms

```
Kitchen: "Abandoned Victorian kitchen, rusty oven, cracked tiles, dim lighting, horror atmosphere"
Basement: "Dark cellar with stone walls, wooden support beams, single hanging light bulb, water puddles, cobwebs"
Bedroom: "Decrepit bedroom with old bed, torn wallpaper, moonlight through dusty window, cave-like texture walls"
Living Room: "Victorian living room with covered furniture, grandfather clock, dusty bookshelf, candlelight"
```

### Limitations

- Web-based only (desktop recommended for full features)
- Generation limits based on subscription tier
- May require post-processing in Blender for Godot optimization
- Gaussian splats not directly supported in Godot (use mesh export)

### Resources

- Documentation: https://docs.worldlabs.ai
- Platform: https://marble.worldlabs.ai
- Blog: https://www.worldlabs.ai/blog/marble-world-model

---

## Mixamo (mixamo.com)

### Overview

Mixamo is Adobe's **free** platform providing 3D characters and animations. It's the source of "George" the zombie in our Horror Game project (using the "Zombie Crawl.fbx" model).

### Key Features

- **Completely Free**: No purchase or Creative Cloud subscription required (just Adobe ID)
- **Royalty-Free License**: Use for personal, commercial, and non-profit projects including video games
- **Extensive Animation Library**: Thousands of motion-captured animations
- **Auto-Rigging**: Upload your own 3D models and Mixamo will automatically add a skeleton
- **Real-Time Preview**: See animations on characters before downloading

### Available Content

#### Characters
- Pre-made humanoid characters (various styles)
- Zombie and creature variants
- Can upload custom characters for rigging

#### Animation Categories
Relevant to horror games:
- **Zombie animations**: Stand up, crawl, attack, idle
- **Locomotion**: Walking, running, crawling, limping
- **Combat**: Attack swings, hit reactions, death animations
- **Idle**: Standing, looking around, breathing
- **Interactions**: Door opening, picking up objects

### Export Formats

| Format | Description | Godot Compatibility |
|--------|-------------|---------------------|
| **FBX Binary** | Standard format | Yes (via import) |
| **FBX for Unity** | Unity-optimized | Works in Godot too |
| **Collada (DAE)** | Open format | Yes |

### Download Options

When downloading animations:
- **With Skin**: Includes character mesh (use for first download)
- **Without Skin**: Armature and animation only (for additional animations)
- **Frames per Second**: 24, 30, or 60 fps
- **Keyframe Reduction**: Optimize file size
- **In Place**: Keep character stationary (recommended for game dev)

### Godot Integration Workflow

#### Method 1: Direct Import (Godot 4.3+)

1. Download character with T-Pose animation first (FBX Binary, With Skin, 60fps)
2. Download additional animations (Without Skin, In Place)
3. Drag FBX files into Godot's FileSystem
4. Double-click to open Advanced Import Settings
5. Create BoneMap with SkeletonProfileHumanoid
6. Save BoneMap for reuse with other Mixamo imports

#### Method 2: Via Blender (More Control)

1. Import FBX into Blender
2. Clean up and optimize mesh
3. Export as GLTF/GLB
4. Import into Godot

#### Method 3: Godot Game Tools Plugin

1. Download all animations with T-Pose first
2. Use Blender addon "Godot Game Tools"
3. Merge all animations into single GLB file
4. Results in smaller file size with no duplicate data

### Horror Game Character Recommendations

#### Zombie Types Available on Mixamo
- **Zombie (Male/Female)**: Standard zombie models
- **Zombie Brute**: Larger, more threatening
- **Custom Upload**: Rig your own zombie models

#### Recommended Animations for Horror Game

| Animation | Use Case | Download Settings |
|-----------|----------|-------------------|
| **Zombie Crawl** | George's movement (already in use) | In Place, 60fps |
| **Zombie Attack** | When catching player | In Place, 60fps |
| **Zombie Idle** | Patrol/search behavior | In Place, 30fps |
| **Zombie Stand Up** | Spawn from ground | Not In Place, 60fps |
| **Low Crawl** | Alternative crawl style | In Place, 60fps |
| **Zombie Scream** | Jumpscare moment | In Place, 60fps |
| **Walking Dead** | Slow shamble | In Place, 30fps |

#### Additional Characters to Consider

- **Victim/Survivor**: For environmental storytelling (corpses)
- **Ghost/Spirit**: Potential second enemy type
- **Player Character Hands**: First-person arm/hand models

### Limitations

- **Bipedal humanoids only**: No quadrupeds, creatures with tails/wings
- **Single character storage**: Only last used character is stored online
- **No animation history**: Save rigged characters locally
- **Standard skeleton only**: Non-humanoid proportions may not work

### Resources

- Platform: https://www.mixamo.com
- FAQ: https://helpx.adobe.com/creative-cloud/faq/mixamo-faq.html
- Zombie Collection (Sketchfab): https://sketchfab.com/mixamoanimations/collections/zombie-cb508aff4cfa415b8eb3ffc7a19d363a

---

## Integration Strategy for Horror Game

### Recommended Workflow

```
1. ENVIRONMENTS (Marble)
   ├── Generate room base meshes from text/image prompts
   ├── Export as high-quality mesh
   ├── Import to Blender for cleanup
   ├── Export as GLTF for Godot
   └── Apply in mansion.tscn

2. CHARACTERS (Mixamo)
   ├── Download zombie variants with animations
   ├── Process through Blender or direct import
   ├── Set up AnimationTree in Godot
   └── Integrate with existing enemy.tscn

3. COMBINATION
   ├── Marble environments as static geometry
   ├── Mixamo characters as animated entities
   ├── Godot handles gameplay, physics, AI
   └── CSG for quick prototyping/iteration
```

### Asset Pipeline

```
[Marble]                    [Mixamo]
    │                           │
    ▼                           ▼
Generate 3D World          Download FBX
    │                           │
    ▼                           ▼
Export Mesh               Import to Blender
    │                           │
    ▼                           ▼
Import to Blender         Optimize/Merge
    │                           │
    ▼                           ▼
Optimize UV/Materials     Export GLTF
    │                           │
    ▼                           ▼
Export GLTF               Import to Godot
    │                           │
    └──────────┬───────────────┘
               ▼
        Godot Project
               │
    ┌──────────┼──────────┐
    ▼          ▼          ▼
mansion.tscn  enemy.tscn  player.tscn
```

### Cost Analysis

| Resource | Cost | Value for Horror Game |
|----------|------|----------------------|
| Marble Free | $0 | 4 room generations (limited) |
| Marble Pro | $35/mo | 25 rooms + commercial rights |
| Mixamo | $0 | Unlimited characters/animations |
| Blender | $0 | Required for pipeline |
| **Total (Free Tier)** | **$0** | Basic prototyping |
| **Total (Production)** | **$35/mo** | Full quality assets |

---

## Current Horror Game Assets (from Mixamo)

### Already Implemented
- **Zombie Crawl.fbx**: George the zombie model
- **Zombie Crawl_0.png**: Texture map 1
- **Zombie Crawl_1.png**: Texture map 2
- **Zombie Crawl_2.png**: Texture map 3

### Recommended Additions
1. Additional zombie animations (attack, scream, stand up)
2. Alternative zombie models for variety
3. First-person hand/arm model for player
4. Corpse/victim models for environmental storytelling

---

## References

### Marble by World Labs
- [Marble Platform](https://marble.worldlabs.ai/)
- [World Labs Documentation](https://docs.worldlabs.ai)
- [Marble World Model Blog Post](https://www.worldlabs.ai/blog/marble-world-model)
- [Bigger and Better Worlds Update](https://www.worldlabs.ai/blog/bigger-better-worlds)
- [Fast Company Article on World Labs](https://www.fastcompany.com/91437004/fei-fei-li-world-labs-spatial-ai-mapping-3d)

### Mixamo
- [Mixamo Platform](https://www.mixamo.com/)
- [Mixamo FAQ](https://helpx.adobe.com/ca/creative-cloud/faq/mixamo-faq.html)
- [Animate Characters with Mixamo Guide](https://helpx.adobe.com/uk/creative-cloud/help/animate-characters-mixamo.html)
- [Zombie Collection on Sketchfab](https://sketchfab.com/mixamoanimations/collections/zombie-cb508aff4cfa415b8eb3ffc7a19d363a)

### Godot Integration Tutorials
- [Import Mixamo Characters to Godot (Tripo3D)](https://www.tripo3d.ai/blog/collect/how-to-import-mixamo-characters-and-animations-in-godot-engine-dhuedr-jp_a)
- [Mixamo Animations to Godot Plugin (Godot Forum)](https://forum.godotengine.org/t/mixamo-animations-to-godot-plugin/87630)
- [From Mixamo to Godot: An Easier Approach (itch.io)](https://antzgames.itch.io/mixamo-to-godot)
- [Godot 4: Easy and Automatic 3D Animation using Mixamo](https://bytemyke.com/godot-4-mixamo/)
- [Bringing Mixamo Animations to Life in Godot](https://9to5grind.dev/posts/bringing-mixamo-animations-to-life-in-godot/)
- [Godot Game Tools for Merging Mixamo Models](https://peardox.com/merging-mixamo-models-using-godot-game-tools/)
