# nITG-synn-template

This template is a complete rewrite of the [Mirin Template](https://github.com/XeroOl/notitg-mirin/), in Luau.

The goal of this template is to have auto-completion & strict typing, and to avoid global variables as much as possible when writing scripts.

Note: this template is not intended to be used by beginners, if you're a beginner please use the [Mirin Template](https://github.com/XeroOl/notitg-mirin/) instead !

## Credits

XeroOl and all [Mirin Template](https://github.com/XeroOl/notitg-mirin/) contributors. This template is based off of it.

## Extra Features

- Most Luau functions backported to Lua 5.0 (string, table & math libraries, string interpolation, type-checking, compound operators)
(NOTE: continue statements not supported, see [Darklua issue #202](https://github.com/seaofvoices/darklua/issues/202))

- Fixes Lua 5.0 for loop bugs

- XML Actors auto-completion

- Auto-completion & type-checking for all of [nITG's Lua API](https://craftedcart.gitlab.io/notitg_docs/lua_api/index.html)

## Instructions

1. Install [Aftman](https://github.com/lpghatguy/aftman) and run `aftman install`.

2. Run the following every time before you playtest your modfile:

```bash
lune run scripts/build
```

## Documentation

There currently isn't any documentation on this template, but you can look at the [Mirin Template Documentaiton](https://xerool.github.io/notitg-mirin) since it's mostly similar.
