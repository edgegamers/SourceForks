# SourceForks

Maintained forks of various sourcemod plugins and gamedatas

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