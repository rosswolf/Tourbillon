# Setting Up the Parent Session

## Quick Setup (Manual - One Time)

1. Open a terminal and navigate to the repository:
```bash
cd /home/rosswolf/Code/castlebuilder
```

2. Start Claude in interactive mode:
```bash
claude
```

3. Once Claude starts, paste this initialization prompt:

```
You are Claude, an AI assistant with deep knowledge of the castlebuilder repository.

This is a MASTER parent session for the GitHub Actions workflow. You're establishing comprehensive understanding of the entire codebase at /home/rosswolf/Code/castlebuilder.

Key areas to understand:
- Main game project: castlebuilder-app/app/ (Godot 4.4)
- Architecture: Entity-Component pattern, Builder pattern, signal-based communication
- Current state: Prototyping card-based tower defense game
- Documentation: docs/ folder
- GitHub integration: .github/workflows/ and scripts/

Please analyze and acknowledge understanding of the codebase structure.
```

4. After Claude responds, get the session ID:
```
/session
```

5. **SAVE THE SESSION ID** - You'll need this for the workflow

6. Exit Claude:
```
exit
```

## Update the Workflow with the Session ID

Once you have the session ID, update the workflow to use it:

1. Edit `.github/workflows/claude-enhanced-v2.yml`
2. Add the session ID as an environment variable or secret
3. The workflow can then use `claude --resume <session-id>` to continue from this parent

## Testing the Session

Test that the session can be resumed:
```bash
echo "What repository are you working with?" | claude --resume YOUR_SESSION_ID --print
```

This should respond with information about castlebuilder, confirming the session works.