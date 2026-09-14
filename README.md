# Mindful Claude

Breathe while Claude works.

Every prompt you send gives you 10 to 60+ seconds of dead time. Most of us reach for the phone. This Claude Mod turns that time into a guided breathing exercise: the moment Claude starts working, a breathing animation appears above the prompt and the spinner counts the breath with you. The moment Claude answers, it is gone.

![Mindful Claude demo](demo.gif)

```
⏺ Running 2 shell commands…
✻ Breathe in 4s… (16s · ↓ 843 tokens · thinking)

                    ░▒▓████▓▒░
          ░▒▓████████████████████▓▒░
    ░▒▓████████████████████████████████▓▒░
          ░▒▓████████████████████▓▒░
                    ░▒▓████▓▒░
                 Breathe in... 4s
                Coherent Breathing
──────────────────────────────────────────
❯
```

## Why

Slow, structured breathing at about 5.5 breaths per minute raises heart rate variability (HRV), a marker of stress resilience. Even short sessions lower cortisol and sharpen focus. Every Claude turn becomes a micro-session for your nervous system, and you never leave the terminal.

## What you get

- **Auto-launch, auto-dismiss.** The band appears when a turn starts and disappears when it ends. Nothing to open, nothing to close.
- **The spinner breathes too.** `Lollygagging…` becomes `Breathe in 4s…`, so the countdown is in your eye line even when you are reading tool output.
- **4 exercises**: Coherent Breathing, Physiological Sigh, Box Breathing, 4-7-8.
- **4 animation styles**, picked at random per turn: Pulse, Ripples, Dots, Wave.
- **Zero tokens.** The mod draws everything itself. The model never sees it.
- **No tmux, no jq, no settings surgery.** Two commands to install.

## Requirements

- Claude Code 2.1.269 or later, with `CLAUDE_CODE_ENABLE_FUNCTION_HOOKS=1` set. Claude Mods are in early access, so the flag is needed until they ship by default.
- An interactive terminal session. Nothing draws in `claude -p`, the desktop app or mobile yet.
- A font with block and box-drawing characters. Any modern terminal is fine.

## Quick start

1. Turn function hooks on. Add this to `~/.claude/settings.json` (create the file, or merge the `env` key into what is there):

   ```json
   {
     "env": {
       "CLAUDE_CODE_ENABLE_FUNCTION_HOOKS": "1"
     }
   }
   ```

   For a single session instead, prefix the command: `CLAUDE_CODE_ENABLE_FUNCTION_HOOKS=1 claude`.

2. Install from GitHub. The repo is its own marketplace:

   ```sh
   claude plugin marketplace add halluton/Mindful-Claude
   claude plugin install mindful-claude@mindful-claude
   ```

3. Start `claude` and send a prompt. Breathe.

To try it without installing, or to hack on it:

```sh
git clone https://github.com/halluton/Mindful-Claude
cd Mindful-Claude
claude --plugin-dir .
```

The repo's own `.claude/settings.json` sets the flag for sessions started inside the folder.

To remove it:

```sh
claude plugin uninstall mindful-claude
claude plugin marketplace remove mindful-claude
```

## `/breathe`

Settings live in one slash command and persist across sessions.

| Command | What it does |
|---|---|
| `/breathe` | Show the current settings |
| `/breathe off` / `/breathe on` | Hide or show the band |
| `/breathe hrv` | Coherent Breathing: 5.5s in, 5.5s out |
| `/breathe sigh` | Physiological Sigh: double inhale, long exhale |
| `/breathe box` | Box Breathing: 4s in, 4s hold, 4s out, 4s hold |
| `/breathe 478` | 4-7-8 Breathing: 4s in, 7s hold, 8s out |
| `/breathe style wave` | Pin a style: `pulse`, `ripples`, `dots`, `wave`, or `random` |
| `/breathe delay 5` | Wait this many seconds into a turn before showing the band (default 0) |
| `/breathe spinner off` | Leave the spinner alone |

Every form runs straight away, even while Claude is working.

### Exercises

| Exercise | Pattern | Best for |
|---|---|---|
| **Coherent Breathing** | 5.5s in / 5.5s out | Sustained HRV improvement |
| **Physiological Sigh** | Double inhale / long exhale | Quick calm-down |
| **Box Breathing** | 4s in / 4s hold / 4s out / 4s hold | Focus and concentration |
| **4-7-8 Breathing** | 4s in / 7s hold / 8s out | Deep relaxation |

## How it works

This is a [Claude Mod](https://github.com/anthropics/claude-code/issues/91870): a plugin whose behaviour is a TypeScript hooks module running inside Claude Code, not shell commands.

- `hooks/register.tsx` is the hooks module. It hooks `ui.render` for the `AbovePrompt` band and mounts the animation while the band's `isWorking` prop is true, so the engine itself decides when the band appears and disappears. It hooks `ui.render` for the `Spinner` to rewrite its word with the current phase, registers `/breathe`, and keeps settings in `$.store`.
- `hooks/breathe.tsx` is the surface module: the animation. It runs on the drawing thread with its own frame clock, ten frames a second, and posts the phase back to the hooks module once a second so the spinner stays in step.
- `hooks/breath/*.ts` hold the exercises, the easing, the four shapes and the command parser as pure functions. `bun test` covers them.

## Develop

```sh
bun test                                            # exercises, shapes, the /breathe parser
claude plugin validate .claude-plugin/plugin.json   # lists the hooked events, $ calls and surface modules
claude plugin validate .                            # checks the marketplace manifest
```

Type checking needs the early-access declarations: open a session in this folder with function hooks on, run `/plugin-types` (it writes the git-ignored `.claude/types/`), then:

```sh
bunx -p typescript tsc -p .
```

Edits hot-reload into a running `claude --plugin-dir .` session. Run with `--debug-file /tmp/mindful.log` to see what the engine refused, if anything.

Two rules for surface modules, learned the hard way by [cc-arcade](https://github.com/sezaakgun/cc-arcade): never name a local variable `h` (every JSX tag compiles to a call of `h`), and write `Client` module paths as string literals.

## The tmux version

The original, pure-bash version that ran in a tmux pane lives in [`legacy/`](legacy/). It still works if you cannot use function hooks yet.

## License

MIT. See [LICENSE](LICENSE).
