#Requires AutoHotkey v2.0
#SingleInstance Force
#Warn
ListLines(0)

; default value is 30 ms, one shift takes at least 30 ms on a high-end system
TimerPeriod := 30
; the alpha value of the taskbar (using 0 or 255 is not recommended, the colors are bright in this mode, and it's distracting to the eyes)
TaskBarAlpha := 100
; start the timer
SetTimer(TaskBar_RandColorShift.Bind(TaskBarAlpha), TimerPeriod) ; <-- random colors
;SetTimer(TaskBar_ColorShift.Bind(0x000000, 0xFFFFFF, TaskBarAlpha), TimerPeriod) ; <-- only two colors

; unfortunately, there is no restore function yet
;^Escape::ExitApp

/**
 * Shifts the color of the Windows taskbar using random colors.
 *
 * @param {Integer} Alpha - The alpha value for transparent mode.
 * @param {Integer} Range - The value where the color shift ends. This determines how long the color transition takes.
 */
TaskBar_RandColorShift(Alpha := 255, Range := 255, *) {

    static c1 := {R:0, G:0, B:0},
           c2 := {R:0, G:0, B:255},
           i := 0

    ; linear interpolation between the two specified colors
    p := (i += 1) / Range, ; percent
    R := c1.R + Ceil(p * (c2.R - c1.R)),
    G := c1.G + Ceil(p * (c2.G - c1.G)),
    B := c1.B + Ceil(p * (c2.B - c1.B)),
    Color := Format("{:#02x}{:02x}{:02x}{:02x}", Alpha, R, G, B)

    ; if it reaches the color2 then swap the colors and set a new color2
    if (i=range) {
        c1 := c2,
        c2 := {R : Random(0,255), G : Random(0,255), B : Random(0,255)},
        i := 0
    }
    ; apply the new color setting on the taskbar
    ColorMode := !Alpha || Alpha = 255 ? 1 : 2
    TaskBar_SetAttr(ColorMode, Color)
}

/**
 * Shifts the color of the Windows taskbar using user-defined colors.
 *
 * @param {Hex} Color1 - 0x000000
 * @param {Hex} Color2 - 0x000000
 * @param {Integer} Alpha - The alpha value for transparent mode.
 * @param {Integer} Range - The value where the color shift ends. This determines how long the color transition takes.
 */
TaskBar_ColorShift(Color1 := 0x000000, Color2 := 0xFFFFFF, Alpha := 255, Range := 255, *) {

    static i := 0, reverse := 1

    c1 := { R : (0xff0000 & Color1) >> 16,
	        G : (0x00ff00 & Color1) >> 8,
	        B :  0x0000ff & Color1 }

    c2 := { R : (0xff0000 & Color2) >> 16,
            G : (0x00ff00 & Color2) >> 8,
            B :  0x0000ff & Color2 }   

    ; linear interpolation between the two specified colors
    p := (i += 1 * reverse) / Range, ; percent
    R := c1.R + Ceil(p * (c2.R - c1.R)),
    G := c1.G + Ceil(p * (c2.G - c1.G)),
    B := c1.B + Ceil(p * (c2.B - c1.B)),
    Color := Format("{:#02x}{:02x}{:02x}{:02x}", Alpha, R, G, B)

    ; change direction
    if i=range || !i 
        reverse := reverse * (-1)
    ; apply the new color setting on the taskbar
    ColorMode := !Alpha || Alpha = 255 ? 1 : 2
    TaskBar_SetAttr(ColorMode, Color)
}

/**
 * The following function is a fork (update to v2) of jNizM's Make the Windows 10 taskbar translucent (blur) repository.
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
