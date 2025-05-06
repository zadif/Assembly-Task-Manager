include functionHeaders.inc
.386
.model flat, stdcall
.stack 4096

GetLogicalDrives PROTO
GetDiskFreeSpaceExA PROTO :PTR BYTE, :PTR QWORD, :PTR QWORD, :PTR QWORD

.data
drivePath db "A:\", 0
msg1 db "Available Drives and Storage Info (in GB):", 0Dh, 0Ah, 0
msgTotal db " Total: ", 0
msgFree db " Free: ", 0
szCRLF db 0Dh, 0Ah, 0

driveMask DWORD ?
totalSpace QWORD ?
freeSpace QWORD ?
unused QWORD ?

.code

diskInfo PROC
    pushad
    mov edx, OFFSET msg1
    call WriteString

    INVOKE GetLogicalDrives
    mov driveMask, eax

    mov ecx, 0              ; Drive letter index (A-Z)
    mov ebx, driveMask      ; Bitmask of available drives

check_drive:
    cmp ecx, 26
    jge done

    test ebx, 1
    jz skip_drive

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

    ; Total GB = totalSpace / 1GB
    mov eax, dword ptr totalSpace
    mov edx, dword ptr totalSpace + 4
    mov ecx, 1073741824         ; 1 GB in bytes
    call Div64
    mov edx, OFFSET msgTotal
    call WriteString
    call WriteDec
    call CrLf

    ; Free GB = freeSpace / 1GB
    mov eax, dword ptr freeSpace
    mov edx, dword ptr freeSpace + 4
    mov ecx, 1073741824
    call Div64
    mov edx, OFFSET msgFree
    call WriteString
    call WriteDec
    call CrLf
    call CrLf

skip_drive:
    shr ebx, 1              ; Shift mask to next drive
    inc ecx                 ; Move to next drive letter
    jmp check_drive

done:
    popad
    ret
diskInfo ENDP

; 64-bit divide: EDX:EAX / ECX = EAX (result)
Div64 PROC
    push ebx
    mov ebx, ecx        ; Divisor
    div ebx             ; EDX:EAX / ECX
    pop ebx
    ret
Div64 ENDP

END
