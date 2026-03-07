#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

; Corner timer version (v2)

; --- Configuration ---
cyclemin  := 30   ; Overall work cycle length (minutes)
warn1sec  := 60   ; 1st warning (seconds before end)
warn2sec  := 15   ; 2nd warning (seconds before end)
breakmin  := 3    ; Length of required break (minutes)
extendmin := 2    ; Length of extension (minutes)
pwd       := "y523zc459711462Cat?" ; Lockscreen password

; --- Calculated Variables ---
step1sec  := (cyclemin * 60 * 1000) - (warn1sec * 1000)
step2sec  := (warn1sec * 1000) - (warn2sec * 1000)
step3sec  := warn2sec * 1000
breaksec  := breakmin * 60 * 1000
extendsec := extendmin * 60 * 1000

; --- State Variables ---
global on_break      := 0
global timer_on      := 0
global welcome       := 0
global extendable    := 0
global countdown_val := 0
global cycleEndTime  := 0  ; A_TickCount when Step3 will fire
global LockGui       := ""
global ProgGui       := ""
global StatusGui     := ""
global StatusLine1   := ""
global StatusLine2   := ""

; --- Exit Handler ---
OnExit(ExitFunc)

; --- Main Loop ---
SetTimer(IdleCheck, 1000)
SetTimer(StatusUpdate, 1000)
CreateStatusGui()

; ------------------------------------------------------------------------------
; Logic Handlers
; ------------------------------------------------------------------------------

