REM ASCII ONE BIT GAME
REM $DYNAMIC
_CONTROLCHR OFF
RANDOMIZE TIMER

REDIM SHARED AS INTEGER screenresx, screenresy, winresx, winresy
screenresx = _DESKTOPWIDTH
screenresy = _DESKTOPHEIGHT
winresx = screenresx
winresy = screenresy - 80
SCREEN _NEWIMAGE(winresx / 2, winresy / 2, 32)
COLOR _RGBA(255, 255, 255, 255), _RGBA(0, 0, 0, 255)
DO: LOOP UNTIL _SCREENEXISTS
REDIM SHARED AS LONG font

TYPE gamestate
    AS INTEGER columns, rows, lastEnv, lastItem, direction, colorset
    AS _INTEGER64 score
    AS DOUBLE lastCycleTime, speed, basespeed, startTime, endTime
    AS STRING * 1 keyHit
    AS STRING * 20 state
END TYPE
REDIM SHARED gamestate AS gamestate

TYPE keys
    AS STRING * 1 right, left, up, down
END TYPE
REDIM SHARED keys AS keys
keys.right = "d"
keys.left = "a"
keys.up = "w"
keys.down = "s"

TYPE matrixObject
    AS STRING * 20 type, state
    AS STRING * 1 char
END TYPE
REDIM SHARED envMatrix(0, 0) AS matrixObject
REDIM SHARED itemMatrix(0, 0) AS matrixObject

TYPE player
    AS STRING char, state
    AS _INTEGER64 x, y, timer
    AS _BYTE health
END TYPE
REDIM SHARED player AS player

TYPE colour
    AS _UNSIGNED LONG normal, highlight, red, green, blue, white, black, colorSwitch, dirSwitch, scorePlus, transparent, bgHighlight
END TYPE
REDIM SHARED colour AS colour
colour.normal = _RGBA(0, 194, 177, 255)
colour.highlight = _RGBA(0, 255, 216, 255)
colour.red = _RGBA(255, 0, 0, 255)
colour.green = _RGBA(0, 255, 0, 255)
colour.blue = _RGBA(0, 0, 255, 255)
colour.white = _RGBA(230, 230, 230, 255)
colour.black = _RGBA(10, 10, 10, 255)
colour.transparent = _RGBA(0, 0, 0, 0)
colour.bgHighlight = _RGBA(30, 30, 30, 255)
colour.colorSwitch = _RGBA(194, 0, 144, 255)
colour.dirSwitch = _RGBA(194, 0, 144, 255)
colour.scorePlus = _RGBA(194, 0, 144, 255)
gamestate.colorset = 1

_SCREENMOVE (_DESKTOPWIDTH / 2) - (_WIDTH(0) / 2), (_DESKTOPHEIGHT / 2) - (_HEIGHT(0) / 2)
initFont
initGame
initPlayer
DO
    runGameCycle
LOOP

SUB runGameCycle
    calcEnv
    updatePlayer
    COLOR getStateColor~&("normal"), colour.black
    CLS
    displayBackground
    displayItems
    displayEnv
    displayPlayer
    displayUI
    _DISPLAY
    '_LIMIT 60
END SUB

SUB checkKey (key$)
    SELECT CASE key$
        CASE keys.up
            movePlayer 0, -1
        CASE keys.down
            movePlayer 0, 1
    END SELECT
END SUB

SUB checkMouse
    DO
        mousescroll = mousescroll + _MOUSEWHEEL
    LOOP WHILE _MOUSEINPUT
    movePlayer 0, mousescroll
END SUB

SUB movePlayer (xDif, yDif)
    player.x = player.x + xDif
    player.y = player.y + yDif
    IF player.x > gamestate.columns THEN player.x = gamestate.columns
    IF player.x < 1 THEN player.x = 1
    IF player.y > gamestate.rows THEN player.y = gamestate.rows
    IF player.y < 1 THEN player.y = 1
END SUB

FUNCTION getKeyHit$
    buffer$ = INKEY$
    IF LEN(buffer$) > 0 THEN
        getKeyHit$ = buffer$
    ELSE
        IF _KEYDOWN(ASC(keys.up)) THEN getKeyHit$ = keys.up: EXIT FUNCTION
        IF _KEYDOWN(ASC(keys.down)) THEN getKeyHit$ = keys.down: EXIT FUNCTION
        IF _KEYDOWN(ASC(keys.left)) THEN getKeyHit$ = keys.left: EXIT FUNCTION
        IF _KEYDOWN(ASC(keys.right)) THEN getKeyHit$ = keys.right: EXIT FUNCTION
        getKeyHit$ = ""
    END IF
