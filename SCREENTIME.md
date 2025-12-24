# Screen Time Workaround for GitHub Pushes

## Problem

When Screen Time is enabled on macOS, you may encounter HTTP 400 errors when trying to push large commits to GitHub:

```
error: RPC failed; HTTP 400 curl 22 The requested URL returned error: 400
send-pack: unexpected disconnect while reading sideband packet
fatal: the remote end hung up unexpectedly
```

This can happen even if you've successfully authenticated with GitHub CLI (`gh auth login`).

## Solution

Configure git to use larger HTTP buffers and HTTP/1.1 protocol:

```bash
# Increase HTTP post buffer to handle larger uploads
git config --global http.postBuffer 524288000

# Use HTTP/1.1 protocol (more compatible with Screen Time restrictions)
git config --global http.version HTTP/1.1

# Configure git to use GitHub CLI for authentication
git config --global credential.helper "!gh auth git-credential"
```

## Additional Setup

Make sure you have:

1. **GitHub CLI installed and authenticated:**
   ```bash
   gh auth login --git-protocol https --hostname github.com --web
   ```

2. **Git user configured:**
   ```bash
   git config --global user.name "your-username"
   git config --global user.email "your-email@users.noreply.github.com"
   ```

## After Configuration

Try pushing again:

```bash
git push -u origin main
```

The push should now succeed even with Screen Time enabled.

## Notes

- The `http.postBuffer` setting (524288000 bytes = ~500MB) allows git to handle larger file uploads
- HTTP/1.1 is more compatible with network restrictions than HTTP/2
- These settings are global and will apply to all git repositories on your system

