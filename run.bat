@echo off

if not exist build\ (
  mkdir build
)

odin run aurora -out:build\aurora.exe -debug
