INCLUDE functionHeaders.inc
.386
.model flat, stdcall
.stack 4096

GetLogicalDrives PROTO
GetDiskFreeSpaceExA PROTO :PTR BYTE, :PTR QWORD, :PTR QWORD, :PTR QWORD

.data
drivePath db "A:\", 0
msg1 db "Available Drives and Storage Info (in GB):", 0Dh, 0Ah, 0
msgTotal db "  Total: ", 0
msgFree db "  Free: ", 0
msgError db "  N/A (Unable to retrieve)", 0
szCRLF db 0Dh, 0Ah, 0

driveMask DWORD ?
totalSpace QWORD ?
freeSpace QWORD ?
unused QWORD ?
bytesPerGB QWORD 1073741824 ; 1 GB = 2^30 bytes

.code
diskInfo PROC
    pushad
    ; Display header
    mov edx, OFFSET msg1
    call WriteString

    ; Get logical drives bitmask
    INVOKE GetLogicalDrives
    mov driveMask, eax

    ; Check each drive (A to Z)
    mov ecx, 0              ; Drive letter index (0 = A, 1 = B, etc.)
    mov ebx, driveMask      ; Bitmask of available drives

check_drive:
    cmp ecx, 26
    jge done

    ; Check if drive exists (bit set in mask)
    test ebx, 1
    jz skip_drive

    ; Preserve ECX (loop counter)
    push ecx

    ; Set current drive letter in drivePath (e.g., C:\)
    mov al, 'A'
    add al, cl
    mov drivePath, al       ; Set first character: A, B, C...
    mov drivePath+1, ':'    ; Colon
    mov drivePath+2, '\'    ; Backslash
    mov drivePath+3, 0      ; Null terminator

    ; Print drive name
    mov edx, OFFSET drivePath
    call WriteString
    call CrLf

    ; Call GetDiskFreeSpaceExA
    INVOKE GetDiskFreeSpaceExA, ADDR drivePath, ADDR unused, ADDR totalSpace, ADDR freeSpace
    cmp eax, 0              ; Check if call succeeded
    je error_space

    ; Display total space
    mov edx, OFFSET msgTotal
    call WriteString
    mov eax, DWORD PTR totalSpace
    mov edx, DWORD PTR totalSpace + 4
    push edx
    push eax
    call DivideByGB
    call WriteDec
    call CrLf

    ; Display free space
    mov edx, OFFSET msgFree
    call WriteString
    mov eax, DWORD PTR freeSpace
    mov edx, DWORD PTR freeSpace + 4
    push edx
    push eax
    call DivideByGB
    call WriteDec
    call CrLf
    call CrLf
    jmp restore_ecx

error_space:
    ; Display error message for failed disk space query
    mov edx, OFFSET msgTotal
    call WriteString
    mov edx, OFFSET msgError
    call WriteString
    call CrLf
    mov edx, OFFSET msgFree
    call WriteString
    mov edx, OFFSET msgError
    call WriteString
    call CrLf
    call CrLf

restore_ecx:
    ; Restore ECX (loop counter)
    pop ecx

skip_drive:
    shr ebx, 1              ; Shift mask to next drive
    inc ecx                 ; Move to next drive letter
    jmp check_drive

done:
    popad
    ret
diskInfo ENDP

; Divide 64-bit value (passed on stack) by bytesPerGB, result in EAX
DivideByGB PROC
    push ebp
    mov ebp, esp
    push ebx

    ; Get 64-bit value from stack (EDX:EAX)
    mov eax, [ebp + 8]      ; Lower 32 bits
    mov edx, [ebp + 12]     ; Upper 32 bits

    ; Load divisor (1 GB)
    mov ebx, DWORD PTR bytesPerGB ; Lower 32 bits of 1GB
    ; bytesPerGB upper 32 bits are 0, so no need for full 64-bit division

    ; Perform division: EDX:EAX / EBX
    xor ecx, ecx            ; Clear ECX for simplicity
    div ebx                 ; EDX:EAX / EBX, quotient in EAX, remainder in EDX

    pop ebx
    mov esp, ebp
    pop ebp
    ret 8                   ; Clean up 8 bytes (two DWORDs) from stack
DivideByGB ENDP

END