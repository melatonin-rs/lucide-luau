# lucide-luau
A Luau port of Lucide icons, made for Roblox script executors

## Install

```lua
local Lucide = loadstring(game:HttpGet("https://cdn.jsdelivr.net/gh/melatonin-rs/lucide-luau@main/src/init.luau"))()
```

## Quick start

```lua
local icon = Instance.new("ImageLabel")
icon.Size = UDim2.fromOffset(24, 24)
icon.BackgroundTransparency = 1
icon.Parent = script.Parent

icon.Image = Lucide.get("settings")
```

Icons are white with alpha, so `ImageColor3` tints them:

```lua
icon.Image = Lucide.get("heart")
icon.ImageColor3 = Color3.fromRGB(255, 90, 90)
```

## API

### Lucide.get(name, size?)

Returns a content id for the `Image` property.

- `name` — icon name from lucide.dev/icons, e.g. `"arrow-right"`
- `size` — `96` or `256`, default `96`

### Lucide.apply(label, name, size?)

Same as `get`, but assigns `Image` and `ScaleType` for you.

```lua
Lucide.apply(icon, "shield-check")
```

### Lucide.preload(names, size?)

Downloads a batch of icons in parallel and warms the local cache. Useful before opening a UI.

```lua
Lucide.preload({ "x", "settings", "search", "user", "bell" })
```

### Lucide.clearCache()

Wipes the local cache folder (`lucide-cache` in your executor workspace).

## Icon names

Browse [lucide.dev/icons](https://lucide.dev/icons) — the name under each icon is exactly what you pass to `get()`.

## Executor requirements

Works with any executor that supports:

- `request` (falls back to `game:HttpGet`)
- `writefile` / `isfile` / `isfolder` / `makefolder`
- `getcustomasset`

## How it works

- `crates/builder` renders every SVG from `lucide-static` to white PNG with Rust + resvg
- GitHub Actions rebuilds the icon set daily and commits it to `icons/`
- the module downloads PNG from jsDelivr, caches it on disk, dedupes parallel requests
- if an icon is missing locally, falls back to wsrv.nl

## License

MIT. Lucide icon set is ISC.
