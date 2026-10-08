# Lua3D

A small three-dimensional engine written in LuaJIT using OpenGL.

## Features

- OpenGL window creation
- Three-dimensional transformations
- Camera movement and rotation
- Depth testing
- Colored meshes
- Texture mapping
- Directional lighting
- Custom matrix and vector classes
- Bundled Lua and native dependencies

## Requirements

- Windows
- A graphics driver supporting OpenGL three point three or newer
- No separate Lua, MoonGL, MoonGLFW, or MoonImage installation is required
- If running using a separate Lua installation, LuaJIT 5.1 is required.

The project includes its required Lua executable, dynamic libraries, and Lua support files inside the `vendor` folder.

## Running the Engine

Clone the repository:

```powershell
git clone https://github.com/Orangeyouglad30/lua3d.git
```

Run the .ps1 script

```powershell
.\run.ps1
```