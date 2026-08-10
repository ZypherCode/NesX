.include "constants.inc"

.segment "CODE"

.import stdout_buffer
.import write_ptr
.import read_ptr

.import cursor_raw_l
.import cursor_raw_h
.import nmi_counter

.export new_line
.proc new_line
  LDA #$20  ; This symbol clears the cursor. Do not use #$0a here!
  JSR draw_char

  LDA cursor_raw_l
  AND #%11110000
  STA cursor_raw_l

  AND #%00010000
  BEQ if_even

  if_odd:
    CLC
    LDA cursor_raw_l
    ADC #$10
    STA cursor_raw_l
    BNE return
    INC cursor_raw_h
    JMP return

  if_even:
    CLC
    LDA cursor_raw_l
    ADC #$20
    STA cursor_raw_l
    BNE return
    INC cursor_raw_h

return:
  LDX PPUSTATUS
  LDX cursor_raw_h
  STX PPUADDR
  LDX cursor_raw_l
  STX PPUADDR
  RTS
.endproc

.export draw_char
.proc draw_char ; A = tile 
  CMP #$0a
  BNE draw
  JSR new_line
  RTS

draw:
  STA PPUDATA 
  INC cursor_raw_l
  BNE return
  INC cursor_raw_h

return:
  RTS 
.endproc

.export nmi_handler
.proc nmi_handler
  pha     ; Сохранить A
  txa     ; Передать X в A
  pha     ; Сохранить X
  tya     ; Передать Y в A
  pha     ; Сохранить Y
  php     ; Сохранить флаги (процессорный статус)

  INC nmi_counter

  LDX PPUSTATUS
  LDX cursor_raw_h
  STX PPUADDR
  LDX cursor_raw_l
  STX PPUADDR

  LDY #$0
print_stdout:
  LDX read_ptr
  CPX write_ptr
  BEQ exit

  CPY #31
  BEQ exit

  LDX read_ptr
  LDA stdout_buffer,X
  JSR draw_char
  INC read_ptr

  INY
  JMP print_stdout

exit:
  LDA nmi_counter
  AND #%00010000
  BNE hide_cursor
  LDA #$db
  STA PPUDATA
  JMP oamdma
  hide_cursor:
  LDA #$20
  STA PPUDATA
  oamdma:

  ; LDA PPUSTATUS
  ; LDA #$00
  ; STA OAMADDR
  ; LDA #$20
  ; STA OAMDMA

  LDA #$00  ; Отключить скроллинг
  STA $2005
  STA $2005

  plp     ; Восстановить флаги
  pla     ; Восстановить Y
  tay     ; Передать из A в Y
  pla     ; Восстановить X
  tax     ; Передать из A в X
  pla     ; Восстановить A

  RTI
.endproc