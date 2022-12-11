IDEAL
MODEL small
STACK 100h
DATASEG
;------------------------------------------------------Strings
s_start db 'Press S To Start$'
s_author db 'Liam Shani 2020$'
s_left db 'A -Left$'
s_right db 'D -Right$'
s_quit db 'ESC -Quit$'
s_lines db 'Lines Completed$'
s_gameover db 'GAME OVER!$'
s_totallines db 'Total Lines$'
s_restart db 'Press S To Play Again$'

s_score db '000$';string of score
s_Time db '00:00$';string of time

;----------------------------------------------------Configoration
score dw 0;score
ranNum db 0;number being incremented by several procedures, used in GenerateRanNum
screenwidth dw 320
IsSPressed db 0;flag if s is pressed
Quit db 0;flag if ESC is pressed
playerInputPressed db 0;flag if a key is pressed
blockSize dw 5
blocksPerPiece dw 4 ;num of blocks in one piece
BlocksPositions dw 0,0,0,0;stores the positions of each block of the piece
colourCemented dw 34,14,48,40,54,36,42;colour of a cemented piece
colorFallingPiece dw 47,6,37,33,55,39,44;colour of a piece that is falling
currentpiececolor dw 0;index of the current colour 
piecePosition dw 0;position of the top left corner of the piece
piecePosition2 dw 0
pieceOren dw 0;piece Orentation index
delay_Hunseconds db 5;delay between frames
seconds db 0
seconds1 db 99
delay_stop db 0
cementCounter db 0;num of frames when a piece can no longer fall and the player can still control it

;-----------------------------------------------------All of the pieces
pieceLine dw 10,1610,3210,4810
    dw 1600,1605,1610,1615 
    dw 10,1610,3210,4810
    dw 1600,1605,1610,1615 
pieceSquare dw 1605,1610,3205,3210 
    dw 1605,1610,3205,3210 
    dw 1605,1610,3205,3210  
    dw 1605,1610,3205,3210 
pieceT dw 1605,1610,1615,3210
    dw 10,1610,1615,3210
    dw 10,1605,1610,1615
    dw 10,1605,1610,3210
pieceJ dw 1605,1610,1615,3215
    dw 10,15,1610,3210
    dw 5,1605,1610,1615
    dw 10,1610,3205,3210
pieceL dw 10,1610,3210,3215
    dw 1605,1610,1615,3205
    dw 15,1605,1610,1615
    dw 5,10,1610,3210
pieceZ dw 1605,1610,3210,3215
    dw 15,1610,1615,3210
    dw 1605,1610,3210,3215
    dw 15,1610,1615,3210
pieceS dw 1610,1615,3205,3210
    dw 10,1610,1615,3215
    dw 1610,1615,3205,3210
    dw 10,1610,1615,3215


CODESEG


proc ClearScreen
    push es
    push ax
    push di
    push cx

    mov ax,0A000h
    mov es,ax
    mov ax,0
    xor di,di
    mov cx,(320*200)/2
    rep stosw;clears screen

    pop cx
    pop di
    pop ax
    pop es
    ret
endp ClearScreen


proc UpdateBlocksPositions
    cmp [pieceOren],0
    je pieceOren0

    cmp [pieceOren],1
    je pieceOren1

    cmp [pieceOren],2
    je pieceOren2

    add bx,24
    call ChangeBlocksPositions
    jmp endingUpdate

    pieceOren0:
    call ChangeBlocksPositions
    jmp endingUpdate
    pieceOren1:
    add bx,8
    call ChangeBlocksPositions
    jmp endingUpdate
    pieceOren2:
    add bx,16
    call ChangeBlocksPositions

    endingUpdate:
    ret
endp UpdateBlocksPositions


proc ChangeBlocksPositions
    push si
    push dx
    mov si,offset BlocksPositions
    mov cx,4
    loop_1:
        mov dx,[bx]
        mov [si],dx
        add bx,2
        add si,2
        loop loop_1  
    pop si
    pop dx
    ret
endp ChangeBlocksPositions


proc PrintTime
    mov dl,33
    mov dh,1
    mov bx,offset s_Time
    call PrintStringAt
    ret
endp PrintTime


