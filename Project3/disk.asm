 include functionHeaders.inc 
.386
.model flat, stdcall
.stack 4096


GetLogicalDrives PROTO  ;

.data
drivePath db "C:\", 0
MAX_PATH dd 260



driveMask DWORD ?
msg1 db "Available Drives:", 0Dh, 0Ah, 0
driveRoot db "A:", 0
szCRLF db 0Dh, 0Ah, 0

.code

diskInfo PROC
pushad
    mov edx, OFFSET msg1
    call WriteString

    ; Get logical drives bitmask
    INVOKE GetLogicalDrives
    mov driveMask, eax

    ; Check each drive (A to Z)
    mov ecx, 0          ; Counter for drive letters (0 = A, 1 = B, etc.)
    mov ebx, driveMask  ; Bitmask to check

check_drive:
    cmp ecx, 26         ; Stop after Z
    jge done

    ; Check if drive exists (bit set in mask)
    test ebx, 1
    jz next_drive

    ; Set drive letter in driveRoot
    mov driveRoot, 'A'
    add driveRoot, cl   ; Adjust to current drive letter

    ; Display drive letter
    mov edx, OFFSET driveRoot
    call WriteString
    mov edx, OFFSET szCRLF
    call WriteString

next_drive:
    shr ebx, 1          ; Shift right to check next bit
    inc ecx             ; Next drive letter
    jmp check_drive

done:
    popad
    ret
diskInfo ENDP
END 







