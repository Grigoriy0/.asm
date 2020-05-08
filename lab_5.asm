;.386
;.model flat,stdcall
.model small
.stack 100h
.data
    bufSize         equ 128
    LINE_IS_EMPTY   equ 1
    LINE_NOT_EMPTY  equ 0
    CR              equ 13
    LF              equ 10
    SPACE           equ 20h
    TAB             equ 9

    filename        db 80 dup(0)
    out_file        db "output.txt", 0, '$'
    buffer          db bufSize dup(0)
    bufEnd          db 0
    
    handle_in       dw 0
    handle_out      dw 0
    flag            db 0
    readed          dw 0
    start_index     dw 0
    end_index       dw 0


    closeString     db "Close the file$"
    openFileError   db "Error of open!$"
    openString      db "Open the file$"
    newLine         db CR, LF, '$'
    errorString     db "Error!$"
    exitString      db "Exit$"
    bf_e db "buffer ends$"
    endline db "end of line$"
    _w db "write$"
    _r db "read$"
    ad db "access denied$"
    wi db "wrong handle$"
    testt db "test$"
    
.code 


log macro string
    pusha
    lea dx, string
    call outputString
    call printNewLine
    popa
endm

to_cx_dx macro var
    push si
    lea si, var
    mov cx, [si]
    mov dx, [si + 2]
    pop si
endm

;Вывод строки
outputString proc
    mov ah, 09h
    int 21h
    ret 
outputString endp 

;Вывод \n
printNewLine proc
    lea dx, newLine
    call outputString
    ret
printNewLine endp

;Считывание имени файла из ком.строки
get_name proc
    push ax
    push cx
    push di
    push si
    xor cx, cx
    mov cl, es:[80h]  ;Количество символом в командной строке
    cmp cl, 0
    je GET_NAME_END
    mov si, 82h       ;Смещение командной строки в блоке PSP
    lea di, filename
GET_NAME_LOOP:
    mov al, es:[si]   ;Заносим в al посимвольно значение командной строки
    cmp al, 0Dh
    je GET_NAME_END
    mov [di], al
    inc di
    inc si
    jmp GET_NAME_LOOP 
GET_NAME_END:
    
    pop si
    pop di
    pop cx
    pop ax
    ret
get_name endp

;Открытие файла для чтения и записи
fopen_exist  proc 
    mov ah, 3dh         ;3Dh - открыть существующий файл
    mov al, 0           ;Режим доступа чтение
    lea dx, filename
    int 21h
    jc OPEN_ERROR       ; CF = 1
    mov handle_in, ax
    ret
fopen_exist endp

fopen_new  proc
    mov cx, 0
    lea dx, out_file
    mov ah, 3Ch         ;3Ch - создать новый файл (переписать существующий)
    int 21h
    jc OPEN_ERROR
    mov handle_out, ax
    ret
fopen_new endp

;Закрытие файла
fclose macro handle
    mov ah, 3eh         ;3Eh - закрытие файла
    mov bx, handle
    int 21h
endm

; read bufSize into buffer
; проходить по буферу и :
; в течении строки проверять, есть ли там другие символы, кроме CR, LF, SPACE, TAB => flag = 1
; if (flag == 1) continue to 1
; записать в output текущую строку
; LF - 10 (Enter)
; CR - 13

; SP - 20h
; TAB - 9

write proc
;пишем в файл
;bx - идентификатор, 
;ds:dx - адрес буфера с данными
;cx - число байтов для записи
    log _w
    push ax
    push bx
    push cx
    push dx
    mov ah, 40h
    mov bx, handle_out
    mov dx, start_index
    mov cx, end_index
    sub cx, start_index
    int 21h
    jc ERROR_WRITE
    pop dx
    pop cx
    pop bx
    pop ax
    ret
write endp

read proc
    log _r
;читаем из файла
;bx - идентификатор, 
;ds:dx - адрес буфера с данными
;cx - число байтов для чтения
    push ax
    push bx
    push cx
    push dx
    mov ah, 3fh
    mov cx, bufSize
    mov bx, handle_in
    lea dx, buffer
    int 21h
    cmp ax, 0
    je _CLOSE        ; конец файла
    lea si, buffer
    add si, ax
    mov [si], 0
    mov readed, ax  ; сохраняем прочитанное колличество
    pop dx
    pop cx
    pop bx
    pop ax
    ret
read endp
get_next macro
    inc si
    mov al, [si]
endm

if_we_found_end_of_line proc
    log endline
    push ax
    push dx
_SKIP_CR:
    cmp al, CR
    jne _SKIP_LF
    get_next
_SKIP_LF:
    get_next
_SKIP_O:
    mov end_index, si
    cmp flag, LINE_IS_EMPTY
    je _END_OF_LINE_NO_WRITE
    call write
_END_OF_LINE_NO_WRITE:
    mov dx, end_index
    mov start_index, dx
    pop dx
    pop ax
    ret
if_we_found_end_of_line endp

if_buffer_ends proc
    log bf_e
    mov end_index, si
    cmp flag, LINE_IS_EMPTY
    je _BUFFER_ENDS_NO_WRITE
    call write
_BUFFER_ENDS_NO_WRITE:
    call read
    lea si, buffer
    mov start_index, si
    mov al, [si]
    ret
if_buffer_ends endp

;Удаление пустых строк
space proc

    call read
    mov flag, LINE_IS_EMPTY
    
    lea si, buffer
    add si, 3
    mov start_index, si
    mov al, [si]
    _READ_LOOP:
        cmp al, SPACE
        ja _SET_FLAG
        cmp al, 0
        je _BUFFER_ENDS
        cmp al, LF
        je _LINE_ENDS
        _LINE_ENDS_CONTINUE:
        ; it's white symbol
        _BUFFER_ENDS_CONTINUE:
        cmp al, 0
        je _BUFFER_ENDS
        get_next
    jmp _READ_LOOP

    ret
_LINE_ENDS:
    mov flag, LINE_IS_EMPTY
    call if_we_found_end_of_line
    jmp _LINE_ENDS_CONTINUE
_SET_FLAG:
    mov flag, LINE_NOT_EMPTY
_SET_FLAG_SKIP_CHARS:
    get_next
    cmp al, CR
    je _SET_FLAG_SKIP_END
_SET_FLAG_SKIP_CHARS_CHECK_:
    cmp al, 0
    je _BUFFER_ENDS
    jmp _SET_FLAG_SKIP_CHARS
_SET_FLAG_SKIP_END:
    call if_we_found_end_of_line
    jmp _LINE_ENDS_CONTINUE
_BUFFER_ENDS:
    call if_buffer_ends
    jmp _BUFFER_ENDS_CONTINUE
    ret
endp


ERROR_WRITE:
    cmp ax, 05h
    je ERR_AD
    cmp ax, 06h
    je ERR_WI
    jmp ERROR
ERR_AD:
    log ad
    jmp ERROR
ERR_WI:
    log wi
    jmp ERROR

ERROR:
    lea dx, errorString
    call outputString
    call printNewLine
    jmp EXIT

OPEN_ERROR:
    lea dx, openFileError
    call outputString
    call printNewLine
    jmp EXIT
               
BEGIN:         
    mov ax, @data
    mov ds, ax
    
    call get_name
    call fopen_exist
    call fopen_new
    
    lea dx, openString
    call outputString
    call printNewLine
    
    call space
_CLOSE:
           
    fclose handle_in
    fclose handle_out
    
    lea dx, closeString  
    call outputString
    call printNewLine

EXIT:                  
    lea dx, exitString
    call outputString 
    call printNewLine
    mov ah, 4ch
    int 21h            
end BEGIN