$project_root = Split-Path -Parent $MyInvocation.MyCommand.Path

Set-Location $project_root

& "$project_root\vendor\bin\luajit.exe" "$project_root\main.lua"