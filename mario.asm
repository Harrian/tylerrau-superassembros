%include "asm_io.inc"
%include "io.inc"
; initialized data is put in the .data segment
segment .data
clear db 27,"[2J",27,"[1;1H",0
cc db 27,"c",0
scanFormat db "%c",0
file db "input.txt",0
mode db "r",0
formatA db "%c",0
x dd 3
y dd 3
prevX dd 0
prevY dd 0
score dd 1
scorep db "Score: ",0
finalscore db "Final Score: ",0

rows dd 20
cols dd 89
; uninitialized data is put in the .bss segment
segment .bss
text resb 2000

; code is put in the .text segment
segment .text
    global  asm_main
	extern fscanf
	extern fopen
	extern fclose
	extern scanf
	extern getchar
	extern putchar
asm_main:
    enter   0,0               ; setup routine
    pusha
	;***************CODE STARTS HERE*******
		mov eax, clear    ;two lines to clear
		call print_string ;clear the screen
		mov eax, cc
		call load	;load the file into text
		call update ;update the file with the location 
		mov eax, text
		call print_string
		
		
	  top:
		call movement
		call update
		mov eax, clear    ;two lines to clear
		call print_string ;clear the screen
		mov eax, text
		call print_string
			
			mov eax, [y]
			inc eax
			mov edx, 0
			imul eax,[cols]
			add eax, [x]
			mov bl,byte [text+eax]
			cmp bl,45h
			jz breakout
		
		mov eax, scorep
		call print_string
		mov eax, [score]
		call print_int
		call print_nl
		jmp top
		breakout:
		mov eax,finalscore
		call print_string
		mov eax,[score]
		call print_int
		call print_nl
	;***************CODE ENDS HERE*********
    popa
    mov     eax, 0            ; return back to C
    leave                     
    ret
;*********************************
;* Function to load var text with*
;* input from input.txt          * 
;*********************************
load:
	push eax
	push esi

	sub esp, 20h
	;get the file pointer
	mov dword [esp+4], mode; the mode for the file which is "r"	
	mov dword [esp], file; the name of the file.  Hard coded here (input.txt)
	call fopen ; call fopen to open the file

	;read stuff
	mov [esp], eax; mov the file pointer to param 1
	mov eax, esp  ;use stack to store a pointer where char goes
	add eax, 1Ch  ;address is 1C up from the bottom of the stack
	mov [esp+8], eax;pointer is param 3
	mov dword [esp+4], scanFormat; fromat is param 2

	mov edx, 0
	mov [prevX], edx
  	mov [prevY], edx

  scan:	call fscanf; call scanf 
	cmp eax, 0 ; eax will be less than 1 when EOF
	jl done; eof means quit
	mov eax, [esp+1Ch]; mov the result (on the stack) to eax
	
	cmp al, 'M'
	jz Mario
	
	mov edx, [prevX]; increment prevX
	inc edx
	mov [prevX], edx

	cmp al, 10
	jz NewLine
	
	jmp save
NewLine:

	mov dword [prevX], 0
	mov edx, [prevY]
	inc edx
	mov [prevY], edx
	jmp save
	
Mario:
	mov edx, [prevX]
	mov [x], edx
	mov edx, [prevY]
	mov [y], edx
	jmp save
	
save:
	
	mov [text + esi], al; store in the array
	inc esi; add one to esi (index in the array)
	cmp esi, 2000; dont go tooo far into the array
	jz done; quit if went too far
	jmp scan ;loop back
done:
	call fclose; close the file pointer
	mov byte [text+esi],0 ;set the last char to null
	add esp, 20h; unallocate stack space
	
	pop esi	;restore registers
	pop eax
	ret

	;*********************************
	;* Function to update the screen *
	;*                               * 
	;*********************************

update:
	push eax
	push ebx
	push ecx
	push edx
	;update the new loc
	mov eax, [x]
	mov ebx, [y]
	mov edx, 0
	imul ebx, [cols]

	add eax, ebx
	mov byte [text + eax], 'M'
	mov ecx,eax
	;update the old loc
	mov eax, [prevX]
	mov ebx, [prevY]
	mov edx, 0
	imul ebx, [cols]

	add eax, ebx
	cmp eax,ecx
	jz jumpover
	mov byte [text + eax], ' '
	mov edx,[score]
	dec edx
	mov [score],edx
	jumpover:
	pop edx
	pop ecx
	pop ebx
	pop eax
	
ret


