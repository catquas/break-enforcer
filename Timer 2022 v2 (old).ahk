#Persistent 
#SingleInstance

OnExit("ExitFunc")

ExitFunc(ExitReason, ExitCode)
{
    if ExitReason not in Logoff,Shutdown
    {
        MsgBox, 4, , Are you sure you want to exit?
        IfMsgBox, No
            return 1  ; OnExit functions must return non-zero to prevent exit.
    }
    ; Do not call ExitApp -- that would prevent other OnExit functions from being called.
}


;#include C:\Users\buxton_b\OneDrive - US Department of Labor - BLS\Desktop\AHK\devicelist.ahk

;Set times for things (default 25, 60, 20, 3)
cyclemin := 25 ;overall break timer cycle length
warn1sec := 60 ;1st warning, seconds before end
warn2sec := 15 ;2nd warning, seconds before end
breakmin := 3 ;length of required break in minutes
extendmin := 2 ;length of extension to time limit triggered by hotkey (in minutes)
pwd = 808595103267Cat! ;lockscreen password

;Compute miliseconds based on set times
step1sec := (cyclemin * 60 * 1000) - (warn1sec * 1000)
step2sec := (warn1sec * 1000) - (warn2sec * 1000)
step3sec := warn2sec * 1000
breaksec := breakmin * 60 * 1000
extendsec := extendmin * 60 * 1000

;Set on break to false, and welcome message triggered to false
global on_break := 0 ;whether actively on break, such that lock is triggered on keypress
global timer := 0 ;whether timer is active at all (will not be if no key pressed since startup or end of a break)
global welcome := 0
global firstinput := 0
global last_timeidlep := 0
global extendable := 0 ;whether break can be postponed
global kvm := 1 ;kvm switch status, 1 means this computer is activated

;Check if keyboard and mouse are idle every 1 second
SetTimer, idle_check, 1500

/*
;If something was plugged or unplugged, or KVM was changed
OnMessage(0x219, "notify_change") 

notify_change(wParam, lParam, msg, hwnd) 
{ 
	;msgbox %a_timeidlephysical% %on_break%
	;if KVM was changed, haven't been typing lately, and not on break, then go to step2 (first warning)
	if (a_timeidlephysical > 25000 and on_break = 0 and firstinput = 1) {
		
		keyboard := 0
		oArray := JEE_DeviceList("`r`n")
		for _, oObj in oArray {
			for vKey, vValue in oObj {
				if (instr(vValue, "Keyboard")) {
					;MsgBox, % vValue
					keyboard := 1
				}
			}
		}
		;if kvm was set to this computer in but now keyboard not plugged in
		if (kvm = 1 && keyboard = 0) {
			kvm := 0
		}
		;If it is plugged in but kvm = 0 (from before), and the first timer hasn't started: 
		if (kvm = 0 && keyboard = 1 && extendable = 0) {
;			msgbox, 4,, Take a Break in two mintues?
;        IfMsgBox Yes
			SetTimer, step1kvm, 60000
			SetTimer, step2, off
			SetTimer, step3, off
		}
	}
}
*/

idle_check:
if (firstinput = 0) {
	if (a_timeidlephysical < last_timeidlep) {
		firstinput = 1
		;msgbox % firstinput
	} else {
		last_timeidlep := a_timeidlephysical
	}
}
; If keyboard or mouse used when not on break, then start break timer
if (a_timeidlephysical < 2000 and on_break = 0 and timer = 0) {
	progress, zh0 fs70 ctAqua cwBlue w800, Starting Break Time Loop
	sleep 1000
	progress, off
	timer = 1
	welcome = 0
	SetTimer, step1, %step1sec%
}
; If keyboard or mouse used when on break, then run lockscreen
if (a_timeidlephysical < 2000 and on_break = 1) {
	;DllCall("LockWorkStation")
	lockscreen()
	SetTimer, idle_check, Off ;turn idle_check timer off so it is not still checking while lockscreen is up
	SetTimer, step3, Off
} 
; If keyoard and mouse are idle for full break min, then stop timers and end break
if (a_timeidlephysical > breaksec and welcome = 0) {
	progress, zh0 fs70 ctAqua cwBlue w800, Welcome back!
	on_break = 0
	welcome = 1 ;prevent "welcome back" from triggering repeatedly
	timer = 0
	SetTimer, step1, Off
	SetTimer, step2, Off
	SetTimer, step3, Off
}
return

