# break-enforcer
Force yourself to take regular breaks from the computer

## Description
Forces you to take breaks every 25 miniutes (by default). 
By detecting keyboard and mouse input, it will start a cycle when you start using the computer.
If you are idle for 3 minutes (by default), the timer will be reset and a new cycle will start.
Once you have 1 minute left (by default), you will get the first warning.
Once you have 15 seconds left (by default), you will get the second warning, which will count down to zero.
Once the end of cycle is reached, any mouse or keyboard input will trigger the lockscreen, which requires a password to disable.
The lockscreen is always-on-top, and keyboard shortcuts and mouse clicks which might remove it are disabled.
You can still shut down your computer whilte the lockscreen is up, and not much else.

## Requirements
- Autohotkey 2.0

## Options
cyclemin : Overall break timer cycle length. Your break will start being enforced after you have been interacting with the computer for this amount of minutes, unless you extend.
warn1sec : 1st warning that break is about to be enforced, number seconds before end of the cycle.
warn2sec : 2nd warning that break is about to be enforced, number seconds before end of the cycle.
breakmin : Length of break enforcement period in minutes
extendmin : Number of minutes break can be postponed by using hotkey.
pwd : Password to disable lock screen. Make it hard to remember or at least hard to type.
