; NOVO OS - ядро
bits 32
org 0x8000

VGAMEM  equ 0xA0000
CANVAS  equ 0x200000
FONT    equ 0x300000
W       equ 320
H       equ 200
TOPH    equ 20
DOCKY   equ 176
DOCKH   equ 24
DOCKW   equ 64

start:
    call grab_font
    call mouse_init
    call disk_check
    call disk_identify
    call cfg_load
    call rtc_read
    mov dword [fm_sel], -1
    call draw_screen
    call flip
    call draw_cursor

.loop:
    inc dword [ticks]
    cmp dword [ticks], 500000
    jb .no_tick
    mov dword [ticks], 0
    call rtc_read
    call draw_screen
    call flip
    call draw_cursor
.no_tick:
    in al, 0x64
    test al, 1
    jz .loop
    test al, 0x20
    jz .notmouse
    call read_packet

    cmp byte [drag_icon], 255
    je .no_ico_drag
    cmp byte [mbtn], 1
    jne .stop_ico_drag
    movzx eax, byte [drag_icon]
    mov edx, eax
    shl eax, 2
    add eax, iconx
    mov ebx, [mx]
    sub ebx, [drag_id_x]
    mov [eax], ebx
    mov eax, edx
    shl eax, 2
    add eax, icony
    mov ebx, [my]
    sub ebx, [drag_id_y]
    mov [eax], ebx
    mov byte [drag_ico_moved], 1
    jmp .redraw
.stop_ico_drag:
    cmp byte [drag_ico_moved], 0
    jne .no_ico_click
    movzx eax, byte [drag_icon]
    cmp eax, 0
    jne .ico_c1
    mov byte [npopen], 1
    mov byte [npmin], 0
    mov byte [focus], 0
    call np_load
    jmp .ico_done
.ico_c1:
    cmp eax, 1
    jne .ico_c2
    mov byte [clopen], 1
    mov byte [clmin], 0
    mov byte [focus], 1
    jmp .ico_done
.ico_c2:
    mov byte [aboutopen], 1
.ico_done:
.no_ico_click:
    mov byte [drag_icon], 255
    jmp .redraw
.no_ico_drag:

    cmp byte [cldrag], 1
    jne .nocldrag
    cmp byte [mbtn], 1
    jne .stopcl
    mov eax, [mx]
    sub eax, [cldx]
    mov [clx], eax
    mov eax, [my]
    sub eax, [cldy]
    mov [cly], eax
    jmp .redraw
.stopcl:
    mov byte [cldrag], 0
.nocldrag:
    cmp byte [clopen], 1
    jne .noclstart
    cmp byte [clmin], 1
    je .noclstart
    cmp byte [mbtn], 1
    jne .noclstart
    cmp byte [mprev], 1
    je .noclstart
    call over_cltitle
    test al, al
    jz .noclstart
    mov byte [focus], 1
    mov byte [cldrag], 1
    mov eax, [mx]
    sub eax, [clx]
    mov [cldx], eax
    mov eax, [my]
    sub eax, [cly]
    mov [cldy], eax
    jmp .redraw
.noclstart:

    cmp byte [swdrag], 1
    jne .noswdrag
    cmp byte [mbtn], 1
    jne .stopsw
    mov eax, [mx]
    sub eax, [swdx]
    mov [swx], eax
    mov eax, [my]
    sub eax, [swdy]
    mov [swy], eax
    jmp .redraw
.stopsw:
    mov byte [swdrag], 0
.noswdrag:
    cmp byte [setopen], 1
    jne .noswstart
    cmp byte [setmin], 1
    je .noswstart
    cmp byte [mbtn], 1
    jne .noswstart
    cmp byte [mprev], 1
    je .noswstart
    call over_swtitle
    test al, al
    jz .noswstart
    mov byte [focus], 2
    mov byte [swdrag], 1
    mov eax, [mx]
    sub eax, [swx]
    mov [swdx], eax
    mov eax, [my]
    sub eax, [swy]
    mov [swdy], eax
    jmp .redraw
.noswstart:

    cmp byte [npdrag], 1
    jne .nodrag
    cmp byte [mbtn], 1
    jne .stopdrag
    mov eax, [mx]
    sub eax, [npdx]
    mov [npx], eax
    mov eax, [my]
    sub eax, [npdy]
    mov [npy], eax
    jmp .redraw
.stopdrag:
    mov byte [npdrag], 0
.nodrag:
    cmp byte [npopen], 1
    jne .nostart
    cmp byte [npmin], 1
    je .nostart
    cmp byte [mbtn], 1
    jne .nostart
    cmp byte [mprev], 1
    je .nostart
    call over_nptitle
    test al, al
    jz .nostart
    mov byte [focus], 0
    mov byte [npdrag], 1
    mov eax, [mx]
    sub eax, [npx]
    mov [npdx], eax
    mov eax, [my]
    sub eax, [npy]
    mov [npdy], eax
.nostart:

    cmp byte [tdrag], 1
    jne .notdrag
    cmp byte [mbtn], 1
    jne .stoptd
    mov eax, [mx]
    sub eax, [tdx]
    mov [tx], eax
    mov eax, [my]
    sub eax, [tdy]
    mov [ty], eax
    jmp .redraw
.stoptd:
    mov byte [tdrag], 0
.notdrag:
    cmp byte [topen], 1
    jne .notstart
    cmp byte [tmin], 1
    je .notstart
    cmp byte [mbtn], 1
    jne .notstart
    cmp byte [mprev], 1
    je .notstart
    call over_ttitle
    test al, al
    jz .notstart
    mov byte [focus], 3
    mov byte [tdrag], 1
    mov eax, [mx]
    sub eax, [tx]
    mov [tdx], eax
    mov eax, [my]
    sub eax, [ty]
    mov [tdy], eax
.notstart:

    cmp byte [fmdrag], 1
    jne .nofmdrag
    cmp byte [mbtn], 1
    jne .stopfmd
    mov eax, [mx]
    sub eax, [fmdx]
    mov [fmx], eax
    mov eax, [my]
    sub eax, [fmdy]
    mov [fmy], eax
    jmp .redraw
.stopfmd:
    mov byte [fmdrag], 0
.nofmdrag:
    cmp byte [fmopen], 1
    jne .nofmstart
    cmp byte [fmmin], 1
    je .nofmstart
    cmp byte [mbtn], 1
    jne .nofmstart
    cmp byte [mprev], 1
    je .nofmstart
    call over_fmtitle
    test al, al
    jz .nofmstart
    mov byte [focus], 5
    mov byte [fmdrag], 1
    mov eax, [mx]
    sub eax, [fmx]
    mov [fmdx], eax
    mov eax, [my]
    sub eax, [fmy]
    mov [fmdy], eax
.nofmstart:

    cmp byte [mbtn], 1
    jne .no_ico_start
    cmp byte [mprev], 1
    je .no_ico_start
    call desktopicons_at_mouse
    cmp eax, -1
    je .no_ico_start
    push eax
    call point_in_window
    test al, al
    pop eax
    jnz .no_ico_start
    mov [drag_icon], al
    mov byte [drag_ico_moved], 0
    movzx edx, al
    shl edx, 2
    add edx, iconx
    mov ebx, [mx]
    sub ebx, [edx]
    mov [drag_id_x], ebx
    movzx edx, al
    shl edx, 2
    add edx, icony
    mov ebx, [my]
    sub ebx, [edx]
    mov [drag_id_y], ebx
.no_ico_start:

    mov byte [setdown], 0
    mov byte [xdown], 0
    mov byte [npxdown], 0
    mov byte [clxdown], 0
    mov byte [cldown], 255
    mov byte [swmindown], 0
    mov byte [clmindown], 0
    mov byte [npmindown], 0
    mov byte [tmindown], 0
    mov byte [txdown], 0
    mov byte [npfdown], 0
    mov byte [tfdown], 0
    mov byte [fmxdown], 0
    mov byte [fmmindown], 0
    cmp byte [mbtn], 1
    jne .noclheld
    cmp byte [clopen], 1
    jne .noclheld
    cmp byte [clmin], 1
    je .noclheld
    call over_clclose
    test al, al
    jz .clmin1
    mov byte [clxdown], 1
    jmp .clmin_done
.clmin1:
    call over_clmin
    test al, al
    jz .clmin_done
    mov byte [clmindown], 1
.clmin_done:
    cmp byte [clopen], 1
    jne .noclheld
    call calc_btn_at
    cmp eax, -1
    je .noclheld
    mov [cldown], al
.noclheld:
    cmp byte [mbtn], 1
    jne .notheld
    call over_setbtn
    test al, al
    jz .notset
    mov byte [setdown], 1
.notset:
    cmp byte [setopen], 1
    jne .notsw
    call over_closebtn
    test al, al
    jz .notswmin
    mov byte [xdown], 1
    jmp .notsw
.notswmin:
    call over_swmin
    test al, al
    jz .notsw
    mov byte [swmindown], 1
.notsw:
    cmp byte [npopen], 1
    jne .notnpmin
    call over_npclose
    test al, al
    jz .notnpf
    mov byte [npxdown], 1
    jmp .notnpmin
.notnpf:
    call over_npfull
    test al, al
    jz .notnpmin2
    mov byte [npfdown], 1
    jmp .notnpmin
.notnpmin2:
    call over_npmin
    test al, al
    jz .notnpmin
    mov byte [npmindown], 1
.notnpmin:
    cmp byte [topen], 1
    jne .nottmin
    call over_tclose
    test al, al
    jz .nottf
    mov byte [txdown], 1
    jmp .nottmin
.nottf:
    call over_tfull
    test al, al
    jz .nottmin2
    mov byte [tfdown], 1
    jmp .nottmin
.nottmin2:
    call over_tmin
    test al, al
    jz .nottmin
    mov byte [tmindown], 1
.nottmin:
    cmp byte [fmopen], 1
    jne .nofmmin
    call over_fmclose
    test al, al
    jz .nofmmin2
    mov byte [fmxdown], 1
    jmp .nofmmin
.nofmmin2:
    call over_fmmin
    test al, al
    jz .nofmmin
    mov byte [fmmindown], 1
.nofmmin:
.notheld:

    mov al, [mbtn]
    mov ah, [mprev]
    mov [mprev], al
    test ah, ah
    jz .nopress
    test al, al
    jnz .nopress
    call on_click
    jmp .redraw
.nopress:

    mov al, [mrbtn]
    mov ah, [mrprev]
    mov [mrprev], al
    test ah, ah
    jz .norpress
    test al, al
    jnz .norpress
    call on_rclick
    jmp .redraw
.norpress:

    call dock_at_mouse
    mov [sel], eax

.redraw:
    call draw_screen
    call flip
    call draw_cursor
    jmp .loop
.notmouse:
    in al, 0x60
    cmp al, 0x3B
    jne .hk_f2
    mov byte [topen], 1
    mov byte [tmin], 0
    mov byte [focus], 3
    jmp .loop
.hk_f2:
    cmp al, 0x3C
    jne .hk_f3
    mov byte [npopen], 1
    mov byte [npmin], 0
    mov byte [focus], 0
    call np_load
    jmp .loop
.hk_f3:
    cmp al, 0x3D
    jne .hk_f4
    mov byte [clopen], 1
    mov byte [clmin], 0
    mov byte [focus], 1
    jmp .loop
.hk_f4:
    cmp al, 0x3E
    jne .hk_esc
    mov byte [fmopen], 1
    mov byte [fmmin], 0
    mov byte [focus], 5
    jmp .loop
.hk_esc:
    cmp al, 0x01
    jne .hk_shift
    cmp byte [focus], 0
    jne .esc1
    mov byte [npopen], 0
    jmp .loop
.esc1:
    cmp byte [focus], 1
    jne .esc2
    mov byte [clopen], 0
    jmp .loop
.esc2:
    cmp byte [focus], 2
    jne .esc3
    mov byte [setopen], 0
    jmp .loop
.esc3:
    cmp byte [focus], 3
    jne .esc4
    mov byte [topen], 0
    jmp .loop
.esc4:
    cmp byte [focus], 5
    jne .loop
    mov byte [fmopen], 0
    jmp .loop
.hk_shift:
    cmp al, 0x2A
    jne .notshl
    mov byte [shift], 1
    jmp .loop
.notshl:
    cmp al, 0xAA
    jne .notshlr
    mov byte [shift], 0
    jmp .loop
.notshlr:
    cmp al, 0x36
    jne .notshr
    mov byte [shift], 1
    jmp .loop
.notshr:
    cmp al, 0xB6
    jne .notshrr
    mov byte [shift], 0
    jmp .loop
.notshrr:
    cmp al, 0x1D
    jne .notctrldown
    mov byte [ctrl], 1
    jmp .loop
.notctrldown:
    cmp al, 0x9D
    jne .notctrlup
    mov byte [ctrl], 0
    jmp .loop
.notctrlup:
    cmp byte [topen], 1
    jne .not_term_key
    cmp byte [tmin], 1
    je .not_term_key
    test al, 0x80
    jnz .loop
    call key_decode
    test al, al
    jz .loop
    call term_key
    call draw_screen
    call flip
    call draw_cursor
    jmp .loop
.not_term_key:
    cmp byte [npopen], 1
    jne .not_np_key
    cmp byte [npmin], 1
    je .not_np_key
    test al, 0x80
    jnz .loop
    call key_decode
    test al, al
    jz .loop
    call np_key
    call draw_screen
    call flip
    call draw_cursor
    jmp .loop
.not_np_key:
    cmp byte [fmopen], 1
    jne .loop
    cmp byte [fmmin], 1
    je .loop
    test al, 0x80
    jnz .loop
    cmp al, 0x53
    jne .not_del_key
    call fm_delete
    call draw_screen
    call flip
    call draw_cursor
    jmp .loop
.not_del_key:
    cmp al, 0x1C
    jne .not_enter_key
    call fm_open_selected
    call draw_screen
    call flip
    call draw_cursor
    jmp .loop
.not_enter_key:
    call key_decode
    test al, al
    jz .loop
    call fm_key
    call draw_screen
    call flip
    call draw_cursor
    jmp .loop

disk_identify:
    pusha
    mov dx, DISKPORT + 7
    mov al, 0xEC
    out dx, al
    mov dx, DISKPORT + 7
    in al, dx
    in al, dx
    in al, dx
    in al, dx
    mov dx, DISKPORT + 7
    mov ecx, 0x400000
.wait:
    in al, dx
    test al, 0x80
    jz .not_busy
    dec ecx
    jnz .wait
    jmp .fail
.not_busy:
    test al, 0x08
    jz .fail
    mov dx, DISKPORT
    mov edi, idbuf
    mov ecx, 256
    cld
    rep insw
    mov esi, idbuf + 54
    mov edi, disk_model
    mov ecx, 20
.model_loop:
    mov al, [esi+1]
    mov [edi], al
    inc edi
    mov al, [esi]
    mov [edi], al
    inc edi
    add esi, 2
    dec ecx
    jnz .model_loop
    mov byte [edi], 0
    mov edi, disk_model + 39
.trim:
    cmp edi, disk_model
    jb .trimmed
    cmp byte [edi], ' '
    jne .trimmed
    mov byte [edi], 0
    dec edi
    jmp .trim
.trimmed:
    movzx eax, word [idbuf + 120]
    movzx ebx, word [idbuf + 122]
    shl ebx, 16
    or eax, ebx
    shr eax, 1
    mov [disk_size_val], eax
    mov byte [disk_size_unit], 0
    cmp eax, 1024
    jb .done
    shr eax, 10
    mov [disk_size_val], eax
    mov byte [disk_size_unit], 1
    cmp eax, 1024
    jb .done
    shr eax, 10
    mov [disk_size_val], eax
    mov byte [disk_size_unit], 2
.done:
    popa
    ret
.fail:
    mov byte [disk_model], 0
    mov dword [disk_size_val], 0
    mov byte [disk_size_unit], 0
    popa
    ret

fmt_num:
    pusha
    mov ebx, 10
    mov esi, numbuf
    xor ecx, ecx
.digits:
    xor edx, edx
    div ebx
    add dl, '0'
    mov [esi], dl
    inc esi
    inc ecx
    test eax, eax
    jnz .digits
    dec esi
.reverse:
    cmp esi, numbuf
    jb .done
    mov al, [esi]
    mov [edi], al
    inc edi
    dec esi
    jmp .reverse
.done:
    mov byte [edi], 0
    popa
    ret

point_in_window:
    cmp byte [topen], 1
    jne .p1
    cmp byte [tmin], 1
    je .p1
    mov eax, [mx]
    sub eax, [tx]
    cmp eax, 0
    jb .p1
    cmp eax, TW
    ja .p1
    mov eax, [my]
    sub eax, [ty]
    cmp eax, 0
    jb .p1
    cmp eax, TH
    ja .p1
    mov al, 1
    ret
.p1:
    cmp byte [npopen], 1
    jne .p2
    cmp byte [npmin], 1
    je .p2
    mov eax, [mx]
    sub eax, [npx]
    cmp eax, 0
    jb .p2
    cmp eax, NPW
    ja .p2
    mov eax, [my]
    sub eax, [npy]
    cmp eax, 0
    jb .p2
    cmp eax, NPH
    ja .p2
    mov al, 1
    ret
.p2:
    cmp byte [clopen], 1
    jne .p3
    cmp byte [clmin], 1
    je .p3
    mov eax, [mx]
    sub eax, [clx]
    cmp eax, 0
    jb .p3
    cmp eax, CLW
    ja .p3
    mov eax, [my]
    sub eax, [cly]
    cmp eax, 0
    jb .p3
    cmp eax, CLH
    ja .p3
    mov al, 1
    ret
.p3:
    cmp byte [setopen], 1
    jne .p4
    cmp byte [setmin], 1
    je .p4
    mov eax, [mx]
    sub eax, [swx]
    cmp eax, 0
    jb .p4
    cmp eax, SWW
    ja .p4
    mov eax, [my]
    sub eax, [swy]
    cmp eax, 0
    jb .p4
    cmp eax, 130
    ja .p4
    mov al, 1
    ret
.p4:
    cmp byte [fmopen], 1
    jne .p5
    cmp byte [fmmin], 1
    je .p5
    mov eax, [mx]
    sub eax, [fmx]
    cmp eax, 0
    jb .p5
    cmp eax, FMW
    ja .p5
    mov eax, [my]
    sub eax, [fmy]
    cmp eax, 0
    jb .p5
    cmp eax, FMH
    ja .p5
    mov al, 1
    ret
.p5:
    cmp byte [aboutopen], 1
    jne .pno
    mov eax, [mx]
    sub eax, [abx]
    cmp eax, 0
    jb .pno
    cmp eax, ABW
    ja .pno
    mov eax, [my]
    sub eax, [aby]
    cmp eax, 0
    jb .pno
    cmp eax, ABH
    ja .pno
    mov al, 1
    ret
.pno:
    xor al, al
    ret

rtc_read:
    pusha