proc ChangeTime
    mov ah,2Ch
    int 21h

    cmp dh,[seconds]
    ja ChangeTime1
    ret
    ChangeTime1:
    mov [seconds1],dh
    cmp [s_Time+4],'9'
    jne ChangeSeconds
    cmp [s_Time+3],'5'
    jne ChangeTens
    cmp [s_Time+1],'9'
    jne ChangeMin
    cmp [s_Time],'9'
    jne ChangeTensMin
    mov [s_Time],0
    mov [s_Time+1],0
    mov [s_Time+3],0
    mov [s_Time+4],0
    jmp endingSeconds


    ChangeSeconds:
    add [s_Time+4],1
    jmp endingSeconds

    ChangeTens:
    mov [s_Time+4],'0'
    add [s_Time+3],1
    jmp endingSeconds

    ChangeMin:
    mov [s_Time+3],'0'
    mov [s_Time+4],'0'
    add [s_Time+1],1
    jmp endingSeconds

    ChangeTensMin:
    mov [s_Time+1],'0'
    mov [s_Time+3],'0'
    mov [s_Time+4],'0'
    add [s_Time],1

    endingSeconds:
    call PrintTime    
    ret
endp ChangeTime


proc DeleteTime
    mov [s_Time],'0'
    mov [s_Time+1],'0'
    mov [s_Time+3],'0'
    mov [s_Time+4],'0'    
    ret
endp DeleteTime


proc PrintStringAt
    ;position the cursor
    push bx
    mov ah,2
    xor bh,bh
    int 10h

    ;print the string
    mov ah,9h
    pop dx
    int 21h
    ret
endp PrintStringAt


proc PrintStart
    mov bx,offset s_author
    mov dh,1
    mov dl,0
    call PrintStringAt;print the string author 
    mov bx, offset s_start
    mov dh,10
    mov dl,11
    call PrintStringAt;print the string start
    mov bx,offset s_quit
    mov dh,13
    mov dl,14
    call PrintStringAt;print the string quit
    ret
endp PrintStart


proc IsItESCOrS
    mov ah,1h
    int 16h;has a key got pressed?
    jne CharHasPressed;yes
    jmp ending_IsItESCOrS

    CharHasPressed:
    mov ah,0h;read key from buffer
    int 16h

    ;clear keyboard buffer
    push ax
    mov ah,6
    mov dl,0FFh
    int 21h
    pop ax

    cmp al,'s'
    je endingS
    cmp al,'S'
    je endingS

    cmp al,27d
    je endingESC
    jmp ending_IsItESCOrS

    endingS:
    mov [IsSPressed],1
    jmp ending_IsItESCOrS

    endingESC:
    mov [Quit],1

    ending_IsItESCOrS:
    ret
endp IsItESCOrS


proc DrawPixel
    push ax
    push es
    mov ax,0A000h;video memory offset
    mov es,ax
    mov [es:di],dl;draws the pixel
    pop es
    pop ax
    ret
endp DrawPixel


proc ReadPixel
    push ax
    push es
    ;reads pixels colour
    mov ax,0A000h
    mov es,ax
    mov dl,[es:di]

    pop es
    pop ax
    ret
endp ReadPixel


proc DrawHline
    loop_printlineH:
        call DrawPixel
        inc di
        loop loop_printlineH
    ret
endp DrawHline


proc DrawVline
    loop_printlineV:
        call DrawPixel
        add di,[screenwidth];moves di 1 pixel down
        loop loop_printlineV
    ret
endp DrawVline


proc DrawScreenPlay
    mov dl,27;colour white

    ;draws horizontal line between the left corner and the right corner
    mov cx,52
    mov di,14214
    call DrawHline

    ; draws vertical line between the top left and bottom left
    mov cx,105
    mov di,14534
    call DrawVline

    ;draws horizontal line between bottom left and bottom right
    mov cx,52
    mov di,48134
    call DrawHline

    ;draws vertical line between top right and bottom right
    mov cx,105
    mov di,14585
    call DrawVline

    ;draws the author string again
    mov bx,offset s_author
    mov dh,23
    mov dl,2
    call PrintStringAt

    ;draws the left string
    mov dh, 12
    mov dl, 2
    mov bx,offset s_left
    call PrintStringAt

    ;draws the right string
    mov dh, 10
    mov dl, 2
    mov bx,offset s_right
    call PrintStringAt

    ;draws the quit string
    mov dh, 14
    mov dl, 2
    mov bx,offset s_quit
    call PrintStringAt

    ;draws the lines string
    mov dh, 8
    mov dl, 24
    mov bx,offset s_lines
    call PrintStringAt

    ret
