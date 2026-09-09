# Game systems

Run **project.godot in standard Godot 4.6.2 or newer**, then press F5. No .NET edition or C# SDK is required.

## Play

- WASD moves; the mouse controls facing.
- Hold left mouse to shoot; Space slashes.
- Escape opens/closes pause. Losing window focus also pauses the game.
- The pause menu provides Settings, Achievements, and Save & main menu.
- Continue restores your saved player position. New game resets the position but keeps earned achievements and lifetime counters.

The main scene is `Scenes/UI/game_shell.tscn`. Your gameplay remains in `Scenes/Free_world.tscn`; movement, attack geometry, and collision shapes have not been rewritten.

## GDScript structure

- `Scripts/UI/game_shell.gd`: main/pause/settings/achievements/quit screens, HUD, notifications, world loading, and periodic player saves.
- `Scripts/Systems/game_services.gd`: the `GameServices` autoload. Owns settings, save data, sound/music playback, seeded random-number generator instance, localized text, and progress events.
- `GameServices.game_event(kind)` allows other systems to listen for gameplay events. `record_event()` increments counters and unlocks the four current achievements once.
- `character.gd` reports successful shots and slashes. `solid_block.gd` reports hits.
- `Localization/ui.json`: English, Spanish, French, German, Italian, and Japanese menu strings. Add new keys for all six languages. For exported builds, include `Localization/*.json` in the non-resource export filter.
- `assets/fonts/NotoSansJP.ttf`: portable Japanese font fallback, with its SIL Open Font License.

## Saves and settings

`user://cube_save.json` contains versioned JSON with settings, player position/aim, achievements, and lifetime shot/slash/hit counts. On macOS this normally lives in `~/Library/Application Support/Godot/app_userdata/Isometric cube game/`.

Position autosaves every five seconds, on pause, when returning to the menu, and when closing the window. Settings/progress saves are coalesced to avoid writing for every frame or slider tick. Writes use a temporary file followed by a rename. Malformed data falls back to defaults with a notification.

Master, Music, and SFX volumes and fullscreen/language choices persist. Music/SFX are separate audio buses. The template's music is an AI-generated placeholder; see `assets/audio/README.md` and the accompanying MIT license.

This is a sandbox: blocks flash when hit but are not destructible. The save therefore stores the player's state rather than a changing terrain or enemy population.

## Verification

Run:

```sh
godot --headless --path . --script res://tests/systems_test.gd
```

The integration test uses `user://cube_systems_test.json`, not the normal save. It covers pause, menu input suppression, achievements, all six translations, audio settings, persistence, Continue, and corrupt-save recovery.
