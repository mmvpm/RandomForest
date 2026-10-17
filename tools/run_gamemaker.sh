#!/bin/zsh
# Run the installed GameMaker compiler or runner with scoped project-local output.
set -eu
runtime_root='/Users/Shared/GameMakerStudio2-LTS2026/Cache/runtimes/runtime-2026.0.0.23'
case "${1:-}" in
  compile)
    build_options="${2:?Pass a compile.bff path}"
    exec /usr/bin/env DOTNET_ReadyToRun=0 "$runtime_root/bin/igor/osx/arm64/Igor" --options="$build_options" -j=1 -- Mac Compile
    ;;
  run)
    game_package="${2:?Pass a game.zip path}"
    runtime_log="${3:?Pass a runtime log path}"
    exec "$runtime_root/mac/YoYo Runner.app/Contents/MacOS/Mac_Runner" -game "$game_package" -output "$runtime_log"
    ;;
  *) print -u2 'Usage: run_gamemaker.sh compile compile.bff | run game.zip runtime.log'; exit 2 ;;
esac
