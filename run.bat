@echo off

if not exist build\ (
  mkdir build
)
if not exist build\SDL2.dll (
  copy vendor\sdl\windows\SDL2.dll build\SDL2.dll
)

odin run aurora -out:build\aurora.exe -debug
