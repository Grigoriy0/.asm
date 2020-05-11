.model small
.stack 100h
.data
    bufSize         equ 128
    LINE_IS_EMPTY   equ 0
    LINE_NOT_EMPTY  equ 1
    CR              equ 13
    LF              equ 10
    SPACE           equ 20h
    TAB             equ 9

    filename        db 80 dup(0)
    buffer          db bufSize dup(0)
    buf             db 0
    handle          dw 0
    counter         dd 0
    viewed          dw 0
    space_counter   dw 0
    flag            db LINE_IS_EMPTY
      
    closeString     db "Close the file$"
    openFileError   db "Error of open!$"  
    openString      db "Open the file$" 
    newLine         db CR, LF, '$'
    errorString     db "Error!$"
    exitString      db "Exit$"
    lastSymbol      db 0
  
.code 
   
outputString proc
    mov ah, 09h
    int 21h
    ret
outputString endp 

printNewLine proc
    lea dx, newLine
    call outputString
    ret
printNewLine endp   

add_to_si macro short
    push cx
    push bx
    lea bx, short
    mov cx, word ptr [bx]
_ADD_TO_SI_LOOP:
    call inc_si_proc
    loop _ADD_TO_SI_LOOP
    pop bx
    pop cx
endm


inc_si_proc proc
    push ax
    cmp [si + 2], 0ffffh
    jne _INC_SI_JUST_INC

    mov ax, [si]
    add ax, 1
    mov word ptr [si], ax
    mov ax, 0
    mov word ptr [si + 2], ax
    pop ax
    ret
_INC_SI_JUST_INC:
    mov ax, [si + 2]
    add ax, 1
    mov word ptr [si + 2], ax
    pop ax
    ret    
inc_si_proc endp


sub_to_si macro short
    push cx
    push bx
    lea bx, short
    mov cx, word ptr [bx]
_SUB_TO_SI_LOOP:
    call dec_si_proc
    loop _SUB_TO_SI_LOOP
    pop bx
    pop cx
endm


dec_si_proc proc
    push ax
    cmp word ptr [si + 2], 0h
    jne _DEC_SI_JUST_DEC

    mov ax, [si]
    dec ax
    mov word ptr [si], ax
    mov ax, 0ffffh
    mov word ptr [si + 2], ax
    pop ax
    ret
_DEC_SI_JUST_DEC:
    mov ax, [si + 2]
    dec ax
    mov word ptr [si + 2], ax
    pop ax
    ret    
dec_si_proc endp


get_name proc
    push ax
    push cx
    push di
    push si
    xor cx, cx
    mov cl, es:[80h]
    cmp cl, 0
    je _GET_NAME_END
    mov di, 82h
    lea si, filename
_GET_NAME_LOOP:
    mov al, es:[di]
    cmp al, 0Dh
    je _GET_NAME_END
    mov [si], al
    inc di
    inc si
    jmp _GET_NAME_LOOP 
_GET_NAME_END:
    pop si
    pop di
    pop cx
    pop ax   
    ret
get_name endp


fopen  proc 
    mov ah, 3dh
    mov al, 2
    lea dx, filename 
    int 21h 
    jc openError  
    mov handle, ax  
    ret
fopen endp


fclose proc 
    mov ah, 3eh 
    mov bx, handle 
    int 21h 
    jc _ERROR 
    ret
fclose endp     



space_delete_proc proc
lea bx, counter
mov word ptr [bx], 0
mov word ptr [bx + 2], 0
mov space_counter, 0
_READ_TO_BUFFER:     
    mov cx, bufSize
    mov bx, handle
    lea dx, buffer 
    mov ah, 3fh
    int 21h
    jc _ERROR
    xor cx, cx
    mov cx, ax
    jcxz _CLOSE
    
    push ax
    xor si, si
    mov viewed, 0 
    mov flag, LINE_IS_EMPTY
    lea si, buffer
    cmp byte ptr [si], 0
    je _CLOSE

        _VIEW_BUFFER:  
            inc viewed ; inc count of viewed bytes
            cmp  byte ptr [si], LF
            je _END_OF_LINE  
            cmp  byte ptr [si], SPACE
            jne _CHECK_TAB
            _ITS_TAB:  
            pop ax
            cmp ax, viewed
            je _END_OF_LINE
            push ax
            inc si
            jmp _VIEW_BUFFER
_CHECK_TAB:
    cmp byte ptr [si], TAB
    jne _NOT_WHITE_SPACE
    jmp _ITS_TAB
_NOT_WHITE_SPACE:
    cmp byte ptr [si], CR
    je _CRET
    pop ax
    cmp ax, viewed
    je _END_OF_LINE
    push ax
    mov flag, LINE_NOT_EMPTY
    inc si
    jmp _VIEW_BUFFER 

_END_OF_LINE:
    cmp flag, LINE_NOT_EMPTY
    jne _EMPTY
        
_NOT_EMPTY:

    xor ax, ax ; set pointer to start index
    mov bx, handle
    mov ah, 42h
    mov dx, counter
    xor cx, cx
    int 21h 

    xor ax, ax ; write to number of viewed bytes
    mov bx, handle
    mov ah, 40h
    mov dx, offset buffer
    mov cx, viewed
    int 21h
 


    ; lea si, counter
    ; add_to_si viewed
    mov ax, counter
    add ax, viewed
    mov counter, ax

    ; lea si, counter
    ; add_to_si space_counter
    mov ax, counter
    add ax, space_counter
    mov counter, ax

    ; return pointer to old position
    xor ax, ax
    mov bx, handle
    mov ah, 42h
    mov dx, counter
    xor cx, cx
    int 21h

    ; lea si, counter
    ; sub_to_si space_counter
    mov ax, counter
    sub ax, space_counter
    mov counter, ax
    
    jmp _READ_TO_BUFFER

_EMPTY:

    mov ax, viewed
    add space_counter, ax
    ; lea si, counter
    ; add_to_si space_counter
    mov ax, counter
    add ax, space_counter
    mov counter, ax


    xor ax, ax
    mov bx, handle
    mov ah, 42h
    mov dx, counter
    xor cx, cx
    int 21h
   
    ; lea si, counter
    ; sub_to_si space_counter
    mov ax, counter
    sub ax, space_counter
    mov counter, ax

    jmp _READ_TO_BUFFER

_CRET:
    pop ax
    cmp ax, viewed
    je _END_OF_LINE
    push ax
    inc si
    jmp _VIEW_BUFFER
endp     
      
      
_ERROR:
    lea dx, errorString
    call outputString
    call printNewLine
    jmp _EXIT  
      
openError:
    lea dx, openFileError
    call outputString
    call printNewLine
    jmp _EXIT  
               
begin:         
    mov ax, @data
    mov ds, ax
    
    call get_name 
    call fopen 
    
    lea dx, openString
    call outputString  
    call printNewLine
    
    call space_delete_proc 
    jmp _CLOSE 
      
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

_EXIT:                  
    lea dx, exitString
    call outputString 
    call printNewLine
    mov ah, 4ch
    int 21h            
end begin