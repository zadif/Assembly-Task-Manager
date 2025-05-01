
include functionHeaders.inc
.386
.model flat, stdcall
.stack 4096
option casemap:none
 

; Manually define what we need to avoid includes
SYSTEM_POWER_STATUS STRUCT
    ACLineStatus      BYTE ?
    BatteryFlag       BYTE ?
    BatteryLifePercent BYTE ?
    Reserved1         BYTE ?
    BatteryLifeTime   DWORD ?
    BatteryFullLifeTime DWORD ?
SYSTEM_POWER_STATUS ENDS

; Declare Windows API function
GetSystemPowerStatus PROTO :DWORD

.data
bStatus SYSTEM_POWER_STATUS <>  ; Battery status structure
pMsg    db "Battery: ",0        ; Text labels
cMsg    db "Charging: ",0
tMsg    db "Mins left: ",0
yes     db "Yes",0
no      db "No",0

.code
BatteryCheck PROC
    ; Get battery status
    invoke GetSystemPowerStatus, ADDR bStatus

    ; Show percentage
    mov edx, OFFSET pMsg
    call WriteString
    movzx eax, bStatus.BatteryLifePercent
    call WriteDec
    mov al, '%'
    call WriteChar
    call Crlf

    ; Show charging status
    mov edx, OFFSET cMsg
    call WriteString
    cmp bStatus.ACLineStatus, 0
    jne charging
    mov edx, OFFSET no
    jmp show
charging:
    mov edx, OFFSET yes
show:
    call WriteString
    call Crlf

    ; Show minutes left
    mov edx, OFFSET tMsg
    call WriteString
    mov eax, bStatus.BatteryLifeTime
    xor edx, edx
    mov ebx, 60
    div ebx
    call WriteDec
    call Crlf

    INVOKE ExitProcess, 0
BatteryCheck  ENDP

END 