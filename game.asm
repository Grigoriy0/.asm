.model small
.stack 100h
.data
    ; 24x80
    M_SIZE   equ 0x0780
    matrix   dw M_SIZE dup(0x0720)
    path     dw 0x2000 dup(0)
    path_pos dw 0
    
    REQUARED_PERCENT equ 90

    DIR_UP      equ 10
    DIR_RIGHT   equ 11
    DIR_DOWN    equ 12
    DIR_LEFT    equ 13
    DIR_UR      equ 3 ; 11
    DIR_DR      equ 1 ; 01
    DIR_DL      equ 0 ; 00
    DIR_UL      equ 2 ; 10

    ; attributes
    CHAR_PLAYER equ 0x02DB
    CHAR_ENEMY  equ 0x05DB
    CHAR_PATH   equ 0x072A
    CHAR_SEA    equ 0x0720
    CHAR_LAND   equ 0x07DB
    CH_PL_LAND  equ 0x32DB

    enem_num dw 4
    enem_pos dw 0x0505, 0x0606,  0x0307,   0x1608
    enem_dir dw DIR_UR, DIR_DR,  DIR_DL,   DIR_UL
    
.code

enemy_mov proc
    pusha
    
    lea si, enem_pos
    lea di, enem_dir
    mov cx, enem_num
    
_ENEMY_MOV_CYCLE:
    mov ax, [di] 
    
    cmp ax, DIR_UR
    jne _ENEMY_DIR_D_R
    ; up-right
    mov bx, [si]
    celladdr
    ;clear old pos
    mov bx, cs:_celladdr
    add bx, offset matrix
    mov [bx], CHAR_SEA
    
    mov bx, [si] 
    dec bl      ;  /\
    inc bh      ;  ->
    
    celladdr
    mov bx, cs:_celladdr
    add bx, offset matrix
    mov ax, [bx]
    cmp ax, CHAR_LAND
    je _ENEM_U_R_COLLISION
    cmp ax, CH_PL_LAND
    je _ENEM_U_R_COLLISION
    cmp ax, CHAR_PATH
    je _ENEMY_END_GAME
    cmp ax, CHAR_PLAYER
    je _ENEMY_END_GAME
_ENEM_U_R_STEP:
    mov bx, [si]
    dec bl
    inc bh
    mov [si], bx
    celladdr
    mov bx, cs:_celladdr
    add bx, offset matrix
    
    mov [bx], CHAR_ENEMY
    jmp _ENEMY_CONTINUE
    
_ENEM_U_R_COLLISION:
    mov dx, [di]
_ENEM_U_R_COL_U:
    mov bx, [si]
    dec bl
    celladdr
    mov bx, cs:_celladdr
    add bx, offset matrix
    cmp [bx], CHAR_LAND
    jne _ENEM_U_R_COL_R
    and dl, 11111101b ;down
_ENEM_U_R_COL_R:
    mov bx, [si]
    inc bh
    celladdr
    mov bx, cs:_celladdr
    add bx, offset matrix
    cmp [bx], CHAR_LAND
    jne _ENEM_U_R_GO
    and dl, 11111110b ;left
_ENEM_U_R_GO:
    cmp dx, [di]
    jne _ENEM_U_R_END
    mov dl, DIR_DL
_ENEM_U_R_END:
    mov [di], dx
    mov bx, [si]
    celladdr
    mov bx, cs:_celladdr
    add bx, offset matrix
    mov [bx], CHAR_ENEMY
    


_ENEMY_DIR_D_R:
    cmp ax, DIR_DR
    jne _ENEMY_DIR_D_L
    mov bx, [si]
    celladdr
    ;clear old pos
    mov bx, cs:_celladdr
    add bx, offset matrix
    mov [bx], CHAR_SEA
    
    mov bx, [si]
    inc bh      ; ->
    inc bl      ; \/
    
    celladdr
    mov bx, cs:_celladdr
    add bx, offset matrix
    mov ax, [bx]

    cmp ax, CHAR_LAND
    je _ENEM_D_R_COLLISION
    cmp ax, CH_PL_LAND
    je _ENEM_D_R_COLLISION
    cmp ax, CHAR_PATH
    je _ENEMY_END_GAME
    cmp ax, CHAR_PLAYER
    je _ENEMY_END_GAME