.wait:
    mov al, 0x0A
    out 0x70, al
    in al, 0x71
    test al, 0x80
    jnz .wait
    mov al, 0x0B
    out 0x70, al
    in al, 0x71
    mov [rtc_mode], al
    mov al, 0x04
    out 0x70, al
    in al, 0x71
    mov [rtc_hour], al
    mov al, 0x02
    out 0x70, al
    in al, 0x71
    mov [rtc_min], al
    mov al, 0x07
    out 0x70, al
    in al, 0x71
    mov [rtc_day], al
    mov al, 0x08
    out 0x70, al
    in al, 0x71
    mov [rtc_mon], al
    mov al, [rtc_hour]
    and al, 0x80
    mov [rtc_pm], al
    test byte [rtc_mode], 4
    jnz .no_bcd
    mov al, [rtc_hour]
    and al, 0x7F
    call bcd2bin
    mov [rtc_hour], al
    mov al, [rtc_min]
    call bcd2bin
    mov [rtc_min], al
    mov al, [rtc_day]
    call bcd2bin
    mov [rtc_day], al
    mov al, [rtc_mon]
    call bcd2bin
    mov [rtc_mon], al
.no_bcd:
    test byte [rtc_mode], 2
    jnz .h24
    cmp byte [rtc_pm], 0
    je .h24
    mov al, [rtc_hour]
    cmp al, 12
    jae .h24
    add al, 12
    mov [rtc_hour], al
.h24:
    movzx eax, byte [rtc_hour]
    add eax, 7
    cmp eax, 24
    jl .tz_ok
    sub eax, 24
.tz_ok:
    mov [rtc_hour], al
    cmp byte [rtc_hour], 23
    jbe .hok
    mov byte [rtc_hour], 0
.hok:
    cmp byte [rtc_min], 59
    jbe .mok
    mov byte [rtc_min], 0
.mok:
    popa
    ret

bcd2bin:
    push ebx
    push ecx
    mov bl, al
    and al, 0x0F
    shr bl, 4
    mov cl, bl
    shl bl, 3
    add bl, cl
    add bl, cl
    add al, bl
    pop ecx
    pop ebx
    ret

shutdown:
    mov dx, 0x604
    mov ax, 0x2000
    out dx, ax
    mov dx, 0xB004
    mov ax, 0x2000
    out dx, ax
    cli
.halt:
    hlt
    jmp .halt

restart:
    cli
    mov al, 0xFE
    out 0x64, al
.halt:
    hlt
    jmp .halt

DISKPORT equ 0x1F0

disk_wait:
    push edx
    push ecx
    mov ecx, 0x400000
    mov dx, DISKPORT + 7
.l:
    in al, dx
    test al, 0x80
    jz .ok
    dec ecx
    jnz .l
    mov byte [diskerr], 1
.ok:
    pop ecx
    pop edx
    ret

read_sector:
    pusha
    mov byte [diskerr], 0
    push eax
    mov dx, DISKPORT + 6
    shr eax, 24
    and al, 0x0F
    or al, 0xE0
    out dx, al
    pop eax
    push eax
    mov dx, DISKPORT + 7
    in al, dx
    in al, dx
    in al, dx
    in al, dx
    pop eax
    mov dx, DISKPORT + 2
    push eax
    mov al, 1
    out dx, al
    pop eax
    push eax
    mov dx, DISKPORT + 3
    out dx, al
    pop eax
    push eax
    mov dx, DISKPORT + 4
    shr eax, 8
    out dx, al
    pop eax
    push eax
    mov dx, DISKPORT + 5
    shr eax, 16
    out dx, al
    pop eax
    mov dx, DISKPORT + 7
    mov al, 0x20
    out dx, al
    push ecx
    mov ecx, 0x400000
    mov dx, DISKPORT + 7
.ready:
    in al, dx
    test al, 0x80
    jnz .again
    test al, 0x01
    jnz .failed
    test al, 0x08
    jnz .gotready
    test al, 0x20
    jnz .failed
.again:
    dec ecx
    jnz .ready
.failed:
    pop ecx
    mov byte [diskerr], 1
    jmp .done
.gotready:
    pop ecx
    mov dx, DISKPORT
    mov ecx, 256
    cld
    rep insw
.done:
    popa
    ret

write_sector:
    pusha
    mov byte [diskerr], 0
    push eax
    mov dx, DISKPORT + 6
    shr eax, 24
    and al, 0x0F
    or al, 0xE0
    out dx, al
    pop eax
    push eax
    mov dx, DISKPORT + 7
    in al, dx
    in al, dx
    in al, dx
    in al, dx
    pop eax
    mov dx, DISKPORT + 2
    push eax
    mov al, 1
    out dx, al
    pop eax
    push eax
    mov dx, DISKPORT + 3
    out dx, al
    pop eax
    push eax
    mov dx, DISKPORT + 4
    shr eax, 8
    out dx, al
    pop eax
    push eax
    mov dx, DISKPORT + 5
    shr eax, 16
    out dx, al
    pop eax
    mov dx, DISKPORT + 7
    mov al, 0x30
    out dx, al
    push ecx
    mov ecx, 0x400000
    mov dx, DISKPORT + 7
.ready:
    in al, dx
    test al, 0x80
    jnz .again
    test al, 0x01
    jnz .failed
    test al, 0x08
    jnz .gotready
.again:
    dec ecx
    jnz .ready
.failed:
    pop ecx
    mov byte [diskerr], 1
    jmp .done
.gotready:
    pop ecx
    mov dx, DISKPORT
    mov ecx, 256
    cld
    rep outsw
    mov dx, DISKPORT + 7
    mov al, 0xE7
    out dx, al
    call disk_wait
.done:
    popa
    ret

DIRSEC   equ 200
DATASEC  equ 201
MAXFILES equ 16
ENTSZ    equ 32

load_dir:
    pusha
    mov eax, DIRSEC
    mov edi, dirbuf
    call read_sector
    popa
    ret

save_dir:
    pusha
    mov eax, DIRSEC
    mov esi, dirbuf
    call write_sector
    popa
    ret

find_file:
    push ebx
    push ecx
    push edx
    xor ebx, ebx
.l:
    cmp ebx, MAXFILES
    jae .none
    mov eax, ebx
    imul eax, ENTSZ
    add eax, dirbuf
    cmp byte [eax], 0
    je .next
    push esi
    mov edx, eax
    xor ecx, ecx
.cmp:
    mov al, [esi + ecx]
    cmp al, [edx + ecx]
    jne .nomatch
    test al, al
    jz .match
    inc ecx
    cmp ecx, 12
    jb .cmp
.match:
    pop esi
    mov eax, ebx
    jmp .done
.nomatch:
    pop esi
.next:
    inc ebx
    jmp .l
.none:
    mov eax, -1
.done:
    pop edx
    pop ecx
    pop ebx
    ret

find_free:
    push ebx
    xor ebx, ebx
.l:
    cmp ebx, MAXFILES
    jae .none
    mov eax, ebx
    imul eax, ENTSZ
    add eax, dirbuf
    cmp byte [eax], 0
    je .found
    inc ebx
    jmp .l
.found:
    mov eax, ebx
    pop ebx
    ret
.none:
    mov eax, -1
    pop ebx
    ret

save_file:
    pusha
    mov [savelen], ecx
    mov [savesrc], edi
    mov [savename], esi
    call load_dir
    cmp byte [diskerr], 0
    jne .fail
    mov esi, [savename]
    call find_file
    cmp eax, -1
    jne .haveent
    call find_free
    cmp eax, -1
    je .fail
.haveent:
    mov [saveent], eax
    imul eax, ENTSZ
    add eax, dirbuf
    mov edi, eax
    mov esi, [savename]
    mov ecx, 12
    cld
.cpname:
    mov al, [esi]
    mov [edi], al
    test al, al
    jz .padname
    inc esi
    inc edi
    dec ecx
    jnz .cpname
    jmp .lenput
.padname:
    mov byte [edi], 0
    inc edi
    dec ecx
    jnz .padname
.lenput:
    mov eax, [saveent]
    imul eax, ENTSZ
    add eax, dirbuf
    mov ecx, [savelen]
    mov [eax + 12], ecx
    mov ecx, [saveent]
    add ecx, DATASEC
    mov [eax + 16], ecx
    mov edi, secbuf
    mov ecx, 512
    xor al, al
    rep stosb
    mov esi, [savesrc]
    mov edi, secbuf
    mov ecx, [savelen]
    cmp ecx, 512
    jbe .cpdata
    mov ecx, 512
.cpdata:
    rep movsb
    mov eax, [saveent]
    add eax, DATASEC
    mov esi, secbuf
    call write_sector
    cmp byte [diskerr], 0
    jne .fail
    call save_dir
    cmp byte [diskerr], 0
    jne .fail
    popa
    mov al, 1
    ret
.fail:
    popa
    xor al, al
    ret

load_file:
    push esi
    push edi
    call load_dir
    cmp byte [diskerr], 0
    jne .fail
    pop edi
    pop esi
    push esi
    push edi
    call find_file
    cmp eax, -1
    je .fail
    imul eax, ENTSZ
    add eax, dirbuf
    mov ecx, [eax + 12]
    mov [loadlen], ecx
    mov eax, [eax + 16]
    pop edi
    push edi
    call read_sector
    cmp byte [diskerr], 0
    jne .fail
    pop edi
    pop esi
    mov ecx, [loadlen]
    mov al, 1
    ret
.fail:
    pop edi
    pop esi
    xor ecx, ecx
    xor al, al
    ret

disk_check:
    pusha
    xor eax, eax
    mov edi, secbuf
    call read_sector
    cmp byte [diskerr], 0
    jne .bad
    cmp byte [secbuf + 510], 0x55
    jne .bad
    cmp byte [secbuf + 511], 0xAA
    jne .bad
    mov dword [p_diskmsg], t_diskok
    jmp .e
.bad:
    mov dword [p_diskmsg], t_diskbad
.e:
    popa
    ret

ITEMS   equ 6
MENUX   equ 2
MENUW   equ 34
MENUH   equ 16
SALLX   equ 40
SALLW   equ 34
SETX    equ W - 22
SETY    equ 1
SETW    equ 18
SETH    equ 18

draw_screen:
    cmp byte [bgmode], 1
    jne .try2
    mov dword [rx], 0
    mov dword [ry], 0
    mov dword [rw], W
    mov dword [rh], H
    mov al, [bgcol1]
    mov [rc], al
    call rect
    jmp .bg_done
.try2:
    cmp byte [bgmode], 2
    jne .try3
    mov dword [rx], 0
    mov dword [ry], 0
    mov dword [rw], W
    mov dword [rh], 100
    mov al, [bgcol1]
    mov [rc], al
    call rect
    mov dword [rx], 0
    mov dword [ry], 100
    mov dword [rw], W
    mov dword [rh], 100
    mov al, [bgcol2]
    mov [rc], al
    call rect
    jmp .bg_done
.try3:
    mov dword [rx], 0
    mov dword [ry], 0
    mov dword [rw], W
    mov dword [rh], 66
    mov al, [bgcol1]
    mov [rc], al
    call rect
    mov dword [rx], 0
    mov dword [ry], 66
    mov dword [rw], W
    mov dword [rh], 67
    mov al, [bgcol2]
    mov [rc], al
    call rect
    mov dword [rx], 0
    mov dword [ry], 133
    mov dword [rw], W
    mov dword [rh], H-133
    mov al, [bgcol3]
    mov [rc], al
    call rect
.bg_done:

    call draw_desktopicons

    cmp byte [focus], 0
    je .f_np
    cmp byte [focus], 1
    je .f_cl
    cmp byte [focus], 2
    je .f_set
    cmp byte [focus], 3
    je .f_term
    cmp byte [focus], 5
    je .f_fm
    call draw_settings
    call draw_notepad
    call draw_calc
    call draw_term
    call draw_fm
    jmp .windows_done
.f_np:
    call draw_settings
    call draw_calc
    call draw_term
    call draw_fm
    call draw_notepad
    jmp .windows_done
.f_cl:
    call draw_settings
    call draw_notepad
    call draw_term
    call draw_fm
    call draw_calc
    jmp .windows_done
.f_set:
    call draw_notepad
    call draw_calc
    call draw_term
    call draw_fm
    call draw_settings
    jmp .windows_done
.f_term:
    call draw_settings
    call draw_notepad
    call draw_calc
    call draw_fm
    call draw_term
    jmp .windows_done
.f_fm:
    call draw_settings
    call draw_notepad
    call draw_calc
    call draw_term
    call draw_fm
.windows_done:

    call draw_about

    mov dword [rx], 0
    mov dword [ry], 0
    mov dword [rw], W
    mov dword [rh], TOPH
    mov byte [rc], 7
    call rect
    mov dword [rx], 0
    mov dword [ry], 0
    mov dword [rw], W
    mov dword [rh], 1
    mov byte [rc], 15
    call rect
    mov dword [rx], 0
    mov dword [ry], TOPH - 1
    mov dword [rw], W
    mov dword [rh], 1
    mov byte [rc], 8
    call rect

    mov dword [rx], MENUX
    mov dword [ry], SETY
    mov dword [rw], MENUW
    mov dword [rh], MENUH
    mov byte [rc], 7
    call rect
    mov dword [bx0], MENUX
    mov dword [by0], SETY
    mov dword [bwid], MENUW
    mov dword [bhgt], MENUH
    mov byte [blight], 15
    mov byte [bdark], 8
    call bevel
    mov esi, t_menu
    mov ecx, MENUX + 5
    mov edx, SETY + 2
    mov al, 0
    call text_at

    mov dword [rx], SALLX
    mov dword [ry], SETY
    mov dword [rw], SALLW
    mov dword [rh], MENUH
    mov byte [rc], 7
    call rect
    mov dword [bx0], SALLX
    mov dword [by0], SETY
    mov dword [bwid], SALLW
    mov dword [bhgt], MENUH
    mov byte [blight], 15
    mov byte [bdark], 8
    call bevel
    mov esi, t_sall
    mov ecx, SALLX + 4
    mov edx, SETY + 2
    mov al, 0
    call text_at

    call draw_pinned
    mov eax, [clock_x]
    mov [clock_pos], eax

    movzx eax, byte [rtc_hour]
    call fmt2
    mov esi, timebuf
    mov ecx, [clock_pos]
    mov edx, 2
    mov al, 0
    call text_at
    mov esi, t_colon
    mov ecx, [clock_pos]
    add ecx, 16
    mov edx, 2
    mov al, 0
    call text_at
    movzx eax, byte [rtc_min]
    call fmt2
    mov esi, timebuf
    mov ecx, [clock_pos]
    add ecx, 24
    mov edx, 2
    mov al, 0
    call text_at
    mov esi, t_space
    mov ecx, [clock_pos]
    add ecx, 38
    mov edx, 2
    mov al, 0
    call text_at
    movzx eax, byte [rtc_day]
    call fmt2
    mov esi, timebuf
    mov ecx, [clock_pos]
    add ecx, 46
    mov edx, 2
    mov al, 0
    call text_at
    mov esi, t_dot
    mov ecx, [clock_pos]
    add ecx, 62
    mov edx, 2
    mov al, 0
    call text_at
    movzx eax, byte [rtc_mon]
    call fmt2
    mov esi, timebuf
    mov ecx, [clock_pos]
    add ecx, 70
    mov edx, 2
    mov al, 0
    call text_at

    call draw_indicators

    mov dword [rx], SETX
    mov dword [ry], SETY
    mov dword [rw], SETW
    mov dword [rh], SETH
    mov byte [rc], 7
    call rect
    mov dword [bx0], SETX
    mov dword [by0], SETY
    mov dword [bwid], SETW
    mov dword [bhgt], SETH
    mov byte [blight], 15
    mov byte [bdark], 8
    cmp byte [setdown], 1
    jne .setup
    mov byte [blight], 8
    mov byte [bdark], 15
.setup:
    call bevel
    mov dword [rx], SETX + 4
    mov dword [ry], SETY + 8
    mov dword [rw], 10
    mov dword [rh], 2
    mov byte [rc], 0
    call rect

    mov dword [rx], 0
    mov dword [ry], DOCKY
    mov dword [rw], W
    mov dword [rh], DOCKH
    mov byte [rc], 7
    call rect
    mov dword [rx], 0
    mov dword [ry], DOCKY
    mov dword [rw], W
    mov dword [rh], 1
    mov byte [rc], 15
    call rect
    mov dword [rx], 0
    mov dword [ry], DOCKY + DOCKH - 1
    mov dword [rw], W
    mov dword [rh], 1
    mov byte [rc], 8
    call rect

    xor ebx, ebx
.dockloop:
    cmp ebx, 5
    jae .dockdone
    mov eax, ebx
    imul eax, DOCKW
    add eax, 2
    mov [rx], eax
    mov dword [ry], DOCKY + 2
    mov dword [rw], DOCKW - 4
    mov dword [rh], DOCKH - 4
    mov byte [rc], 7
    call rect
    mov eax, ebx
    imul eax, DOCKW
    add eax, 2
    mov [bx0], eax
    mov dword [by0], DOCKY + 2
    mov dword [bwid], DOCKW - 4
    mov dword [bhgt], DOCKH - 4
    mov byte [blight], 15
    mov byte [bdark], 8
    push ebx
    mov eax, [sel]
    cmp eax, ebx
    pop ebx
    jne .noHi
    mov byte [blight], 8
    mov byte [bdark], 15
.noHi:
    call bevel
    mov esi, [docklabels + ebx*4]
    mov eax, ebx
    imul eax, DOCKW
    add eax, 12
    mov ecx, eax
    mov edx, DOCKY + 4
    xor al, al
    call text_at
    inc ebx
    jmp .dockloop
.dockdone:

    call draw_menu
    call draw_ctxmenu
    ret

draw_desktopicons:
    pusha
    xor ebx, ebx
.loop:
    cmp ebx, 3
    jae .done
    mov eax, ebx
    shl eax, 2
    add eax, iconx
    mov eax, [eax]
    mov [rx], eax
    mov eax, ebx
    shl eax, 2
    add eax, icony
    mov eax, [eax]
    mov [ry], eax
    mov dword [rw], 24
    mov dword [rh], 24
    cmp ebx, 0
    jne .c1
    mov byte [rc], 1
    jmp .cd
.c1:
    cmp ebx, 1
    jne .c2
    mov byte [rc], 10
    jmp .cd
.c2:
    mov byte [rc], 14
.cd:
    call rect
    mov eax, [rx]
    add eax, 8
    mov ecx, eax
    mov eax, [ry]
    add eax, 4
    mov edx, eax
    mov esi, [iconletters + ebx*4]
    mov al, 15
    call text_at
    mov eax, [rx]
    mov ecx, eax
    mov eax, [ry]
    add eax, 26
    mov edx, eax
    mov esi, [iconnames + ebx*4]
    mov al, 15
    call text_at
    inc ebx
    jmp .loop
.done:
    popa
    ret

draw_pinned:
    pusha
    mov edx, SALLX + SALLW + 4
    mov [clock_x], edx
    xor ebx, ebx
