# Publishing to itch.io

This document describes how to publish The Crawlers horror game to itch.io.

## Prerequisites

### Install Butler

Butler is itch.io's command-line tool for uploading games.

**macOS:**
```bash
cd /tmp
curl -L -o butler.zip "https://broth.itch.zone/butler/darwin-amd64/LATEST/archive/default"
unzip -o butler.zip
mkdir -p ~/bin
mv butler ~/bin/
mv 7z.so ~/bin/
mv libc7zip.dylib ~/bin/
chmod +x ~/bin/butler
```

**Verify installation:**
```bash
~/bin/butler version
```

### Authenticate with itch.io

**Option 1: Interactive login (in terminal)**
```bash
~/bin/butler login
```

**Option 2: API key (for CI/CD or non-interactive)**
1. Go to https://itch.io/user/settings/api-keys
2. Generate a new API key
3. Set the environment variable:
```bash
export BUTLER_API_KEY=your_api_key_here
```

## Exporting from Godot

Before publishing, export the game for web:

1. Open the project in Godot
2. Go to **Project > Export**
3. Select **Web** preset
4. Click **Export Project**
5. Save to the `web_export/` folder as `index.html`

## Publishing to itch.io

### Push the build

```bash
~/bin/butler push "/Users/nateaune/Documents/Godot/Horror Game/web_export" nateaune/horror-game:html5
```

### Check upload status

```bash
~/bin/butler status nateaune/horror-game:html5
```

## Game URLs

- **itch.io page:** https://nateaune.itch.io/horror-game
- **GitHub repo:** https://github.com/natea/horrorgame

## Channel Names

- `html5` - Web/browser version
- `windows` - Windows desktop build
- `mac` - macOS desktop build
- `linux` - Linux desktop build

## Version History

| Version | Date | Notes |
|---------|------|-------|
| 1 | 2024-12-28 | Initial itch.io upload with intro cutscene, key counter, audio, and win screen |

## Troubleshooting

### "invalid game" error
Make sure the game URL matches exactly: `nateaune/horror-game`

### Authentication issues
Re-run `~/bin/butler login` or check your API key at https://itch.io/user/settings/api-keys

### Build not processing
Check status with `~/bin/butler status nateaune/horror-game:html5` - it may take a minute to process.
