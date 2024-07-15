# nITG-synn-template

This template is a complete rewrite of the [Mirin Template](https://github.com/XeroOl/notitg-mirin/), in [Luau](https://luau-lang.org/).

The goal of this template is to have auto-completion & strict typing and to avoid global variables as much as possible when writing scripts.

## DISCLAIMER

Note: this template is not intended to be used by beginners or people who are not familiar with the Luau language, please use the [Mirin Template](https://github.com/XeroOl/notitg-mirin/) instead !

## Credits

@XeroOl and all [Mirin Template](https://github.com/XeroOl/notitg-mirin/) contributors. This template is based on it.

@ArcticFqx for [script that allows you to create actors by script](https://github.com/ArcticFqx/nitg-theme/blob/master/Lua/geno.lua). This template uses a heavily modified version of it for the [Make Actors in Lua feature](https://github.com/synnwave/nITG-synn-template/pull/1).

## Extra Features

- Most Luau functions backported to Lua 5.0 (string, table & math libraries, string interpolation, type-checking, compound operators)
(NOTE: continue statements not supported, see [Darklua issue #202](https://github.com/seaofvoices/darklua/issues/202))

- Fixes Lua 5.0 for loop bugs

- XML Actors auto-completion

- Auto-completion & type-checking for all of [nITG's Lua API](https://craftedcart.gitlab.io/notitg_docs/lua_api/index.html)

- Create actors in Lua scripts (see [PR #1](https://github.com/synnwave/nITG-synn-template/pull/1))

## Instructions

1. Install [Aftman](https://github.com/lpghatguy/aftman) and run `aftman install`.

2. Run the following every time before you playtest your mod file:

```bash
lune run scripts/build
```

Or alternatively, you can watch the project so that it builds it each time you save a file:

```bash
lune run scripts/watch
```

## Documentation

There currently isn't any documentation on this template, but you can look at the [Mirin Template Documentaiton](https://xerool.github.io/notitg-mirin) since it's mostly similar.

## NOTES

Please configure Luau LSP to use the following configuration:

```json
"luau-lsp.require.mode": "relativeToFile",
"luau-lsp.platform.type": "standard",
"luau-lsp.sourcemap.enabled": false
```
