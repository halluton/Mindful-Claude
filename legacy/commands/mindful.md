Configure the Mindful Breathing extension.

Read the config file at `~/.claude/mindful/config` to check current settings. If it doesn't exist, the defaults are: enabled=true, exercise=0, delay=5.

Show the user the current status:
- **Enabled**: true/false
- **Exercise**: 0=Coherent Breathing (5.5s in, 5.5s out), 1=Physiological Sigh (double inhale + long exhale), 2=Box Breathing (4-4-4-4), 3=4-7-8 Breathing (4s in, 7s hold, 8s out)
- **Delay**: seconds before the breathing pane appears

Then ask what they'd like to change (toggle on/off, switch exercise, change delay). Update `~/.claude/mindful/config` with the new values using sed. Create the file and directory if they don't exist. The config format is simple key=value lines:

```
enabled=true
exercise=0
delay=5
```