endp DrawScreenPlay


proc DisplayScore
    mov bx,offset s_score
    mov ax,[score]
    ;hundreds
    mov dl,100
    div dl
    mov cl,'0'
    add cl,al
    mov [bx],cl

    ;tens   
    mov al,ah
    xor ah,ah
    mov dl,10
    div dl
    mov cl,'0'
    add cl,al
    mov [bx+1],cl

    ;ones
    mov cl,'0'
    add cl,ah
    mov [bx+2],cl

    ;Display the score
    mov dh,10
    mov dl,30
    call PrintStringAt
    ret
endp DisplayScore


proc Delay1
    push ax
    push bx
    push cx
    push dx

    ;read current time
    xor bl,bl
    mov ah,2Ch
    int 21h

    mov al,[ranNum]
    add al,dl
    mov [ranNum],al

    ;store seconds
    mov [seconds],dh

    ;calculate stopping point and adjust
    add dl,[delay_Hunseconds]
    cmp dl,100
    jb delay_secondAdjustmentDone

    ;adjust
    sub dl,100
    mov bl,1

    delay_secondAdjustmentDone:
    mov [delay_stop],dl

    readTime:
    int 21h

    cmp bl,0;is it the same second
    je SameSecond;yes

    cmp dh,[seconds]
    je readTime
    ;not in the same second, so stop
    push dx
    sub dh,[seconds]
    cmp dh,2
    pop dx
    jae DelayDone
    jmp StoppingPointReachedCheck

    SameSecond:
    cmp dh,[seconds];if false were done
    jne DelayDone

    StoppingPointReachedCheck:
    cmp dl,[delay_stop];keep reading time if dl is below than stopping point
    jb readTime

    DelayDone:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
endp Delay1


proc DrawBlock
    push di
    push cx
    push dx
    mov cx,bx
    loop_DrawBlock:
        push cx
        push di
        mov cx,bx
        call DrawHline
        pop di
        add di,[screenwidth]
        pop cx
        loop loop_DrawBlock
    pop dx
    pop cx
    pop di
    ret
endp DrawBlock


proc DrawPiece
    mov cx,[blocksPerPiece]
    loop_drawPiece:;draws the blocks from last to first
        mov di,[piecePosition]
        mov bx,cx
        shl bx,1
        sub bx,2
        add di,[BlocksPositions+bx]
        mov bx,[blockSize]
        call DrawBlock
        loop loop_drawPiece
    ret
endp DrawPiece


proc MoveAndDrawPiece
    ;delete the old piece
    mov dl,0
    call DrawPiece

    ;changes the position
    mov ax,[piecePosition]
    add ax,[piecePosition2]
    mov [piecePosition],ax

    ;draw new piece
    mov bx,[currentpiececolor]
    shl bx,1
    mov dl,[byte ptr colorFallingPiece+bx]
    call DrawPiece
    ret
endp MoveAndDrawPiece


proc IsLinePossible
    push cx
    push di
    push bx
    mov cx,[blockSize]
    loop_IsLinePossible:
        call ReadPixel
        cmp dl,0
        jne LineObstacle

        IsLinePossibleNextPixel:
        add di,bx;next pixel
        loop loop_IsLinePossible

    xor ax,ax
    jmp IsLinePossibleDone

    LineObstacle:
    push bx
    mov bx,[currentpiececolor]
    shl bx,1;two bytes per color
    mov al,[byte ptr colorFallingPiece+bx]
    cmp dl,al
    pop bx
    jne IsLinePossibleFail
    jmp IsLinePossibleNextPixel

    IsLinePossibleFail:
    mov al,1

    IsLinePossibleDone:
    pop bx
    pop di
    pop cx
    ret
endp IsLinePossible


proc CanPieceBePlaced
    mov cx,[blocksPerPiece]
    loop_CanPieceBePlaced:
        mov di,[piecePosition]
        mov bx,cx
        shl bx,1
        sub bx,2
        add di,[BlocksPositions+bx]

        push cx
        mov bx,1
        mov cx,[blockSize]
        loop_2CanPieceBePlaced:
            call IsLinePossible
            cmp al,0
            jne Fail_CanPieceBePlaced
            add di,[screenwidth]
            loop loop_2CanPieceBePlaced

        pop cx

        loop loop_CanPieceBePlaced

    xor ax,ax
    jmp success_CanPieceBePlaced

    Fail_CanPieceBePlaced:
    mov al,1
    pop cx

    success_CanPieceBePlaced:
    ret
