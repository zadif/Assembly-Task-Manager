include functionHeaders.inc


.686
.model flat, stdcall
.stack 4096
option casemap:none

; Explicit API declarations
GlobalMemoryStatusEx PROTO :DWORD
GetVersion PROTO
GetDiskFreeSpaceExA PROTO :DWORD,:DWORD,:DWORD,:DWORD
GetTickCount PROTO
string_print MACRO str1
  mov edx,offset str1
  call WriteString
ENDM
.data
cpuBrand    db "CPU: ",0
cpuName     db 49 dup(0)
ramStr      db "RAM (GB): ",0
osStr       db "OS: Windows ",0
diskStr     db "Disk (GB): ",0
uptimeStr   db "Uptime (Hrs): ",0
drive       db "C:\",0
gb          dd 1073741824
totalMem    dq ?

.code
systemSpecs PROC
    ; Get CPU information
    string_print cpuBrand
    
    ; Get CPU brand string
    mov eax, 80000002h
    cpuid
    mov DWORD PTR [cpuName], eax
    mov DWORD PTR [cpuName+4], ebx
    mov DWORD PTR [cpuName+8], ecx
    mov DWORD PTR [cpuName+12], edx
    
    mov eax, 80000003h
    cpuid
    mov DWORD PTR [cpuName+16], eax
    mov DWORD PTR [cpuName+20], ebx
    mov DWORD PTR [cpuName+24], ecx
    mov DWORD PTR [cpuName+28], edx
    
    mov eax, 80000004h
    cpuid
    mov DWORD PTR [cpuName+32], eax
    mov DWORD PTR [cpuName+36], ebx
    mov DWORD PTR [cpuName+40], ecx
    mov DWORD PTR [cpuName+44], edx
    
    string_print cpuName
    call Crlf

    ; Get RAM size
    string_print ramStr
    invoke GlobalMemoryStatusEx, ADDR totalMem
    mov eax, DWORD PTR [totalMem]
    xor edx, edx
    div gb
    call WriteDec
    call Crlf

    ; Get OS version
    string_print osStr
    invoke GetVersion
    shr eax, 8
    and eax, 0FFh
    call WriteDec
    call Crlf

    ; Get disk space
    string_print diskStr
    invoke GetDiskFreeSpaceExA, ADDR drive, 0, ADDR totalMem, 0
    mov eax, DWORD PTR [totalMem]
    xor edx, edx
    div gb
    call WriteDec
    call Crlf

    ; Get uptime
    string_print uptimeStr
    invoke GetTickCount
    mov ebx, 3600000
    xor edx, edx
    div ebx
    call WriteDec
    call Crlf

    ret
systemSpecs ENDP

END