_ENEM_D_R_STEP:
    mov bx, [si]
    inc bh
    inc bl
    mov [si], bx
    celladdr
    mov bx, cs:_celladdr
    add bx, offset matrix
    mov [bx], CHAR_ENEMY
    jmp _ENEMY_CONTINUE

_ENEM_D_R_COLLISION:
    mov dx, [di]
_ENEM_D_R_COL_D:
    mov bx, [si]
    inc bl ; ++y
    celladdr
    mov bx, cs:_celladdr
    add bx, offset matrix
    cmp [bx], CHAR_LAND
    jne _ENEM_D_R_COL_R
    or dl, 00000010b ;up
_ENEM_D_R_COL_R:
    mov bx, [si]
    inc bh ; ++x
    celladdr
    mov bx, cs:_celladdr
    add bx, offset matrix
    cmp [bx], CHAR_LAND
    jne _ENEM_D_R_GO
    and dl, 11111110b ;left
_ENEM_D_R_GO:
    cmp dx, [di]
    jne _ENEM_D_R_END
    mov dl, DIR_UL
_ENEM_D_R_END:
    mov [di], dx
    mov bx, [si]
    celladdr
    mov bx, cs:_celladdr
    add bx, offset matrix
    mov [bx], CHAR_ENEMY
    


_ENEMY_DIR_D_L:
    cmp ax, DIR_DL
    jne _ENEMY_DIR_U_L
    mov bx, [si]
    celladdr
    ;clear old pos
    mov bx, cs:_celladdr
    add bx, offset matrix
    mov [bx], CHAR_SEA
    
    mov bx, [si] 
    inc bl      ; \/
    dec bh      ; <-
    mov dx, bx
    
    celladdr
    mov bx, cs:_celladdr
    add bx, offset matrix
    mov ax, [bx]
    cmp ax, CHAR_LAND
    je _ENEM_D_L_COLLISION
    cmp ax, CH_PL_LAND
    je _ENEM_D_L_COLLISION
    cmp ax, CHAR_PATH
    je _ENEMY_END_GAME
    cmp ax, CHAR_PLAYER
    je _ENEMY_END_GAME
_ENEM_D_L_STEP:
    mov bx, [si]
    inc bl
    dec bh
    mov [si], bx
    celladdr
    mov bx, cs:_celladdr
    add bx, offset matrix
    
    mov [bx], CHAR_ENEMY
    jmp _ENEMY_CONTINUE
    
_ENEM_D_L_COLLISION:
    mov dx, [di]
_ENEM_D_L_COL_D:
    mov bx, [si]
    inc bl
    celladdr
    mov bx, cs:_celladdr
    add bx, offset matrix
    cmp [bx], CHAR_LAND
    jne _ENEM_D_L_COL_L
    or dl, 00000010b ; up
_ENEM_D_L_COL_L:
    mov bx, [si]
    dec bh
    celladdr
    mov bx, cs:_celladdr
    add bx, offset matrix
    cmp [bx], CHAR_LAND
    jne _ENEM_D_L_GO
    or dl, 00000001b ;right
_ENEM_D_L_GO:
    cmp dx, [di]
    jne _ENEM_D_L_END
    mov dl, DIR_UR
_ENEM_D_L_END:
    mov [di], dx
    mov bx, [si]
    celladdr
    mov bx, cs:_celladdr
    add bx, offset matrix
    mov [bx], CHAR_ENEMY