.pl:
    cmp ebx, ITEMS
    jae .pdone
    cmp byte [pinstate + ebx], 0
    je .pnext
    mov [rx], edx
    push edx
    mov dword [ry], SETY
    mov dword [rw], 20
    mov dword [rh], MENUH
    mov byte [rc], 7
    call rect
    mov [bx0], edx
    mov dword [by0], SETY
    mov dword [bwid], 20
    mov dword [bhgt], MENUH
    mov byte [blight], 15
    mov byte [bdark], 8
    call bevel
    push ebx
    mov esi, [menulabels + ebx*4]
    movzx eax, byte [esi]
    mov [pinchar], al
    mov byte [pinchar+1], 0
    mov esi, pinchar
    pop ebx
    push ebx
    mov ecx, edx
    add ecx, 6
    mov edx, SETY + 2
    mov al, 0
    call text_at
    pop ebx
    pop edx
    add edx, 24
    mov [clock_x], edx
.pnext:
    inc ebx
    jmp .pl
.pdone:
    popa
    ret

draw_indicators:
    pusha
    cmp byte [npopen], 1
    jne .i1
    mov dword [rx], W - 100
    mov dword [ry], 3
    mov dword [rw], 14
    mov dword [rh], 14
    cmp byte [npmin], 1
    je .npmin1
    mov byte [rc], 7
    jmp .npmin0
.npmin1:
    mov byte [rc], 8
.npmin0:
    call rect
    mov dword [bx0], W - 100
    mov dword [by0], 3
    mov dword [bwid], 14
    mov dword [bhgt], 14
    mov byte [blight], 15
    mov byte [bdark], 8
    call bevel
    mov esi, t_iN
    mov ecx, W - 96
    mov edx, 4
    mov al, 0
    call text_at
.i1:
    cmp byte [clopen], 1
    jne .i2
    mov dword [rx], W - 84
    mov dword [ry], 3
    mov dword [rw], 14
    mov dword [rh], 14
    cmp byte [clmin], 1
    je .clmin1
    mov byte [rc], 7
    jmp .clmin0
.clmin1:
    mov byte [rc], 8
.clmin0:
    call rect
    mov dword [bx0], W - 84
    mov dword [by0], 3
    mov dword [bwid], 14
    mov dword [bhgt], 14
    mov byte [blight], 15
    mov byte [bdark], 8
    call bevel
    mov esi, t_iC
    mov ecx, W - 80
    mov edx, 4
    mov al, 0
    call text_at
.i2:
    cmp byte [setopen], 1
    jne .i3
    mov dword [rx], W - 68
    mov dword [ry], 3
    mov dword [rw], 14
    mov dword [rh], 14
    cmp byte [setmin], 1
    je .setmin1
    mov byte [rc], 7
    jmp .setmin0
.setmin1:
    mov byte [rc], 8
.setmin0:
    call rect
    mov dword [bx0], W - 68
    mov dword [by0], 3
    mov dword [bwid], 14
    mov dword [bhgt], 14
    mov byte [blight], 15
    mov byte [bdark], 8
    call bevel
    mov esi, t_iS
    mov ecx, W - 64
    mov edx, 4
    mov al, 0
    call text_at
.i3:
    cmp byte [topen], 1
    jne .i4
    mov dword [rx], W - 52
    mov dword [ry], 3
    mov dword [rw], 14
    mov dword [rh], 14
    cmp byte [tmin], 1
    je .tmin1
    mov byte [rc], 7
    jmp .tmin0
.tmin1:
    mov byte [rc], 8
.tmin0:
    call rect
    mov dword [bx0], W - 52
    mov dword [by0], 3
    mov dword [bwid], 14
    mov dword [bhgt], 14
    mov byte [blight], 15
    mov byte [bdark], 8
    call bevel
    mov esi, t_iT
    mov ecx, W - 48
    mov edx, 4
    mov al, 0
    call text_at
.i4:
    cmp byte [fmopen], 1
    jne .i5
    mov dword [rx], W - 36
    mov dword [ry], 3
    mov dword [rw], 14
    mov dword [rh], 14
    cmp byte [fmmin], 1
    je .fmmin1
    mov byte [rc], 7
    jmp .fmmin0
.fmmin1:
    mov byte [rc], 8
.fmmin0:
    call rect
    mov dword [bx0], W - 36
    mov dword [by0], 3
    mov dword [bwid], 14
    mov dword [bhgt], 14
    mov byte [blight], 15
    mov byte [bdark], 8
    call bevel
    mov esi, t_iF
    mov ecx, W - 32
    mov edx, 4
    mov al, 0
    call text_at
.i5:
    popa
    ret

fmt2:
    pusha
    xor edx, edx
    mov ecx, 10
    div ecx
    add al, '0'
    mov [timebuf], al
    add dl, '0'
    mov [timebuf+1], dl
    mov byte [timebuf+2], 0
    popa
    ret

MENUWIN_X equ 2
MENUWIN_Y equ TOPH
MENUWIN_W equ 90
MENUWIN_H equ ITEMS*16 + 8

draw_menu:
    cmp byte [menuopen], 1
    jne .e
    mov dword [rx], MENUWIN_X + 2
    mov dword [ry], MENUWIN_Y + 2
    mov dword [rw], MENUWIN_W
    mov dword [rh], MENUWIN_H
    mov byte [rc], 8
    call rect
    mov dword [rx], MENUWIN_X
    mov dword [ry], MENUWIN_Y
    mov dword [rw], MENUWIN_W
    mov dword [rh], MENUWIN_H
    mov byte [rc], 7
    call rect
    mov dword [bx0], MENUWIN_X
    mov dword [by0], MENUWIN_Y
    mov dword [bwid], MENUWIN_W
    mov dword [bhgt], MENUWIN_H
    mov byte [blight], 15
    mov byte [bdark], 8
    call bevel
    xor ebx, ebx
.mloop:
    cmp ebx, ITEMS
    jae .mdone
    mov eax, ebx
    imul eax, 16
    add eax, MENUWIN_Y + 4
    mov [ry], eax
    mov dword [rx], MENUWIN_X + 4
    mov dword [rw], MENUWIN_W - 8
    mov dword [rh], 16
    mov byte [rc], 7
    call rect
    push ebx
    cmp byte [pinstate + ebx], 0
    je .norm
    mov byte [rc], 10
    jmp .drawn
.norm:
    mov byte [rc], 0
.drawn:
    pop ebx
    push ebx
    mov esi, [menulabels + ebx*4]
    mov ecx, MENUWIN_X + 6
    mov edx, eax
    mov al, [rc]
    call text_at
    pop ebx
    inc ebx
    jmp .mloop
.mdone:
.e:
    ret

CTXW equ 100
CTXH equ 2*16 + 8

draw_ctxmenu:
    cmp byte [ctxopen], 1
    jne .e
    mov eax, [ctx_x]
    add eax, 2
    mov [rx], eax
    mov eax, [ctx_y]
    add eax, 2
    mov [ry], eax
    mov dword [rw], CTXW
    mov dword [rh], CTXH
    mov byte [rc], 8
    call rect
    mov eax, [ctx_x]
    mov [rx], eax
    mov eax, [ctx_y]
    mov [ry], eax
    mov dword [rw], CTXW
    mov dword [rh], CTXH
    mov byte [rc], 7
    call rect
    mov eax, [ctx_x]
    mov [bx0], eax
    mov eax, [ctx_y]
    mov [by0], eax
    mov dword [bwid], CTXW
    mov dword [bhgt], CTXH
    mov byte [blight], 15
    mov byte [bdark], 8
    call bevel
    mov eax, [ctx_y]
    add eax, 4
    mov [ry], eax
    mov eax, [ctx_x]
    add eax, 4
    mov [rx], eax
    mov dword [rw], CTXW - 8
    mov dword [rh], 16
    mov byte [rc], 7
    call rect
    mov esi, t_settings
    mov ecx, [ctx_x]
    add ecx, 6
    mov edx, [ctx_y]
    add edx, 4
    xor al, al
    call text_at
    mov eax, [ctx_y]
    add eax, 20
    mov [ry], eax
    mov eax, [ctx_x]
    add eax, 4
    mov [rx], eax
    mov dword [rw], CTXW - 8
    mov dword [rh], 16
    mov byte [rc], 7
    call rect
    mov esi, t_about
    mov ecx, [ctx_x]
    add ecx, 6
    mov edx, [ctx_y]
    add edx, 20
    xor al, al
    call text_at
.e:
    ret

ABW equ 200
ABH equ 100

draw_about:
    cmp byte [aboutopen], 1
    jne .e
    mov eax, [abx]
    add eax, 2
    mov [rx], eax
    mov eax, [aby]
    add eax, 2
    mov [ry], eax
    mov dword [rw], ABW
    mov dword [rh], ABH
    mov byte [rc], 8
    call rect
    mov eax, [abx]
    mov [rx], eax
    mov eax, [aby]
    mov [ry], eax
    mov dword [rw], ABW
    mov dword [rh], ABH
    mov byte [rc], 7
    call rect
    mov eax, [abx]
    mov [bx0], eax
    mov eax, [aby]
    mov [by0], eax
    mov dword [bwid], ABW
    mov dword [bhgt], ABH
    mov byte [blight], 15
    mov byte [bdark], 8
    call bevel
    mov eax, [abx]
    add eax, 2
    mov [rx], eax
    mov eax, [aby]
    add eax, 2
    mov [ry], eax
    mov dword [rw], ABW - 4
    mov dword [rh], 16
    mov byte [rc], 1
    call rect
    mov esi, t_about
    mov ecx, [abx]
    add ecx, 80
    mov edx, [aby]
    add edx, 4
    mov al, 15
    call text_at
    mov eax, [abx]
    add eax, 6
    mov [rx], eax
    mov eax, [aby]
    add eax, 4
    mov [ry], eax
    mov dword [rw], 12
    mov dword [rh], 12
    mov byte [rc], 7
    call rect
    mov eax, [abx]
    add eax, 6
    mov [bx0], eax
    mov eax, [aby]
    add eax, 4
    mov [by0], eax
    mov dword [bwid], 12
    mov dword [bhgt], 12
    mov byte [blight], 15
    mov byte [bdark], 8
    cmp byte [abxdown], 1
    jne .xup
    mov byte [blight], 8
    mov byte [bdark], 15
.xup:
    call bevel
    xor ecx, ecx
.xdiag:
    push ecx
    mov eax, [abx]
    add eax, 8
    add eax, ecx
    mov [rx], eax
    mov eax, [aby]
    add eax, 6
    add eax, ecx
    mov [ry], eax
    mov dword [rw], 1
    mov dword [rh], 1
    mov byte [rc], 0
    call rect
    pop ecx
    push ecx
    mov eax, [abx]
    add eax, 8
    add eax, ecx
    mov [rx], eax
    mov eax, [aby]
    add eax, 11
    sub eax, ecx
    mov [ry], eax
    mov dword [rw], 1
    mov dword [rh], 1
    mov byte [rc], 0
    call rect
    pop ecx
    inc ecx
    cmp ecx, 6
    jb .xdiag
    mov esi, t_about1
    mov ecx, [abx]
    add ecx, 10
    mov edx, [aby]
    add edx, 28
    xor al, al
    call text_at
    mov esi, t_about2
    mov ecx, [abx]
    add ecx, 10
    mov edx, [aby]
    add edx, 44
    xor al, al
    call text_at
    mov esi, t_about3
    mov ecx, [abx]
    add ecx, 10
    mov edx, [aby]
    add edx, 60
    xor al, al
    call text_at
.e:
    ret

SWW     equ 180
SWH     equ 90
SWCX    equ 8
SWCY    equ 40
SWCW    equ 10
SWCH    equ 12

draw_settings:
    cmp byte [setopen], 1
    jne .e
    cmp byte [setmin], 1
    je .e
    cmp byte [setpage], 0
    jne .p1
    call draw_setmenu
    jmp .e
.p1:
    cmp byte [setpage], 1
    jne .p2
    call draw_setwincol
    jmp .e
.p2:
    call draw_setdesk
.e:
    ret

draw_close_x:
    mov eax, [swx]
    add eax, 6
    mov [rx], eax
    mov eax, [swy]
    add eax, 4
    mov [ry], eax
    mov dword [rw], 12
    mov dword [rh], 12
    mov byte [rc], 7
    call rect
    mov eax, [swx]
    add eax, 6
    mov [bx0], eax
    mov eax, [swy]
    add eax, 4
    mov [by0], eax
    mov dword [bwid], 12
    mov dword [bhgt], 12
    mov byte [blight], 15
    mov byte [bdark], 8
    cmp byte [xdown], 1
    jne .xup
    mov byte [blight], 8
    mov byte [bdark], 15
.xup:
    call bevel
    xor ecx, ecx
.xdiag:
    push ecx
    mov eax, [swx]
    add eax, 8
    add eax, ecx
    mov [rx], eax
    mov eax, [swy]
    add eax, 6
    add eax, ecx
    mov [ry], eax
    mov dword [rw], 1
    mov dword [rh], 1
    mov byte [rc], 0
    call rect
    pop ecx
    push ecx
    mov eax, [swx]
    add eax, 8
    add eax, ecx
    mov [rx], eax
    mov eax, [swy]
    add eax, 11
    sub eax, ecx
    mov [ry], eax
    mov dword [rw], 1
    mov dword [rh], 1
    mov byte [rc], 0
    call rect
    pop ecx
    inc ecx
    cmp ecx, 6
    jb .xdiag
    ret

draw_back_btn:
    mov eax, [swx]
    add eax, 20
    mov [rx], eax
    mov eax, [swy]
    add eax, 4
    mov [ry], eax
    mov dword [rw], 12
    mov dword [rh], 12
    mov byte [rc], 7
    call rect
    mov eax, [swx]
    add eax, 20
    mov [bx0], eax
    mov eax, [swy]
    add eax, 4
    mov [by0], eax
    mov dword [bwid], 12
    mov dword [bhgt], 12
    mov byte [blight], 15
    mov byte [bdark], 8
    call bevel
    mov eax, [swx]
    add eax, 23
    mov [rx], eax
    mov eax, [swy]
    add eax, 9
    mov [ry], eax
    mov dword [rw], 6
    mov dword [rh], 2
    mov byte [rc], 0
    call rect
    mov eax, [swx]
    add eax, 23
    mov [rx], eax
    mov eax, [swy]
    add eax, 8
    mov [ry], eax
    mov dword [rw], 2
    mov dword [rh], 1
    mov byte [rc], 0
    call rect
    mov eax, [swx]
    add eax, 23
    mov [rx], eax
    mov eax, [swy]
    add eax, 11
    mov [ry], eax
    mov dword [rw], 2
    mov dword [rh], 1
    mov byte [rc], 0
    call rect
    ret

draw_setmenu:
    cmp byte [setopen], 1
    jne .e
    mov eax, [swx]
    add eax, 2
    mov [rx], eax
    mov eax, [swy]
    add eax, 2
    mov [ry], eax
    mov dword [rw], 140
    mov dword [rh], 70
    mov byte [rc], 8
    call rect
    mov eax, [swx]
    mov [rx], eax
    mov eax, [swy]
    mov [ry], eax
    mov dword [rw], 140
    mov dword [rh], 70
    mov byte [rc], 7
    call rect
    mov eax, [swx]
    mov [bx0], eax
    mov eax, [swy]
    mov [by0], eax
    mov dword [bwid], 140
    mov dword [bhgt], 70
    mov byte [blight], 15
    mov byte [bdark], 8
    call bevel
    mov eax, [swx]
    add eax, 2
    mov [rx], eax
    mov eax, [swy]
    add eax, 2
    mov [ry], eax
    mov dword [rw], 136
    mov dword [rh], 16
    mov byte [rc], 1
    call rect
    mov esi, t_setwin
    mov ecx, [swx]
    add ecx, 40
    mov edx, [swy]
    add edx, 4
    mov al, 15
    call text_at
    call draw_close_x
    mov eax, [swx]
    add eax, 10
    mov [rx], eax
    mov eax, [swy]
    add eax, 24
    mov [ry], eax
    mov dword [rw], 120
    mov dword [rh], 16
    mov byte [rc], 7
    call rect
    mov eax, [swx]
    add eax, 10
    mov [bx0], eax
    mov eax, [swy]
    add eax, 24
    mov [by0], eax
    mov dword [bwid], 120
    mov dword [bhgt], 16
    mov byte [blight], 15
    mov byte [bdark], 8
    call bevel
    mov esi, t_wincol
    mov ecx, [swx]
    add ecx, 20
    mov edx, [swy]
    add edx, 27
    xor al, al
    call text_at
    mov eax, [swx]
    add eax, 10
    mov [rx], eax
    mov eax, [swy]
    add eax, 44
    mov [ry], eax
    mov dword [rw], 120
    mov dword [rh], 16
    mov byte [rc], 7
    call rect
    mov eax, [swx]
    add eax, 10
    mov [bx0], eax
    mov eax, [swy]
    add eax, 44
    mov [by0], eax
    mov dword [bwid], 120
    mov dword [bhgt], 16
    mov byte [blight], 15
    mov byte [bdark], 8
    call bevel
    mov esi, t_desksettings
    mov ecx, [swx]
    add ecx, 20
    mov edx, [swy]
    add edx, 47
    xor al, al
    call text_at
.e:
    ret

draw_setwincol:
    cmp byte [setopen], 1
    jne .e
    mov eax, [swx]
    add eax, 2
    mov [rx], eax
    mov eax, [swy]
    add eax, 2
    mov [ry], eax
    mov dword [rw], SWW
    mov dword [rh], 70
    mov byte [rc], 8
    call rect
    mov eax, [swx]
    mov [rx], eax
    mov eax, [swy]
    mov [ry], eax
    mov dword [rw], SWW
    mov dword [rh], 70
    mov byte [rc], 7
    call rect
    mov eax, [swx]
    mov [bx0], eax
    mov eax, [swy]
    mov [by0], eax
    mov dword [bwid], SWW
    mov dword [bhgt], 70
    mov byte [blight], 15
    mov byte [bdark], 8
    call bevel
    mov eax, [swx]
    add eax, 2
    mov [rx], eax
    mov eax, [swy]
    add eax, 2
    mov [ry], eax
    mov dword [rw], SWW - 4
    mov dword [rh], 16
    mov byte [rc], 1
    call rect
    mov esi, t_wincol
    mov ecx, [swx]
    add ecx, 50
    mov edx, [swy]
    add edx, 4
    mov al, 15
    call text_at
    call draw_close_x
    call draw_back_btn
    xor ebx, ebx
.colors:
    cmp ebx, 16
    jae .colsdone
    push ebx
    mov eax, ebx
    imul eax, SWCW
    add eax, [swx]
    add eax, 10
    mov [rx], eax
    mov eax, [swy]
    add eax, 40
    mov [ry], eax
    mov dword [rw], SWCW
    mov dword [rh], SWCH
    pop ebx
    push ebx
    mov [rc], bl
    call rect
    pop ebx
    inc ebx
    jmp .colors
