include functionHeaders.inc

.686
.model flat, stdcall
.stack 4096
option casemap:none

; Explicit API declarations
GlobalMemoryStatusEx PROTO :DWORD
GetVersionExA PROTO :DWORD
GetDiskFreeSpaceExA PROTO :DWORD,:DWORD,:DWORD,:DWORD
GetTickCount64 PROTO
GetLogicalDrives PROTO
GetPhysicallyInstalledSystemMemory PROTO :DWORD

string_print MACRO str1
  mov edx, offset str1
  call WriteString
ENDM

; Structures
MEMORYSTATUSEX STRUCT
    dwLength          DWORD ?
    dwMemoryLoad      DWORD ?
    ullTotalPhys      QWORD ?
    ullAvailPhys      QWORD ?
    ullTotalPageFile  QWORD ?
    ullAvailPageFile  QWORD ?
    ullTotalVirtual   QWORD ?
    ullAvailVirtual   QWORD ?
    ullAvailExtendedVirtual QWORD ?
MEMORYSTATUSEX ENDS

OSVERSIONINFO STRUCT
    dwOSVersionInfoSize DWORD ?
    dwMajorVersion      DWORD ?
    dwMinorVersion      DWORD ?
    dwBuildNumber       DWORD ?
    dwPlatformId        DWORD ?
    szCSDVersion        BYTE 128 DUP (?)
OSVERSIONINFO ENDS

.data
cpuBrand    db "CPU: ",0
cpuName     db 49 dup(0)
ramStr      db "RAM (GB): ",0
osStr       db "OS: Windows ",0
diskStr     db "Total Disks: ",0
uptimeStr   db "Uptime (Hrs): ",0
drive       db "C:\",0
gb          dd 1073741824
totalMem    MEMORYSTATUSEX <>
osInfo      OSVERSIONINFO <>
diskSpace   QWORD ?
driveMask   dd ?
msPerHour   dd 3600000
installedRam dd ?  ; For GetPhysicallyInstalledSystemMemory result in KB

; Adding an array
diskSizes   dd 100, 200, 300, 400  ; Example array storing disk sizes in GB (4 elements)

.code
systemSpecs PROC
    ; Get CPU information
    string_print cpuBrand
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

    ; Get RAM size using GetPhysicallyInstalledSystemMemory
    string_print ramStr
    invoke GetPhysicallyInstalledSystemMemory, ADDR installedRam
    test eax, eax
    jnz ramSuccess
    ; Fallback to GlobalMemoryStatusEx if GetPhysicallyInstalledSystemMemory fails
    mov totalMem.dwLength, SIZEOF MEMORYSTATUSEX
    invoke GlobalMemoryStatusEx, ADDR totalMem
    mov eax, DWORD PTR totalMem.ullTotalPhys
    mov edx, DWORD PTR totalMem.ullTotalPhys[4]
    div gb
    call WriteDec
    mov edx, offset ramStr
    call WriteString
    jmp ramDone

ramSuccess:
    mov eax, installedRam   ; RAM in KB
    xor edx, edx
    mov ebx, 1024           ; Convert KB to MB
    div ebx
    mov ebx, 1024           ; Convert MB to GB
    div ebx
    call WriteDec

ramDone:
    call Crlf

    ; Get OS version
    string_print osStr
    mov osInfo.dwOSVersionInfoSize, SIZEOF OSVERSIONINFO
    invoke GetVersionExA, ADDR osInfo
    mov eax, osInfo.dwMajorVersion
    call WriteDec
    mov al, '.'
    call WriteChar
    mov eax, osInfo.dwMinorVersion
    call WriteDec
    call Crlf

    ; Get total number of disks
    string_print diskStr
    invoke GetLogicalDrives
    mov driveMask, eax
    xor ecx, ecx          ; Counter for disks
    mov ebx, 1            ; Bit mask starting from A:
  countLoop:
      test driveMask, ebx   ; Check if bit is set
      jz nextBit            ; If bit is 0, skip
      inc ecx               ; Increment counter if bit is 1
  nextBit:
      shl ebx, 1            ; Move to next bit (next drive)
      cmp ebx, 10000000b    ; Check up to Z: (26 bits)
      jb countLoop
      mov eax, ecx
      call WriteDec
      call Crlf

    ret
systemSpecs ENDP

END