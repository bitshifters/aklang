# aklang: start here

The ArchieKlang Announcetro, a 28 KB Acorn Archimedes intro by Bitshifters, Alcatraz and Torment, released at NOVA 2024 in the Oldschool Demo Compo; the first Archie prod to use the AmigaKlang soft synth (via ArchieKlang). This repo is the clean release record: a single-commit snapshot cut down from archie-verse to only what the intro uses. It rebuilds both released downloads (ARM250+ and ARM2) byte for byte.

| | |
|---|---|
| GitHub | https://github.com/bitshifters/aklang (public) |
| Origin | Snapshot of the old bitshifters/aklang main at 82f1b9b (itself archie-verse plus 6 commits), made 2026-11-27. Full history is in https://github.com/kieranhj/archie-verse at tag `archive/aklang-main`. |
| Local path | D:\bitshifters\aklang |
| Branch | main (only branch) |
| Prod page | https://bitshifters.github.io/posts/prods/bs-archieklang.html (downloads `bs-archieklang,ddc` and `bs-aklang-arm2,ddc`) |

## What's in here

- `archie-verse.asm`: entry point (`_DEBUG` and `_SLOW_CPU` can be set from the command line); `src\app.asm`, `src\fx\` (bits, outline-scroller, scope), `src\data\` (sequence, scrolltext); `src\loader.asm`: Shrinkler loader.
- `lib\`: the 22 archie-verse library files the release and debug builds open, including `archieklang.asm`, `arc-shrinkler.asm`, `sine`, `math-var`, `line-segments`, `outline-font`. Dead `.if` branches (sync, IRQ handler, MOD from file, unused lib modules, the non-ArchieKlang music path) were removed.
- `src\gen\arcmusic.asm` (checked in): the AmigaKlang synth script, generated from `data\akp\Rhino2.mod.txt`; `data\akp\Rhino2.akp` is the AmigaKlang project it came from.
- `data\music\archieklang_smp_rhino9.mod` (split by `bin\SplitMod.exe`), `data\riscos\tinyQ149t2,ffa` (embedded TinyQTM), `data\gfx\aklang_icon16.png`.
- `bin\`: vasm, vlink, Shrinkler (+ its MinGW DLLs), SplitMod, snmake, dos2unix, Python 3 converters with bundled `png.py`, `make_spark.py`.

## Build and run

- `make` (or `make.bat`): release build: `!AKlang` = Shrinkler-packed `!Run,ff8` + `!Sprites`, and `build\bs-archieklang,ddc`. `make arm2`: the ARM2 version and `build\bs-aklang-arm2,ddc`. Verified 2026-11-27, from a fresh clone, as byte-identical to both live downloads; SHA-256s are in README.md.
- `make uncompressed`, `make debug` (`_DEBUG=1`), `make deploy` (to `..\arculator\hostfs\Builds`; override with `make.bat deploy HOSTFS=...`), `make music` (regenerate `arcmusic.asm`; needs `pip install parse`), `make clean`.
- Needs `python.exe` (Python 3). Use cmd / Windows Terminal, not Git Bash.
- Run `!AKlang` in Arculator (`D:\bitshifters\arculator`), A3010 preset.

## Local changes

- None.

## Status and next steps

- Done: released 2024-06-15 (ARM250+ and ARM2 the same day; downloads unchanged since). Both were built from source identical to old main 82f1b9b (ARM2 with `_SLOW_CPU` set to 1). A rebuild of the party commit 397020a was not verified: its build needs Python 2 and, with Python 3 substituted, it did not produce the released binary (not investigated further, since main reproduces it).
- Snapshot published 2026-11-27 as the release record.

## See also

- README.md; `D:\archie\mine\archie-verse` (framework, full history); `D:\archie\mine\archieklang` (the ArchieKlang port, kieranhj/archieklang); `D:\bitshifters\push`, `D:\bitshifters\chipo-django3`.