endp CanPieceBePlaced


proc GenerateRanNum
    mov al,[ranNum]
    add al,31
    mov [ranNum],al
    div bl
    mov al,ah;save remainder in al
    xor ah,ah
    ret
endp GenerateRanNum


proc RanPiece
    call Delay1
    mov bl,7
    call GenerateRanNum
    mov [currentpiececolor],ax
    mov bl,4
    call GenerateRanNum
    mov [pieceOren],ax
    ret
endp RanPiece


proc ReadChar
    mov ah,1h
    int 16h; has a Key Has been pressed
    jne keyPressed; yes
    jmp ending_ReadChar;no key has been pressed

    keypressed:
    ;reads key
    mov ah,0h
    int 16h
    cmp al,27;if ESC is pressed
    je quits

    cmp al,'a'
    jne checkA
    jmp moveLeft

    CheckA:
    cmp al,'A'
    jne Checkd
    jmp moveLeft

    Checkd:
    cmp al,'d'
    je moveRight
    cmp al,'D'
    je moveRight

    jmp ending_ReadChar;if the key doesnt match

    quits:
    mov [Quit],1
    jmp ending_ReadChar

    moveRight:
    mov [playerInputPressed],1
    mov cx,[blocksPerPiece]
    loop_MoveRight:
        mov di,[piecePosition]
        mov bx,cx
        shl bx,1
        sub bx,2
        add di,[BlocksPositions + bx]
        add di,[blockSize]
        mov bx,[screenwidth]
        call IsLinePossible;if line not possible cant move
        cmp al,0
        jne DoneR
        loop loop_MoveRight

    mov ax,[piecePosition2]
    add ax,[blockSize]
    mov [piecePosition2],ax

    DoneR:
    mov al,[ranNum]
    add al,3
    mov [ranNum],al
    jmp ending_ReadChar

    moveLeft:
    mov [playerInputPressed],1
    mov cx,[blocksPerPiece]
    loop_MoveLeft:
        mov di,[piecePosition]
        mov bx,cx
        shl bx,1
        sub bx,2
        add di,[BlocksPositions+bx]
        dec di
        mov bx,[screenwidth]
        call IsLinePossible;if line not possible cant move
        cmp al,0;if =0 line is possible
        jne DoneL
        loop loop_MoveLeft

    mov ax,[piecePosition2]
    sub ax,[blockSize]
    mov [piecePosition2],ax

    DoneL:
    mov al,[ranNum]
    add al,5
    mov [ranNum],al
    jmp ending_ReadChar

    ending_ReadChar:
    ret
endp ReadChar


proc AttemptLineRemoval
    push cx
    mov di,47815
    mov cx,104
    loop_LineRemoval:
        call IsHLineFull;is the line without black pixels?
        cmp al,0
        je FullLineFound;no
        sub di,[screenwidth];line isn't full
        loop loop_LineRemoval
    jmp NoLineFound;no full lines were found

    FullLineFound:
    loop_FullLineFound:
        push cx
        push di

        mov si,di
        sub si,[screenwidth]
        mov cx,50
        push ds
        push es
        mov ax,0A000h;video segment
        mov ds,ax
        mov es,ax
        rep movsb;memory copy-will work 50 times copying the line above the current line into current line

        pop es
        pop ds
        pop di
        pop cx
        sub di,[screenwidth]
        loop loop_FullLineFound

    xor dl,dl
    mov cx,50
    call DrawHline
    mov al,1
    jmp LineRemovalDone

    NoLineFound:
    xor al,al

    LineRemovalDone:
    pop cx
    ret
endp AttemptLineRemoval


proc IsHLineFull
    push di
    push cx
    mov cx,50
    loop_IsHLineFull:
        call ReadPixel
        cmp dl,0
        je Fail_IsHLineFull
        inc di
        loop loop_IsHLineFull
    xor ax,ax
    jmp IsHLineFullDone

    Fail_IsHLineFull:
    mov al,1

    IsHLineFullDone:
    pop cx
    pop di
    ret
endp IsHLineFull


proc CanMoveDown
    push di
    push cx
    mov cx,[blockSize]
    FindPosition:
    add di,[screenwidth]
    loop FindPosition

    mov bx,1
    call IsLinePossible
    cmp al,0
    jne ObstacleFound
    xor ax,ax
    jmp CanMoveDownDone

    ObstacleFound:
    mov ax,1

    CanMoveDownDone:
    pop cx
    pop di
    ret