_ENEMY_DIR_U_L:
    cmp ax, DIR_UL
    jne _ENEMY_CONTINUE    
    
    mov bx, [si]
    celladdr
    ;clear old pos
    mov bx, cs:_celladdr
    add bx, offset matrix
    mov [bx], CHAR_SEA
    
    mov bx, [si] 
    dec bh      ; <-
    dec bl      ; /\
    
    celladdr
    mov bx, cs:_celladdr
    add bx, offset matrix
    mov ax, [bx]
    cmp ax, CHAR_LAND
    je _ENEM_U_L_COLLISION
    cmp ax, CH_PL_LAND
    je _ENEM_U_L_COLLISION
    cmp ax, CHAR_PATH
    je _ENEMY_END_GAME
    cmp ax, CHAR_PLAYER
    je _ENEMY_END_GAME
_ENEM_U_L_STEP:
    mov bx, [si]
    dec bh
    dec bl
    mov [si], bx
    celladdr
    mov bx, cs:_celladdr
    add bx, offset matrix
    
    mov [bx], CHAR_ENEMY
    jmp _ENEMY_CONTINUE
    
_ENEM_U_L_COLLISION:
    mov dx, [di]
_ENEM_U_L_COL_U:
    mov bx, [si]
    dec bl
    celladdr
    mov bx, cs:_celladdr
    add bx, offset matrix
    cmp [bx], CHAR_LAND
    jne _ENEM_U_L_COL_L
    and dl, 11111101b ; down
_ENEM_U_L_COL_L:
    mov bx, [si]
    dec bh
    celladdr
    mov bx, cs:_celladdr
    add bx, offset matrix
    cmp [bx], CHAR_LAND
    jne _ENEM_U_L_GO
    or dl, 00000001b ;right
_ENEM_U_L_GO:
    cmp dx, [di]
    jne _ENEM_U_L_END
    mov dl, DIR_DR
_ENEM_U_L_END:
    mov [di], dx
    mov bx, [si]
    celladdr
    mov bx, cs:_celladdr
    add bx, offset matrix
    mov [bx], CHAR_ENEMY
_ENEMY_CONTINUE:
    add si, 2
    add di, 2
    loop _ENEMY_MOV_CYCLE     
    
    popa
    ret
_ENEMY_END_GAME:
    mov ax, 0
    mov cs:_game_exit_flag, al 
    popa
    ret
endp

check_end_game proc
    push cx
    push ax
    push bx
    mov cx, enem_num
    lea bx, enem_pos
_CHECK_LOOP:
    mov ax, [bx]
    cmp ax, cs:_player_pos
    je _CHECK_END_GAME
    add bx, 2
    loop _CHECK_LOOP
    pop bx
    pop ax
    pop cx
    ret
_CHECK_END_GAME:
    mov ax, 0
    mov cs:_game_exit_flag, al
    pop bx
    pop ax
    pop cx
    ret
endp


;;;;;;;;;  
clearscr proc near
    push ax
    mov ax, 03
    int 10h
    pop ax
    ret
endp
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;put str function;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

put_x        db ?
put_y        db ?
put_attr     db ?
put_str_ptr  dw ?
put_str_seg  dw ?
put_str proc near
    pusha
    push es
    push ds
    
    mov ax, cs:put_str_seg
    mov ds, ax
    
    xor ax, ax
    mov al, cs:put_y
    mov bl, 160
    mul bl        ;160 * y == first byte of yth row
    
    mov bl, cs:put_x
    xor bh, bh
    add ax, bx
    add ax, bx  ;add to first byte of yth row xpos
                   ;now in ax position of first latter of str
    mov dx, 0xB800               
    mov es, dx
    mov bx, ax
    mov si, cs:put_str_ptr
    ; source ds:si, destiny es:bx
    mov ah, cs:put_attr
_PUT_STR_LOOP:
    mov al, ds:[si]
    cmp al, '$'
    je _PUT_STR_END
    mov es:[bx], ax
    add bx, 2 
    inc si
    jmp _PUT_STR_LOOP
    
    
_PUT_STR_END:
    pop ds
    pop es   
    popa   
    ret
endp 

