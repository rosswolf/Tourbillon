# Web Deployment Guide for Tourbillon

## Quick Start

### Local Testing
```bash
# Navigate to the app directory
cd elastic-app/app

# Build for web
./build_web.sh

# Serve locally
python3 serve_web.py
# OR
python3 -m http.server 8000 --directory build/web

# Open in browser
# http://localhost:8000
```

## Deployment Options

### Option 1: GitHub Pages (Automatic)

The repository is configured with GitHub Actions to automatically deploy to GitHub Pages when you push to main.

1. **Enable GitHub Pages:**
   - Go to Settings → Pages in your GitHub repository
   - Under "Source", select "GitHub Actions"
   - Save the settings

2. **Push to main:**
   ```bash
   git push origin main
   ```

3. **Access your game:**
   - URL will be: `https://[username].github.io/Tourbillon/`
   - Check Actions tab to monitor deployment

### Option 2: Netlify (Drop & Deploy)

1. **Build locally:**
   ```bash
   cd elastic-app/app
   ./build_web.sh
   ```

2. **Deploy to Netlify:**
   - Go to [app.netlify.com](https://app.netlify.com)
   - Drag the `build/web` folder to the deployment area
   - Your game will be live immediately with a unique URL

3. **Custom domain (optional):**
   - Claim your site in Netlify
   - Add a custom domain in Site Settings

### Option 3: Vercel

1. **Install Vercel CLI:**
   ```bash
   npm i -g vercel
   ```

2. **Build and deploy:**
   ```bash
   cd elastic-app/app
   ./build_web.sh
   cd build/web
   vercel --prod
   ```

3. **Follow prompts to configure**

### Option 4: itch.io

1. **Build the game:**
   ```bash
   cd elastic-app/app
   ./build_web.sh
   ```

2. **Create ZIP:**
   ```bash
   cd build/web
   zip -r ../../tourbillon-web.zip *
   ```

3. **Upload to itch.io:**
   - Create new project on itch.io
   - Upload the ZIP file
   - Set "This file will be played in the browser"
   - Enable SharedArrayBuffer support in settings

## Build Configuration

### Export Settings

The `export_presets.cfg` file contains HTML5 export settings:
- Canvas resize policy: Project settings
- Focus canvas on start: Enabled
- VRAM compression: Enabled for desktop

### Required Headers

For Godot 4.x, the following headers are required:
- `Cross-Origin-Embedder-Policy: require-corp`
- `Cross-Origin-Opener-Policy: same-origin`

The `serve_web.py` script includes these automatically.

## Troubleshooting

### Export Templates Missing

If you get an error about missing export templates:

1. **In Godot Editor:**
   - Editor → Manage Export Templates
   - Download for your version
   - Install

2. **Via Command Line:**
   ```bash
   # Download templates (replace with your version)
   wget https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_export_templates.tpz
   
   # Install
   mkdir -p ~/.local/share/godot/export_templates/4.3.stable/
   unzip Godot_v4.3-stable_export_templates.tpz -d ~/.local/share/godot/export_templates/4.3.stable/
   ```

### SharedArrayBuffer Issues

If the game shows a black screen or SharedArrayBuffer error:
- Make sure you're using the provided `serve_web.py` script locally
- For production, ensure your hosting provides the required headers
- GitHub Pages and Netlify handle this automatically

### Audio Issues

Web browsers require user interaction before playing audio:
- Add a "Click to Start" screen
- Or mute audio by default with an unmute button

### Performance

For better web performance:
- Reduce texture sizes
- Use WebP format for images
- Enable texture compression in export settings
- Minimize the number of audio files

## CI/CD Pipeline

The GitHub Actions workflow (`.github/workflows/deploy-web.yml`) automatically:
1. Builds the project when pushing to main
2. Exports to HTML5
3. Deploys to GitHub Pages

To use it:
1. Enable GitHub Pages (Settings → Pages → Source: GitHub Actions)
2. Push to main branch
3. Check Actions tab for build status
4. Game will be available at `https://[username].github.io/Tourbillon/`

## Testing Checklist

Before deploying:
- [ ] Test locally with `serve_web.py`
- [ ] Check console for errors (F12 in browser)
- [ ] Test on different browsers (Chrome, Firefox, Safari)
- [ ] Verify mobile responsiveness
- [ ] Test audio playback
- [ ] Check loading time

## Quick Deploy Script

Create `deploy.sh` for one-command deployment:

```bash
#!/bin/bash
# deploy.sh - Build and deploy to GitHub Pages

# Build
cd elastic-app/app
./build_web.sh

# Commit and push
git add build/web
git commit -m "Update web build"
git push origin main

echo "Deployment triggered! Check GitHub Actions for status"
```

## Support

- Godot Web Export Docs: https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html
- GitHub Pages: https://pages.github.com/
- Netlify: https://www.netlify.com/
- itch.io HTML5 Games: https://itch.io/docs/creators/html5