endp CanMoveDown


proc DisplayGameOver
    call ClearScreen

    ;print the string game over
    mov bx,offset s_gameover
    mov dl,15
    mov dh,3
    call PrintStringAt

    ;print the string restart
    mov bx,offset s_restart
    mov dl,10
    mov dh,7
    call PrintStringAt

    ;print the string quit
    mov bx,offset s_quit
    mov dl,15
    mov dh,10
    call PrintStringAt
    ret
endp DisplayGameOver


;-------------------------------------------Main Program


GameStartTetris:
    mov ax, @data
    mov ds, ax

    mov ax,13h;graphics mode
    int 10h


    CheckInput:
    call RanPiece
    call PrintStart
    loop_ReadInputS:
        call IsItESCOrS
        cmp [IsSPressed],0
        je IsItEsc1
        jmp SIsPressed

    IsItEsc1:
    cmp [Quit],0
    jne EscJmpEnding
    je loop_ReadInputS
    jmp SIsPressed

    EscJmpEnding:
    jmp EndTetris

    SIsPressed:
    call DeleteTime
    call ClearScreen;delete the strings from screen
    call DrawScreenPlay;draw the play screen and controls
    call PrintTime;draw the timer


    DisplayScoreAndGenerateNewPiece:
    call DisplayScore
    mov [piecePosition],14550
    mov bx,[currentpiececolor]
    shl bx,5
    add bx,offset pieceLine
    call UpdateBlocksPositions
    call CanPieceBePlaced
    cmp al,0
    je RanPiece1
    jmp ending_GameOver

    RanPiece1:
    call RanPiece


    loop_Tetris:
        call ChangeTime
        call Delay1

        mov [piecePosition2],0
        mov [playerInputPressed],0

        Input:
        call ReadChar
        cmp [Quit],0
        je horizontalMovment
        jmp EndTetris

        horizontalMovment:
        mov ax,[piecePosition2]
        cmp ax,0
        je VerticalMovment
        call MoveAndDrawPiece

        VerticalMovment:
        mov cx,[blocksPerPiece]
        loop_VerticalMovment:
            mov di,[piecePosition]
            mov bx,cx
            shl bx,1
            sub bx,2
            add di,[BlocksPositions + bx]
            call CanMoveDown
            cmp al,0
            jne Fail_loop_VerticalMovment
            loop loop_VerticalMovment

        jmp success_VerticalMovment

        Fail_loop_VerticalMovment:
        mov al,[playerInputPressed]
        cmp al,0
        je VerticalMovmentImmediate
        mov al,[cementCounter]
        dec al
        mov [cementCounter],al
        cmp al,0
        jne loop_Tetris

        VerticalMovmentImmediate:
        mov [cementCounter],0
        mov bx,[currentpiececolor]
        shl bx,1
        mov dl,[byte ptr colourCemented+bx]
        call DrawPiece
        xor dx,dx
        mov cx,20
        loop_VerticalMovmentImmediateClearLines:
            push dx
            call AttemptLineRemoval
            pop dx
            add dl,al
            loop loop_VerticalMovmentImmediateClearLines
            
        ;update score
        mov ax,dx
        mov dl,[byte ptr blockSize]
        div dl
        xor ah,ah
        mov dx,[score]
        add ax,dx
        cmp ax,100
        jl scoreUnder100
        sub ax,100

        scoreUnder100:
        mov [score],ax
        jmp DisplayScoreAndGenerateNewPiece

        success_VerticalMovment:
        mov [cementCounter],10
        mov ax,[screenwidth]
        mov [piecePosition2],ax
        call MoveAndDrawPiece
        jmp loop_Tetris


    ending_GameOver:
    mov [IsSPressed],0
    mov [Quit],0
    call ClearScreen
    call DisplayGameOver

    ending_GameOver2:
    mov ah,1
    int 16h
    je ending_GameOver2
    call IsItESCOrS
    cmp [IsSPressed],1
    jne IsItEsc
    jmp SIsPressed

    IsItEsc:
    cmp [Quit],1
    jne ending_GameOver2


    EndTetris:
    ;set to text mode
    mov ah,0h
    mov al,2
    int 10h

    mov ax, 4c00h
    int 21h
END GameStartTetris