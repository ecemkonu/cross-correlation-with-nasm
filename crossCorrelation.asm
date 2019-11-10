segment .data

segment .bss
outLen resd 1
outArr resd 1
firstLen resd 1
firstArr resd 1
secLen resd 1
secArr resd 1
windowInd resd 1
counter resd 1


segment .text
global cross_correlation_asm_full
;function name is specified as global to let c function calling notified.

cross_correlation_asm_full:
    mov dword[counter], 0
	push ebp
	mov	ebp,esp
    push ebx
    
    mov ebx, 0
	mov ecx, [ebp+28]
    sub ecx,1
    mov [outLen], ecx

    mov esi, [ebp+24]
    mov [outArr], esi
    mov edx, 0 
    ;sets output array entries to zero
    reset:
        mov [esi], edx
        add esi,4
        sub ecx, 1
        cmp ecx, 0
        jge reset

    mov ecx, [ebp+20]
    sub ecx, 1
    mov [secLen], ecx

    mov esi, [ebp+16]
    mov [secArr], esi

    mov ecx, [ebp+12]
    sub ecx, 1
    mov [firstLen], ecx

    mov esi, [ebp+8]
    mov [firstArr], esi
    ;parameters are read to variables in bss segment.

outLenLoop:
    ;sum at eax, value to move to output place
    ;for each outLenLoop, a window will be iterated
    ;check if outLenLoop > lenArr1, if so do skip those array indexes for first array
    mov ecx, ebx
    add ecx, 1
    mov edx, -1
    winSizeInnerLoop:
        add edx, 1
        mov [windowInd], edx
        indexOutBound:
            sub ecx, 1
            cmp ecx, -1
            jle next_step
            cmp ecx, [firstLen]
            jg indexOutBound
;reduces inner loop variant, conv indexes are calculated as follows
;for first array, offset is inner loop invariant
;for second array, offset is length - 1 - outer loop invariant + inner loop invariant
;outer loop invariant loops over all output indices
;inner loop invariant has at most window - second array- size entries
;valid entries holding conditions above are multiplied and added to corresponding output entry
        mov eax, [secLen]
        add eax, ecx
        sub eax, ebx
        cmp eax, 0
            jl next_step

        push edx
        push ebx

        mov esi, [secArr]
        push ecx
        mov ecx, 4
        mul ecx
        pop ecx
        add esi, eax

        mov edi, [firstArr]
        mov eax, 4
        mul ecx
        add edi, eax
        
        mov eax, [esi]
        mov ebx, [edi]
        mul ebx

        pop ebx
        push ecx
        mov ecx, eax

        mov eax, 4
        mul ebx
        
        mov edi, [outArr]
        add edi, eax
        add [edi], ecx
        pop ecx

        pop edx

        mov edx, [windowInd]
        cmp edx, [secLen]
        jle winSizeInnerLoop


    next_step:
        inc ebx
        cmp ebx, [outLen]
        jle outLenLoop

    mov ebx, 1
    mov ecx, [outLen]
    

    mov esi, [outArr]

    ;loop for summing up all entries, result written to eax, return register
    summed:
        mov eax, [esi]
        add esi,4
        cmp ecx, 0
        jl done
        sub ecx, 1
        cmp eax, 0
        je summed
        add [counter], ebx
        jmp summed


    done:

    ;pop ebx
    ;mov	esp,ebp
    mov eax, [counter]
    pop ebx
	pop	ebp
    ret
