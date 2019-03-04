@echo off & (
    setlocal EnableExtensions EnableDelayedExpansion

    rem find binary
    set bn=%~n0
    set "suffix=.exe"
    set "arch=!PROCESSOR_ARCHITEW6432!"
    if "!arch!" == "" set "arch=!PROCESSOR_ARCHITECTURE!"
    for %%P in ("A=a" "B=b" "C=c" "D=d" "E=e" "F=f" "G=g" "H=h" "I=i" "J=j"
        "K=k" "L=l" "M=m" "N=n" "O=o" "P=p" "Q=q" "R=r" "S=s" "T=t" "U=u"
        "V=v" "W=w" "X=x" "Y=y" "Z=z") do set "arch=!arch:%%~P!"
    if /I "!arch!" == "x86" set arch=386
    set "file="
    for %%G in (client server) do if "!file!" == "" (
        set "type=%%G"
        for %%H in (!bn!_%%G !bn!-%%G %%G_windows_!arch!) do if "!file!" == "" (
            set "file=!cd!\%%H!suffix!"
            if not exist "!file!" set file=
        )
        if "!file!" == "" if /I "!arch!" == "amd64" (
            set "file=!cd!\%%G_windows_386!suffix!"
            if not exist "!file!" set file=
        )
    )
    if "!file!" == "" for %%G in (client server) do if "!file!" == "" (
        set "type=%%G"
        for %%H in (!bn!_%%G!suffix! !bn!-%%G!suffix!) do if "!file!" == "" (
            set "file=%%~dpnx$PATH:H"
        )
    )
    if "!file!" == "" (
        echo no !bn! client or server found >&2
        exit /B 1
    )
    set "argv[0]=!file!"

    set "SP= "
    set "HT=	"
    (set LF=^
%=Do not remove this line=%
)
    for /F %%P in ('copy /Z %0 NUL') do set "CR=%%P"
    set "EM=^!"
    set "QUOTE=""
    set "PERCENT=%%"
    set "BACKSLASH=\"
    set "CARET=^"

    set argc=0

    rem add host and port
    set "optclient0=localaddr;SS_LOCAL_HOST;SS_LOCAL_PORT;127.0.0.1;12948"
    set "optclient1=remoteaddr;SS_REMOTE_HOST;SS_REMOTE_PORT;vps;29900"
    set "optserver0=listen;SS_REMOTE_HOST;SS_REMOTE_PORT;!QUOTE!!QUOTE!;29900"
    set "optserver1=target;SS_LOCAL_HOST;SS_LOCAL_PORT;127.0.0.1;12948"
    for %%G in (!type!) do for %%H in (0 1) do (
        for /F "tokens=1-5 delims=;" %%1 in ("!opt%%G%%H!") do (
            set /A argc+=1
            set "argv[!argc!]=--%%1"
            if "!%%2!" == "" set "%%2=%%~4"
            if not "!%%2!" == "" if not "!%%2::=!" == "!%%2!" (
                if not "!%%2:~0,1!" == "[" set "%%2=[!%%2!]"
            )
            if "!%%3!" == "" set "%%3=%%5"
            set /A argc+=1
            set "argv[!argc!]=!%%2!:!%%3!"
        )
    )

    set lenHint=4096 2048 1024 512 256 128 64 32 16 8 4 2 1

    rem parse options
    set "opts=!SS_PLUGIN_OPTIONS!"

    if not "!opts!" == "" (
        set "buf=!opts!"
        set len=1
        for %%P in (!lenHint!) do if not "!buf:~%%P,1!" == "" (
            set /A "len+=%%P"
            set "buf=!buf:~%%P!"
        )
        set offset=0
        set break=0
        for /L %%_ in (0,1,!len!) do if !break! EQU 0 (
            for %%G in (key value) do if !break! EQU 0 (
                set buf=
                for /L %%_ in (!offset!,1,!len!) do if !break! EQU 0 (
                    for %%P in (!offset!) do set "ch=!opts:~%%P,1!"
                    set /A offset+=1
                    if "!ch!" == "" (
                        set break=3
                    ) else if "!ch!" == ";" (
                        set break=2
                    ) else if "%%G!ch!" == "key=" (
                        set break=1
                    ) else (
                        if "!ch!" == "!BACKSLASH!" (
                            for %%P in (!offset!) do set "ch=!opts:~%%P,1!"
                            set /A offset+=1
                            if "!ch!" == "" (
                                echo nothing following final escape in !opts! >&2
                                exit /B 1
                            )
                        )
                        set "buf=!buf!!ch!"
                    )
                )
                if !break! NEQ 0 set /A break-=1
                if %%G == key (
                    if "!buf!" == "" (
                        echo empty key in !opts! >&2
                        exit /B 1
                    )
                    set "buf=--!buf!"
                )
                set /A argc+=1
                set "argv[!argc!]=!buf!"
            )
            if !break! NEQ 0 set /A break-=1
        )
    )

    rem quote arguments
    for /L %%G in (0,1,!argc!) do (
        set "arg=!argv[%%G]!"
        if "!arg!" == "" (
            set "argv[%%G]=!QUOTE!!QUOTE!"
        ) else (
            set "buf=!arg!"
            set /A limit=0
            for %%P in (!lenHint!) do if not "!buf:~%%P,1!" == "" (
                set /A "limit+=%%P"
                set "buf=!buf:~%%P!"
            )
            set buf=
            set bss=
            set /A doQuote=0
            for /L %%H in (0,1,!limit!) do (
                set "ch=!arg:~%%H,1!"
                if "!ch!" == "!BACKSLASH!" (
                    set "bss=!bss!!ch!"
                ) else (
                    if "!ch!" == "!QUOTE!" (
                        set "buf=!buf!!bss!!BACKSLASH!"
                    ) else if "!ch!" LSS "!EM!" (
                        if "!ch!" == "!SP!" set doQuote=1
                        if "!ch!" == "!HT!" set doQuote=1
                        if "!ch!" == "!LF!" set doQuote=1
                        if "!ch!" == "!CR!" set doQuote=1
                    )
                    set bss=
                )
                set "buf=!buf!!ch!"
            )

            if !doQuote! EQU 0 (
                set "argv[%%G]=!buf!"
            ) else (
                set "argv[%%G]=!QUOTE!!buf!!bss!!QUOTE!"
            )
        )
    )

    rem original command line arguments
    setlocal EnableExtensions DisableDelayedExpansion
    set "args=%*"
    setlocal EnableExtensions EnableDelayedExpansion

    if not "!args!" == "" (
        set "buf=!args!"
        set /A len=1
        for %%P in (!lenHint!) do if not "!buf:~%%P,1!" == "" (
            set /A "len+=%%P"
            set "buf=!buf:~%%P!"
        )

        set break=0
        set offset=0
        set inQuote=0
        set escape=0
        for /L %%_ in (0,1,!len!) do if !break! EQU 0 (
            set buf=
            for /L %%_ in (!offset!,1,!len!) do if !break! EQU 0 (
                for %%P in (!offset!) do set "ch=!args:~%%P,1!"
                set /A offset+=1
                if "!ch!" == "" (
                    set break=2
                ) else if "!ch!" == "!BACKSLASH!" (
                    set /A "escape=1-!escape!"
                ) else (
                    if "!ch!" == "!QUOTE!" (
                        if !escape! EQU 0 set /A "inQuote=1-!inQuote!"
                    ) else if !inQuote! EQU 0 (
                        if "!ch!" == "!SP!" set break=1
                        if "!ch!" == "!HT!" set break=1
                    )
                    set escape=0
                )
                if !break! EQU 0 set "buf=!buf!!ch!"
            )
            if !break! NEQ 0 set /A break-=1
            if not "!buf!" == "" (
                set /A argc+=1
                set "argv[!argc!]=!buf!"
            )
        )
    )

    rem escape arguments
    set args=
    set "spec=!SP!!HT!!EM!!QUOTE!&(),;<>!CARET!|"
    set "alter=!CARET!!CARET!"
    for /L %%G in (0,1,!argc!) do if not "!argv[%%G]:*!=!" == "!argv[%%G]!" (
        set "alter=!CARET!!CARET!!CARET!!CARET!"
    )
    for /L %%G in (0,1,!argc!) do (
        rem escape special character in cmd.exe
        rem should never be empty, quote if actually empty string
        set "arg=!argv[%%G]!"
        set "buf=!arg!"
        set /A limit=0
        for %%P in (!lenHint!) do if not "!buf:~%%P,1!" == "" (
            set /A "limit+=%%P"
            set "buf=!buf:~%%P!"
        )
        set buf=
        for /L %%H in (0,1,!limit!) do (
            set "ch=!arg:~%%H,1!"
            if "!ch!" == "!CR!" (
                set "buf=!buf!!PERCENT!!EM!"
            ) else if "!ch!" == "!LF!" (
                set "buf=!buf!!CARET!!ch!!ch!"
            ) else for /F delims^=^ eol^= %%P in ("!ch!") do (
                if "!spec:%%P=!" == "!spec!" (
                    set "buf=!buf!!ch!"
                ) else if "!ch!" == "!CARET!" (
                    set "buf=!buf!!alter!"
                ) else if "!ch!" == "!EM!" (
                    set "buf=!buf!!CARET!!CARET!!ch!"
                ) else (
                    set "buf=!buf!!CARET!!ch!"
                )
            )
        )
        set "args=!args! !buf!"
    )
)
(
    rem restore environment variables
    endlocal
    endlocal
    endlocal

    rem execute the arguments
    rem we do escape character "!" so enable delayed expansion
    setlocal EnableExtensions EnableDelayedExpansion
    rem clear environment variables we has already parsed
    set SS_LOCAL_HOST=
    set SS_LOCAL_PORT=
    set SS_REMOTE_HOST=
    set SS_REMOTE_PORT=
    set SS_PLUGIN_OPTIONS=
    for /F %%! in ('copy /Z %0 NUL') do%args%
    endlocal
    exit /B
)
