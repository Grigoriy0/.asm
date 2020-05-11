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
    buffer          db bufSize dup(0)
    buf             db 0    
    handle          dw 0       
    counter         dw 0 
    c               dw 0
    flag            db 0
    space_counter   dw 0  
      
    closeString     db "Close the file$"
    errorExeString  db "Atata, ne zapuskay .exe!$"
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


checkTab:            
    cmp byte ptr [si], TAB
    jne notWhiteSpace
    jmp next
    
    
space_proc proc
mov counter, 0
mov space_counter, 0
i:     
    mov cx, 128
    mov bx, handle
    lea dx, buffer 
    mov ah, 3fh     
    int 21h
    jc _ERROR
    xor cx, cx
    mov cx, ax 
    jcxz close 
    
    push ax
    xor si, si
    mov c, 0 
    mov flag, 0
    lea si, buffer 
    cmp byte ptr [si], 0
    je close     
            
        k:  
            inc c 
            cmp  byte ptr [si], LF
            je endOfLine  
            cmp  byte ptr [si], SRACE
            jne checkTab
            next:  
            pop ax
            cmp ax, c
            je endOfLine
            push ax
            inc si
            jmp k
    jmp i

notWhiteSpace:
    cmp byte ptr [si], CR
    je cret    
    pop ax
    cmp ax, c
    je endOfLine
    push ax
    mov flag, 1 
    inc si
    jmp k  

nonEmpty:


    xor ax, ax
    mov bx, handle
    mov ah, 42h
    mov dx, counter
    xor cx, cx
    int 21h 




    xor ax, ax
    mov bx, handle
    mov ah, 40h
    mov dx, offset buffer
    xor cx, cx
    mov cx, c  
    int 21h
 
 

    mov ax, counter
    add ax, c
    mov counter, ax

    mov ax, counter
    add ax, space_counter
    mov counter, ax
      
         
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

Empty:

    mov ax, c
    add space_counter, ax
    mov ax, counter
    add ax, space_counter
    mov counter, ax


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

    
endOfLine:
    cmp flag, 1
    je  nonEmpty
    jne Empty
        
cret:
    pop ax
    cmp ax, c
    je endOfLine
    push ax
    inc si
    jmp k
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
    
    call space_proc 
    jmp close 
      
close:                                                             
    
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