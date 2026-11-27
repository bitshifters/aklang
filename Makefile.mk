##########################################################################
# ARCHIEKLANG ANNOUNCETRO MAKEFILE
# Run with bin\snmake.exe via make.bat (Windows, cmd.exe).
##########################################################################

RM_RF:=-cmd /c rd /s /q
MKDIR_P:=-cmd /c mkdir
COPY:=copy
VASM?=bin\vasmarm_std_win32.exe
VLINK?=bin\vlink.exe
SHRINKLER?=bin\Shrinkler.exe
SPLITMOD?=bin\SplitMod.exe
PYTHON3?=python.exe
DOS2UNIX?=bin\dos2unix.exe

AKP2ARC=./bin/akp2arc.py
PNG2ARC_SPRITE=./bin/png2arc_sprite.py
PNG2ARC_DEPS:=./bin/png2arc.py ./bin/arc.py ./bin/png.py ./bin/png2arc_font.py ./bin/png2arc_sprite.py
MAKE_SPARK=./bin/make_spark.py

FOLDER=!AKlang
HOSTFS?=..\arculator\hostfs\Builds

##########################################################################
# RELEASE BUILDS
# !AKlang as a single Shrinkler-packed !Run (the 28 KB release form),
# plus a Spark archive of it. `release` targets ARM250+, `arm2` the ARM2.
##########################################################################

.PHONY:release
release: shrink
	$(PYTHON3) $(MAKE_SPARK) $(FOLDER) -o build/bs-archieklang,ddc

.PHONY:arm2
arm2: VASM_FLAGS=-D_SLOW_CPU=1
arm2: shrink
	$(PYTHON3) $(MAKE_SPARK) $(FOLDER) -o build/bs-aklang-arm2,ddc

.PHONY:shrink
shrink: build ./build/loader.bin ./build/icon.bin
	$(RM_RF) $(FOLDER)
	$(MKDIR_P) $(FOLDER)
	$(COPY) .\build\icon.bin "$(FOLDER)\!Sprites,ff9"
	$(COPY) .\build\loader.bin "$(FOLDER)\!Run,ff8"

##########################################################################
# DEVELOPMENT BUILDS
# Uncompressed !RunImage started by an obey file, optionally _DEBUG=1.
##########################################################################

.PHONY:uncompressed
uncompressed: build ./build/archie-verse.bin ./build/!run.txt ./build/icon.bin
	$(RM_RF) $(FOLDER)
	$(MKDIR_P) $(FOLDER)
	$(COPY) .\build\!run.txt "$(FOLDER)\!Run,feb"
	$(COPY) .\build\icon.bin "$(FOLDER)\!Sprites,ff9"
	$(COPY) .\build\archie-verse.bin "$(FOLDER)\!RunImage,ff8"

.PHONY:debug
debug: VASM_FLAGS=-D_DEBUG=1
debug: uncompressed

# Copy the built folder to an Arculator hostfs (override HOSTFS=... as needed).
.PHONY:deploy
deploy:
	$(RM_RF) "$(HOSTFS)\$(FOLDER)"
	$(MKDIR_P) "$(HOSTFS)\$(FOLDER)"
	$(COPY) "$(FOLDER)\*.*" "$(HOSTFS)\$(FOLDER)\*.*"

build:
	$(MKDIR_P) "./build"

.PHONY:clean
clean:
	$(RM_RF) "build"
	$(RM_RF) "$(FOLDER)"

##########################################################################
# CODE
##########################################################################

./build/loader.bin: build ./src/loader.asm ./build/archie-verse.shri
	$(VASM) -L build\loader.txt -m250 -Fbin -opt-adr -D_USE_SHRINKLER=1 -o $@ ./src/loader.asm

./build/archie-verse.shri: ./build/archie-verse.bin
	$(SHRINKLER) -b -d -p -z -3 ./build/archie-verse.bin $@

./build/archie-verse.bin: build ./build/archie-verse.o link_script.txt
	$(VLINK) -T link_script.txt -b rawbin1 -o $@ build/archie-verse.o -Mbuild/linker.txt

.PHONY:./build/archie-verse.o	# always build as source dependencies aren't tracked.
./build/archie-verse.o: build archie-verse.asm ./build/music.mod.trk
	$(VASM) -L build/compile.txt -m250 -Fvobj -opt-adr $(VASM_FLAGS) -o build/archie-verse.o archie-verse.asm

##########################################################################
# MUSIC
# The MOD's pattern data is embedded; its samples are generated at run
# time by ArchieKlang from src/gen/arcmusic.asm (the AmigaKlang synth
# script, generated from data/akp/Rhino2.mod.txt) plus data/akp/Rhino2.mod.raw.
##########################################################################

./build/music.mod.trk: ./data/music/archieklang_smp_rhino9.mod | build
	$(COPY) .\data\music\archieklang_smp_rhino9.mod .\build\music.mod
	$(SPLITMOD) build\music.mod

# Regenerate src/gen/arcmusic.asm (checked in). Needs `pip install parse`.
.PHONY:music
music:
	$(PYTHON3) $(AKP2ARC) ./data/akp/Rhino2.mod.txt -o ./src/gen/arcmusic.asm

##########################################################################
# RISC OS APP FILES
##########################################################################

./build/icon.bin: ./data/gfx/aklang_icon16.png $(PNG2ARC_DEPS)
	$(PYTHON3) $(PNG2ARC_SPRITE) --name !aklang -o $@ $< 9

./build/!run.txt: ./data/text/!run.txt
	$(DOS2UNIX) -n $< $@
