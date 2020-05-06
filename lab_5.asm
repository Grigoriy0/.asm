.model small
.stack 100h
.data
    filename        db 80 dup(0)
    buffer          db 128 dup(0)
    buf             db 0
    handle          dw 0
    counter         dw 0
    c               dw 0
    flag            db 0
    space_counter   dw 0  
      
    closeString     db "Close the file$"
    openFileError   db "Error of open!$"
    openString      db "Open the file$"
    newLine         db 13, 10, '$'
    errorString     db "Error!$"
    exitString      db "Exit$"
    lastSymbol      db 0
  
.code 
   
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
    cmp al, 0Dh       ;0Dh - товарищ Enter, он же возврат каретки
    je GET_NAME_END
    mov [di], al      ;заносим символ из ком.строки в filename
    inc di            ;на следующий символ
    inc si
    jmp GET_NAME_LOOP 
GET_NAME_END:
    
    pop si            ;Восстанавливаем регистры
    pop di
    pop cx
    pop ax
    ret
get_name endp

;Открытие файла для чтения и записи
fopen  proc 
    mov ah, 3dh         ;3Dh - открыть существующий файл
    mov al, 2           ;Режим доступа (чтение и запись)
    lea dx, filename
    int 21h
    jc OPEN_ERROR       ;Словили маслину - выходим, CF = 1
    mov handle, ax
    ret
fopen endp

;Закрытие файла
fclose proc 
    mov ah, 3eh         ;3Eh - закрытие файла
    mov bx, handle
    int 21h
    jc ERROR
    ret
fclose endp


_CHECK_TAB:
    cmp byte ptr [si], 9
    jne notWhiteSpace
    jmp _NEXT
    
;Удаление пустых строк
space proc
    mov counter, 0
    mov space_counter, 0
    i:
    mov cx, 128     ; В cx количество байт для чтения
    mov bx, handle  ; В bx дескриптор
    lea dx, buffer  ; В dx адрес текста для считывания
    mov ah, 3fh     ; 3f - читать файл
    int 21h
    jc ERROR
    cmp ax, 0
    je _CLOSE        ; конец файла
    
    push ax         ; сохраняем колличество прочитанных байт
    mov c, 0        ; Счётчик прочитанных символов
    mov flag, 0
    xor si, si
    lea si, buffer
    cmp byte ptr [si], 0
    je _CLOSE     

        _COMPARE:
            inc c   ; количество символов в строке++
            cmp  byte ptr [si], 10      ; newline LF
            je _END_OF_LINE             ; Если конец строки
            cmp  byte ptr [si], ' '
            jne _CHECK_TAB
            _NEXT:
            pop ax
            cmp ax, c    ; если прочитали весь буфер(все, что выгружено в буфер)
            je _END_OF_LINE
            push ax
            inc si
            jmp _COMPARE
    jmp i

notWhiteSpace:
    cmp byte ptr [si], 13   ; carriage return
    je _CRET
    pop ax
    cmp ax, c
    je _END_OF_LINE
    push ax
    mov flag, 1     ; Флаг = 1, значит строка не пустая
    inc si
    jmp _COMPARE

;достигли конца строки - чекаем была ли она пустой
_END_OF_LINE:
    cmp flag, 1
    jne _EMPTY
    
_NOT_EMPTY:
;перемещаем указатель
;bx - идентификатор, cx,dx - расстояние, al = 0 - относительно начала
    xor ax, ax
    mov bx, handle
    mov ah, 42h
    mov dx, counter
    xor cx, cx
    int 21h

;пишем в файл
;bx - идентификатор, ds:dx - адрес буфера с данными
;cx - число байтов для записи
    xor ax, ax
    mov bx, handle
    mov ah, 40h
    mov dx, offset buffer
    xor cx, cx
    mov cx, c
    int 21h
 
;добавляем к общему числу прочитанных символов число символов, прочитанных
;из текущей строки
    mov ax, counter
    add ax, c
    mov counter, ax

    mov ax, counter
    add ax, space_counter
    mov counter, ax
      
;вновь тягаем указатель, только на этот раз к началу следующей строки
    xor ax, ax
    mov bx, handle
    mov ah, 42h
    mov dx, counter
    xor cx, cx
    int 21h

    mov ax, counter
    sub ax, space_counter
    mov counter, ax
    
    jmp i 

_EMPTY:
;обновляем значение считанных символов и символов в пустой строке
    mov ax, c
    add space_counter, ax
    mov ax, counter
    add ax, space_counter
    mov counter, ax

;перемещаем указатель к концу пустой строки
    xor ax, ax
    mov bx, handle
    mov ah, 42h
    mov dx, counter
    xor cx, cx
    int 21h
   
    mov ax, counter
    sub ax, space_counter
    mov counter, ax

    jmp i

_CRET:
    pop ax
    cmp ax, c
    je _END_OF_LINE
    push ax
    inc si
    jmp _COMPARE
endp


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
    call fopen
    
    lea dx, openString
    call outputString
    call printNewLine
    
    call space
_CLOSE:
    
    xor ax, ax
    mov bx, handle
    mov ah, 42h 
    dec counter
    mov dx, counter
    xor cx, cx
    int 21h    

    mov bx, handle
    mov ah, 40h
    int 21h
           
    call fclose 
    
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