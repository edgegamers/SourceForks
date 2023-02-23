# SourceForks

Maintained forks of various sourcemod plugins and gamedatas

## Plugins

**Current SourceMod Version:** 1.11

All plugins use a common patching library, `include/asm_patch.sp`.
This library helps with un-patching code when the plugin is unloaded
and comes with utility commands that allow you to see active patches and their original contents.

### Antilag
*Originally by Backwards*

Antilag merges several individual exploit plugins by Backwards and refactors them for enhanced functionality and maintainability.
- More reliance on gamedata instead of hardcoded addresses
- Bans players attempting to use certain exploits

You can use the cvar `sourceforks_antilag_punishment` to configure the punishment for cheaters attempting to lag the server.
- **0**: Benign (same functionality as original plugin)
- **1**: Notify admins, otherwise benign
- **2**: Kick the cheater if they continue
- **3**: Permanently ban the cheater if they continue.

> **Note**: It is impossible for any legitimate player on a vanilla client to reach the "attempted DDOS" alert.
> If you see this, or they were banned for DDoSing, they are cheating. Period.
> It is possible, however, for the "suspicious network activity" alert to trigger on really, really bad connections on 93 tick or above servers.

- **Command** `noop_antilag` presents users with RCON flags the status of all active patches.


### MovementUnlocker
*Originally by Peace-Maker*

Almost identical to the original, but refactored to use gamedata.

- **Command** `noop_movementunlocker` presents users with RCON flags the status of all active patches.

### Generic Map Crash Fixes
*An Original Plugin*

Prevents several map issues from crashing or lagging the server. This includes:
- Calling `Deactivate` on a `game_ui` that has no active player
- Maps with no navmesh causing re-generation on the fly (Usually doesn't crash, but lots of lag.)

### GOTV Hibernation
*An Original Plugin*

Prevents GOTV bots from leaving the server when server hibernation (`sv_hibernate`) is enabled.
> **Note**: Also appears to prevent *any* bot from leaving the server during hibernation. This does not appear to have an impact on the hibernation's efficiency, so it should be fine.

- **Command** `noop_tvhibernation` presents users with RCON flags the status of all active patches.

## Licensing

**ALL FORKS ARE RELEASED UNDER THE LICENSE THE ORIGINALS WERE RELEASED UNDER.**

If you created one of the plugins included in this fork and do not want your plugin in this fork, please let me know and I will take it down.

All *additions* to the original plugins are licensed under the unilicense (see LICENSE.md) where it is possible to do so.

## Testing

A docker container is used to store CS:GO and GDC. Use `docker build . -t sourceforks-gdc` to build it,
Or use the scripts provided in `test/` to handle running the container for you.

The GDC script has the optional argument `USE_BUILDX` which can be set to `$True` if you wish to use a buildkit container instead of `docker build`. (`ps > test.ps1 -USE_BUILDX:$True`). Additionally, the switch `SUPPRESS_BUILD` can be used to add the `--quiet` parameter to docker build commands.

Another docker container is provided for the plugins themselves--See `src/Dockerfile` and `src/build.ps1` for more info.

## Partial Gamedata

In some cases, the amount of undocumented offsets makes it debilitating to properly maintain some gamedata files.
In this case, only the signatures are maintained and put in a partial file under `gamedata/partial/`. 