printstr macro ptr, seg, attr, addr_x, addr_y
    
    pusha
    mov dx, offset ptr 
    mov cs:put_str_ptr, dx
    mov dx, seg
    mov cs:put_str_seg, dx
    mov dl, attr
    mov cs:put_attr, dl
    mov dh, addr_x
    mov dl, addr_y
    mov cs:put_x, dh
    mov cs:put_y, dl
    call put_str    
    popa
endm            


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;main menu;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
menu_set_1 macro
    mov cs:_selected, 1
    mov cs:_l1_attr, SLCT_ATTR
    mov cs:_l2_attr, NORM_ATTR
    mov cs:_l3_attr, NORM_ATTR
endm
menu_set_2 macro
    mov cs:_selected, 2
    mov cs:_l1_attr, NORM_ATTR
    mov cs:_l2_attr, SLCT_ATTR
    mov cs:_l3_attr, NORM_ATTR
endm
menu_set_3 macro
    mov cs:_selected, 3
    mov cs:_l1_attr, NORM_ATTR
    mov cs:_l2_attr, NORM_ATTR
    mov cs:_l3_attr, SLCT_ATTR
endm

select_down macro
    mov al, cs:_selected
    inc al
    cmp al, 4
    menu_set_1
    je _MENU_SELECT_DOWN_END
    cmp al, 3
    menu_set_3
    je _MENU_SELECT_DOWN_END
    cmp al, 2
    menu_set_2
_MENU_SELECT_DOWN_END:
endm

select_up macro
    mov al, cs:_selected
    dec al
    cmp al, 0
    menu_set_3
    je _MENU_SELECT_UP_END
    cmp al, 1
    menu_set_1
    je _MENU_SELECT_UP_END
    cmp al, 2
    menu_set_2
_MENU_SELECT_UP_END:
endm

UP_PRESSED      equ 0x4800
DOWN_PRESSED    equ 0x5000
LEFT_PRESSED    equ 0x4B00 
RIGHT_PRESSED   equ 0x4D00
menu proc near
    
    NORM_ATTR equ 7     
    SLCT_ATTR equ 224
    
    call clearscr   
    
    ;print title msg
    
    printstr _control, cs, NORM_ATTR, 0, 2
    printstr _title, cs, NORM_ATTR, 37, 0    
    
     
_MENU_PRINT:
    
    printstr _level1, cs, cs:_l1_attr, 20, 10
    printstr _level2, cs, cs:_l2_attr, 20, 12
    printstr _level3, cs, cs:_l3_attr, 20, 14 

    mov ah, 00
    int 16h 
    
    cmp ax, 0x1C0D ;enter
    je _MENU_GAME_START
    
    cmp ax, DOWN_PRESSED
    jne _MENU_UP_CMP
    select_down
    jmp _MENU_PRINT

_MENU_UP_CMP:
    cmp ax, UP_PRESSED
    jne _MENU_PRINT
    select_up
    jmp _MENU_PRINT
    
_MENU_GAME_START:
     
    mov ah, cs:_selected
    mov cs:game_level, ah
    call game
    
    ret
    _selected db 1
    
    _title    db 'ksonix$'
    _level1   db 'level 1$'
    _level2   db 'level 2$'
    _level3   db 'level 3$'
    _control  db 'q - quit, control - key ', 0x18, 0x19, 0x1A, 0x1B, '$' 
_LEVEL_ATTR:
    _l1_attr  db SLCT_ATTR
    _l2_attr  db NORM_ATTR
    _l3_attr  db NORM_ATTR
endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;game;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

game_old_handl dd ?
_game_exit_flag db 1
game_iteration db 0
game_level     db ? 
 
game_inter proc far
    pusha
    
    mov ah, cs:game_level
    mov al, cs:game_iteration
    inc al
    
    cmp al, ah
    jne _GAME_LOAD_BACK
    
    mov al, 0
    
    call enemy_mov
    
_GAME_LOAD_BACK:
    mov cs:game_iteration, al
    
    mov ah, 1 ; symbol ready?
    int 0x16

    jz _GAME_INT_END
_GAME_INT_CL_BUF:
    mov ah, 0
    int 0x16
    push ax
    mov ah, 1
    int 0x16
    jz _GAME_INT_END_CL_BUF
    pop ax
    jmp _GAME_INT_CL_BUF
     
