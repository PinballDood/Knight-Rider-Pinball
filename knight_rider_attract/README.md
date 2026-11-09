# Knight Rider attract prototype

## Start in Godot 4.7.2
1. Import the `godot` folder as a project, then run Main.tscn (F6) or the project (F5).
2. Put your own licensed/locally extracted intro video at `godot/assets/video/knight_rider_intro.ogv`.
3. SPACE restarts the 90-second loop; H toggles example high scores.
4. Godot's built-in VideoStreamPlayer supports Ogg Theora `.ogv`. The video is not included.
5. Example leaderboard and last-game scores are PLACEHOLDERS, not connected to MPF yet.

## MPF integration
- `mpf/attract_cues.yaml` illustrates the 6 cue events and an example light mapping. Do NOT replace your machine's existing configuration with it.
- Godot sends JSON UDP messages to localhost port 50505 only when `BRIDGE_ENABLED` is set to true in `scripts/attract.gd`.
- A receiver/bridge is required to translate these into MPF events. The exact bridge depends on your MPF/MC setup; none is included or assumed operational.
- Use your existing P3-ROC/PCA LED mapping, not arbitrary example names. `l_pop_bottom` is a placeholder and may not exist.
- True frame-accurate synchronization requires an MPF-controlled master clock or a feedback link; the included prototype uses screen cue boundaries only.
- Game-start interruption, live scores, and full playfield GI/insert shows require integration with your existing machine configuration.

## Cue times
00 intro / 06 intro video / 36 diagnostics / 46 title / 58 scores / 76 standby / 90 repeat.