.colsdone:
    movzx eax, byte [titlecol]
    imul eax, SWCW
    add eax, [swx]
    add eax, 10
    mov [rx], eax
    mov eax, [swy]
    add eax, 54
    mov [ry], eax
    mov dword [rw], SWCW
    mov dword [rh], 2
    mov byte [rc], 0
    call rect
.e:
    ret

draw_setdesk:
    cmp byte [setopen], 1
    jne .e
    mov eax, [swx]
    add eax, 2
    mov [rx], eax
    mov eax, [swy]
    add eax, 2
    mov [ry], eax
    mov dword [rw], SWW
    mov dword [rh], 130
    mov byte [rc], 8
    call rect
    mov eax, [swx]
    mov [rx], eax
    mov eax, [swy]
    mov [ry], eax
    mov dword [rw], SWW
    mov dword [rh], 130
    mov byte [rc], 7
    call rect
    mov eax, [swx]
    mov [bx0], eax
    mov eax, [swy]
    mov [by0], eax
    mov dword [bwid], SWW
    mov dword [bhgt], 130
    mov byte [blight], 15
    mov byte [bdark], 8
    call bevel
    mov eax, [swx]
    add eax, 2
    mov [rx], eax
    mov eax, [swy]
    add eax, 2
    mov [ry], eax
    mov dword [rw], SWW - 4
    mov dword [rh], 16
    mov byte [rc], 1
    call rect
    mov esi, t_desksettings
    mov ecx, [swx]
    add ecx, 50
    mov edx, [swy]
    add edx, 4
    mov al, 15
    call text_at
    call draw_close_x
    call draw_back_btn
    movzx eax, byte [bgmode]
    dec eax
    imul eax, 50
    add eax, [swx]
    add eax, 6
    mov [rx], eax
    mov eax, [swy]
    add eax, 22
    mov [ry], eax
    mov dword [rw], 44
    mov dword [rh], 12
    mov byte [rc], 10
    call rect
    mov esi, t_mode1
    mov ecx, [swx]
    add ecx, 14
    mov edx, [swy]
    add edx, 24
    xor al, al
    call text_at
    mov esi, t_mode2
    mov ecx, [swx]
    add ecx, 64
    mov edx, [swy]
    add edx, 24
    xor al, al
    call text_at
    mov esi, t_mode3
    mov ecx, [swx]
    add ecx, 114
    mov edx, [swy]
    add edx, 24
    xor al, al
    call text_at
    xor ebx, ebx
.c1:
    cmp ebx, 16
    jae .c1done
    push ebx
    mov eax, ebx
    imul eax, SWCW
    add eax, [swx]
    add eax, 10
    mov [rx], eax
    mov eax, [swy]
    add eax, 40
    mov [ry], eax
    mov dword [rw], SWCW
    mov dword [rh], SWCH
    pop ebx
    push ebx
    mov [rc], bl
    call rect
    pop ebx
    inc ebx
    jmp .c1
.c1done:
    movzx eax, byte [bgcol1]
    imul eax, SWCW
    add eax, [swx]
    add eax, 10
    mov [rx], eax
    mov eax, [swy]
    add eax, 52
    mov [ry], eax
    mov dword [rw], SWCW
    mov dword [rh], 2
    mov byte [rc], 0
    call rect
    xor ebx, ebx
.c2:
    cmp ebx, 16
    jae .c2done
    push ebx
    mov eax, ebx
    imul eax, SWCW
    add eax, [swx]
    add eax, 10
    mov [rx], eax
    mov eax, [swy]
    add eax, 60
    mov [ry], eax
    mov dword [rw], SWCW
    mov dword [rh], SWCH
    pop ebx
    push ebx
    mov [rc], bl
    call rect
    pop ebx
    inc ebx
    jmp .c2
.c2done:
    movzx eax, byte [bgcol2]
    imul eax, SWCW
    add eax, [swx]
    add eax, 10
    mov [rx], eax
    mov eax, [swy]
    add eax, 72
    mov [ry], eax
    mov dword [rw], SWCW
    mov dword [rh], 2
    mov byte [rc], 0
    call rect
    xor ebx, ebx
.c3:
    cmp ebx, 16
    jae .c3done
    push ebx
    mov eax, ebx
    imul eax, SWCW
    add eax, [swx]
    add eax, 10
    mov [rx], eax
    mov eax, [swy]
    add eax, 80
    mov [ry], eax
    mov dword [rw], SWCW
    mov dword [rh], SWCH
    pop ebx
    push ebx
    mov [rc], bl
    call rect
    pop ebx
    inc ebx
    jmp .c3
.c3done:
    movzx eax, byte [bgcol3]
    imul eax, SWCW
    add eax, [swx]
    add eax, 10
    mov [rx], eax
    mov eax, [swy]
    add eax, 92
    mov [ry], eax
    mov dword [rw], SWCW
    mov dword [rh], 2
    mov byte [rc], 0
    call rect
.e:
    ret

bevel:
    pusha
    mov eax, [bx0]
    mov [rx], eax
    mov eax, [by0]
    mov [ry], eax
    mov eax, [bwid]
    mov [rw], eax
    mov dword [rh], 1
    mov al, [blight]
    mov [rc], al
    call rect
    mov eax, [bx0]
    mov [rx], eax
    mov eax, [by0]
    mov [ry], eax
    mov dword [rw], 1
    mov eax, [bhgt]
    mov [rh], eax
    mov al, [blight]
    mov [rc], al
    call rect
    mov eax, [bx0]
    mov [rx], eax
    mov eax, [by0]
    add eax, [bhgt]
    dec eax
    mov [ry], eax
    mov eax, [bwid]
    mov [rw], eax
    mov dword [rh], 1
    mov al, [bdark]
    mov [rc], al
    call rect
    mov eax, [bx0]
    add eax, [bwid]
    dec eax
    mov [rx], eax
    mov eax, [by0]
    mov [ry], eax
    mov dword [rw], 1
    mov eax, [bhgt]
    mov [rh], eax
    mov al, [bdark]
    mov [rc], al
    call rect
    popa
    ret

FMW equ 220
FMH equ 130

draw_fm:
    cmp byte [fmopen], 1
    jne .e
    cmp byte [fmmin], 1
    je .e
    mov eax, [fmx]
    add eax, 2
    mov [rx], eax
    mov eax, [fmy]
    add eax, 2
    mov [ry], eax
    mov dword [rw], FMW
    mov dword [rh], FMH
    mov byte [rc], 8
    call rect
    mov eax, [fmx]
    mov [rx], eax
    mov eax, [fmy]
    mov [ry], eax
    mov dword [rw], FMW
    mov dword [rh], FMH
    mov byte [rc], 7
    call rect
    mov eax, [fmx]
    mov [bx0], eax
    mov eax, [fmy]
    mov [by0], eax
    mov dword [bwid], FMW
    mov dword [bhgt], FMH
    mov byte [blight], 15
    mov byte [bdark], 8
    call bevel
    mov eax, [fmx]
    add eax, 2
    mov [rx], eax
    mov eax, [fmy]
    add eax, 2
    mov [ry], eax
    mov dword [rw], FMW - 4
    mov dword [rh], 16
    mov al, [titlecol]
    mov [rc], al
    call rect
    mov esi, t_fmwin
    mov ecx, [fmx]
    add ecx, 90
    mov edx, [fmy]
    add edx, 4
    mov al, 15
    call text_at
    mov eax, [fmx]
    add eax, 6
    mov [rx], eax
    mov eax, [fmy]
    add eax, 4
    mov [ry], eax
    mov dword [rw], 12
    mov dword [rh], 12
    mov byte [rc], 7
    call rect
    mov eax, [fmx]
    add eax, 6
    mov [bx0], eax
    mov eax, [fmy]
    add eax, 4
    mov [by0], eax
    mov dword [bwid], 12
    mov dword [bhgt], 12
    mov byte [blight], 15
    mov byte [bdark], 8
    cmp byte [fmmindown], 1
    jne .mup
    mov byte [blight], 8
    mov byte [bdark], 15
.mup:
    call bevel
    mov eax, [fmx]
    add eax, 8
    mov [rx], eax
    mov eax, [fmy]
    add eax, 12
    mov [ry], eax
    mov dword [rw], 8
    mov dword [rh], 2
    mov byte [rc], 0
    call rect
    mov eax, [fmx]
    add eax, 20
    mov [rx], eax
    mov eax, [fmy]
    add eax, 4
    mov [ry], eax
    mov dword [rw], 12
    mov dword [rh], 12
    mov byte [rc], 7
    call rect
    mov eax, [fmx]
    add eax, 20
    mov [bx0], eax
    mov eax, [fmy]
    add eax, 4
    mov [by0], eax
    mov dword [bwid], 12
    mov dword [bhgt], 12
    mov byte [blight], 15
    mov byte [bdark], 8
    cmp byte [fmxdown], 1
    jne .xup
    mov byte [blight], 8
    mov byte [bdark], 15
.xup:
    call bevel
    xor ecx, ecx
.xdiag:
    push ecx
    mov eax, [fmx]
    add eax, 22
    add eax, ecx
    mov [rx], eax
    mov eax, [fmy]
    add eax, 6
    add eax, ecx
    mov [ry], eax
    mov dword [rw], 1
    mov dword [rh], 1
    mov byte [rc], 0
    call rect
    pop ecx
    push ecx
    mov eax, [fmx]
    add eax, 22
    add eax, ecx
    mov [rx], eax
    mov eax, [fmy]
    add eax, 11
    sub eax, ecx
    mov [ry], eax
    mov dword [rw], 1
    mov dword [rh], 1
    mov byte [rc], 0
    call rect
    pop ecx
    inc ecx
    cmp ecx, 6
    jb .xdiag
    mov eax, [fmx]
    add eax, 4
    mov [rx], eax
    mov eax, [fmy]
    add eax, 22
    mov [ry], eax
    mov dword [rw], FMW - 8
    mov dword [rh], FMH - 55
    mov byte [rc], 15
    call rect
    mov esi, t_fmdisk
    mov ecx, [fmx]
    add ecx, 8
    mov edx, [fmy]
    add edx, 24
    xor al, al
    call text_at
    cmp byte [disk_model], 0
    je .no_model
    mov esi, disk_model
    mov ecx, [fmx]
    add ecx, 56
    mov edx, [fmy]
    add edx, 24
    xor al, al
    call text_at
.no_model:
    mov eax, [disk_size_val]
    test eax, eax
    jz .no_size
    mov edi, numbuf2
    call fmt_num
    mov esi, numbuf2
    mov ecx, [fmx]
    add ecx, 8
    mov edx, [fmy]
    add edx, 34
    xor al, al
    call text_at
    movzx eax, byte [disk_size_unit]
    cmp eax, 0
    jne .u1
    mov esi, t_unit_kb
    jmp .u_draw
.u1:
    cmp eax, 1
    jne .u2
    mov esi, t_unit_mb
    jmp .u_draw
.u2:
    mov esi, t_unit_gb
.u_draw:
    mov ecx, [fmx]
    add ecx, 80
    mov edx, [fmy]
    add edx, 34
    xor al, al
    call text_at
.no_size:
    mov eax, [fmx]
    add eax, 6
    mov [rx], eax
    mov eax, [fmy]
    add eax, 46
    mov [ry], eax
    mov dword [rw], FMW - 12
    mov dword [rh], 1
    mov byte [rc], 8
    call rect
    call load_dir
    mov dword [fm_row], 0
    xor ebx, ebx
.fmlist:
    cmp ebx, MAXFILES
    jae .fmlistdone
    cmp dword [fm_row], 5
    jae .fmlistdone
    mov eax, ebx
    imul eax, ENTSZ
    add eax, dirbuf
    cmp byte [eax], 0
    je .fmnext
    cmp ebx, [fm_sel]
    jne .fm_notsel
    mov eax, [fm_row]
    imul eax, 12
    add eax, [fmy]
    add eax, 50
    mov [ry], eax
    mov eax, [fmx]
    add eax, 6
    mov [rx], eax
    mov dword [rw], FMW - 12
    mov dword [rh], 12
    mov byte [rc], 1
    call rect
.fm_notsel:
    mov eax, ebx
    imul eax, ENTSZ
    add eax, dirbuf
    mov esi, eax
    mov eax, [fm_row]
    imul eax, 12
    add eax, [fmy]
    add eax, 50
    mov edx, eax
    mov ecx, [fmx]
    add ecx, 10
    cmp ebx, [fm_sel]
    jne .fm_black
    mov al, 15
    jmp .fm_draw
.fm_black:
    xor al, al
.fm_draw:
    call text_at
    inc dword [fm_row]
.fmnext:
    inc ebx
    jmp .fmlist
.fmlistdone:
    mov eax, [fmx]
    add eax, 4
    mov [rx], eax
    mov eax, [fmy]
    add eax, FMH - 28
    mov [ry], eax
    mov dword [rw], 38
    mov dword [rh], 16
    mov byte [rc], 7
    call rect
    mov eax, [fmx]
    add eax, 4
    mov [bx0], eax
    mov eax, [fmy]
    add eax, FMH - 28
    mov [by0], eax
    mov dword [bwid], 38
    mov dword [bhgt], 16
    mov byte [blight], 15
    mov byte [bdark], 8
    call bevel
    mov esi, t_fmcopy
    mov ecx, [fmx]
    add ecx, 10
    mov edx, [fmy]
    add edx, FMH - 25
    xor al, al
    call text_at
    mov eax, [fmx]
    add eax, 46
    mov [rx], eax
    mov eax, [fmy]
    add eax, FMH - 28
    mov [ry], eax
    mov dword [rw], 38
    mov dword [rh], 16
    mov byte [rc], 7
    call rect
    mov eax, [fmx]
    add eax, 46
    mov [bx0], eax
    mov eax, [fmy]
    add eax, FMH - 28
    mov [by0], eax
    mov dword [bwid], 38
    mov dword [bhgt], 16
    mov byte [blight], 15
    mov byte [bdark], 8
    call bevel
    mov esi, t_fmpaste
    mov ecx, [fmx]
    add ecx, 52
    mov edx, [fmy]
    add edx, FMH - 25
    xor al, al
    call text_at
    mov eax, [fmx]
    add eax, 88
    mov [rx], eax
    mov eax, [fmy]
    add eax, FMH - 28
    mov [ry], eax
    mov dword [rw], 38
    mov dword [rh], 16
    mov byte [rc], 7
    call rect
    mov eax, [fmx]
    add eax, 88
    mov [bx0], eax
    mov eax, [fmy]
    add eax, FMH - 28
    mov [by0], eax
    mov dword [bwid], 38
    mov dword [bhgt], 16
    mov byte [blight], 15
    mov byte [bdark], 8
    call bevel
    mov esi, t_fmrename
    mov ecx, [fmx]
    add ecx, 92
    mov edx, [fmy]
    add edx, FMH - 25
    xor al, al
    call text_at
    mov eax, [fmx]
    add eax, 130
    mov [rx], eax
    mov eax, [fmy]
    add eax, FMH - 28
    mov [ry], eax
    mov dword [rw], 38
    mov dword [rh], 16
    mov byte [rc], 7
    call rect
    mov eax, [fmx]
    add eax, 130
    mov [bx0], eax
    mov eax, [fmy]
    add eax, FMH - 28
    mov [by0], eax
    mov dword [bwid], 38
    mov dword [bhgt], 16
    mov byte [blight], 15
    mov byte [bdark], 8
    call bevel
    mov esi, t_fmdel
    mov ecx, [fmx]
    add ecx, 136
    mov edx, [fmy]
    add edx, FMH - 25
    xor al, al
    call text_at
    mov eax, [fmx]
    add eax, 172
    mov [rx], eax
    mov eax, [fmy]
    add eax, FMH - 28
    mov [ry], eax
    mov dword [rw], 38
    mov dword [rh], 16
    mov byte [rc], 7
    call rect
    mov eax, [fmx]
    add eax, 172
    mov [bx0], eax
    mov eax, [fmy]
    add eax, FMH - 28
    mov [by0], eax
    mov dword [bwid], 38
    mov dword [bhgt], 16
    mov byte [blight], 15
    mov byte [bdark], 8
    call bevel
    mov esi, t_fmnew
    mov ecx, [fmx]
    add ecx, 182
    mov edx, [fmy]
    add edx, FMH - 25
    xor al, al
    call text_at
.e:
    ret

fm_delete:
    pusha
    cmp dword [fm_sel], -1
    je .done
    call load_dir
    mov eax, [fm_sel]
    imul eax, ENTSZ
    add eax, dirbuf
    mov byte [eax], 0
    call save_dir
    mov dword [fm_sel], -1
.done:
    popa
    ret

fm_open_selected:
    pusha
    cmp dword [fm_sel], -1
    je .done
    call load_dir
    mov eax, [fm_sel]
    imul eax, ENTSZ
    add eax, dirbuf
    mov esi, eax
    mov edi, npflat
    call load_file
    test al, al
    jz .done
    call np_unflatten
    mov byte [npopen], 1
    mov byte [npmin], 0
    mov byte [focus], 0
    mov dword [p_npmsg], t_nploaded
.done:
    popa
    ret

fm_key:
    cmp byte [ctrl], 1
    jne .e
    cmp al, 'c'
    je .copy
    cmp al, 'C'
    je .copy
    cmp al, 'v'
    je .paste
    cmp al, 'V'
    je .paste
.e:
    ret
.copy:
    cmp dword [fm_sel], -1
    je .copy_done
    call load_dir
    mov eax, [fm_sel]
    imul eax, ENTSZ
    add eax, dirbuf
    mov esi, eax
    mov edi, clip_name
    mov ecx, 12
.copy_loop:
    mov al, [esi]
    mov [edi], al
    inc esi
    inc edi
    dec ecx
    jnz .copy_loop
    mov byte [clip_type], 1
.copy_done:
    ret
.paste:
    cmp byte [clip_type], 1
    jne .paste_done
    mov esi, clip_name
    mov edi, tscratch
    call load_file
    test al, al
    jz .paste_done
    mov [loadlen], ecx
    mov esi, clip_name
    mov edi, npflat
.paste_cpname:
    mov al, [esi]
    test al, al
    jz .paste_addsuffix
    mov [edi], al
    inc esi
    inc edi
    jmp .paste_cpname
.paste_addsuffix:
    mov byte [edi], '2'
    inc edi
    mov byte [edi], 0
    mov esi, npflat
    mov edi, tscratch
    mov ecx, [loadlen]
    call save_file
.paste_done:
    ret

TW equ 280
TH equ 140
TCOLS equ 33
TLINES equ 7