_GAME_INT_END_CL_BUF:
    pop ax
    
    cmp al, 'q'
    jne _GAME_INT_DIR_R
    mov ax, 0
    mov cs:_game_exit_flag, al ; if 'q' than exit
    jmp _GAME_INT_STEP
    
_GAME_INT_DIR_R:
    cmp ax, RIGHT_PRESSED
    jne _GAME_INT_DIR_D
    
    mov al, DIR_RIGHT
    mov cs:_player_mov_dir, al
    jmp _GAME_INT_STEP

_GAME_INT_DIR_D:
    cmp ax, DOWN_PRESSED
    jne _GAME_INT_DIR_L
    
    mov al, DIR_DOWN
    mov cs:_player_mov_dir, al
    jmp _GAME_INT_STEP

_GAME_INT_DIR_L:
    cmp ax, LEFT_PRESSED
    jne _GAME_INT_DIR_U
    
    mov al, DIR_LEFT
    mov cs:_player_mov_dir, al
    jmp _GAME_INT_STEP
    
_GAME_INT_DIR_U:
    cmp ax, UP_PRESSED
    jne _GAME_INT_END
    
    mov al, DIR_UP
    mov cs:_player_mov_dir, al
    jmp _GAME_INT_STEP
_GAME_INT_STEP:
    call player_mov
    
_GAME_INT_END:
    call check_end_game
    popa
    call fieldload
    pushf
    call cs: dword ptr game_old_handl
    
    call fieldinfo
    
    iret
endp 

game proc near
    
    call fieldinit
    
    mov ah, 0x35
    mov al, 0x1C
    int 21h  
    
    mov cs: word ptr game_old_handl, bx
    mov cs: word ptr game_old_handl + 2, es
    
    push ds
    mov ax, cs
    mov ds, ax
    
    mov ah, 0x25
    mov al, 0x1C  
    lea dx, game_inter 
    int 21h
    
    pop ds
    
    
_GAME_LOOP:
    mov al, cs:_game_exit_flag
    cmp al, 1
    je _GAME_LOOP
    
    push ds

    mov dx, cs: word ptr game_old_handl + 2
    mov ds, dx
    mov dx, cs: word ptr game_old_handl

    mov ah, 0x25
    mov al, 0x1C
    int 0x21
    
    pop ds
    
    ret
endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;field info;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

fieldinfo proc near
   pusha
   
   mov cx, M_SIZE
   mov bx, offset matrix
   xor ax, ax
_FIELD_INFO_COUNT:
   mov dx, [bx]
   cmp dx, CHAR_SEA
   jne _FIELD_INFO_CMP_NEXT
   inc ax

_FIELD_INFO_CMP_NEXT:
   cmp dx, CHAR_PATH
   jne _FIELD_INFO_NO_INC
   inc ax
   
_FIELD_INFO_NO_INC:
   add bx, 2
   loop _FIELD_INFO_COUNT
   

   mov dx, ax
   
   mov ax, 1716 ;number of empty cell from beginning
   sub ax, dx
   
   mov bx, 100
   mul bx
   
   mov bx, 1716
   div bx      
   
   cmp ax, REQUARED_PERCENT
   jb _INFO_PRINT ; < u
   mov ax, 0
   mov cs:_game_exit_flag, al
   mov cs:_gameover, al
   popa
   ret 
   
_INFO_PRINT:
   mov bl, 10
   div bl
       
   add ax, 0x3030
   mov cs:_info_str[8], al
   mov cs:_info_str[9], ah
   
   printstr _info_str, cs, NORM_ATTR, 0, 0 
   
   popa
   ret
_info_str db 'full is 00 %$' 
endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;work with field;;;;;;;;;;;;;;;;;   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
fieldinit proc

    lea bx, matrix
    mov ax, CH_PL_LAND
    
    mov [bx], ax
    add bx, 2

    mov cs:_old_cell_val, CHAR_LAND
    mov cs:_player_char, CH_PL_LAND
    mov cx, 79
