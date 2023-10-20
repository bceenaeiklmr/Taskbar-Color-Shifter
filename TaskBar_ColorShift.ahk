#Requires AutoHotkey v2.0
#SingleInstance Force
#Warn
ListLines(0)

; default value is 20 ms, one transition takes 5,1 s
TimerPeriod := 20
; 1 solid color w/o transparency (The colors are bright in this mode, it's distracting to the eyes)
; 2 transparent color
ColorMode := 2
; only required for transparent color
Alpha := 50

; panic button (unfortunately, there is no restore function yet)
^Escape::ExitApp

SetTimer(TaskBar_RandColorShift.Bind(Alpha), TimerPeriod)

/**
 * Shifts the color of the Windows taskbar using random colors.
 *
 * @param {Integer} Alpha - The alpha value for transparent mode.
 * @param {Integer} Range - The value where the color shift ends. This determines how long the color transition takes.
 */
TaskBar_RandColorShift(Alpha := 50, Range := 255, *) {

    static c1 := {R:0, G:0, B:0},
           c2 := {R:0, G:0, B:255},
           i := 0

    ; linear interpolation between the two specified colors
    p := (i += 1) / Range, ; percent
    R := c1.R + Ceil(p * (c2.R - c1.R)),
    G := c1.G + Ceil(p * (c2.G - c1.G)),
    B := c1.B + Ceil(p * (c2.B - c1.B)),
    color := Format("{:#02x}{:02x}{:02x}{:02x}", Alpha, R, G, B)

    ; if it reaches the color2 then swap the colors and set a new color2
    if (i=range) {
        c1 := c2,
        c2 := {R : Random(0,255), G : Random(0,255), B : Random(0,255)},
        i := 0
    }
    ; apply the new color on the taskbar
    TaskBar_SetAttr(ColorMode, color)
}

/**
 * The following function is a fork (update to v2) of jNizM's Make the windows 10 taskbar translucent (blur) repository.
 * https://github.com/jNizM/AHK_TaskBar_SetAttr/tree/master
 * https://autohotkey.com/boards/viewtopic.php?f=6&t=26752
 * 
 * TaskBar_SetAttr(option, color)
 * 
 * option -> 0 = off,
 *           1 = gradient    (+color),
 *           2 = transparent (+color),
 *           3 = blur
 * 
 * color  -> ABGR (alpha | blue | green | red) 0xffd7a78f
 */
TaskBar_SetAttr(accent_state := 0, gradient_color := "0x01000000")
{
    static init, hTrayWnd, ver := DllCall("GetVersion") & 0xff < 10
    static pad := A_PtrSize = 8 ? 4 : 0, WCA_ACCENT_POLICY := 19

    if !IsSet(init) {
        if (ver)
            throw ValueError("Minimum support client: Windows 10", -1)
        if !(hTrayWnd := DllCall("user32\FindWindow", "str", "Shell_TrayWnd", "ptr", 0, "ptr"))
            throw ValueError("Failed to get the handle", -1)
        init := 1
    }

    ACCENT_POLICY := Buffer(16, 0)
    NumPut("int", (accent_state > 0 && accent_state < 4) ? accent_state : 0, ACCENT_POLICY, 0)

    if (accent_state >= 1) && (accent_state <= 2) && (RegExMatch(gradient_color, "0x[[:xdigit:]]{8}"))
        NumPut("int", gradient_color, ACCENT_POLICY, 8)

    WINCOMPATTRDATA := Buffer(4 + pad + A_PtrSize + 4 + pad, 0)
    NumPut("int", WCA_ACCENT_POLICY, WINCOMPATTRDATA, 0)
    NumPut("ptr", ACCENT_POLICY.ptr, WINCOMPATTRDATA, 4 + pad)
    NumPut("uint", ACCENT_POLICY.Size, WINCOMPATTRDATA, 4 + pad + A_PtrSize)
    if !(DllCall("user32\SetWindowCompositionAttribute", "ptr", hTrayWnd, "ptr", WINCOMPATTRDATA.ptr))
        throw ValueError("Failed to set transparency / blur", -1)
    return true
}
