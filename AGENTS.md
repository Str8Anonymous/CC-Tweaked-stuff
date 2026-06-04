# Project Context

This repository is for CC: Tweaked, the Minecraft mod that adds programmable Lua computers and turtles. It is not a Java Minecraft mod project. The code here is Lua meant to run inside an in-game CC: Tweaked turtle.

Use `Docs/` as the local CC: Tweaked reference material before guessing API behavior. The docs are vendored Markdown from CC: Tweaked and cover the mod overview, startup behavior, events, and reference data formats. Useful entry points:

- `Docs/index.md`: explains CC: Tweaked, computers, turtles, peripherals, and the mod ecosystem.
- `Docs/guides/startup.md` and `Docs/reference/startup.md`: explain how `startup.lua` and `startup/` files run when a computer or turtle boots.
- `Docs/guides/using_require.md`: explains CC: Tweaked/Lua module loading. In this project, modules are loaded with `require("ModuleName")`.
- `Docs/events/`: event reference for `os.pullEvent`, keyboard events, HTTP events, turtle inventory events, etc.
- `Docs/reference/block_details.md` and `Docs/reference/item_details.md`: data returned by block/item inspection APIs.

## Runtime Model

The in-game turtle boots from root-level `startup.lua`.

1. `startup.lua` prints a boot message.
2. If `Update.lua` exists, it runs `shell.run("Update")`.
3. `Update.lua` fetches the GitHub contents list for `Str8Anonymous/CC-Tweaked-stuff`, branch `main`, folder `MiningScripts`.
4. For every `.lua` file in that folder, `Update.lua` downloads the raw file into the turtle root using only the file name as the output path.
5. After updating, `startup.lua` runs root-level `Main.lua` if present.

Repo layout differs from turtle layout. In the repo, app modules are under `MiningScripts/`. On the turtle, `Update.lua` writes those files beside `startup.lua` at the filesystem root, so `require("TurtleStart")`, `require("State")`, and similar calls resolve correctly in-game.

## Current Lua Modules

- `startup.lua`: boot entry point for the turtle. Runs updater, then `Main`.
- `Update.lua`: GitHub self-updater. Uses `http.get`, `textutils.unserializeJSON`, `fs.open`, and cache-busting query params.
- `MiningScripts/Main.lua`: app entry point. Creates `TurtleStart` and calls `app:start()`.
- `MiningScripts/TurtleStart.lua`: orchestration module. Creates shared `State`, `Movement`, `EnterStart`, and `Mine` objects. Current `DEBUG_MODE` flow alternates between leaving base and returning home.
- `MiningScripts/MiningConfig.lua`: shared base/mine constants. Base is the turtle block at `1084,63,-340`; cave entrance is `1084,63,-342`; bottom-of-stairs mine start is `1131,16,-342`; target mining level is `Y=16`; mining faces `1` / positive X.
- `MiningScripts/State.lua`: persistent JSON state stored in `state.json`. Defaults are `stage = "at_base"`, `x = 1084`, `y = 63`, `z = -340`, `facing = 0`.
- `MiningScripts/Movement.lua`: movement/refuel/dig/navigation helpers. Tracks coordinates manually after successful movement and saves state after each movement or turn.
- `MiningScripts/Inventory.lua`: inventory helper. `unloadBehind()` turns around, drops all non-empty slots into the chest behind the turtle, and turns back to preserve facing.
- `MiningScripts/EnterStart.lua`: early route module that moves forward twice and turns right.
- `MiningScripts/Mine.lua`: wide straight-tunnel mining behavior at `Y=16`. Tracks `mineDistance`, digs up and both side walls while advancing, avoids digging the floor, and requests return when inventory is full or fuel is low.
- `MiningScripts/Reset.lua`: destructive in-game reset helper. Keeps `startup.lua`, `Update.lua`, and `Reset.lua`, deletes other writable root files, then offers reboot.

## State And Coordinates

`State.lua` treats the base/home position as the turtle block coordinate `x = 1084`, `y = 63`, `z = -340`, facing `0`. The player standing on top sees `y = 64`, but the turtle itself is one block lower. The turtle routes to the cave entrance `x = 1084`, `y = 63`, `z = -342`, then makes a staircase down to the bottom-of-stairs mine start `x = 1131`, `y = 16`, `z = -342`.

`Movement.lua` uses this facing convention:

- `0`: negative Z
- `1`: positive X
- `2`: positive Z
- `3`: negative X

The active state flow in `TurtleStart.lua` is:

1. `at_base`
2. `travel_to_mine`
3. `digging_down`
4. `mining`
5. `returning_home`

`Movement:returnHome()` currently:

1. Goes to `y = 64`.
2. Travels to `x = 1085`.
3. Travels to `z = -339`.
4. Turns to facing `0`.
5. Sets `stage = "at_base"` while preserving `mineDistance`.

When editing movement behavior, keep `state.json` consistent with actual turtle movement. Update state only after a move or turn succeeds.

## Development Notes

- Keep Lua compatible with CC: Tweaked's Lua environment. Prefer APIs documented under `Docs/` and standard ComputerCraft globals such as `turtle`, `fs`, `shell`, `http`, `textutils`, `os`, `keys`, and `sleep`.
- Do not assume normal desktop Lua libraries are available in-game.
- Keep module files self-contained and return tables/classes from modules that are loaded with `require`.
- Avoid changing root/turtle file names casually. The updater downloads by file name, and `startup.lua` expects `Update.lua` and `Main.lua` at turtle root.
- Be careful with destructive helpers. `Reset.lua` deletes writable files in the turtle root after Enter confirmation.
- `Mine:run()` currently mines a wide straight tunnel in facing `1` / positive X from the `Y=16` mine start. Each step mines up plus left/right side blocks, then moves forward. It intentionally does not dig down during strip mining. It resumes by walking `mineDistance` blocks from the mine start before continuing.
- If adding new modules under `MiningScripts/`, they will be downloaded to turtle root by `Update.lua` as long as they end in `.lua`.
- If adding code that needs HTTP, remember the in-game CC: Tweaked config/server must allow HTTP requests.

## Validation

There is a small desktop Lua test harness with mocked CC: Tweaked globals. For quick checks:

- Run `lua52 tests/mining_bot_tests.lua` for the local mocked CC: Tweaked mining tests.
- Review syntax manually for CC: Tweaked Lua compatibility.
- Check module names match `require(...)` calls exactly.
- Confirm any new `MiningScripts/*.lua` file can run from turtle root after the updater downloads it.
- For startup/update behavior, compare against `Docs/guides/startup.md`, `Docs/reference/startup.md`, and `Docs/guides/using_require.md`.