_INIT_LOOP1:
    mov [bx], CHAR_LAND
    add bx, 2
    loop _INIT_LOOP1

    mov cx, 22
_INIT_LOOP2:
    mov [bx], CHAR_LAND
    add bx, 158
    mov [bx], CHAR_LAND
    add bx, 2
    loop _INIT_LOOP2

    mov cx, 80
_INIT_LOOP3:
    mov [bx], CHAR_LAND
    add bx, 2
    loop _INIT_LOOP3
    
    mov cx, enem_num
    mov si, offset enem_pos
_INIT_ENEMY:
    
    mov bx, [si]
    celladdr
    mov bx, cs:_celladdr
    add bx, offset matrix
    mov [bx], CHAR_ENEMY
    add si, 2
    loop _INIT_ENEMY

    ret
endp   

fieldload proc
    pusha
    push es
    push ds
    
    cld
    mov cx, 0x0F00
    
    mov ax, 0xB800
    mov es, ax
    mov di, 160
    
    lea si, matrix
    
    rep movsb
    
    pop ds
    pop es
    popa
    
    ret
endp 

_player_mov_dir db DIR_UP
_player_pos     dw 0
_old_cell_val   dw CHAR_LAND
_celladdr       dw ? 
_player_char    dw CH_PL_LAND
celladdr macro
    ;input: bh-x bl-y 
    ;output: _celladdr = (160y + x)
    push ax
    push cx
    
    xor ax, ax
    mov al, bl
    mov cl, 160
    mul cl
    
    mov cl, bh
    mov ch, 0
    
    add ax, cx
    add ax, cx
    
    mov cs:_celladdr, ax
    pop cx
    pop ax
endm

player_mov proc
    pusha
    call ex_cell_pre_proc
    ;mov right 
    mov al, cs:_player_mov_dir
    cmp al, DIR_RIGHT
    jne _PLAYER_MOV_DIR_D
    mov bx, cs:_player_pos
    cmp bh, 79 ; right border
    je _PLAYER_MOV_END
    celladdr
    mov cx, cs:_old_cell_val 
    mov si, cs:_celladdr
    add si, offset matrix
    mov [si], cx  ; put old_value to current pos
    
    inc bh
    jmp _PLAYER_MOV_STEP  
    
_PLAYER_MOV_DIR_D:
    cmp al, DIR_DOWN
    jne _PLAYER_MOV_DIR_L 
    mov bx, cs:_player_pos
    cmp bl, 23 
    je _PLAYER_MOV_END
    celladdr
    mov cx, cs:_old_cell_val 
    mov si, cs:_celladdr
    add si, offset matrix
    mov [si], cx  ;return old value of cell
    
    inc bl
    jmp _PLAYER_MOV_STEP
    
_PLAYER_MOV_DIR_L:
    cmp al, DIR_LEFT
    jne _PLAYER_MOV_DIR_U 
    mov bx, cs:_player_pos
    cmp bh, 0 ; left border
    je _PLAYER_MOV_END
    celladdr
    mov cx, cs:_old_cell_val 
    mov si, cs:_celladdr
    add si, offset matrix
    mov [si], cx  ;return old value of cell
    
    dec bh
    jmp _PLAYER_MOV_STEP
    
_PLAYER_MOV_DIR_U:
    cmp al, DIR_UP
    jne _PLAYER_MOV_END 
    mov bx, cs:_player_pos
    cmp bl, 0 ; up border
    je _PLAYER_MOV_END
    celladdr
    mov cx, cs:_old_cell_val 
    mov si, cs:_celladdr
    add si, offset matrix
    mov [si], cx  ;return old value of cell
    
    dec bl
      
_PLAYER_MOV_STEP:
    mov cs:_player_pos, bx
    celladdr
    mov si, cs:_celladdr
    add si, offset matrix
    mov cx, [si]
    mov cs:_old_cell_val, cx
    mov cx, cs:_player_char
    mov [si], cx 
