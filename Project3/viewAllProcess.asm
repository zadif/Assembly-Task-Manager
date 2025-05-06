include functionHeaders.inc
.386
.model flat, stdcall
.stack 4096

; API functions
CreateToolhelp32Snapshot PROTO, :DWORD,:DWORD
Process32First PROTO, :DWORD,:DWORD
Process32Next PROTO, :DWORD,:DWORD
CloseHandle PROTO, :DWORD
printstr MACRO str1
  mov edx, offset str1
  call WriteString
ENDM
.data
snap   dd 0
pe     db 556 dup(0)  ; PROCESSENTRY32 buffer
pText  db "PID: ",0
eText  db "  EXE: ",0

.code
viewAllProcess proc
    ; Create snapshot
    invoke CreateToolhelp32Snapshot, 2, 0  ; 2 = TH32CS_SNAPPROCESS
    cmp eax, -1
    je done
    mov snap, eax

    ; Set structure size (first 4 bytes)
    mov dword ptr [pe], 556

    ; Get first process
    invoke Process32First, snap, addr pe
    test eax, eax
    jz close

show:
    ; Display PID (offset 8)
    printstr pText
    mov eax, dword ptr [pe+8]  ; FIXED: Added DWORD PTR
    call WriteDec

    ; Display EXE name (offset 36)
    printstr eText
    lea edx, [pe+36]  ; szExeFile offset
    call WriteString
    call Crlf

    ; Next process
    invoke Process32Next, snap, addr pe
    test eax, eax
    jnz show

close:
    invoke CloseHandle, snap
done:
    ret
viewAllProcess endp

END