;*********************************
;* Function to get mouse movement*
;*                               * 
;*********************************
movement:	
	pushad
    mov ebx, [x]
	mov [prevX], ebx;save old value of x in prevX
    mov ebx, [y]
	mov [prevY], ebx; save old value of y in prevY
	call canonical_off
	call echo_off
	mov eax, formatA
	push eax
	;http://stackoverflow.com/questions/15306463/getchar-returns-the-same-value-27-for-up-and-down-arrow-keys
	call getchar
	call getchar
	call getchar
	call canonical_on
	call echo_on
	cmp eax, 43h; right
	jz right
	cmp eax, 44h; left
	jz left
	cmp eax, 42h; down
	jz down
	cmp eax, 41h; up
	jz up
	jmp over
  right:
	;check if block is to the right
	mov ebx, [y]
	mov edx,0
	imul ebx,[cols]
	mov edx,[x]
	inc edx
	add ebx, edx;
	mov cl,byte [text+ebx]
	cmp cl,42h
	jz mDone
	;check for wall also
	cmp cl,2ah
	jz mDone
	cmp cl,45h
	jz mDone
	;move right
	cmp cl,47h
	jz coinright
	jmp nocoinright
	coinright:
	mov byte [text+ebx], 20h
	mov ebx,[score]
	add ebx,100
	mov [score],ebx
	nocoinright:
    mov eax, [x]
    inc eax
	mov [x], eax
	;check for falling
	mov ebx, [y]
	inc ebx
	mov edx, 0
	imul ebx,[cols]
	add ebx,[x]
	mov cl, byte [text+ebx]
	cmp cl,20h ;check for space
	jz rightfall
	cmp cl,47h  ;check for coin first
	jz rightfall
	jmp mDone
	rightfall:
	mov eax,[x]
	push eax
	mov eax,[y]
	push eax
	call fall
	pop ebx
	pop ebx
	mov [y], eax
	jmp mDone
  left:
	;check if block is to left
	mov ebx, [y]
	mov edx,0
	imul ebx,[cols]
	mov edx,[x]
	dec edx
	add ebx, edx;
	mov cl,byte [text+ebx]
	cmp cl,42h
	jz mDone
	;check for wall also
	cmp cl,2ah
	jz mDone
	cmp cl,45h
	jz mDone
	cmp cl,47h
	jz coinleft
	jmp nocoinleft
	coinleft:
	mov byte [text+ebx], 20h
	mov ebx,[score]
	add ebx,100
	mov [score],ebx

	nocoinleft:
   	mov eax, [x]
	dec eax
	mov [x], eax
	;check for falling
	mov ebx, [y]
	inc ebx
	mov edx, 0
	imul ebx,[cols]
	add ebx,[x]
	mov cl, byte [text+ebx]
	cmp cl,20h ;check for space
	jz leftfall
	cmp cl,47h  ;check for coin first
	jz leftfall
	jmp mDone
	leftfall:
	mov eax,[x]
	push eax
	mov eax,[y]
	push eax
	call fall
	pop ebx
	pop ebx
	mov [y], eax
    jmp mDone
  up:
	mov eax,[y]
	inc eax
	mov edx,0
	imul eax,[cols]
	add eax,[x]
	mov bl, byte [text+eax]
	cmp bl,42h
	jz jmpbase
	cmp bl,2ah
	jz jmpbase
	jmp mDone
	jmpbase:
	mov eax,[x]
	push eax
	mov eax,[y]
	push eax
	call jump
	pop ebx
	pop ebx
	mov [y], eax
	jmp mDone
  down:
   	mov eax,[x]
	push eax
	mov eax,[y]
	push eax
	call fall
	pop ebx
	pop ebx
	mov [y], eax
	jmp mDone
  mDone:
over:pop eax
	popad
	ret
	
	
fall:
	push ebp
	mov ebp,esp

	push ebx
	push ecx
	push edx

	mov eax,[ebp+8h]
	mov ebx,[ebp+8h]
	
	topoffallloop:
	inc ebx
	mov edx,0
	imul ebx,[cols]
	add ebx,[ebp+0Ch]
	mov dl, byte [text+ebx]

	cmp dl,2ah;check for wall
	jz jmpdone
	cmp dl,42h;check for brick
	jz jmpdone
	cmp dl,45h;check for exit
	jz jmpdone

	cmp dl,20h
	jz fallovercoin
	cmp dl,47h
	;do gold coin here
	mov byte [text+ebx], 20h
	mov ebx,[score]
	add ebx,100
	mov [score],ebx
	fallovercoin:
	inc eax
	mov ebx,eax
	jmp topoffallloop

	falldone:

	pop edx
	pop ecx
	pop ebx

	mov esp,ebp
	pop ebp
	ret

jump:
	push ebp
	mov ebp,esp

	push ebx
	push ecx
	push edx

	mov eax,[ebp+8h]
	mov ebx,[ebp+8h]
	mov ecx,3
	topofjumploop:
	dec ebx
	mov edx,0
	imul ebx,[cols]
	add ebx,[ebp+0Ch]
	mov dl, byte [text+ebx]

	cmp dl,2ah
	jz jmpdone
	
	cmp dl,42h
	jz calltosmash
	jmp jmpoversmash
	
calltosmash:
	;if we make it here we can let go of edx
	mov edx,[ebp+0Ch]
	push edx
	mov edx,[ebp+8h]
	push edx
	call smash
	pop edx
	pop edx
	
	jmp jmpdone
jmpoversmash:
	cmp dl,45h
	jz jmpdone


	cmp dl,20h
	jz jumpovercoin
	cmp dl,47h
	;do gold coin here
	mov byte [text+ebx], 20h
	mov ebx,[score]
	add ebx,100
	mov [score],ebx
	jumpovercoin:

	dec eax
	mov ebx,eax
	loop topofjumploop

	jmpdone:

	pop edx
	pop ecx
	pop ebx

	mov esp,ebp
	pop ebp
	ret

smash:
	push ebp
	mov ebp,esp

	push eax ;this function gives eax back because jump needs to return a value in eax
	push ebx
	push ecx
	push edx
	
	; mov eax, [y]
	; call print_int
	; mov eax, [x]
	; call print_nl
	; call print_int
	
	mov edx,0
	mov eax,[ebp+8h]
	dec eax
	imul eax, [cols]
	add eax,[ebp+0Ch]; eax holds the address extension for the block above the assembro
	; dump_regs 1
	cmp eax,1343
	jz SMASHIT
	cmp eax,1199
	jz SMASHIT
	cmp eax,781
	jz SMASHIT
	cmp eax,1140
	jz SMASHIT
	jmp cancelsmash
	SMASHIT:
	mov byte [text+ebx],20h
	cancelsmash:
	pop edx
	pop ecx
	pop ebx
	pop eax

	mov esp,ebp
	pop ebp
	ret