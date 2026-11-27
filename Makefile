# Wrapper so that `make` works from PowerShell / Windows Terminal.
# GNU make runs recipes with cmd.exe here (no sh on PATH).
# The real build is Makefile.mk, run by bin\snmake.exe via make.bat.
.PHONY: all release arm2 uncompressed debug deploy clean music help
all: release

release arm2 uncompressed debug deploy clean music:
	cmd /c .\make.bat $@

help:
	@echo make              - release build (ARM250+): !AKlang and build\bs-archieklang,ddc
	@echo make arm2         - ARM2 release build: !AKlang and build\bs-aklang-arm2,ddc
	@echo make uncompressed - !AKlang with an uncompressed !RunImage
	@echo make debug        - uncompressed, assembled with _DEBUG=1
	@echo make deploy       - copy !AKlang to ..\arculator\hostfs\Builds (make.bat deploy HOSTFS=path to override)
	@echo make music        - regenerate src\gen\arcmusic.asm from data\akp\Rhino2.mod.txt (needs pip parse)
	@echo make clean        - remove build and !AKlang