_PLAYER_MOV_END:
    popa
    
    call cell_post_proc
    
    ret
endp

ex_cell_pre_proc proc
    push ax
    
    mov ax, cs:_old_cell_val
    cmp ax, CHAR_SEA
    jne _EX_CELL_PREV_PROCEND
    mov ax, CHAR_PATH
    mov cs:_old_cell_val, ax
    mov cs:_player_char, CHAR_PLAYER
    
_EX_CELL_PREV_PROCEND:
    pop ax
    ret
endp

cell_post_proc proc
    pusha
    push_stack _player_pos
    mov ax, cs:_old_cell_val
    cmp ax, CHAR_PATH
    jne _D0_NOT_CLEAR_CYCLE
    call clear_cycle
    jmp _POST_PROC_END
_D0_NOT_CLEAR_CYCLE:
    cmp ax, CHAR_LAND
    jne _POST_PROC_END
    call fill_cycle
    mov cs:_player_char, CH_PL_LAND

_POST_PROC_END:
    mov ax, cs:_old_cell_val
    cmp ax, CHAR_ENEMY
    jne _POST_DONT_BREAK_GAME
    mov ax, 0
    mov cs:_game_exit_flag, al

_POST_DONT_BREAK_GAME:
    popa
    ret
endp

clear_cycle proc
    pusha
    
    mov ax, cs:_player_pos
    pop_stack
    
_CLEAR_CYCLE:
    pop_stack
    mov bx, cs:poped_val
    cmp ax, bx
    je _CLEAR_CYCLE_END
    
    celladdr
    mov bx, cs:_celladdr
    add bx, offset matrix
    mov [bx], CHAR_SEA
    
    jmp _CLEAR_CYCLE
    
_CLEAR_CYCLE_END:
    
    push_stack _player_pos
    popa
    ret
endp 

fill_cycle proc
    pusha

    mov cx, M_SIZE ;number words in matrix
    mov bx, offset matrix
    
    mov ax, 0  ;clear stack
    mov path_pos, ax
    
    call fill_temp_field
    
    call fill_obl
    call restore_field
    
    mov ax, 0  ;clear stack
    mov path_pos, ax
    
_FILL_CYCLE:
    
    mov ax, [bx]
    cmp al, '*'
    jne _FILL_CONTINUE
    mov al, 0xDB ;filled cell
    mov [bx], ax

_FILL_CONTINUE:
    add bx, 2
    loop _FILL_CYCLE
    
    popa
    ret
endp

push_stack macro value
    pusha
    
    mov ax, cs:value 
    mov dx, path_pos
    mov bx, offset path
    add bx, dx
    mov [bx], ax
    add dx, 2
    mov path_pos, dx
    
    popa
endm 

poped_val dw ?
pop_stack macro s
    pusha

    mov bx, offset path ; [][][][][]
    mov ax, path_pos    ;           /\
    sub ax, 2
    add bx, ax
    mov cx, [bx]
    mov path_pos, ax    ; [][][][]
    mov cs:poped_val, cx;         /\
    
    popa
endm

fill_temp_field proc
    pusha
    
    mov cx, M_SIZE
    mov bx, offset matrix
    mov cs:__fill_color, 0

_FILL_TEMP_CYCLE:
    mov ax, [bx]
    cmp ax, CHAR_SEA
    jne _FIELD_TEMP_CONTINUE
    
    inc cs:__fill_color
    mov cs:__fill_count, 0
    mov cs:__fill_enemy, 0
    
    call fill_recurse
    
    push_stack __fill_count
    push_stack __fill_enemy
    push_stack __fill_color
    
_FIELD_TEMP_CONTINUE:
    add bx, 2
    loop _FILL_TEMP_CYCLE

    popa
    ret
endp

__fill_count dw ?
__fill_enemy dw ?
__fill_color dw ?
_fill_rec_pos dw ?

