INCLUDE="$(pwd)/include"
RES="nesx.nes"

ca65 -I $INCLUDE "bios/boot.asm" 
ca65 -I $INCLUDE "bios/screen.asm"
ca65 -I $INCLUDE "bios/keyboard.asm"
ca65 -I $INCLUDE "kernel/api.asm"
ld65 "bios/boot.o" "bios/screen.o" "bios/keyboard.o" "kernel/api.o" -C "nes.cfg" -o $RES
rm "bios/boot.o"
rm "bios/screen.o"
rm "bios/keyboard.o"
rm "kernel/api.o"