draw_term:
    cmp byte [topen], 1
    jne .e
    cmp byte [tmin], 1
    je .e
    mov eax, [tx]
    add eax, 2
    mov [rx], eax
    mov eax, [ty]
    add eax, 2
    mov [ry], eax
    mov dword [rw], TW
    mov dword [rh], TH
    mov byte [rc], 8
    call rect
    mov eax, [tx]
    mov [rx], eax
    mov eax, [ty]
    mov [ry], eax
    mov dword [rw], TW
    mov dword [rh], TH
    mov byte [rc], 7
    call rect
    mov eax, [tx]
    mov [bx0], eax
    mov eax, [ty]
    mov [by0], eax
    mov dword [bwid], TW
    mov dword [bhgt], TH
    mov byte [blight], 15
    mov byte [bdark], 8
    call bevel
    mov eax, [tx]
    add eax, 2
    mov [rx], eax
    mov eax, [ty]
    add eax, 2
    mov [ry], eax
    mov dword [rw], TW - 4
    mov dword [rh], 16
    mov al, [titlecol]
    mov [rc], al
    call rect
    mov esi, t_twin
    mov ecx, [tx]
    add ecx, 120
    mov edx, [ty]
    add edx, 4
    mov al, 15
    call text_at
    mov eax, [tx]
    add eax, 6
    mov [rx], eax
    mov eax, [ty]
    add eax, 4
    mov [ry], eax
    mov dword [rw], 12
    mov dword [rh], 12
    mov byte [rc], 7
    call rect
    mov eax, [tx]
    add eax, 6
    mov [bx0], eax
    mov eax, [ty]
    add eax, 4
    mov [by0], eax
    mov dword [bwid], 12
    mov dword [bhgt], 12
    mov byte [blight], 15
    mov byte [bdark], 8
    cmp byte [tmindown], 1
    jne .mup
    mov byte [blight], 8
    mov byte [bdark], 15
.mup:
    call bevel
    mov eax, [tx]
    add eax, 8
    mov [rx], eax
    mov eax, [ty]
    add eax, 12
    mov [ry], eax
    mov dword [rw], 8
    mov dword [rh], 2
    mov byte [rc], 0
    call rect
    mov eax, [tx]
    add eax, 20
    mov [rx], eax
    mov eax, [ty]
    add eax, 4
    mov [ry], eax
    mov dword [rw], 12
    mov dword [rh], 12
    mov byte [rc], 7
    call rect
    mov eax, [tx]
    add eax, 20
    mov [bx0], eax
    mov eax, [ty]
    add eax, 4
    mov [by0], eax
    mov dword [bwid], 12
    mov dword [bhgt], 12
    mov byte [blight], 15
    mov byte [bdark], 8
    cmp byte [tfdown], 1
    jne .fup
    mov byte [blight], 8
    mov byte [bdark], 15
.fup:
    call bevel
    mov eax, [tx]
    add eax, 22
    mov [rx], eax
    mov eax, [ty]
    add eax, 6
    mov [ry], eax
    mov dword [rw], 8
    mov dword [rh], 8
    mov byte [rc], 0
    call rect
    mov eax, [tx]
    add eax, 24
    mov [rx], eax
    mov eax, [ty]
    add eax, 8
    mov [ry], eax
    mov dword [rw], 4
    mov dword [rh], 4
    mov byte [rc], 7
    call rect
    mov eax, [tx]
    add eax, 34
    mov [rx], eax
    mov eax, [ty]
    add eax, 4
    mov [ry], eax
    mov dword [rw], 12
    mov dword [rh], 12
    mov byte [rc], 7
    call rect
    mov eax, [tx]
    add eax, 34
    mov [bx0], eax
    mov eax, [ty]
    add eax, 4
    mov [by0], eax
    mov dword [bwid], 12
    mov dword [bhgt], 12
    mov byte [blight], 15
    mov byte [bdark], 8
    cmp byte [txdown], 1
    jne .xup
    mov byte [blight], 8
    mov byte [bdark], 15
.xup:
    call bevel
    xor ecx, ecx
.xdiag:
    push ecx
    mov eax, [tx]
    add eax, 36
    add eax, ecx
    mov [rx], eax
    mov eax, [ty]
    add eax, 6
    add eax, ecx
    mov [ry], eax
    mov dword [rw], 1
    mov dword [rh], 1
    mov byte [rc], 0
    call rect
    pop ecx
    push ecx
    mov eax, [tx]
    add eax, 36
    add eax, ecx
    mov [rx], eax
    mov eax, [ty]
    add eax, 11
    sub eax, ecx
    mov [ry], eax
    mov dword [rw], 1
    mov dword [rh], 1
    mov byte [rc], 0
    call rect
    pop ecx
    inc ecx
    cmp ecx, 6
    jb .xdiag
    mov eax, [tx]
    add eax, 4
    mov [rx], eax
    mov eax, [ty]
    add eax, 22
    mov [ry], eax
    mov dword [rw], TW - 8
    mov dword [rh], TH - 46
    mov byte [rc], 15
    call rect
    xor ebx, ebx
.ll:
    cmp ebx, TLINES
    jae .lldone
    mov esi, ebx
    imul esi, TCOLS
    add esi, tbuf
    cmp byte [esi], 0
    je .llnext
    push ebx
    mov eax, ebx
    imul eax, 10
    add eax, [ty]
    add eax, 24
    mov edx, eax
    mov eax, [tx]
    add eax, 6
    mov ecx, eax
    mov al, 0
    call text_at
    pop ebx
.llnext:
    inc ebx
    jmp .ll
.lldone:
    mov eax, [tx]
    add eax, 4
    mov [rx], eax
    mov eax, [ty]
    add eax, TH - 22
    mov [ry], eax
    mov dword [rw], TW - 8
    mov dword [rh], 16
    mov byte [rc], 15
    call rect
    mov esi, t_prompt
    mov ecx, [tx]
    add ecx, 6
    mov edx, [ty]
    add edx, TH - 20
    mov al, 0
    call text_at
    mov esi, tin
    mov ecx, [tx]
    add ecx, 14
    mov edx, [ty]
    add edx, TH - 20
    mov al, 0
    call text_at
    mov eax, [tin_len]
    imul eax, 8
    add eax, [tx]
    add eax, 14
    mov [rx], eax
    mov eax, [ty]
    add eax, TH - 20
    mov [ry], eax
    mov dword [rw], 6
    mov dword [rh], 2
    mov byte [rc], 0
    call rect
.e:
    ret

term_newline:
    pusha
    mov esi, tbuf + TCOLS
    mov edi, tbuf
    mov ecx, (TLINES-1) * TCOLS
    cld
    rep movsb
    mov edi, tbuf + (TLINES-1)*TCOLS
    mov ecx, TCOLS
    xor al, al
    rep stosb
    popa
    ret

term_addline:
    pusha
    call term_newline
    mov edi, tbuf + (TLINES-1)*TCOLS
    mov ecx, TCOLS - 1
.cp:
    mov al, [esi]
    test al, al
    jz .done
    mov [edi], al
    inc esi
    inc edi
    dec ecx
    jz .done
    jmp .cp
.done:
    mov byte [edi], 0
    popa
    ret

term_echo_line:
    pusha
    mov edi, temp_echo
    mov byte [edi], '$'
    inc edi
    mov byte [edi], ' '
    inc edi
    mov esi, tin
.cp:
    mov al, [esi]
    test al, al
    jz .done
    mov [edi], al
    inc edi
    inc esi
    jmp .cp
.done:
    mov byte [edi], 0
    mov esi, temp_echo
    call term_addline
    popa
    ret

cmd_eq:
    push esi
    push edi
    xor ecx, ecx
.loop:
    mov al, [esi+ecx]
    test al, al
    jz .check_end
    mov ah, [edi+ecx]
    cmp ah, al
    jne .no
    inc ecx
    jmp .loop
.check_end:
    mov al, [edi+ecx]
    cmp al, 0
    je .yes
    cmp al, ' '
    je .yes
.no:
    pop edi
    pop esi
    xor al, al
    ret
.yes:
    pop edi
    pop esi
    mov al, 1
    ret

term_arg:
    mov edi, tin
.skip:
    mov al, [edi]
    test al, al
    jz .none
    cmp al, ' '
    je .found
    inc edi
    jmp .skip
.found:
    inc edi
.sk2:
    cmp byte [edi], ' '
    jne .ok
    inc edi
    jmp .sk2
.ok:
    ret
.none:
    mov edi, 0
    ret

term_key:
    cmp al, 0
    je .e
    cmp al, 13
    je .enter
    cmp al, 8
    je .back
    cmp al, 32
    jb .e
    mov ecx, [tin_len]
    cmp ecx, 30
    jae .e
    mov [tin + ecx], al
    inc dword [tin_len]
    mov byte [tin + ecx + 1], 0
.e:
    ret
.enter:
    mov ecx, [tin_len]
    mov byte [tin + ecx], 0
    call term_exec
    mov dword [tin_len], 0
    mov byte [tin], 0
    ret
.back:
    cmp dword [tin_len], 0
    je .e
    dec dword [tin_len]
    mov ecx, [tin_len]
    mov byte [tin + ecx], 0
    ret

term_exec:
    cmp dword [tin_len], 0
    jne .notempty
    call term_newline
    ret
.notempty:
    call term_echo_line
    mov edi, tin
    mov esi, cmd_help
    call cmd_eq
    test al, al
    jnz .do_help
    mov edi, tin
    mov esi, cmd_ls
    call cmd_eq
    test al, al
    jnz .do_ls
    mov edi, tin
    mov esi, cmd_dir
    call cmd_eq
    test al, al
    jnz .do_ls
    mov edi, tin
    mov esi, cmd_cat
    call cmd_eq
    test al, al
    jnz .do_cat
    mov edi, tin
    mov esi, cmd_open
    call cmd_eq
    test al, al
    jnz .do_open
    mov edi, tin
    mov esi, cmd_rm
    call cmd_eq
    test al, al
    jnz .do_rm
    mov edi, tin
    mov esi, cmd_touch
    call cmd_eq
    test al, al
    jnz .do_touch
    mov edi, tin
    mov esi, cmd_echo
    call cmd_eq
    test al, al
    jnz .do_echo
    mov edi, tin
    mov esi, cmd_ver
    call cmd_eq
    test al, al
    jnz .do_ver
    mov edi, tin
    mov esi, cmd_clear
    call cmd_eq
    test al, al
    jnz .do_clear
    mov edi, tin
    mov esi, cmd_note
    call cmd_eq
    test al, al
    jnz .do_note
    mov edi, tin
    mov esi, cmd_calc
    call cmd_eq
    test al, al
    jnz .do_calc
    mov edi, tin
    mov esi, cmd_about
    call cmd_eq
    test al, al
    jnz .do_about
    mov edi, tin
    mov esi, cmd_off
    call cmd_eq
    test al, al
    jnz .do_off
    mov edi, tin
    mov esi, cmd_reboot
    call cmd_eq
    test al, al
    jnz .do_reboot
    mov edi, tin
    mov esi, cmd_files
    call cmd_eq
    test al, al
    jnz .do_files
    mov esi, t_unknown
    call term_addline
    ret
.do_help:
    mov esi, t_help1
    call term_addline
    mov esi, t_help2
    call term_addline
    mov esi, t_help3
    call term_addline
    ret
.do_ls:
    call load_dir
    xor ebx, ebx
.ls1:
    cmp ebx, MAXFILES
    jae .ls_done
    mov eax, ebx
    imul eax, ENTSZ
    add eax, dirbuf
    cmp byte [eax], 0
    je .ls_next
    call term_addline
.ls_next:
    inc ebx
    jmp .ls1
.ls_done:
    ret
.do_cat:
    call term_arg
    cmp edi, 0
    je .cat_fail
    mov esi, edi
    mov edi, tscratch
    call load_file
    test al, al
    jz .cat_fail
    mov esi, tscratch
    call term_addline
    ret
.cat_fail:
    mov esi, t_err_file
    call term_addline
    ret
.do_open:
    call term_arg
    cmp edi, 0
    je .open_fail
    mov esi, edi
    mov edi, npflat
    call load_file
    test al, al
    jz .open_fail
    call np_unflatten
    mov byte [npopen], 1
    mov byte [npmin], 0
    mov byte [focus], 0
    mov dword [p_npmsg], t_nploaded
    ret
.open_fail:
    mov esi, t_err_file
    call term_addline
    ret
.do_rm:
    call term_arg
    cmp edi, 0
    je .rm_fail
    mov esi, edi
    call load_dir
    call find_file
    cmp eax, -1
    je .rm_fail
    imul eax, ENTSZ
    add eax, dirbuf
    mov byte [eax], 0
    call save_dir
    mov esi, t_ok_rm
    call term_addline
    ret
.rm_fail:
    mov esi, t_err_file
    call term_addline
    ret
.do_touch:
    call term_arg
    cmp edi, 0
    je .touch_fail
    mov esi, edi
    mov edi, tscratch
    mov byte [edi], 0
    mov ecx, 0
    call save_file
    mov esi, t_ok_touch
    call term_addline
    ret
.touch_fail:
    mov esi, t_err_file
    call term_addline
    ret
.do_echo:
    call term_arg
    cmp edi, 0
    je .echo_fail
    mov esi, edi
    call term_addline
    ret
.echo_fail:
    ret
.do_ver:
    mov esi, t_about1
    call term_addline
    mov esi, t_about2
    call term_addline
    ret
.do_clear:
    mov edi, tbuf
    mov ecx, TLINES*TCOLS
    xor al, al
    cld
    rep stosb
    ret
.do_note:
    mov byte [npopen], 1
    mov byte [npmin], 0
    mov byte [focus], 0
    call np_load
    ret
.do_calc:
    mov byte [clopen], 1
    mov byte [clmin], 0
    mov byte [focus], 1
    ret
.do_about:
    mov byte [aboutopen], 1
    ret
.do_off:
    call shutdown
.do_reboot:
    call restart
.do_files:
    mov byte [fmopen], 1
    mov byte [fmmin], 0
    mov byte [focus], 5
    ret

over_setbtn:
    mov eax, [mx]
    cmp eax, SETX
    jb .no
    cmp eax, SETX + SETW
    jae .no
    mov eax, [my]
    cmp eax, SETY
    jb .no
    cmp eax, SETY + SETH
    jae .no
    mov al, 1
    ret
.no:
    xor al, al
    ret

over_menubtn:
    mov eax, [mx]
    cmp eax, MENUX
    jb .no
    cmp eax, MENUX + MENUW
    jae .no
    mov eax, [my]
    cmp eax, SETY
    jb .no
    cmp eax, SETY + MENUH
    jae .no
    mov al, 1
    ret
.no:
    xor al, al
    ret

over_sallbtn:
    mov eax, [mx]
    cmp eax, SALLX
    jb .no
    cmp eax, SALLX + SALLW
    jae .no
    mov eax, [my]
    cmp eax, SETY
    jb .no
    cmp eax, SETY + MENUH
    jae .no
    mov al, 1
    ret
.no:
    xor al, al
    ret

indicator_at_mouse:
    mov eax, [my]
    cmp eax, 3
    jb .none
    cmp eax, 17
    ja .none
    mov eax, [mx]
    cmp eax, W - 100
    jb .none
    cmp eax, W - 86
    jb .indN
    cmp eax, W - 84
    jb .none
    cmp eax, W - 70
    jb .indC
    cmp eax, W - 68
    jb .none
    cmp eax, W - 54
    jb .indS
    cmp eax, W - 52
    jb .none
    cmp eax, W - 38
    jb .indT
    cmp eax, W - 36
    jb .none
    cmp eax, W - 22
    jb .indF
    jmp .none
.indN:
    xor eax, eax
    ret
.indC:
    mov eax, 1
    ret
.indS:
    mov eax, 2
    ret
.indT:
    mov eax, 3
    ret
.indF:
    mov eax, 4
    ret
.none:
    mov eax, -1
    ret

over_cltitle:
    cmp byte [clopen], 1
    jne .no
    mov eax, [my]
    sub eax, [cly]
    cmp eax, 2
    jb .no
    cmp eax, 18
    ja .no
    mov eax, [mx]
    sub eax, [clx]
    cmp eax, 34
    jb .no
    cmp eax, CLW
    ja .no
    mov al, 1
    ret
.no:
    xor al, al
    ret

over_swtitle:
    cmp byte [setopen], 1
    jne .no
    mov eax, [my]
    sub eax, [swy]
    cmp eax, 2
    jb .no
    cmp eax, 18
    ja .no
    mov eax, [mx]
    sub eax, [swx]
    cmp eax, 34
    jb .no
    cmp eax, SWW
    ja .no
    mov al, 1
    ret
.no:
    xor al, al
    ret

over_nptitle:
    cmp byte [npopen], 1
    jne .no
    mov eax, [my]
    sub eax, [npy]
    cmp eax, 2
    jb .no
    cmp eax, 18
    ja .no
    mov eax, [mx]
    sub eax, [npx]
    cmp eax, 44
    jb .no
    cmp eax, NPW
    ja .no
    mov al, 1
    ret
.no:
    xor al, al
    ret

over_ttitle:
    cmp byte [topen], 1
    jne .no
    mov eax, [my]
    sub eax, [ty]
    cmp eax, 2
    jb .no
    cmp eax, 18
    ja .no
    mov eax, [mx]
    sub eax, [tx]
    cmp eax, 48
    jb .no
    cmp eax, TW
    ja .no
    mov al, 1
    ret
.no:
    xor al, al
    ret

over_fmtitle:
    cmp byte [fmopen], 1
    jne .no
    mov eax, [my]
    sub eax, [fmy]
    cmp eax, 2
    jb .no
    cmp eax, 18
    ja .no
    mov eax, [mx]
    sub eax, [fmx]
    cmp eax, 34
    jb .no
    cmp eax, FMW
    ja .no
    mov al, 1
    ret
.no:
    xor al, al
    ret

over_npclose:
    cmp byte [npopen], 1
    jne .no
    mov eax, [mx]
    sub eax, [npx]
    cmp eax, 34
    jb .no
    cmp eax, 46
    ja .no
    mov eax, [my]
    sub eax, [npy]
    cmp eax, 4
    jb .no
    cmp eax, 16
    ja .no
    mov al, 1
    ret
.no:
    xor al, al
    ret

over_npfull:
    cmp byte [npopen], 1
    jne .no
    mov eax, [mx]
    sub eax, [npx]
    cmp eax, 20
    jb .no
    cmp eax, 32
    ja .no
    mov eax, [my]
    sub eax, [npy]
    cmp eax, 4
    jb .no
    cmp eax, 16
    ja .no
    mov al, 1
    ret
.no:
    xor al, al
    ret

over_npmin:
    cmp byte [npopen], 1
    jne .no
    mov eax, [mx]
    sub eax, [npx]
    cmp eax, 6
    jb .no
    cmp eax, 18
    ja .no
    mov eax, [my]
    sub eax, [npy]
    cmp eax, 4
    jb .no
    cmp eax, 16
    ja .no
    mov al, 1
    ret
.no:
    xor al, al
    ret

over_tclose:
    cmp byte [topen], 1
    jne .no
    mov eax, [mx]
    sub eax, [tx]
    cmp eax, 34
    jb .no
    cmp eax, 46
    ja .no
    mov eax, [my]
    sub eax, [ty]
    cmp eax, 4
    jb .no
    cmp eax, 16
    ja .no
    mov al, 1
    ret
.no:
    xor al, al
    ret