;first warning triggers at end of step1 timer, and then starts step2 timer
step1kvm:
SetTimer, step1kvm, Off
progress, zh0 fs70 ctAqua cwBlue w800, %warn1sec% Second Warning (KVM)
extendable = 0
sleep 5000
progress, off
SetTimer, step2, %step2sec%
return

;first warning triggers at end of step1 timer, and then starts step2 timer
step1:
SetTimer, step1, Off
progress, zh0 fs70 ctAqua cwBlue w800, %warn1sec% Second Warning
extendable = 1
sleep 5000
progress, off
SetTimer, step2, %step2sec%
return

;second warning triggers at end of step2 timer, and then starts step3 timer
step2:
SetTimer, step2, Off
progress, zh0 fs70 ctAqua cwBlue w800, %warn2sec% Second Warning
;sleep 5000
;progress, off
SetTimer, step3, %step3sec%
countdown := warn2sec - 1
stopcount := 0
loop %countdown% {
	sleep 1000
	if (stopcount = 1) {
		break
	}
	secleft := warn2sec - a_index 
	progress, zh0 fs70 ctAqua cwBlue w800, %secleft% Second Warning
}
return

;final warning triggers at end of step3 timer
step3:
SetTimer, step3, Off
progress, zh0 fs70 ctYellow cwRed w800, Take a Break!
on_break = 1 ;when on break is 1, typing or mousing triggers lockscreen
extendable = 0
return

;Lockscreen to come up and require password
lockscreen(){
	Gui, -SysMenu ;supposed to remove minimize, maximize, and close buttons
	Gui, New, , Lockscreen ; Creates a new GUI called Lockscreen.
	Gui, font, s10, Verdana  
	Gui, color, red
	Gui, Add, Text,, Password ;label for text box
	Gui, Add, Edit, vPassword ;what is entered in this text box is stored to the variable "password" when submitted.
	Gui, Add, Button, w55 x280 default, OK ;OK button, the default option makes it also trigger by pressing enter.
	Gui, Show, Center W1900 h1000, Lockscreen ;Shows lockscreen, gives it a size (might want to make this a percent of screen)
	WinSet, AlwaysOnTop, On, Lockscreen ahk_class AutoHotkeyGUI ;This actually makes the GUI stay on top of everything.
}


;When OK button is clicked or enter key typed
buttonOK:
Gui, Submit  ; Save the input from the user to each control's associated variable.
;If password is correct, set on break to false, and start idle_check timer again
if (password = pwd) {
	progress, off
	on_break = 0
	timer = 0
	SetTimer, idle_check, 1000
}
;If password is incorrect, trigger lockscreen again
if (password != pwd) {
	lockscreen()
}
return

#+p::
if (extendable = 1) {
	stopcount := 1
	SetTimer, step3, Off
	progress, zh0 fs70 ctAqua cwBlue w800, %extendmin% more minutes
	extendable = 0
	sleep 5000
	progress, off
	SetTimer, step2, %extendsec%
}
return

;If lockscreen is up, disable all hotkeys that would get you out of it without the password, and also disable mouse clicks
#IfWinExist Lockscreen ahk_class AutoHotkeyGUI
!f4:: 
#b:: 
#d:: 
#m:: 
#down:: 
lbutton:: 
rbutton::
return
#ifwinexist


/*
1. Set timer to 24 minutes, and once done run step 2
2. Message 1 minute warning, set timer to 40 seconds, and once done run step 3
3. Message 20 second warning, set timer to 20 seconds, and once done run step 4
4. Message Take a Break, pause timer, trigger lockscreen on keypress
5. If timeidle = 3 minutes, then run step 1
6. If VGA switch to this computer, run step 2
*/