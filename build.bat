@echo off

if not exist build\ (
  mkdir build
)

odin build aurora -out:build\aurora.exe