END FUNCTION

SUB displayBackground
    LINE (0, getRow(player.y))-(_WIDTH(0), getRow(player.y + 1) - 1), colour.bgHighlight, BF
END SUB

SUB displayUI
    COLOR getStateColor~&("red"), colour.transparent
    IF _TRIM$(gamestate.state) = "running" THEN
        DO: i = i + 1
            _PRINTSTRING (getColumn(i), getRow(1)), CHR$(3)
        LOOP UNTIL i = player.health
        _PRINTSTRING (getColumn(1), getRow(2)), LTRIM$(STR$(gamestate.score))
    ELSEIF _TRIM$(gamestate.state) = "over" THEN
        gameOver
    END IF
END SUB

SUB gameOver
    CLS
    text$ = "GAME OVER"
    _PRINTSTRING (getColumn(INT((gamestate.columns / 2) - (LEN(text$) / 2))), getRow(INT(gamestate.rows / 2))), text$
    text$ = "You collected " + LTRIM$(STR$(gamestate.score)) + " visual samples."
    IF gamestate.score > 10000 THEN
        text$ = text$ + " That would make for an amazing collection!"
    END IF
    _PRINTSTRING (getColumn(INT((gamestate.columns / 2) - (LEN(text$) / 2))), getRow(INT(gamestate.rows / 2) + 1)), text$
    gameTime$ = LTRIM$(STR$(gamestate.endTime - gamestate.startTime))
    gameTimePoint = INSTR(gameTime$, ".")
    gameTime$ = MID$(gameTime$, 1, gameTimePoint + 3)
    text$ = "Could not break the fourth wall after " + gameTime$ + " seconds"
    _PRINTSTRING (getColumn(INT((gamestate.columns / 2) - (LEN(text$) / 2))), getRow(INT(gamestate.rows / 2) + 2)), text$
    _DISPLAY
END SUB