over_tfull:
    cmp byte [topen], 1
    jne .no
    mov eax, [mx]
    sub eax, [tx]
    cmp eax, 20
    jb .no
    cmp eax, 32
    ja .no
    mov eax, [my]
    sub eax, [ty]
    cmp eax, 4
    jb .no
    cmp eax, 16
    ja .no
    mov al, 1
    ret
.no:
    xor al, al
    ret

over_tmin:
    cmp byte [topen], 1
    jne .no
    mov eax, [mx]
    sub eax, [tx]
    cmp eax, 6
    jb .no
    cmp eax, 18
    ja .no
    mov eax, [my]
    sub eax, [ty]
    cmp eax, 4
    jb .no
    cmp eax, 16
    ja .no
    mov al, 1
    ret
.no:
    xor al, al
    ret

over_fmclose:
    cmp byte [fmopen], 1
    jne .no
    mov eax, [mx]
    sub eax, [fmx]
    cmp eax, 20
    jb .no
    cmp eax, 32
    ja .no
    mov eax, [my]
    sub eax, [fmy]
    cmp eax, 4
    jb .no
    cmp eax, 16
    ja .no
    mov al, 1
    ret
.no:
    xor al, al
    ret

over_fmmin:
    cmp byte [fmopen], 1
    jne .no
    mov eax, [mx]
    sub eax, [fmx]
    cmp eax, 6
    jb .no
    cmp eax, 18
    ja .no
    mov eax, [my]
    sub eax, [fmy]
    cmp eax, 4
    jb .no
    cmp eax, 16
    ja .no
    mov al, 1
    ret
.no:
    xor al, al
    ret

over_clclose:
    cmp byte [clopen], 1
    jne .no
    mov eax, [mx]
    sub eax, [clx]
    cmp eax, 20
    jb .no
    cmp eax, 32
    ja .no
    mov eax, [my]
    sub eax, [cly]
    cmp eax, 4
    jb .no
    cmp eax, 16
    ja .no
    mov al, 1
    ret
.no:
    xor al, al
    ret

over_clmin:
    cmp byte [clopen], 1
    jne .no
    mov eax, [mx]
    sub eax, [clx]
    cmp eax, 6
    jb .no
    cmp eax, 18
    ja .no
    mov eax, [my]
    sub eax, [cly]
    cmp eax, 4
    jb .no
    cmp eax, 16
    ja .no
    mov al, 1
    ret
.no:
    xor al, al
    ret

over_closebtn:
    cmp byte [setopen], 1
    jne .no
    mov eax, [mx]
    sub eax, [swx]
    cmp eax, 6
    jb .no
    cmp eax, 18
    ja .no
    mov eax, [my]
    sub eax, [swy]
    cmp eax, 4
    jb .no
    cmp eax, 16
    ja .no
    mov al, 1
    ret
.no:
    xor al, al
    ret

over_swback:
    cmp byte [setopen], 1
    jne .no
    mov eax, [mx]
    sub eax, [swx]
    cmp eax, 20
    jb .no
    cmp eax, 34
    ja .no
    mov eax, [my]
    sub eax, [swy]
    cmp eax, 4
    jb .no
    cmp eax, 16
    ja .no
    mov al, 1
    ret
.no:
    xor al, al
    ret

over_swmin:
    cmp byte [setopen], 1
    jne .no
    mov eax, [mx]
    sub eax, [swx]
    cmp eax, 34
    jb .no
    cmp eax, 46
    ja .no
    mov eax, [my]
    sub eax, [swy]
    cmp eax, 4
    jb .no
    cmp eax, 16
    ja .no
    mov al, 1
    ret
.no:
    xor al, al
    ret

dock_at_mouse:
    mov eax, [my]
    cmp eax, DOCKY
    jb .none
    cmp eax, DOCKY + DOCKH
    jae .none
    mov eax, [mx]
    xor edx, edx
    mov ecx, DOCKW
    div ecx
    cmp eax, 5
    jae .none
    ret
.none:
    mov eax, -1
    ret

desktopicons_at_mouse:
    push ebx
    xor ebx, ebx
.loop:
    cmp ebx, 3
    jae .none
    mov eax, ebx
    shl eax, 2
    add eax, iconx
    mov eax, [eax]
    mov [ico_tmp_x], eax
    mov eax, ebx
    shl eax, 2
    add eax, icony
    mov eax, [eax]
    mov [ico_tmp_y], eax
    mov eax, [mx]
    cmp eax, [ico_tmp_x]
    jb .next
    mov edx, [ico_tmp_x]
    add edx, 24
    cmp eax, edx
    ja .next
    mov eax, [my]
    cmp eax, [ico_tmp_y]
    jb .next
    mov edx, [ico_tmp_y]
    add edx, 24
    cmp eax, edx
    ja .next
    mov eax, ebx
    pop ebx
    ret
.next:
    inc ebx
    jmp .loop
.none:
    pop ebx
    mov eax, -1
    ret

on_click:
    cmp byte [ctxopen], 1
    jne .noctx
    mov eax, [mx]
    cmp eax, [ctx_x]
    jb .closectx
    push eax
    mov eax, [ctx_x]
    add eax, CTXW
    cmp [esp], eax
    pop eax
    ja .closectx
    mov eax, [my]
    cmp eax, [ctx_y]
    jb .closectx
    push eax
    mov eax, [ctx_y]
    add eax, CTXH
    cmp [esp], eax
    pop eax
    ja .closectx
    mov eax, [my]
    sub eax, [ctx_y]
    sub eax, 4
    js .closectx
    xor edx, edx
    mov ecx, 16
    div ecx
    cmp eax, 0
    jne .ctx_about
    mov byte [setopen], 1
    mov byte [setmin], 0
    mov byte [setpage], 0
    mov byte [focus], 2
    mov byte [ctxopen], 0
    ret
.ctx_about:
    cmp eax, 1
    jne .closectx
    mov byte [aboutopen], 1
    mov byte [ctxopen], 0
    ret
.closectx:
    mov byte [ctxopen], 0
    ret
.noctx:

    cmp byte [menuopen], 1
    jne .notmenu
    call menu_at_mouse
    cmp eax, -1
    je .closemenu
    cmp eax, 0
    jne .m1
    mov byte [npopen], 1
    mov byte [npmin], 0
    mov byte [focus], 0
    call np_load
    jmp .menuclose
.m1:
    cmp eax, 1
    jne .m2
    mov byte [topen], 1
    mov byte [tmin], 0
    mov byte [focus], 3
    jmp .menuclose
.m2:
    cmp eax, 2
    jne .m3
    mov byte [clopen], 1
    mov byte [clmin], 0
    mov byte [focus], 1
    jmp .menuclose
.m3:
    cmp eax, 3
    jne .m4
    mov byte [setopen], 1
    mov byte [setmin], 0
    mov byte [setpage], 0
    mov byte [focus], 2
    jmp .menuclose
.m4:
    cmp eax, 4
    jne .m5
    call shutdown
    jmp .menuclose
.m5:
    cmp eax, 5
    jne .menuclose
    call restart
.menuclose:
    mov byte [menuopen], 0
    ret
.closemenu:
    mov byte [menuopen], 0
    ret
.notmenu:

    call over_menubtn
    test al, al
    jz .notmb
    mov byte [menuopen], 1
    ret
.notmb:

    call over_sallbtn
    test al, al
    jz .notsall
    mov byte [npmin], 1
    mov byte [clmin], 1
    mov byte [setmin], 1
    mov byte [tmin], 1
    mov byte [fmmin], 1
    ret
.notsall:

    call over_setbtn
    test al, al
    jz .notset
    mov byte [setopen], 1
    mov byte [setmin], 0
    mov byte [setpage], 0
    mov byte [focus], 2
    ret
.notset:

    mov edx, SALLX + SALLW + 4
    xor ebx, ebx
.pin_click:
    cmp ebx, ITEMS
    jae .pin_done
    cmp byte [pinstate + ebx], 0
    je .pin_next
    mov eax, [my]
    cmp eax, SETY
    jb .pin_next
    cmp eax, SETY + MENUH
    ja .pin_next
    mov eax, [mx]
    cmp eax, edx
    jb .pin_next
    push eax
    mov eax, edx
    add eax, 20
    cmp [esp], eax
    pop eax
    ja .pin_next
    cmp ebx, 0
    jne .pc1
    mov byte [npopen], 1
    mov byte [npmin], 0
    mov byte [focus], 0
    call np_load
    ret
.pc1:
    cmp ebx, 1
    jne .pc2
    mov byte [topen], 1
    mov byte [tmin], 0
    mov byte [focus], 3
    ret
.pc2:
    cmp ebx, 2
    jne .pc3
    mov byte [clopen], 1
    mov byte [clmin], 0
    mov byte [focus], 1
    ret
.pc3:
    cmp ebx, 3
    jne .pc4
    mov byte [setopen], 1
    mov byte [setmin], 0
    mov byte [setpage], 0
    mov byte [focus], 2
    ret
.pc4:
    cmp ebx, 4
    jne .pc5
    call shutdown
    ret
.pc5:
    cmp ebx, 5
    jne .pin_next
    call restart
    ret
.pin_next:
    inc ebx
    add edx, 24
    jmp .pin_click
.pin_done:

    call indicator_at_mouse
    cmp eax, -1
    je .notind
    cmp eax, 0
    jne .iC
    cmp byte [npopen], 0
    je .np_open_it
    cmp byte [npmin], 0
    je .np_minimize
    mov byte [npmin], 0
    mov byte [focus], 0
    ret
.np_minimize:
    mov byte [npmin], 1
    ret
.np_open_it:
    mov byte [npopen], 1
    mov byte [npmin], 0
    mov byte [focus], 0
    call np_load
    ret
.iC:
    cmp eax, 1
    jne .iS
    cmp byte [clopen], 0
    je .cl_open_it
    cmp byte [clmin], 0
    je .cl_minimize
    mov byte [clmin], 0
    mov byte [focus], 1
    ret
.cl_minimize:
    mov byte [clmin], 1
    ret
.cl_open_it:
    mov byte [clopen], 1
    mov byte [clmin], 0
    mov byte [focus], 1
    ret
.iS:
    cmp eax, 2
    jne .iT
    cmp byte [setopen], 0
    je .set_open_it
    cmp byte [setmin], 0
    je .set_minimize
    mov byte [setmin], 0
    mov byte [focus], 2
    ret
.set_minimize:
    mov byte [setmin], 1
    ret
.set_open_it:
    mov byte [setopen], 1
    mov byte [setmin], 0
    mov byte [setpage], 0
    mov byte [focus], 2
    ret
.iT:
    cmp eax, 3
    jne .iF
    cmp byte [topen], 0
    je .t_open_it
    cmp byte [tmin], 0
    je .t_minimize
    mov byte [tmin], 0
    mov byte [focus], 3
    ret
.t_minimize:
    mov byte [tmin], 1
    ret
.t_open_it:
    mov byte [topen], 1
    mov byte [tmin], 0
    mov byte [focus], 3
    ret
.iF:
    cmp eax, 4
    jne .notind
    cmp byte [fmopen], 0
    je .fm_open_it
    cmp byte [fmmin], 0
    je .fm_minimize
    mov byte [fmmin], 0
    mov byte [focus], 5
    ret
.fm_minimize:
    mov byte [fmmin], 1
    ret
.fm_open_it:
    mov byte [fmopen], 1
    mov byte [fmmin], 0
    mov byte [focus], 5
    ret
.notind:

    cmp byte [aboutopen], 1
    jne .noabout
    mov eax, [mx]
    sub eax, [abx]
    cmp eax, 6
    jb .noabout
    cmp eax, 18
    ja .noabout
    mov eax, [my]
    sub eax, [aby]
    cmp eax, 4
    jb .noabout
    cmp eax, 16
    ja .noabout
    mov byte [aboutopen], 0
    ret
.noabout:

    cmp byte [setopen], 1
    jne .c1
    cmp byte [setmin], 1
    je .c1
    call over_closebtn
    test al, al
    jz .sm1
    mov byte [setopen], 0
    ret
.sm1:
    cmp byte [setpage], 0
    je .sm_page0
    call over_swback
    test al, al
    jz .sm_page0
    mov byte [setpage], 0
    ret
.sm_page0:
    cmp byte [setpage], 0
    jne .sm_page1
    mov eax, [my]
    sub eax, [swy]
    cmp eax, 24
    jb .sm_page1
    cmp eax, 40
    ja .sm_page1
    mov eax, [mx]
    sub eax, [swx]
    cmp eax, 10
    jb .sm_page1
    cmp eax, 130
    ja .sm_page1
    mov byte [setpage], 1
    ret
.sm_page1:
    cmp byte [setpage], 0
    jne .sm_page2
    mov eax, [my]
    sub eax, [swy]
    cmp eax, 44
    jb .sm_page2
    cmp eax, 60
    ja .sm_page2
    mov eax, [mx]
    sub eax, [swx]
    cmp eax, 10
    jb .sm_page2
    cmp eax, 130
    ja .sm_page2
    mov byte [setpage], 2
    ret
.sm_page2:
    cmp byte [setpage], 1
    jne .sm_page3
    mov eax, [my]
    sub eax, [swy]
    cmp eax, 40
    jb .sm_page3
    cmp eax, 52
    ja .sm_page3
    mov eax, [mx]
    sub eax, [swx]
    sub eax, 10
    js .sm_page3
    xor edx, edx
    mov ecx, SWCW
    div ecx
    cmp eax, 16
    jae .sm_page3
    mov [titlecol], al
    call cfg_save
    ret
.sm_page3:
    cmp byte [setpage], 2
    jne .c1
    mov eax, [my]
    sub eax, [swy]
    cmp eax, 22
    jb .sm_colors
    cmp eax, 34
    ja .sm_colors
    mov eax, [mx]
    sub eax, [swx]
    cmp eax, 6
    jb .sm_colors
    cmp eax, 50
    jb .sm_m1
    cmp eax, 56
    jb .sm_colors
    cmp eax, 100
    jb .sm_m2
    cmp eax, 106
    jb .sm_colors
    cmp eax, 150
    jb .sm_m3
    jmp .sm_colors
.sm_m1:
    mov byte [bgmode], 1
    call cfg_save
    ret
.sm_m2:
    mov byte [bgmode], 2
    call cfg_save
    ret
.sm_m3:
    mov byte [bgmode], 3
    call cfg_save
    ret
.sm_colors:
    mov eax, [my]
    sub eax, [swy]
    cmp eax, 40
    jb .c1
    cmp eax, 52
    jbe .sm_r1
    cmp eax, 60
    jb .c1
    cmp eax, 72
    jbe .sm_r2
    cmp eax, 80
    jb .c1
    cmp eax, 92
    jbe .sm_r3
    jmp .c1
.sm_r1:
    mov eax, [mx]
    sub eax, [swx]
    sub eax, 10
    js .c1
    xor edx, edx
    mov ecx, SWCW
    div ecx
    cmp eax, 16
    jae .c1
    mov [bgcol1], al
    call cfg_save
    ret
.sm_r2:
    mov eax, [mx]
    sub eax, [swx]
    sub eax, 10
    js .c1
    xor edx, edx
    mov ecx, SWCW
    div ecx
    cmp eax, 16
    jae .c1
    mov [bgcol2], al
    call cfg_save
    ret
.sm_r3:
    mov eax, [mx]
    sub eax, [swx]
    sub eax, 10
    js .c1
    xor edx, edx
    mov ecx, SWCW
    div ecx
    cmp eax, 16
    jae .c1
    mov [bgcol3], al
    call cfg_save
    ret
.c1:
    cmp byte [fmopen], 1
    jne .c3
    cmp byte [fmmin], 1
    je .c3
    call over_fmclose
    test al, al
    jz .c1fm
    mov byte [fmopen], 0
    ret
.c1fm:
    call over_fmmin
    test al, al
    jz .c1sel
    mov byte [fmmin], 1
    ret
.c1sel:
    mov eax, [mx]
    sub eax, [fmx]
    cmp eax, 6
    jb .c3
    cmp eax, FMW - 6
    ja .c3
    mov eax, [my]
    sub eax, [fmy]
    cmp eax, 50
    jb .c3
    cmp eax, 110
    ja .c3
    sub eax, 50
    xor edx, edx
    mov ecx, 12
    div ecx
    call load_dir
    mov dword [fm_sel], -1
    xor ebx, ebx
    xor edx, edx
.sel_find:
    cmp ebx, MAXFILES
    jae .c3
    mov ecx, ebx
    imul ecx, ENTSZ
    add ecx, dirbuf
    cmp byte [ecx], 0
    je .sel_next
    cmp edx, eax
    jne .sel_skip
    mov [fm_sel], ebx
    ret
.sel_skip:
    inc edx
.sel_next:
    inc ebx
    jmp .sel_find
.c3:
    cmp byte [npopen], 1
    jne .c3b
    cmp byte [npmin], 1
    je .c3b
    call over_npclose
    test al, al
    jz .c3f
    mov byte [npopen], 0
    ret
.c3f:
    call over_npfull
    test al, al
    jz .c3m
    cmp byte [npfull], 0
    je .c3full_on
    mov byte [npfull], 0
    mov dword [npx], 30
    mov dword [npy], 40
    ret
.c3full_on:
    mov byte [npfull], 1
    mov dword [npx], 0
    mov dword [npy], TOPH
    ret
.c3m:
    call over_npmin
    test al, al
    jz .c3b
    mov byte [npmin], 1
    ret
.c3b:
    cmp byte [topen], 1
    jne .c2
    cmp byte [tmin], 1
    je .c2
    call over_tclose
    test al, al
    jz .c2f
    mov byte [topen], 0
    ret
.c2f:
    call over_tfull
    test al, al
    jz .c2m
    cmp byte [tfull], 0
    je .c2full_on
    mov byte [tfull], 0
    mov dword [tx], 20
    mov dword [ty], 25
    ret
.c2full_on:
    mov byte [tfull], 1
    mov dword [tx], 0
    mov dword [ty], TOPH
    ret
.c2m:
    call over_tmin
    test al, al
    jz .c2
    mov byte [tmin], 1
    ret
.c2:
    cmp byte [clopen], 1
    jne .c1end
    cmp byte [clmin], 1
    je .c1end
    call calc_btn_at
    cmp eax, -1
    jne .calc_press_it
    call over_clclose
    test al, al
    jz .c1m
    mov byte [clopen], 0
    ret
.c1m:
    call over_clmin
    test al, al
    jz .c1end
    mov byte [clmin], 1
    ret
.calc_press_it:
    call calc_press
    ret
.c1end:
    cmp byte [fmopen], 1
    jne .ff0
    cmp byte [fmmin], 1
    je .ff0
    mov eax, [mx]
    sub eax, [fmx]
    cmp eax, 0
    jb .ff0
    cmp eax, FMW
    ja .ff0
    mov eax, [my]
    sub eax, [fmy]
    cmp eax, 0
    jb .ff0
    cmp eax, FMH
    ja .ff0
    mov byte [focus], 5
    ret
