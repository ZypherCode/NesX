MAPPER          = 4    
MIRRORING       = 0 
HAS_SRAM        = 1 

.segment "HEADER"
.byte $4e, $45, $53, $1a ; Magic string that always begins an iNES header
.byte $02        ; Number of 16KB PRG-ROM banks
.byte $01        ; Number of 8KB CHR-ROM banks
.byte MIRRORING | (HAS_SRAM << 1) | ((MAPPER & $0F) << 4) ; Horizontal mirroring, save RAM, mmc3 mapper
.byte (MAPPER & $F0) | %1000   ; No special-case flags set, mmc3 mapper
.byte $00        ; No PRG-RAM present
.byte $00        ; NTSC format
