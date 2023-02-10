# SourceForks

Maintained forks of various sourcemod plugins and gamedatas

## Licensing

**ALL FORKS ARE RELEASED UNDER THE LICENSE THEY WERE ORIGINALLY RELEASED UNDER.**

If you created one of the plugins included in this fork and do not want your plugin in this fork, please let me know and I will take it down.

All *additions* to the original plugins are licensed under the unilicense (see LICENSE.md) where it is legal to do so.

## Testing

A docker container is used to store CS:GO and GDC. Use `docker build . -t sourceforks-gdc` to build it,
Or use the scripts provided in `test/` to handle running the container for you.

Another docker container is provided for the plugins themselves--See `src/Dockerfile` and `src/build.ps1` for more info.