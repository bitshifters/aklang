# ArchieKlang Announcetro
A cheeky 28kb intro for the Acorn Archimedes released at NOVA 2024 in the Oldschool Demo Compo. This is the first production on the Archimedes to use Virgill’s AmigaKlang soft synth - it generates 280+kb of sample data from just a few kb of code!

Some interesting things that this intro demonstrates for Archimedes demos:

- Using ArchieKlang to generate sample data at init time.
- Embedding the QTM RM into the executable.
- Use of TinyQTM (stripped down to 14Kb from 26Kb, although previously 69Kb!)
- Use of RISCOS font libary to render font glyphs that can be copied as sprites.
- Use of vlink to strip bss segments from object files.
- Use of Shrinkler to compress 87Kb executable down to 28Kb.