;void recurse(int x, int y){
;    if ([bx] != CHAR_SEA){
;        [bx] = __fill_color;
;        recurse(x - 1, y);      // <-
;        recurse(x + 1, y);      // ->
;        recurse(x, y - 1);      // /\
;        recurse(x, y + 1);      // \/
;    }
;}
fill_recurse proc
    push ax

    mov ax, [bx]
    cmp ax, CHAR_ENEMY
    jne _FILL_RECURSE_NO_ENEMY
    mov cs:__fill_enemy, 1
    pop ax
    ret
    
_FILL_RECURSE_NO_ENEMY:
    cmp ax, CHAR_SEA
    jne _FILL_RECURSE_END
    inc cs:__fill_count
    mov ax, cs:__fill_color
    mov [bx], ax
    push bx
    sub bx, 2
    call fill_recurse
    pop bx
_REC_MOVE_RIGHT:
    push bx
    add bx, 2
    call fill_recurse
    pop bx
_REC_MOVE_UP:
    push bx
    sub bx, 160
    call fill_recurse
    pop bx
_REC_MOV_DOWN:
    push bx
    add bx, 160
    call fill_recurse
    pop bx
_FILL_RECURSE_END:
    pop ax
    ret
endp

restore_field proc
    pusha
    
    mov cx, M_SIZE
    mov bx, offset matrix
_RESTORE_FIELD_CYCLE:
    mov ax, [bx]
    cmp ax, CHAR_LAND
    je _RESTORE_CYCLE_FINALLY
_RESTORE_CHECK_PLAYER:
    cmp ax, CH_PL_LAND
    je _RESTORE_CYCLE_FINALLY
_RESTORE_CHECK_ENEMY:
    cmp ax, CHAR_ENEMY
    je _RESTORE_CYCLE_FINALLY
_RESTORE_CHECK_STAR:
    cmp ax, CHAR_PATH
    je _RESTORE_CYCLE_FINALLY
    mov [bx], CHAR_SEA
    
_RESTORE_CYCLE_FINALLY:
    add bx, 2
    loop _RESTORE_FIELD_CYCLE
    
    popa  
    ret
endp

fill_obl proc
    pusha
    
    mov cx, path_pos
    mov bx, offset path
    
_FILL_TO_COLOR_LOOP:
    
    mov ax, [bx]
    mov cs:__counted_fill, ax
    add bx, 2
    
    mov ax, [bx]
    mov cs:__is_with_enemy, ax
    
    add bx, 2
    mov ax, [bx]
    mov cs:__color_to_fill, ax
    
    add bx, 2
    sub cx, 5
    
    call fill_color
    
    loop _FILL_TO_COLOR_LOOP
    
    popa
    ret
endp
__color_to_fill dw ?
__is_with_enemy dw ?
__counted_fill  dw ?

fill_color proc
    pusha
    mov ax, cs:__is_with_enemy
    cmp ax, 0
    jne _FILL_COLOR_ENDIND
    mov bx, cs:__counted_fill

    mov dx, cs:__color_to_fill
    mov cx, M_SIZE
    mov bx, offset matrix
_FILL_COLOR_LOOPING:
    mov ax, [bx]
    cmp ax, dx
    jne _FILL_COLOR_LOOPING_CONTINUE
    mov [bx], CHAR_LAND
_FILL_COLOR_LOOPING_CONTINUE:
    add bx, 2
    loop _FILL_COLOR_LOOPING
    
_FILL_COLOR_ENDIND:
    popa
    ret
endp
_gameover db 1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;main;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

main:
    mov ax, @data
    mov ds, ax
    
    mov ah, 1
    mov cx, 2020h
    int 10h 
    
    call menu
    call clearscr

    xor ah, ah
    mov al, cs:_gameover
    cmp ax, 1
    jne _MAIN_WIN
    
    printstr _game_over, cs, NORM_ATTR, 2, 2
    jmp _MAIN_END
_MAIN_WIN:
    printstr _win, cs, NORM_ATTR, 2, 2
    
    
_MAIN_END:
    mov ah, 0x4C
    int 0x21
    _game_over db "GAME OVER =($"
    _win  db "GAME IS WIN =)$"
end main