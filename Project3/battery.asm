include functionHeaders.inc
.386
.model flat, stdcall
.stack 4096
option casemap:none

SYSTEM_POWER_STATUS STRUCT
    ACLineStatus        BYTE ?
    BatteryFlag         BYTE ?
    BatteryLifePercent  BYTE ?
    Reserved1           BYTE ?
    BatteryLifeTime     DWORD ?
    BatteryFullLifeTime DWORD ?
SYSTEM_POWER_STATUS ENDS

GetSystemPowerStatus PROTO :DWORD

PrintBatteryPercent MACRO labelPtr, valueReg
    mov edx, offset labelPtr
    call WriteString
    movzx eax, valueReg
    call WriteDec
    mov al, '%'
    call WriteChar
    call Crlf
ENDM

PrintStr MACRO str1
   mov edx,offset str1
   call WriteString
ENDM
.data
bStatus SYSTEM_POWER_STATUS <>
pMsg    db "Battery: ",0
cMsg    db "Charging: ",0
tMsg    db "Mins left: ",0
yes     db "Yes",0
no      db "No",0
unk     db "Unknown",0

.code
BatteryCheck PROC
    invoke GetSystemPowerStatus, ADDR bStatus

    ; Show battery %
    ;mov edx, OFFSET pMsg
    ;call WriteString
    ;movzx eax, bStatus.BatteryLifePercent
    ;call WriteDec
    PrintBatteryPercent pMsg, bStatus.BatteryLifePercent
   
    ; Show charging status
    PrintStr cMsg
    cmp bStatus.ACLineStatus, 0
    jne charging
    mov edx, OFFSET no
    jmp showCharge
charging:
    mov edx, OFFSET yes
showCharge:
    call WriteString
    call Crlf

    ; Show time left
    PrintStr tMsg
    mov eax, bStatus.BatteryLifeTime
    cmp eax, 0FFFFFFFFh
    je unknown
    xor edx, edx
    mov ebx, 60
    div ebx
    call WriteDec
    call Crlf
    jmp done
unknown:
    PrintStr unk
    call Crlf

done:
    invoke ExitProcess, 0
BatteryCheck ENDP

END