SUB displayEnv
    timeDif## = TIMER(.001) - gamestate.lastCycleTime
    envOffset = (timeDif## / (1 / gamestate.speed)) * gamestate.direction
    IF UBOUND(envMatrix, 1) > 0 AND UBOUND(envMatrix, 2) > 0 THEN
        x = 0: DO: x = x + 1
            y = 0: DO: y = y + 1
                IF envMatrix(x, y).char <> "" THEN
                    COLOR getStateColor~&(_TRIM$(envMatrix(x, y).state)), colour.transparent
                    _PRINTSTRING (getColumn(x - envOffset), getRow(y)), _TRIM$(envMatrix(x, y).char)
                END IF
            LOOP UNTIL y = UBOUND(envMatrix, 2)
        LOOP UNTIL x = UBOUND(envMatrix, 1)
    END IF
END SUB

SUB displayItems
    timeDif## = TIMER(.001) - gamestate.lastCycleTime
    itemOffset = (timeDif## / (1 / gamestate.speed)) * gamestate.direction
    IF UBOUND(itemMatrix, 1) > 0 AND UBOUND(itemMatrix, 2) > 0 THEN
        x = 0: DO: x = x + 1
            y = 0: DO: y = y + 1
                IF itemMatrix(x, y).char <> "" THEN
                    COLOR getStateColor~&(_TRIM$(itemMatrix(x, y).state)), colour.transparent
                    _PRINTSTRING (getColumn(x - itemOffset), getRow(y)), _TRIM$(itemMatrix(x, y).char)
                END IF
            LOOP UNTIL y = UBOUND(itemMatrix, 2)
        LOOP UNTIL x = UBOUND(itemMatrix, 1)
    END IF
END SUB

FUNCTION getStateColor~& (state AS STRING)
    SELECT CASE _TRIM$(state)
        CASE "normal"
            getStateColor~& = colour.normal
        CASE "highlight"
            getStateColor~& = colour.highlight
        CASE "hit"
            getStateColor~& = colour.red
        CASE "red"
            getStateColor~& = colour.red
        CASE "colorSwitch"
            getStateColor~& = HSLtoRGB~&(gamestate.score * 16, 1, 1, 255)
        CASE "dirSwitch"
            getStateColor~& = colour.dirSwitch
        CASE "scorePlus"
            getStateColor~& = colour.scorePlus
    END SELECT
END FUNCTION

SUB displayPlayer
    COLOR getStateColor~&(player.state), colour.transparent
    _PRINTSTRING (getColumn(player.x), getRow(player.y)), player.char
END SUB

SUB calcLogic
    SELECT CASE player.state
        CASE "hit"
            IF player.timer < 3 THEN
                player.timer = player.timer + 1
            ELSE
                player.state = "normal"
                player.timer = 0
            END IF
    END SELECT
    collider$ = playerCollidesWith$
    SELECT CASE collider$
        CASE "wall"
            player.state = "hit"
            IF player.health > 0 THEN player.health = player.health - 1
            IF player.health = 0 AND _TRIM$(gamestate.state) = "running" THEN
                gamestate.endTime = TIMER(.001)
                gamestate.state = "over"
            END IF
        CASE "dirSwitch"
            gamestate.direction = gamestate.direction * -1
            IF gamestate.direction > 0 THEN
                gamestate.lastEnv = gamestate.columns
                gamestate.lastItem = gamestate.columns
            ELSE
                gamestate.lastEnv = 1
                gamestate.lastItem = 1
            END IF
            IF _TRIM$(gamestate.state) = "running" THEN gamestate.score = gamestate.score - 100
        CASE "colorSwitch"
            ' generate new semi-random colors
            DO
                rInt = INT(RND * 4)
            LOOP WHILE rInt = gamestate.colorset
            gamestate.colorset = rInt
            SELECT CASE gamestate.colorset
                CASE 0
                    colour.normal = _RGBA(255, 238, 0, 255)
                    colour.highlight = _RGBA(188, 255, 0, 255)
                    colour.colorSwitch = _RGBA(0, 105, 255, 255)
                    colour.dirSwitch = _RGBA(0, 105, 255, 255)
                    colour.scorePlus = _RGBA(0, 105, 255, 255)
                CASE 1
                    colour.normal = _RGBA(0, 194, 177, 255)
                    colour.highlight = _RGBA(0, 255, 216, 255)
                    colour.colorSwitch = _RGBA(194, 0, 144, 255)
                    colour.dirSwitch = _RGBA(194, 0, 144, 255)
                    colour.scorePlus = _RGBA(194, 0, 144, 255)
                CASE 2
                    colour.normal = _RGBA(155, 0, 255, 255)
                    colour.highlight = _RGBA(238, 72, 255, 255)
                    colour.colorSwitch = _RGBA(255, 150, 0, 255)
                    colour.dirSwitch = _RGBA(255, 150, 0, 255)
                    colour.scorePlus = _RGBA(255, 150, 0, 255)
                CASE 3
                    colour.normal = _RGBA(255, 255, 255, 255)
                    colour.highlight = _RGBA(255, 255, 255, 255)
                    colour.colorSwitch = _RGBA(200, 200, 200, 255)
                    colour.dirSwitch = _RGBA(200, 200, 200, 255)
                    colour.scorePlus = _RGBA(200, 200, 200, 255)
            END SELECT
        CASE "scorePlus"
            IF player.health > 0 THEN
                IF RND < 0.99 THEN
                    gamestate.score = gamestate.score + 100
                    addGridText "100", player.x - 1, player.y, "scorePlus"
                ELSE
                    gamestate.score = gamestate.score + 1000
                    addGridText "1000", player.x - 1, player.y, "scorePlus"
                    addGridText "WOW!", player.x - 1, player.y + 1, "scorePlus"
                END IF
            END IF
    END SELECT
END SUB

SUB addGridText (text AS STRING, x, y, state AS STRING)
    DO: i = i + 1
        itemMatrix(x + i - 1, y).type = "text"
        itemMatrix(x + i - 1, y).char = MID$(text, i, 1)
        itemMatrix(x + i - 1, y).state = state
    LOOP UNTIL i = LEN(text)
END SUB

SUB calcEnv
    timeDif## = TIMER(.001) - gamestate.lastCycleTime
    IF timeDif## >= 1 / gamestate.speed THEN
        gamestate.keyHit = getKeyHit$
        checkKey gamestate.keyHit
        checkMouse
        IF player.health > 0 THEN gamestate.score = gamestate.score + 1
        gamestate.speed = gamestate.basespeed + ((gamestate.score / 420))
        moveEnv
        SELECT CASE gamestate.direction
            CASE 1
                IF generateEnv(UBOUND(envMatrix, 1)) = 0 THEN
                    generateItem UBOUND(itemMatrix, 1)
                END IF
            CASE -1
                IF generateEnv(1) = 0 THEN
                    generateItem 1
                END IF
        END SELECT
        gamestate.lastCycleTime = TIMER(.001)
        calcLogic
    END IF
END SUB

SUB moveEnv
    IF gamestate.direction > 0 THEN
        x = 0: DO: x = x + 1
            y = 0: DO: y = y + 1
                envMatrix(x, y).type = envMatrix(x + 1, y).type
                envMatrix(x, y).char = envMatrix(x + 1, y).char
                envMatrix(x, y).state = envMatrix(x + 1, y).state
                itemMatrix(x, y).type = itemMatrix(x + 1, y).type
                itemMatrix(x, y).char = itemMatrix(x + 1, y).char
                itemMatrix(x, y).state = itemMatrix(x + 1, y).state
            LOOP UNTIL y = UBOUND(envMatrix, 2)
        LOOP UNTIL x = UBOUND(envMatrix, 1) - 1
        gamestate.lastEnv = gamestate.lastEnv - 1
        gamestate.lastItem = gamestate.lastItem - 1
    ELSE
        x = UBOUND(envMatrix, 1) + 1: DO: x = x - 1
            y = UBOUND(envMatrix, 2) + 1: DO: y = y - 1
                envMatrix(x, y).type = envMatrix(x - 1, y).type
                envMatrix(x, y).char = envMatrix(x - 1, y).char
                envMatrix(x, y).state = envMatrix(x - 1, y).state
                itemMatrix(x, y).type = itemMatrix(x - 1, y).type
                itemMatrix(x, y).char = itemMatrix(x - 1, y).char
                itemMatrix(x, y).state = itemMatrix(x - 1, y).state
            LOOP UNTIL y = 1
        LOOP UNTIL x = 2
        gamestate.lastEnv = gamestate.lastEnv + 1
        gamestate.lastItem = gamestate.lastItem + 1
    END IF
END SUB

FUNCTION playerCollidesWith$
    IF LEN(_TRIM$(envMatrix(player.x, player.y).char)) > 0 THEN
        playerCollidesWith$ = "wall"
    END IF
    IF LEN(_TRIM$(itemMatrix(player.x, player.y).char)) > 0 THEN
        playerCollidesWith$ = _TRIM$(itemMatrix(player.x, player.y).type)
    END IF
END FUNCTION

SUB generateItem (x AS INTEGER)
    yLimit = UBOUND(itemMatrix, 2)
    DO: y = y + 1
        itemMatrix(x, y).type = ""
        itemMatrix(x, y).char = ""
        itemMatrix(x, y).state = ""
    LOOP UNTIL y = yLimit
    IF gamestate.direction > 0 AND gamestate.lastItem < UBOUND(itemMatrix, 1) - 10 THEN
        gamestate.lastItem = UBOUND(itemMatrix, 1)
        yPos = 1 + INT(RND * UBOUND(itemMatrix, 2))
        makeItem x, yPos, getRitemType$
    ELSEIF gamestate.direction < 0 AND gamestate.lastItem > 10 THEN
        gamestate.lastItem = 1
        yPos = 1 + INT(RND * UBOUND(itemMatrix, 2))
        makeItem x, yPos, getRitemType$
    END IF
END SUB

FUNCTION generateEnv (x AS INTEGER)
    yLimit = UBOUND(envMatrix, 2)
    IF (gamestate.direction > 0 AND gamestate.lastEnv < UBOUND(envMatrix, 1) - 25) THEN
        gamestate.lastEnv = UBOUND(envMatrix, 1)
        envType$ = getRenvType$
        DO: y = y + 1
            makeEnv x, y, envType$
        LOOP UNTIL y = yLimit
        generateEnv = -1
    ELSEIF gamestate.direction < 0 AND gamestate.lastEnv > 25 THEN
        gamestate.lastEnv = 1
        envType$ = getRenvType$
        DO: y = y + 1
            makeEnv x, y, envType$
        LOOP UNTIL y = yLimit
        generateEnv = -1
    ELSE
        DO: y = y + 1
            envMatrix(x, y).type = ""
            envMatrix(x, y).char = ""
            envMatrix(x, y).state = ""
        LOOP UNTIL y = yLimit
        generateEnv = 0
    END IF
END FUNCTION

SUB makeItem (x, y, itemType$)
    SELECT CASE itemType$
        CASE "dirSwitch"
            itemMatrix(x, y).type = itemType$
            itemMatrix(x, y).char = "%"
            itemMatrix(x, y).state = "dirSwitch"
        CASE "scorePlus"
            itemMatrix(x, y).type = itemType$
            itemMatrix(x, y).char = "+"
            itemMatrix(x, y).state = "scorePlus"
        CASE "colorSwitch"
            itemMatrix(x, y).type = itemType$
            itemMatrix(x, y).char = "c"
            itemMatrix(x, y).state = "colorSwitch"
    END SELECT
END SUB

SUB makeEnv (x, y, envType$)
    SELECT CASE envType$
        CASE "top"
            IF y < INT(UBOUND(envMatrix, 2) / 2) THEN
                envMatrix(x, y).type = envType$
                envMatrix(x, y).char = "#"
                envMatrix(x, y).state = "normal"
            ELSE
                envMatrix(x, y).type = ""
                envMatrix(x, y).char = ""
                envMatrix(x, y).state = ""
            END IF
        CASE "bottom"
            IF y > INT(UBOUND(envMatrix, 2) / 2) THEN
                envMatrix(x, y).type = envType$
                envMatrix(x, y).char = "#"
                envMatrix(x, y).state = "normal"
            ELSE
                envMatrix(x, y).type = ""
                envMatrix(x, y).char = ""
                envMatrix(x, y).state = ""
            END IF
        CASE "middle"
            IF y > INT(UBOUND(envMatrix, 2) / 3) AND y < UBOUND(envMatrix, 2) - INT(UBOUND(envMatrix, 2) / 3) THEN
                envMatrix(x, y).type = envType$
                envMatrix(x, y).char = "#"
                envMatrix(x, y).state = "normal"
            ELSE
                envMatrix(x, y).type = ""
                envMatrix(x, y).char = ""
                envMatrix(x, y).state = ""
            END IF
        CASE "split"
            IF y < INT(UBOUND(envMatrix, 2) / 4) OR y > UBOUND(envMatrix, 2) - INT(UBOUND(envMatrix, 2) / 4) THEN
                envMatrix(x, y).type = envType$
                envMatrix(x, y).char = "#"
                envMatrix(x, y).state = "normal"
            ELSE
                envMatrix(x, y).type = ""
                envMatrix(x, y).char = ""
                envMatrix(x, y).state = ""
            END IF
        CASE "split3"
            IF y < INT(UBOUND(envMatrix, 2) / 5) OR y > UBOUND(envMatrix, 2) - INT(UBOUND(envMatrix, 2) / 5) OR (y > INT(UBOUND(envMatrix, 2) * 0.4) AND y < INT(UBOUND(envMatrix, 2) * 0.6)) THEN
                envMatrix(x, y).type = envType$
                envMatrix(x, y).char = "#"
                envMatrix(x, y).state = "normal"
            ELSE
                envMatrix(x, y).type = ""
                envMatrix(x, y).char = ""
                envMatrix(x, y).state = ""
            END IF
    END SELECT
END SUB

FUNCTION getRitemType$
    rInt = INT(RND * 3)
    SELECT CASE rInt
        CASE 0
            getRitemType$ = "dirSwitch"
        CASE 1
            getRitemType$ = "scorePlus"
        CASE 2
            getRitemType$ = "colorSwitch"
    END SELECT
END FUNCTION

FUNCTION getRenvType$
    rInt = INT(RND * 5)
    SELECT CASE rInt
        CASE 0
            getRenvType$ = "top"
        CASE 1
            getRenvType$ = "bottom"
        CASE 2
            getRenvType$ = "middle"
        CASE 3
            getRenvType$ = "split"
        CASE 4
            getRenvType$ = "split3"
    END SELECT
END FUNCTION

SUB initFont
    fontFile$ = "fonts/PTMono-Regular.ttf"
    font = _LOADFONT(fontFile$, 26, "MONOSPACE")
    _FONT font
END SUB

SUB initGame
    gamestate.columns = INT(_WIDTH(0) / _FONTWIDTH(font)) - 1
    gamestate.rows = INT(_HEIGHT(0) / _FONTHEIGHT(font)) - 1
    REDIM envMatrix(gamestate.columns, gamestate.rows) AS matrixObject
    REDIM itemMatrix(gamestate.columns, gamestate.rows) AS matrixObject
    gamestate.basespeed = 16
    gamestate.speed = gamestate.basespeed
    gamestate.lastCycleTime = TIMER
    gamestate.direction = 1
    gamestate.state = "running"
    gamestate.score = 0
    gamestate.startTime = TIMER(.001)
    player.health = 4
END SUB

SUB updatePlayer
    SELECT CASE player.state
        CASE "normal"
            IF gamestate.direction = 1 THEN player.char = CHR$(16) ELSE player.char = CHR$(17)
        CASE "dead"
            player.char = "X"
    END SELECT
END SUB

SUB initPlayer
    player.char = CHR$(16)
    player.state = "normal"
    player.x = INT(gamestate.columns / 2)
    player.y = INT(gamestate.rows / 2)
END SUB

FUNCTION getRow (row)
    getRow = (_FONTHEIGHT(font) * row)
END FUNCTION

FUNCTION getColumn (column)
    getColumn = (_FONTWIDTH(font) * column)
END FUNCTION

FUNCTION hr& (hue AS _FLOAT, saturation AS _FLOAT, lightness AS _FLOAT)
    SELECT CASE hue
        CASE IS < 60 AND hue >= 0: tr = 1
        CASE IS < 120 AND hue >= 60: tr = 1 - ((hue - 60) / 60)
        CASE IS < 180 AND hue >= 120: tr = 0
        CASE IS < 240 AND hue >= 180: tr = 0
        CASE IS < 300 AND hue >= 240: tr = (hue - 240) / 60
        CASE IS < 360 AND hue >= 300: tr = 1
    END SELECT
    hr& = tr * 255
END FUNCTION

FUNCTION hg& (hue AS _FLOAT, saturation AS _FLOAT, lightness AS _FLOAT)
    SELECT CASE hue
        CASE IS < 60 AND hue >= 0: tg = hue / 60
        CASE IS < 120 AND hue >= 60: tg = 1
        CASE IS < 180 AND hue >= 120: tg = 1
        CASE IS < 240 AND hue >= 180: tg = 1 - ((hue - 180) / 60)
        CASE IS < 300 AND hue >= 240: tg = 0
        CASE IS < 360 AND hue >= 300: tg = 0
    END SELECT
    hg& = tg * 255
END FUNCTION

FUNCTION hb& (hue AS _FLOAT, saturation AS _FLOAT, lightness AS _FLOAT)
    SELECT CASE hue
        CASE IS < 60 AND hue >= 0: tb = 0
        CASE IS < 120 AND hue >= 60: tb = 0
        CASE IS < 180 AND hue >= 120: tb = (hue - 120) / 60
        CASE IS < 240 AND hue >= 180: tb = 1
        CASE IS < 300 AND hue >= 240: tb = 1
        CASE IS < 360 AND hue >= 300: tb = 1 - ((hue - 300) / 60)
    END SELECT
    hb& = tb * 255
END FUNCTION

FUNCTION HSLtoRGB~& (conH, conS, conL, conA)
    IF conH >= 360 THEN
        conH = conH - (360 * INT(conH / 360))
    END IF

    objR = hr&(conH, conS, conL) * conS
    objG = hg&(conH, conS, conL) * conS
    objB = hb&(conH, conS, conL) * conS

    'maximizing to full 255
    IF objR >= objG AND objG >= objB THEN '123
        factor = 255 / objR
    ELSEIF objG >= objR AND objR >= objB THEN '213
        factor = 255 / objG
    ELSEIF objB >= objR AND objR >= objG THEN '312
        factor = 255 / objB
    ELSEIF objR >= objB AND objB >= objG THEN '132
        factor = 255 / objR
    ELSEIF objG >= objB AND objB >= objR THEN '231
        factor = 255 / objG
    ELSEIF objB >= objR AND objG >= objR THEN '321
        factor = 255 / objB
    END IF
    objR = objR * factor
    objG = objG * factor
    objB = objB * factor

    'adjusting to lightness
    objR = objR * conL
    objG = objG * conL
    objB = objB * conL

    'adjusting to saturation
    'IF objR = 0 OR objG = 0 OR objB = 0 THEN
    '    objavg = (objR + objG + objB) / 2
    'ELSE
    '    objavg = (objR + objG + objB) / 3
    'END IF
    'IF conS > 0.1 THEN
    '    objR = objR + ((objavg - objR) * (1 - conS))
    '    objG = objG + ((objavg - objG) * (1 - conS))
    '    objB = objB + ((objavg - objB) * (1 - conS))
    'ELSE
    '    objR = objavg
    '    objG = objavg
    '    objB = objavg
    'END IF

    HSLtoRGB~& = _RGBA(objR, objG, objB, conA)
END FUNCTION
