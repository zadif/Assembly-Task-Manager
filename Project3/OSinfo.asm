 include functionHeaders.inc 
.386
.model flat, stdcall
.stack 4096


    GetTickCount64 PROTO STDCALL             ; Returns 64-bit ms in EDX:EAX
    GetVersionExA PROTO STDCALL :PTR BYTE    ; Pointer to OSVERSIONINFOEXA struct
    GetUserNameA PROTO STDCALL :PTR BYTE, :PTR DWORD ; Pointer to buffer, pointer to size

     OSVERSIONINFOEXA STRUCT
      dwOSVersionInfoSize DWORD ?
      dwMajorVersion      DWORD ?
      dwMinorVersion      DWORD ?
      dwBuildNumber       DWORD ?
      dwPlatformId        DWORD ?
      szCSDVersion        BYTE 128 dup(?) ; Service Pack string
      ; Other fields exist but are omitted here for brevity
    OSVERSIONINFOEXA ENDS

    ; Constants
    MAX_USERNAME_LEN EQU 256 + 1 ; Standard max username length + null terminator

.data
    osInfo      OSVERSIONINFOEXA <>     ; Structure to hold OS version info
    userNameBuf BYTE MAX_USERNAME_LEN dup(?) ; Buffer for username
    userNameLen DWORD MAX_USERNAME_LEN    ; Variable to hold username buffer size

    ; String Labels
    uptimeCap   db "System Uptime: ", 0
    winVerCap   db "Windows Version: ", 0
    buildCap    db " Build ", 0
    spCap       db " ", 0               ; For spacing before Service Pack
    userCap     db "Logged in User: ", 0
    daysStr     db " days, ", 0
    hoursStr    db " hours, ", 0
    minsStr     db " minutes, ", 0
    secsStr     db " seconds", 0
    verErr      db "Error getting version info.", 0
    userErr     db "Error getting username.", 0
    dotStr      db ".", 0

    ; Uptime calculation variables
    ticks64     QWORD ?                 ; 64-bit tick count (milliseconds)
    totalSecs   QWORD ?
    days        DWORD ?
    hours       DWORD ?
    minutes     DWORD ?
    seconds     DWORD ?
    temp64      QWORD ?                 ; Temporary for division

.code

displayOsInfo PROC
 call displayUptime
    call displayWinVersion
    call displayUserName
    ret
displayOsInfo ENDP

displayUptime PROC PRIVATE
; Calculates and displays system uptime.
;---------------------------------------------------------------------
    ; Get 64-bit tick count (milliseconds) in EDX:EAX
    invoke GetTickCount64
    mov DWORD PTR ticks64[0], eax  ; Store low DWORD
    mov DWORD PTR ticks64[4], edx  ; Store high DWORD

    ; Convert ms to total seconds (ticks64 / 1000)
    ; We'll do 64-bit division by a 32-bit number (1000)
    mov edx, DWORD PTR ticks64[4] ; High DWORD of ticks
    mov eax, DWORD PTR ticks64[0] ; Low DWORD of ticks
    mov ecx, 1000                 ; Divisor
    div ecx                       ; EDX:EAX / ECX => EAX = quotient, EDX = remainder (ms part, ignored)
    ; Now EAX contains low DWORD of total seconds, EDX needs high DWORD
    ; Since 1000 is small, the high dword quotient is likely 0 unless uptime is huge,
    ; but for correctness, we should handle the high part division.
    ; For simplicity here, we'll assume EAX holds the significant part for typical uptimes.
    ; A full 64/32 division involves multiple steps if EDX wasn't 0 initially.
    ; Let's store the result for now.
    ; If we need full 64-bit result:
    ; Store quotient low: mov DWORD PTR totalSecs[0], eax
    ; Now handle high part: mov eax, DWORD PTR ticks64[4]
    ; mov edx, 0 ; Remainder from previous div is not needed here, we start fresh high part
    ; div ecx -> eax = quotient high
    ; mov DWORD PTR totalSecs[4], eax
    ; *Simplified approach for this example:* Assume total seconds fit in 32 bits for display logic below
    mov DWORD PTR totalSecs[0], eax ; Use EAX (low dword of quotient) as total seconds
    mov DWORD PTR totalSecs[4], 0   ; Assume high dword is 0


    ; Calculate days, hours, minutes, seconds from totalSecs (treating as 32-bit for simplicity)
    mov eax, DWORD PTR totalSecs[0] ; Total seconds
    mov edx, 0
    mov ebx, 60
    div ebx       ; EAX = total minutes, EDX = seconds part
    mov seconds, edx

    mov edx, 0
    ; EAX already contains total minutes
    div ebx       ; EAX = total hours, EDX = minutes part
    mov minutes, edx

    mov edx, 0
    ; EAX already contains total hours
    mov ebx, 24
    div ebx       ; EAX = total days, EDX = hours part
    mov hours, edx
    mov days, eax ; Remaining quotient is days

    ; Display Uptime
    mov edx, OFFSET uptimeCap
    call WriteString

    mov eax, days
    call WriteDec
    mov edx, OFFSET daysStr
    call WriteString

    mov eax, hours
    call WriteDec
    mov edx, OFFSET hoursStr
    call WriteString

    mov eax, minutes
    call WriteDec
    mov edx, OFFSET minsStr
    call WriteString

    mov eax, seconds
    call WriteDec
    mov edx, OFFSET secsStr
    call WriteString
    call Crlf

    ret
displayUptime ENDP

;---------------------------------------------------------------------
displayWinVersion PROC PRIVATE
; Gets and displays Windows version information.
;---------------------------------------------------------------------
    ; Prepare structure for GetVersionExA
    mov osInfo.dwOSVersionInfoSize, SIZEOF OSVERSIONINFOEXA ; Set size member

    ; Call GetVersionExA
    invoke GetVersionExA, ADDR osInfo
    test eax, eax                 ; Check return value (non-zero is success)
    jz   versionError             ; Jump if failed

    ; Display Version Info
    mov edx, OFFSET winVerCap
    call WriteString

    mov eax, osInfo.dwMajorVersion
    call WriteDec
    mov edx, OFFSET dotStr
    call WriteString
    mov eax, osInfo.dwMinorVersion
    call WriteDec

    mov edx, OFFSET buildCap
    call WriteString
    mov eax, osInfo.dwBuildNumber
    call WriteDec

    ; Display Service Pack if present
    mov al, osInfo.szCSDVersion[0] ; Check first char of service pack string
    test al, al                    ; Is it null?
    jz   versionDone               ; If null, skip SP display

    mov edx, OFFSET spCap
    call WriteString
    mov edx, OFFSET osInfo.szCSDVersion ; Display SP string
    call WriteString

versionDone:
    call Crlf
    ret

versionError:
    mov edx, OFFSET verErr
    call WriteString
    call Crlf
    ret
displayWinVersion ENDP
;---------------------------------------------------------------------
displayUserName PROC PRIVATE
; Gets and displays the current logged-in username.
;---------------------------------------------------------------------
    ; Prepare parameters for GetUserNameA
    mov userNameLen, MAX_USERNAME_LEN ; Reset size before call

    ; Call GetUserNameA
    invoke GetUserNameA, ADDR userNameBuf, ADDR userNameLen
    test eax, eax                 ; Check return value (non-zero is success)
    jz   userError                ; Jump if failed

    ; Display Username
    mov edx, OFFSET userCap
    call WriteString
    mov edx, OFFSET userNameBuf
    call WriteString
    call Crlf
    ret

userError:
    mov edx, OFFSET userErr
    call WriteString
    call Crlf
    ret
displayUserName ENDP


END