.ff0:
    cmp byte [setopen], 1
    jne .ff1
    cmp byte [setmin], 1
    je .ff1
    mov eax, [mx]
    sub eax, [swx]
    cmp eax, 0
    jb .ff1
    cmp eax, SWW
    ja .ff1
    mov eax, [my]
    sub eax, [swy]
    cmp eax, 0
    jb .ff1
    cmp eax, 130
    ja .ff1
    mov byte [focus], 2
    ret
.ff1:
    cmp byte [clopen], 1
    jne .ff2
    cmp byte [clmin], 1
    je .ff2
    mov eax, [mx]
    sub eax, [clx]
    cmp eax, 0
    jb .ff2
    cmp eax, CLW
    ja .ff2
    mov eax, [my]
    sub eax, [cly]
    cmp eax, 0
    jb .ff2
    cmp eax, CLH
    ja .ff2
    mov byte [focus], 1
    ret
.ff2:
    cmp byte [npopen], 1
    jne .ff3
    cmp byte [npmin], 1
    je .ff3
    mov eax, [mx]
    sub eax, [npx]
    cmp eax, 0
    jb .ff3
    cmp eax, NPW
    ja .ff3
    mov eax, [my]
    sub eax, [npy]
    cmp eax, 0
    jb .ff3
    cmp eax, NPH
    ja .ff3
    mov byte [focus], 0
    ret
.ff3:
    cmp byte [topen], 1
    jne .ff4
    cmp byte [tmin], 1
    je .ff4
    mov eax, [mx]
    sub eax, [tx]
    cmp eax, 0
    jb .ff4
    cmp eax, TW
    ja .ff4
    mov eax, [my]
    sub eax, [ty]
    cmp eax, 0
    jb .ff4
    cmp eax, TH
    ja .ff4
    mov byte [focus], 3
    ret
.ff4:
    call dock_at_mouse
    cmp eax, -1
    je .done
    cmp eax, 0
    jne .d1
    mov byte [npopen], 1
    mov byte [npmin], 0
    mov byte [focus], 0
    call np_load
    ret
.d1:
    cmp eax, 1
    jne .d2
    mov byte [topen], 1
    mov byte [tmin], 0
    mov byte [focus], 3
    ret
.d2:
    cmp eax, 2
    jne .d3
    mov byte [clopen], 1
    mov byte [clmin], 0
    mov byte [focus], 1
    ret
.d3:
    cmp eax, 3
    jne .d4
    mov byte [fmopen], 1
    mov byte [fmmin], 0
    mov byte [focus], 5
    ret
.d4:
    cmp eax, 4
    jne .done
    call shutdown
.done:
    ret

on_rclick:
    cmp byte [ctxopen], 1
    je .closeall
    cmp byte [menuopen], 1
    jne .nomenu
    call menu_at_mouse
    cmp eax, -1
    je .closeall
    cmp byte [pinstate + eax], 0
    jne .unpin_me
    mov byte [pinstate + eax], 1
    ret
.unpin_me:
    mov byte [pinstate + eax], 0
    ret
.closeall:
    mov byte [ctxopen], 0
    mov byte [menuopen], 0
    ret
.nomenu:
    mov eax, [my]
    cmp eax, TOPH
    jb .done
    cmp eax, DOCKY
    jae .done
    cmp byte [npopen], 1
    je .done
    cmp byte [clopen], 1
    je .done
    cmp byte [setopen], 1
    je .done
    cmp byte [aboutopen], 1
    je .done
    cmp byte [topen], 1
    je .done
    cmp byte [fmopen], 1
    je .done
    mov eax, [mx]
    mov [ctx_x], eax
    mov eax, [my]
    mov [ctx_y], eax
    mov byte [ctxopen], 1
    ret
.done:
    ret

menu_at_mouse:
    cmp byte [menuopen], 1
    jne .none
    mov eax, [mx]
    cmp eax, MENUWIN_X
    jb .none
    cmp eax, MENUWIN_X + MENUWIN_W
    ja .none
    mov eax, [my]
    cmp eax, MENUWIN_Y
    jb .none
    sub eax, MENUWIN_Y + 4
    js .none
    xor edx, edx
    mov ecx, 16
    div ecx
    cmp eax, ITEMS
    jae .none
    ret
.none:
    mov eax, -1
    ret

key_decode:
    movzx eax, al
    cmp eax, 58
    jae .none
    cmp byte [shift], 1
    je .shifted
    movzx eax, byte [keymap + eax]
    ret
.shifted:
    movzx eax, byte [keymap_shift + eax]
    ret
.none:
    xor al, al
    ret

keymap:
    db 0,27,49,50,51,52,53,54,55,56,57,48
    db 45,61,8,9,113,119,101,114,116,121,117,105
    db 111,112,91,93,13,0,97,115,100,102,103,104
    db 106,107,108,59,39,96,0,0,122,120,99,118
    db 98,110,109,44,46,47,0,0,0,32

keymap_shift:
    db 0,27,33,64,35,36,37,94,38,42,40,41
    db 95,43,8,9,81,87,69,82,84,89,85,73
    db 79,80,123,125,13,0,65,83,68,70,71,72
    db 74,75,76,58,34,126,0,0,90,88,67,86
    db 66,78,77,60,62,63,0,0,0,32

CLW     equ 156
CLH     equ 156
CLBW    equ 34
CLBH    equ 22
CLGAP   equ 4

draw_calc:
    cmp byte [clopen], 1
    jne .e
    cmp byte [clmin], 1
    je .e
    mov eax, [clx]
    add eax, 2
    mov [rx], eax
    mov eax, [cly]
    add eax, 2
    mov [ry], eax
    mov dword [rw], CLW
    mov dword [rh], CLH
    mov byte [rc], 8
    call rect
    mov eax, [clx]
    mov [rx], eax
    mov eax, [cly]
    mov [ry], eax
    mov dword [rw], CLW
    mov dword [rh], CLH
    mov byte [rc], 7
    call rect
    mov eax, [clx]
    mov [bx0], eax
    mov eax, [cly]
    mov [by0], eax
    mov dword [bwid], CLW
    mov dword [bhgt], CLH
    mov byte [blight], 15
    mov byte [bdark], 8
    call bevel
    mov eax, [clx]
    add eax, 2
    mov [rx], eax
    mov eax, [cly]
    add eax, 2
    mov [ry], eax
    mov dword [rw], CLW - 4
    mov dword [rh], 16
    mov al, [titlecol]
    mov [rc], al
    call rect
    mov esi, t_clwin
    mov ecx, [clx]
    add ecx, 60
    mov edx, [cly]
    add edx, 4
    mov al, 15
    call text_at
    mov eax, [clx]
    add eax, 6
    mov [rx], eax
    mov eax, [cly]
    add eax, 4
    mov [ry], eax
    mov dword [rw], 12
    mov dword [rh], 12
    mov byte [rc], 7
    call rect
    mov eax, [clx]
    add eax, 6
    mov [bx0], eax
    mov eax, [cly]
    add eax, 4
    mov [by0], eax
    mov dword [bwid], 12
    mov dword [bhgt], 12
    mov byte [blight], 15
    mov byte [bdark], 8
    cmp byte [clmindown], 1
    jne .mup
    mov byte [blight], 8
    mov byte [bdark], 15
.mup:
    call bevel
    mov eax, [clx]
    add eax, 8
    mov [rx], eax
    mov eax, [cly]
    add eax, 12
    mov [ry], eax
    mov dword [rw], 8
    mov dword [rh], 2
    mov byte [rc], 0
    call rect
    mov eax, [clx]
    add eax, 20
    mov [rx], eax
    mov eax, [cly]
    add eax, 4
    mov [ry], eax
    mov dword [rw], 12
    mov dword [rh], 12
    mov byte [rc], 7
    call rect
    mov eax, [clx]
    add eax, 20
    mov [bx0], eax
    mov eax, [cly]
    add eax, 4
    mov [by0], eax
    mov dword [bwid], 12
    mov dword [bhgt], 12
    mov byte [blight], 15
    mov byte [bdark], 8
    cmp byte [clxdown], 1
    jne .xup
    mov byte [blight], 8
    mov byte [bdark], 15
.xup:
    call bevel
    xor ecx, ecx
.xdiag:
    push ecx
    mov eax, [clx]
    add eax, 22
    add eax, ecx
    mov [rx], eax
    mov eax, [cly]
    add eax, 6
    add eax, ecx
    mov [ry], eax
    mov dword [rw], 1
    mov dword [rh], 1
    mov byte [rc], 0
    call rect
    pop ecx
    push ecx
    mov eax, [clx]
    add eax, 22
    add eax, ecx
    mov [rx], eax
    mov eax, [cly]
    add eax, 11
    sub eax, ecx
    mov [ry], eax
    mov dword [rw], 1
    mov dword [rh], 1
    mov byte [rc], 0
    call rect
    pop ecx
    inc ecx
    cmp ecx, 6
    jb .xdiag
    mov eax, [clx]
    add eax, CLGAP
    mov [rx], eax
    mov eax, [cly]
    add eax, 22
    mov [ry], eax
    mov dword [rw], CLW - 2*CLGAP
    mov dword [rh], 22
    mov byte [rc], 15
    call rect
    mov esi, clbuf
    mov ecx, [clx]
    add ecx, CLGAP + 4
    mov edx, [cly]
    add edx, 25
    xor al, al
    call text_at
    xor ebx, ebx
.btn:
    cmp ebx, 16
    jae .done
    push ebx
    call calc_btn_pos
    mov dword [rw], CLBW
    mov dword [rh], CLBH
    mov byte [rc], 7
    call rect
    mov eax, [rx]
    mov [bx0], eax
    mov eax, [ry]
    mov [by0], eax
    mov dword [bwid], CLBW
    mov dword [bhgt], CLBH
    mov byte [blight], 15
    mov byte [bdark], 8
    pop ebx
    push ebx
    movzx eax, byte [cldown]
    cmp eax, 255
    je .noheld
    cmp eax, ebx
    jne .noheld
    mov byte [blight], 8
    mov byte [bdark], 15
.noheld:
    call bevel
    pop ebx
    push ebx
    call calc_btn_pos
    pop ebx
    push ebx
    movzx eax, byte [ebx + calclabels]
    mov [clchar], al
    mov byte [clchar+1], 0
    mov esi, clchar
    mov ecx, [rx]
    add ecx, 13
    mov edx, [ry]
    add edx, 3
    xor al, al
    call text_at
    pop ebx
    inc ebx
    jmp .btn
.done:
.e:
    ret

calc_btn_pos:
    push eax
    push edx
    mov eax, ebx
    and eax, 3
    imul eax, CLBW + CLGAP
    add eax, [clx]
    add eax, CLGAP
    mov [rx], eax
    mov eax, ebx
    shr eax, 2
    imul eax, CLBH + CLGAP
    add eax, [cly]
    add eax, 48
    mov [ry], eax
    pop edx
    pop eax
    ret

calc_btn_at:
    push ebx
    xor ebx, ebx
.l:
    cmp ebx, 16
    jae .none
    push ebx
    call calc_btn_pos
    pop ebx
    mov eax, [mx]
    cmp eax, [rx]
    jb .next
    push eax
    mov eax, [rx]
    add eax, CLBW
    cmp [esp], eax
    pop eax
    jae .next
    mov eax, [my]
    cmp eax, [ry]
    jb .next
    push eax
    mov eax, [ry]
    add eax, CLBH
    cmp [esp], eax
    pop eax
    jae .next
    mov eax, ebx
    pop ebx
    ret
.next:
    inc ebx
    jmp .l
.none:
    pop ebx
    mov eax, -1
    ret

calc_press:
    push eax
    movzx eax, byte [eax + calclabels]
    cmp al, 'C'
    je .clear
    cmp al, '='
    je .equals
    mov ecx, 0
.findend:
    cmp byte [clbuf + ecx], 0
    je .put
    inc ecx
    cmp ecx, 18
    jb .findend
    jmp .done
.put:
    mov [clbuf + ecx], al
    mov byte [clbuf + ecx + 1], 0
    jmp .done
.clear:
    mov byte [clbuf], 0
    jmp .done
.equals:
    call calc_eval
.done:
    pop eax
    ret

calc_eval:
    pusha
    mov esi, clbuf
    call read_num
    mov [clacc], eax
    mov al, [esi]
    test al, al
    jz .show
    mov [clop], al
    inc esi
    call read_num
    mov ebx, eax
    mov eax, [clacc]
    mov cl, [clop]
    cmp cl, '+'
    je .add
    cmp cl, '-'
    je .sub
    cmp cl, '*'
    je .mul
    cmp cl, '/'
    je .div
    jmp .show
.add:
    add eax, ebx
    jmp .save
.sub:
    sub eax, ebx
    jmp .save
.mul:
    imul eax, ebx
    jmp .save
.div:
    test ebx, ebx
    jz .show
    xor edx, edx
    div ebx
.save:
    mov [clacc], eax
.show:
    mov eax, [clacc]
    call num_to_buf
    popa
    ret

read_num:
    push ebx
    push ecx
    xor eax, eax
    xor ecx, ecx
.l:
    mov cl, [esi]
    cmp cl, '0'
    jb .done
    cmp cl, '9'
    ja .done
    imul eax, 10
    sub cl, '0'
    add eax, ecx
    inc esi
    jmp .l
.done:
    pop ecx
    pop ebx
    ret

num_to_buf:
    pusha
    mov edi, clbuf
    test eax, eax
    jns .pos
    mov byte [edi], '-'
    inc edi
    neg eax
.pos:
    mov ebx, 10
    xor ecx, ecx
.digits:
    xor edx, edx
    div ebx
    add dl, '0'
    push edx
    inc ecx
    test eax, eax
    jnz .digits
.write:
    pop edx
    mov [edi], dl
    inc edi
    dec ecx
    jnz .write
    mov byte [edi], 0
    popa
    ret

NPW     equ 260
NPH     equ 130
NPROWS  equ 6
NPCOLS  equ 30
NPSTR   equ 32

draw_notepad:
    cmp byte [npopen], 1
    jne .e
    cmp byte [npmin], 1
    je .e
    mov eax, [npx]
    add eax, 2
    mov [rx], eax
    mov eax, [npy]
    add eax, 2
    mov [ry], eax
    mov dword [rw], NPW
    mov dword [rh], NPH
    mov byte [rc], 8
    call rect
    mov eax, [npx]
    mov [rx], eax
    mov eax, [npy]
    mov [ry], eax
    mov dword [rw], NPW
    mov dword [rh], NPH
    mov byte [rc], 7
    call rect
    mov eax, [npx]
    mov [bx0], eax
    mov eax, [npy]
    mov [by0], eax
    mov dword [bwid], NPW
    mov dword [bhgt], NPH
    mov byte [blight], 15
    mov byte [bdark], 8
    call bevel
    mov eax, [npx]
    add eax, 2
    mov [rx], eax
    mov eax, [npy]
    add eax, 2
    mov [ry], eax
    mov dword [rw], NPW - 4
    mov dword [rh], 16
    mov al, [titlecol]
    mov [rc], al
    call rect
    mov esi, t_npwin
    mov ecx, [npx]
    add ecx, 130
    mov edx, [npy]
    add edx, 4
    mov al, 15
    call text_at
    mov eax, [npx]
    add eax, 6
    mov [rx], eax
    mov eax, [npy]
    add eax, 4
    mov [ry], eax
    mov dword [rw], 12
    mov dword [rh], 12
    mov byte [rc], 7
    call rect
    mov eax, [npx]
    add eax, 6
    mov [bx0], eax
    mov eax, [npy]
    add eax, 4
    mov [by0], eax
    mov dword [bwid], 12
    mov dword [bhgt], 12
    mov byte [blight], 15
    mov byte [bdark], 8
    cmp byte [npmindown], 1
    jne .mup
    mov byte [blight], 8
    mov byte [bdark], 15
.mup:
    call bevel
    mov eax, [npx]
    add eax, 8
    mov [rx], eax
    mov eax, [npy]
    add eax, 12
    mov [ry], eax
    mov dword [rw], 8
    mov dword [rh], 2
    mov byte [rc], 0
    call rect
    mov eax, [npx]
    add eax, 20
    mov [rx], eax
    mov eax, [npy]
    add eax, 4
    mov [ry], eax
    mov dword [rw], 12
    mov dword [rh], 12
    mov byte [rc], 7
    call rect
    mov eax, [npx]
    add eax, 20
    mov [bx0], eax
    mov eax, [npy]
    add eax, 4
    mov [by0], eax
    mov dword [bwid], 12
    mov dword [bhgt], 12
    mov byte [blight], 15
    mov byte [bdark], 8
    cmp byte [npfdown], 1
    jne .fup
    mov byte [blight], 8
    mov byte [bdark], 15
.fup:
    call bevel
    mov eax, [npx]
    add eax, 22
    mov [rx], eax
    mov eax, [npy]
    add eax, 6
    mov [ry], eax
    mov dword [rw], 8
    mov dword [rh], 8
    mov byte [rc], 0
    call rect
    mov eax, [npx]
    add eax, 24
    mov [rx], eax
    mov eax, [npy]
    add eax, 8
    mov [ry], eax
    mov dword [rw], 4
    mov dword [rh], 4
    mov byte [rc], 7
    call rect
    mov eax, [npx]
    add eax, 34
    mov [rx], eax
    mov eax, [npy]
    add eax, 4
    mov [ry], eax
    mov dword [rw], 12
    mov dword [rh], 12
    mov byte [rc], 7
    call rect
    mov eax, [npx]
    add eax, 34
    mov [bx0], eax
    mov eax, [npy]
    add eax, 4
    mov [by0], eax
    mov dword [bwid], 12
    mov dword [bhgt], 12
    mov byte [blight], 15
    mov byte [bdark], 8
    cmp byte [npxdown], 1
    jne .xup
    mov byte [blight], 8
    mov byte [bdark], 15
.xup:
    call bevel
    xor ecx, ecx
.xdiag:
    push ecx
    mov eax, [npx]
    add eax, 36
    add eax, ecx
    mov [rx], eax
    mov eax, [npy]
    add eax, 6
    add eax, ecx
    mov [ry], eax
    mov dword [rw], 1
    mov dword [rh], 1
    mov byte [rc], 0
    call rect
    pop ecx
    push ecx
    mov eax, [npx]
    add eax, 36
    add eax, ecx
    mov [rx], eax
    mov eax, [npy]
    add eax, 11
    sub eax, ecx
    mov [ry], eax
    mov dword [rw], 1
    mov dword [rh], 1
    mov byte [rc], 0
    call rect
    pop ecx
    inc ecx
    cmp ecx, 6
    jb .xdiag
    mov eax, [npx]
    add eax, 6
    mov [rx], eax
    mov eax, [npy]
    add eax, 22
    mov [ry], eax
    mov dword [rw], NPW - 12
    mov dword [rh], NPH - 28
    mov byte [rc], 15
    call rect
    mov esi, [p_npmsg]
    mov ecx, [npx]
    add ecx, NPW - 60
    mov edx, [npy]
    add edx, 4
    mov al, 15
    call text_at
    xor ebx, ebx
    mov edx, [npy]
    add edx, 24