IdleCheck()
{
    global on_break, timer_on, welcome, LockGui, cycleEndTime

    ; 1. If user returns to work (low idle time) and timer isn't running: Start Work Cycle
    if (A_TimeIdlePhysical < 2000 and on_break = 0 and timer_on = 0) {
        ShowProgress("Starting Work Cycle (" cyclemin "m)", "Blue", 1500)
        timer_on := 1
        welcome := 0
        cycleEndTime := A_TickCount + (cyclemin * 60 * 1000)
        SetTimer(Step1, step1sec)
    }

    ; 2. If user tries to work DURING a break: Trigger Lock
    if (A_TimeIdlePhysical < 2000 and on_break = 1) {
        if (!IsObject(LockGui)) {
            CreateLockScreen()
        }
    } 

    ; 3. If user has been idle long enough to satisfy the break: Reset
    ; if (A_TimeIdlePhysical > breaksec and welcome = 0 and on_break = 1) {
    if (A_TimeIdlePhysical > breaksec and welcome = 0) {
        ShowProgress("Welcome back! Cycle Reset.", "Blue", 2000)
        
        on_break     := 0
        welcome      := 1
        timer_on     := 0
        cycleEndTime := 0
        
        ; Kill all active step timers
        SetTimer(Step1, 0)
        SetTimer(Step2, 0)
        SetTimer(Step3, 0)
        SetTimer(CountdownDisplay, 0)
        
        if (IsObject(LockGui)) {
            LockGui.Destroy()
            LockGui := ""
        }
    }
}

; ------------------------------------------------------------------------------
; Timer Steps
; ------------------------------------------------------------------------------

Step1() {
    global extendable
    SetTimer(Step1, 0)
    ShowProgress("Warning: " warn1sec " seconds remaining", "Blue", 4000, true)
    extendable := 1
    SetTimer(Step2, step2sec)
}

Step2() {
    global extendable, countdown_val
    SetTimer(Step2, 0)
    ; extendable := 1
    
    ; Setup Countdown
    countdown_val := warn2sec
    SetTimer(CountdownDisplay, 1000)
    SetTimer(Step3, step3sec)
}

CountdownDisplay() {
    global countdown_val
    if (countdown_val > 0) {
        ShowProgress(countdown_val " Second Warning", "Blue", 0, true)
        countdown_val--
    } else {
        ProgressOff()
        SetTimer(CountdownDisplay, 0)
    }
}

Step3() {
    global on_break, extendable
    SetTimer(Step3, 0)
    SetTimer(CountdownDisplay, 0)
    ProgressOff()
    
    ; Trigger Break Mode
    ShowProgress("TIME UP! TAKE A BREAK!", "Red", 0, true)
    on_break := 1 
    extendable := 0
}

; ------------------------------------------------------------------------------
; Custom Progress Bar (Mimics AHK v1 Progress)
; ------------------------------------------------------------------------------

ShowProgress(Text, ColorScheme := "Blue", Duration := 0, ShowExtend := false) {
    global ProgGui, extendable

    ; Optionally append extendable indicator as a second line
    displayText := ShowExtend
        ? Text "`n" (extendable ? "  [extendable]" : "  [not extendable]")
        : Text

    ; Destroy existing if present
    if (IsObject(ProgGui))
        ProgGui.Destroy()

    ; Configure Colors
    if (ColorScheme = "Red") {
        BgColor := "Red"
        TxtColor := "Yellow"
    } else { ; Default Blue
        BgColor := "Blue"
        TxtColor := "Aqua"
    }

    ; Create GUI
    ProgGui := Gui("+AlwaysOnTop -Caption +ToolWindow -SysMenu", "ProgressReplica")
    ProgGui.BackColor := BgColor
    ProgGui.SetFont("s30 w700 c" TxtColor, "Verdana")

    ProgGui.Add("Text", "Center w800", displayText)

    ProgGui.Show("NoActivate xCenter y100 w800")

    if (Duration > 0)
        SetTimer(ProgressOff, -Duration)
}

ProgressOff() {
    global ProgGui
    if (IsObject(ProgGui)) {
        ProgGui.Destroy()
        ProgGui := ""
    }
}

; ------------------------------------------------------------------------------
; Lock Screen GUI
; ------------------------------------------------------------------------------

CreateLockScreen() {
    global LockGui, pwd, on_break, timer_on
    
    if (IsObject(LockGui))
        LockGui.Destroy()

    LockGui := Gui("+AlwaysOnTop -SysMenu +ToolWindow", "Lockscreen")
    LockGui.BackColor := "Red"
    LockGui.SetFont("s14", "Verdana")
    
    LockGui.Add("Text", "Center w400", "Type Password to Unlock")
    PassEdit := LockGui.Add("Edit", "w300 Center Password vPassword")
    Btn := LockGui.Add("Button", "w100 Default", "OK")
    
    Btn.OnEvent("Click", (*) => CheckPass(PassEdit.Value))
    
    LockGui.Show("x0 y0 w" A_ScreenWidth " h" A_ScreenHeight)

    CheckPass(InputPass) {
        if (InputPass == pwd) {
            LockGui.Destroy()
            LockGui := ""
            ProgressOff() ; Ensure "Time Up" message is gone
            on_break := 0
            timer_on := 0
            SetTimer(IdleCheck, 1000)
        } else {
            PassEdit.Value := ""
            PassEdit.Focus()
        }
    }
}

; ------------------------------------------------------------------------------
; Hotkeys
; ------------------------------------------------------------------------------

; Stop Soon (Ctrl+Alt+2)
^!2::
{
    wfhsec := 1000 * 60 * 1
    global extendable
    if (extendable = 1) {
        ShowProgress("Accelerating Timer", "Blue", 2000)
        extendable := 0
        SetTimer(Step1, wfhsec)
    }
}

; Snooze Button (Win+Shift+P)
#+p::
{
    global extendable, cycleEndTime
    if (extendable = 1) {
        SetTimer(Step3, 0)
        SetTimer(CountdownDisplay, 0)
        ProgressOff()
        
        ShowProgress("Snoozed for " extendmin " minutes", "Blue", 2000)
        extendable   := 0
        cycleEndTime := A_TickCount + extendsec + step3sec

        SetTimer(Step2, extendsec)
    }
}

; ------------------------------------------------------------------------------
; Lock Screen Restrictions
; ------------------------------------------------------------------------------

#HotIf IsObject(LockGui)
    !F4::Return
    LWin::Return
    RWin::Return
    !Tab::Return
    ^Esc::Return
    LButton::Return 
    RButton::Return
#HotIf

; ------------------------------------------------------------------------------
; Status Overlay (lower-left, always visible)
; ------------------------------------------------------------------------------

CreateStatusGui() {
    global StatusGui, StatusLine1, StatusLine2

    if (IsObject(StatusGui))
        StatusGui.Destroy()

    try
        MonitorGetWorkArea(1, &WL, &WT, &WR, &WB)
    catch
        WB := A_ScreenHeight - 48  ; fallback: assume 48px taskbar

    StatusGui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20", "BreakStatus")
    StatusGui.BackColor := "1a1a1a"
    StatusGui.SetFont("s10 w600 cWhite", "Consolas")
    StatusLine1 := StatusGui.Add("Text", "w120", "Break: --:--")
    StatusLine2 := StatusGui.Add("Text", "w120", "Reset: --:--")
    WinSetTransparent(215, StatusGui)
    StatusGui.Show("NoActivate x5 y" (WB - 58))
}

StatusUpdate() {
    global on_break, timer_on, extendable, cycleEndTime
    global StatusGui, StatusLine1, StatusLine2

    if (!IsObject(StatusGui))
        CreateStatusGui()

    ; Line 1: time until break required
    if (on_break) {
        StatusLine1.Value := "ON BREAK"
    } else if (timer_on) {
        remaining := Max(0, cycleEndTime - A_TickCount)
        mm := remaining // 60000
        ss := Mod(remaining // 1000, 60)
        StatusLine1.Value := Format("Break: {:02}:{:02}", mm, ss)
    } else {
        StatusLine1.Value := "Break: --:--"
    }

    ; Line 2: total time until cycle resets
    ;   - During work:  time left in cycle + full break duration
    ;   - During break: idle time still needed
    if (on_break) {
        stillMs := Max(0, breaksec - A_TimeIdlePhysical)
        mm := stillMs // 60000
        ss := Mod(stillMs // 1000, 60)
        StatusLine2.Value := Format("Reset: {:02}:{:02}", mm, ss)
    } else if (timer_on) {
        stillMs := Max(0, breaksec - A_TimeIdlePhysical)
        mm := stillMs // 60000
        ss := Mod(stillMs // 1000, 60)
        StatusLine2.Value := Format("Reset: {:02}:{:02}", mm, ss)
    } else {
        StatusLine2.Value := "Reset: --:--"
    }
}

; ------------------------------------------------------------------------------
; System Functions
; ------------------------------------------------------------------------------

ExitFunc(ExitReason, ExitCode)
{
    if (ExitReason != "Logoff" and ExitReason != "Shutdown")
    {
        Result := MsgBox("Are you sure you want to exit?", "Break Timer", 4)
        if (Result = "No")
            return 1 
    }
}
