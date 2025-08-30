# Setting Up the Parent Session for GitHub Actions

## Overview
Since the Claude CLI's non-interactive session commands are broken, we need to create the parent session manually in interactive mode. Once created, this session CAN be resumed in GitHub Actions.

## Step 1: Create the Parent Session

1. **Open a terminal and navigate to the repository:**
```bash
cd /home/rosswolf/Code/castlebuilder
```

2. **Start Claude in interactive mode:**
```bash
claude
```

3. **Initialize the parent session with this prompt:**
```
You are the parent session for the castlebuilder GitHub repository. This session will be resumed by GitHub Actions to handle issues and PRs.

Repository: /home/rosswolf/Code/castlebuilder
Project: Godot 4.4 card-based tower defense game
Main project: castlebuilder-app/app/

Key knowledge to maintain:
- Full codebase understanding
- Architecture patterns (Entity-Component, Builder pattern)
- Project conventions from CLAUDE.md
- Current development state

Analyze the repository structure and confirm you understand the codebase.
```

4. **After Claude responds, get the session ID:**
Type exactly:
```
/session
```

5. **SAVE THE SESSION ID** 
Claude will respond with something like:
```
Session ID: a1b2c3d4-e5f6-g7h8-i9j0-k1l2m3n4o5p6
```
Copy this ID!

6. **Exit Claude:**
```
exit
```

## Step 2: Update the Workflow

1. **Edit the workflow file:**
```bash
nano .github/workflows/claude-with-session.yml
```

2. **Replace the placeholder with your session ID:**
Find this line:
```yaml
PARENT_SESSION_ID: "YOUR_SESSION_ID_HERE"
```

Replace with:
```yaml
PARENT_SESSION_ID: "a1b2c3d4-e5f6-g7h8-i9j0-k1l2m3n4o5p6"  # Your actual session ID
```

3. **Save the file**

## Step 3: Test the Session

1. **Test locally first:**
```bash
echo "What repository are you working with?" | claude --resume YOUR_SESSION_ID --print
```

Should respond with castlebuilder information.

2. **Commit and push the workflow:**
```bash
git add .github/workflows/claude-with-session.yml
git commit -m "Add workflow with manual parent session"
git push
```

3. **Test in GitHub:**
Create a comment on an issue with `@claude test session`

## Important Notes

- The session persists as long as the Claude CLI data isn't cleared
- You only need to create the parent session ONCE
- All GitHub Actions will resume from this same parent session
- Response time should be under 1 minute (vs 5-7 minutes without parent)

## If the Session Stops Working

1. Create a new parent session following Step 1
2. Update the workflow with the new session ID
3. Push the changes

## Alternative: Using GitHub Secrets

For better security, store the session ID as a GitHub secret:

1. Go to Settings → Secrets → Actions
2. Create a new secret named `CLAUDE_PARENT_SESSION_ID`
3. Paste your session ID as the value
4. Update the workflow to use:
```yaml
PARENT_SESSION_ID: ${{ secrets.CLAUDE_PARENT_SESSION_ID }}
```

This way the session ID isn't exposed in the code.