.line:
    cmp ebx, NPROWS
    jae .done
    push ebx
    push edx
    mov esi, ebx
    imul esi, NPSTR
    add esi, npbuf
    mov ecx, [npx]
    add ecx, 10
    xor al, al
    call text_at
    pop edx
    pop ebx
    add edx, 16
    inc ebx
    jmp .line
.done:
    mov eax, [nprow]
    imul eax, 16
    add eax, [npy]
    add eax, 24 + 14
    mov [ry], eax
    mov eax, [npcol]
    imul eax, 8
    add eax, [npx]
    add eax, 10
    mov [rx], eax
    mov dword [rw], 7
    mov dword [rh], 2
    mov byte [rc], 0
    call rect
.e:
    ret

np_flatten:
    pusha
    mov edi, npflat
    xor ebx, ebx
.line:
    cmp ebx, NPROWS
    jae .done
    mov esi, ebx
    imul esi, NPSTR
    add esi, npbuf
    xor ecx, ecx
.ch:
    mov al, [esi + ecx]
    test al, al
    jz .eol
    mov [edi], al
    inc edi
    inc ecx
    cmp ecx, NPCOLS
    jb .ch
.eol:
    mov byte [edi], 10
    inc edi
    inc ebx
    jmp .line
.done:
    mov byte [edi], 0
    mov eax, edi
    sub eax, npflat
    mov [npflatlen], eax
    popa
    ret

np_unflatten:
    pusha
    mov [npflatlen], ecx
    mov edi, npbuf
    mov ecx, NPROWS*NPSTR
    xor al, al
    cld
    rep stosb
    mov esi, npflat
    xor ebx, ebx
    xor edx, edx
    mov ecx, [npflatlen]
.ch:
    test ecx, ecx
    jz .done
    mov al, [esi]
    inc esi
    dec ecx
    cmp al, 10
    je .nl
    cmp al, 32
    jb .ch
    cmp edx, NPCOLS
    jae .ch
    push edi
    mov edi, ebx
    imul edi, NPSTR
    add edi, npbuf
    add edi, edx
    mov [edi], al
    pop edi
    inc edx
    jmp .ch
.nl:
    inc ebx
    xor edx, edx
    cmp ebx, NPROWS
    jb .ch
.done:
    mov dword [nprow], 0
    mov dword [npcol], 0
    popa
    ret

np_save:
    pusha
    call np_flatten
    mov esi, t_npfile
    mov edi, npflat
    mov ecx, [npflatlen]
    call save_file
    test al, al
    jz .bad
    mov dword [p_npmsg], t_npsaved
    jmp .e
.bad:
    mov dword [p_npmsg], t_npfail
.e:
    popa
    ret

np_load:
    pusha
    mov esi, t_npfile
    mov edi, npflat
    call load_file
    test al, al
    jz .e
    call np_unflatten
    mov dword [p_npmsg], t_nploaded
.e:
    popa
    ret

cfg_save:
    pusha
    mov al, [titlecol]
    mov [cfgbuf], al
    mov al, [bgcol1]
    mov [cfgbuf+1], al
    mov al, [bgcol2]
    mov [cfgbuf+2], al
    mov al, [bgcol3]
    mov [cfgbuf+3], al
    mov al, [bgmode]
    mov [cfgbuf+4], al
    mov esi, t_cfgfile
    mov edi, cfgbuf
    mov ecx, 5
    call save_file
    popa
    ret

cfg_load:
    pusha
    mov esi, t_cfgfile
    mov edi, cfgbuf
    call load_file
    test al, al
    jz .e
    mov al, [cfgbuf]
    cmp al, 16
    jae .skip1
    mov [titlecol], al
.skip1:
    mov al, [cfgbuf+1]
    cmp al, 16
    jae .skip2
    mov [bgcol1], al
.skip2:
    mov al, [cfgbuf+2]
    cmp al, 16
    jae .skip3
    mov [bgcol2], al
.skip3:
    mov al, [cfgbuf+3]
    cmp al, 16
    jae .skip4
    mov [bgcol3], al
.skip4:
    mov al, [cfgbuf+4]
    cmp al, 1
    jb .e
    cmp al, 3
    ja .e
    mov [bgmode], al
.e:
    popa
    ret

np_key:
    cmp byte [ctrl], 1
    jne .noctrl
    cmp al, 's'
    je .save
    cmp al, 'S'
    je .save
    cmp al, 'c'
    je .copy
    cmp al, 'C'
    je .copy
    cmp al, 'v'
    je .paste
    cmp al, 'V'
    je .paste
    ret
.save:
    call np_save
    ret
.copy:
    call np_flatten
    mov esi, npflat
    mov edi, clip_text
    mov ecx, [npflatlen]
    test ecx, ecx
    jz .copy_done
.copy_loop:
    mov al, [esi]
    mov [edi], al
    inc esi
    inc edi
    dec ecx
    jnz .copy_loop
.copy_done:
    mov byte [edi], 0
    mov byte [clip_type], 2
    ret
.paste:
    cmp byte [clip_type], 2
    jne .e_paste
    mov esi, clip_text
    xor ecx, ecx
.paste_len:
    cmp byte [esi], 0
    je .paste_len_done
    inc esi
    inc ecx
    jmp .paste_len
.paste_len_done:
    test ecx, ecx
    jz .e_paste
    mov esi, clip_text
    mov edi, npflat
    cld
    rep movsb
    mov byte [edi], 0
    mov eax, edi
    sub eax, npflat
    mov ecx, eax
    call np_unflatten
.e_paste:
    ret
.noctrl:
    cmp al, 13
    je .enter
    cmp al, 8
    je .back
    cmp al, 32
    jb .e
    mov ecx, [npcol]
    cmp ecx, NPCOLS
    jae .e
    mov edi, [nprow]
    imul edi, NPSTR
    add edi, npbuf
    add edi, ecx
    mov [edi], al
    inc dword [npcol]
    ret
.enter:
    mov eax, [nprow]
    inc eax
    cmp eax, NPROWS
    jae .e
    mov [nprow], eax
    mov dword [npcol], 0
    ret
.back:
    cmp dword [npcol], 0
    je .e
    dec dword [npcol]
    mov ecx, [npcol]
    mov edi, [nprow]
    imul edi, NPSTR
    add edi, npbuf
    add edi, ecx
    mov byte [edi], 0
.e:
    ret

kwait_write:
    in al, 0x64
    test al, 2
    jnz kwait_write
    ret

kwait_read:
    push ecx
    mov ecx, 0x200000
.l:
    in al, 0x64
    test al, 1
    jnz .ok
    dec ecx
    jnz .l
.ok:
    pop ecx
    ret

msbyte:
    call kwait_read
    in al, 0x60
    ret

mouse_init:
    pusha
    call kwait_write
    mov al, 0xA8
    out 0x64, al
    call kwait_write
    mov al, 0x20
    out 0x64, al
    call kwait_read
    in al, 0x60
    or al, 2
    and al, 0xDF
    mov bl, al
    call kwait_write
    mov al, 0x60
    out 0x64, al
    call kwait_write
    mov al, bl
    out 0x60, al
    call kwait_write
    mov al, 0xD4
    out 0x64, al
    call kwait_write
    mov al, 0xF6
    out 0x60, al
    call msbyte
    call kwait_write
    mov al, 0xD4
    out 0x64, al
    call kwait_write
    mov al, 0xF4
    out 0x60, al
    call msbyte
    popa
    ret

read_packet:
    pusha
    call msbyte
    test al, 8
    jz .done
    mov bl, al
    and al, 1
    mov [mbtn], al
    and bl, 2
    shr bl, 1
    mov [mrbtn], bl
    call msbyte
    movsx eax, al
    add eax, [mx]
    cmp eax, 0
    jge .x1
    xor eax, eax
.x1:
    cmp eax, W-1
    jle .x2
    mov eax, W-1
.x2:
    mov [mx], eax
    call msbyte
    movsx eax, al
    neg eax
    add eax, [my]
    cmp eax, 0
    jge .y1
    xor eax, eax
.y1:
    cmp eax, H-1
    jle .y2
    mov eax, H-1
.y2:
    mov [my], eax
.done:
    popa
    ret

draw_cursor:
    pusha
    mov esi, cursor
    xor ecx, ecx
.row:
    xor edx, edx
.col:
    movzx ebx, byte [esi]
    inc esi
    test ebx, ebx
    jz .skip
    mov eax, [mx]
    add eax, edx
    cmp eax, W
    jae .skip
    push eax
    mov eax, [my]
    add eax, ecx
    cmp eax, H
    jae .skippop
    imul eax, W
    pop edi
    add eax, edi
    add eax, VGAMEM
    mov [eax], bl
    jmp .skip
.skippop:
    pop eax
.skip:
    inc edx
    cmp edx, 8
    jb .col
    inc ecx
    cmp ecx, 12
    jb .row
    popa
    ret

rect:
    pusha
    mov eax, [rx]
    mov ebx, [rw]
    mov ecx, [ry]
    mov edx, [rh]
    cmp eax, 0
    jge .xok
    add ebx, eax
    xor eax, eax
.xok:
    cmp eax, W
    jge .none
    push eax
    add eax, ebx
    cmp eax, W
    jle .xok2
    mov ebx, W
    sub ebx, [esp]
.xok2:
    pop eax
    cmp ecx, 0
    jge .yok
    add edx, ecx
    xor ecx, ecx
.yok:
    cmp ecx, H
    jge .none
    push ecx
    add ecx, edx
    cmp ecx, H
    jle .yok2
    mov edx, H
    sub edx, [esp]
.yok2:
    pop ecx
    cmp ebx, 0
    jle .none
    cmp edx, 0
    jle .none
    mov edi, ecx
    imul edi, W
    add edi, eax
    add edi, CANVAS
.row:
    push edx
    push edi
    mov ecx, ebx
    mov al, [rc]
    cld
    rep stosb
    pop edi
    add edi, W
    pop edx
    dec edx
    jnz .row
.none:
.done:
    popa
    ret

draw_char:
    pusha
    mov [chx], ecx
    mov [chy], edx
    mov bl, [charcol]
    xor ecx, ecx
.row:
    mov al, [esi+ecx]
    xor edx, edx
.col:
    test al, 0x80
    jz .skip
    push eax
    mov eax, [chx]
    add eax, edx
    cmp eax, 0
    jl .nodot
    cmp eax, W
    jge .nodot
    push eax
    mov eax, [chy]
    add eax, ecx
    cmp eax, 0
    jl .nodotpop
    cmp eax, H
    jge .nodotpop
    imul eax, W
    pop edi
    add eax, edi
    add eax, CANVAS
    mov [eax], bl
    jmp .nodot
.nodotpop:
    pop eax
.nodot:
    pop eax
.skip:
    shl al, 1
    inc edx
    cmp edx, 8
    jb .col
    inc ecx
    cmp ecx, 16
    jb .row
    popa
    ret

chx     dd 0
chy     dd 0

text_at:
    pusha
    mov [charcol], al
.next:
    movzx eax, byte [esi]
    test eax, eax
    jz .done
    push esi
    push ecx
    push edx
    shl eax, 4
    add eax, FONT
    mov esi, eax
    call draw_char
    pop edx
    pop ecx
    pop esi
    inc esi
    add ecx, 8
    cmp ecx, W-8
    jb .next
.done:
    popa
    ret

flip:
    pusha
    mov esi, CANVAS
    mov edi, VGAMEM
    mov ecx, W*H/4
    cld
    rep movsd
    popa
    ret

grab_font:
    pusha
    mov esi, 0x1000
    mov edi, FONT
    mov ecx, 256*16
    cld
    rep movsb
    popa
    ret

; === ДАННЫЕ ===
rx      dd 0
ry      dd 0
rw      dd 0
rh      dd 0
rc      db 0
charcol db 15

mx      dd 160
my      dd 100
mbtn    db 0
mrbtn   db 0
mrprev  db 0
shift   db 0

cursor:
    db 15,0,0,0,0,0,0,0
    db 15,15,0,0,0,0,0,0
    db 15,8,15,0,0,0,0,0
    db 15,8,8,15,0,0,0,0
    db 15,8,8,8,15,0,0,0
    db 15,8,8,8,8,15,0,0
    db 15,8,8,8,8,8,15,0
    db 15,8,8,8,15,15,15,15
    db 15,8,15,8,15,0,0,0
    db 15,15,0,15,8,15,0,0
    db 15,0,0,15,8,15,0,0
    db 0,0,0,0,15,15,0,0

sel     dd 0
ticks   dd 0
clock_x dd 0
clock_pos dd 0

docklabels:
    dd dl1, dl2, dl3, dl4, dl5
dl1 db "Note", 0
dl2 db "Term", 0
dl3 db "Calc", 0
dl4 db "Files", 0
dl5 db "Off", 0

menulabels:
    dd ml1, ml2, ml3, ml4, ml5, ml6
ml1 db "Notepad", 0
ml2 db "Terminal", 0
ml3 db "Calculator", 0
ml4 db "Settings", 0
ml5 db "Shutdown", 0
ml6 db "Restart", 0

pinstate db 0,0,0,0,0,0
pinchar  db 0, 0

iconletters:
    dd it1, it2, it3
it1 db "N", 0
it2 db "C", 0
it3 db "A", 0
iconnames:
    dd in1, in2, in3
in1 db "Note", 0
in2 db "Calc", 0
in3 db "About", 0

iconx   dd 8, 8, 8
icony   dd 30, 70, 110

drag_icon db 255
drag_id_x dd 0
drag_id_y dd 0
drag_ico_moved db 0
ico_tmp_x dd 0
ico_tmp_y dd 0

rtc_mode db 0
rtc_pm   db 0
rtc_hour db 0
rtc_min  db 0
rtc_sec  db 0
rtc_day  db 0
rtc_mon  db 0
timebuf  db 0,0,0,0

diskerr db 0
secbuf  times 512 db 0
dirbuf  times 512 db 0
idbuf   times 512 db 0
numbuf  times 16 db 0
numbuf2 times 16 db 0
disk_model times 42 db 0
disk_size_val dd 0
disk_size_unit db 0
savelen dd 0
savesrc dd 0
savename dd 0
saveent dd 0
loadlen dd 0
tscratch times 512 db 0
temp_echo times 40 db 0

clx     dd 90
cly     dd 25
clopen  db 0
clmin   db 0
clxdown db 0
clmindown db 0
cldown  db 255
clchar  db 0, 0
clbuf   times 20 db 0
cldrag  db 0
cldx    dd 0
cldy    dd 0
clacc   dd 0
clop    db 0

calclabels db "789/456*123-0C=+"

swx     dd 60
swy     dd 40
swdrag  db 0
swdx    dd 0
swdy    dd 0
swmindown db 0
setpage db 0

ctrl    db 0
npflat  times 512 db 0
npflatlen dd 0
p_npmsg dd t_npnone

npx     dd 30
npy     dd 40
npdrag  db 0
npdx    dd 0
npdy    dd 0

npopen  db 0
npmin   db 0
npfull  db 0
npxdown db 0
npmindown db 0
npfdown db 0
nprow   dd 0
npcol   dd 0
npbuf   times NPROWS*NPSTR db 0

setopen db 0
setmin  db 0
setdown db 0
xdown   db 0
bx0     dd 0
by0     dd 0
bwid    dd 0
bhgt    dd 0
blight  db 15
bdark   db 8
mprev   db 0

menuopen db 0

ctxopen db 0
ctx_x   dd 0
ctx_y   dd 0

aboutopen db 0
abx       dd 60
aby       dd 50
abxdown   db 0

bgmode   db 1
bgcol1   db 3
bgcol2   db 1
bgcol3   db 15
focus    db 4

tx       dd 20
ty       dd 25
topen    db 0
tmin     db 0
tfull    db 0
tdrag    db 0
tdx      dd 0
tdy      dd 0
txdown   db 0
tmindown db 0
tfdown   db 0
tbuf     times TLINES*TCOLS db 0
tin      times 34 db 0
tin_len  dd 0

fmx      dd 50
fmy      dd 40
fmopen   db 0
fmmin    db 0
fmdrag   db 0
fmdx     dd 0
fmdy     dd 0
fmxdown  db 0
fmmindown db 0
fm_sel   dd 0
fm_row   dd 0
clip_name times 16 db 0
clip_type db 0
clip_text times 512 db 0

t_menu    db "Menu", 0
t_sall    db "Hide", 0
t_colon   db ":", 0
t_dot     db ".", 0
t_space   db " ", 0
t_iN      db "N", 0
t_iC      db "C", 0
t_iS      db "S", 0
t_iT      db "T", 0
t_iF      db "F", 0
t_settings db "Settings", 0
t_about   db "About", 0
t_prompt  db "$", 0
t_unknown db "unknown", 0
t_help1   db "help, ls, dir, cat, open,", 0
t_help2   db "rm, touch, echo, ver, clear,", 0
t_help3   db "note, calc, files, off", 0
t_err_file db "no file", 0
t_ok_rm   db "removed", 0
t_ok_touch db "created", 0
t_mode1   db "1col", 0
t_mode2   db "2col", 0
t_mode3   db "3col", 0
t_wincol  db "Window color", 0
t_desksettings db "Desktop", 0
t_unit_kb db " KB", 0
t_unit_mb db " MB", 0
t_unit_gb db " GB", 0
t_about1  db "NOVO OS 0.2.0.1", 0
t_about2  db "Based on Xanex 0.6", 0
t_about3  db "Idea by Semen", 0
t_setwin  db "Settings", 0
t_fmwin   db "File Manager", 0
t_fmdisk  db "Disk 0:", 0
t_fmempty db "no files", 0
t_fmcopy  db "Copy", 0
t_fmpaste db "Paste", 0
t_fmrename db "Rename", 0
t_fmdel   db "Delete", 0
t_fmnew   db "New", 0
titlecol  db 1
cfgbuf    times 512 db 0
t_cfgfile db "config", 0
p_diskmsg dd t_diskbad
t_diskok  db "Disk: OK", 0
t_diskbad db "Disk: error", 0
t_npwin   db "Notepad", 0
t_clwin   db "Calculator", 0
t_twin    db "Terminal", 0
t_npfile  db "notes.txt", 0
t_npnone  db "", 0
t_npsaved db "saved", 0
t_nploaded db "loaded", 0
t_npfail  db "error", 0

cmd_help  db "help", 0
cmd_ls    db "ls", 0
cmd_dir   db "dir", 0
cmd_cat   db "cat", 0
cmd_open  db "open", 0
cmd_rm    db "rm", 0
cmd_touch db "touch", 0
cmd_echo  db "echo", 0
cmd_ver   db "ver", 0
cmd_clear db "clear", 0
cmd_note  db "note", 0
cmd_calc  db "calc", 0
cmd_about db "about", 0
cmd_off   db "off", 0
cmd_reboot db "reboot", 0
cmd_files db "files", 0

times 65536-($-$$) db 0
