﻿/*
    此插件仅供自用，依赖对 DC 代码的修改以及专门的配置

    ---

    DC 的优势

    开源，免费，跨平台，可以自由改代码定制功能，很好编译
    可以改代码让所有目录中的父目录（..）消失（已完成）
    可以把按键绑定到工具栏的子菜单上，然后再通过按键触发功能
    内建 lua 解释器，方便写一些高级功能（感觉功能有限，用处不大）
    主界面和配置界面更漂亮、好用

    ---

    TODO

    整理代码
*/

DoubleCommander:
    global DC := "ahk_class DClass"
    global DC_Dir := "c:\mine\app\doublecmd"
    ; 用于记录文件打开对话框所属窗体
    global DC_CallerId := 0

    DC_Name := "DoubleCommander"

    vim.SetWin(DC_Name, "DClass", "doublecmd.exe")
    vim.Mode("normal", DC_Name)

    vim.BeforeActionDo("DC_ForceInsertMode", DC_Name)
return

DC_ForceInsertMode() {
    ControlGetFocus, ctrl
    if (InStr(ctrl, "Edit") == 1) {
        return true
    }

    WinGet, MenuID, ID, AHK_CLASS #32768
    if (MenuID != "") {
        return true
    }

    return false
}

DC_Run(cmd) {
    ControlSetText, Edit1, % cmd, % DC
    ControlSend, Edit1, {enter}, % DC
}

; 返回值 [1]: left/right [2]: 左侧面板所占比例 0-100
DC_GetPanelInfo() {
    ClipSaved := ClipboardAll
    Clipboard := ""
    DC_run("cm_CopyPanelInfoToClip")
    ClipWait, 2

    PanelInfo := StrSplit(Clipboard, " ")
    Clipboard := ClipSaved

    return PanelInfo
}

DC_ExecuteToolbarItem(Id) {
    DC_Run("cm_ExecuteToolbarItem ToolItemID=" . Id)
}

DC_ColumnsView(columnset) {
    if (columnset == "") {
        DC_Run("cm_ColumnsView")
    } else {
        DC_Run("cm_ColumnsView columnset=" columnset)
    }
}

<DC_RenameFull>:
    Send, {f2}^a
return

<DC_Test>:
    ; DC_ExecuteToolbarItem("{700FF494-B939-48A3-B248-8823EB366AEA}")
    DC_Run("cm_About")
return

<DC_Restart>:
    WinClose, % DC
    WinWaitClose, % DC, , 2

    Run, % DC_Dir . "\doublecmd.exe --no-splash"

    WinWaitActive, % DC

    if (!WinExist(DC)) {
        MsgBox, 重启失败 %ErrorMessage%
    }
return

<DC_Show_50_50>:
    DC_Run("cm_PanelsSplitterPerPos splitpct=50")
return

<DC_Show_100_0>:
    DC_Run("cm_PanelsSplitterPerPos splitpct=100")
return

<DC_Show_0_100>:
    DC_Run("cm_PanelsSplitterPerPos splitpct=0")
return

<DC_HorizontalFilePanels>:
    DC_Run("cm_HorizontalFilePanels mode=legacy")
return

<DC_Toggle_50_100>:
    PanelInfo := DC_GetPanelInfo()

    if (abs(50 - PanelInfo[2]) < 10) {
        if (PanelInfo[1] == "left") {
            DC_Run("cm_PanelsSplitterPerPos splitpct=100")
        } else {
            DC_Run("cm_PanelsSplitterPerPos splitpct=0")
        }
    } else {
        DC_Run("cm_PanelsSplitterPerPos splitpct=50")
    }
return

<DC_MakeDir>:
    DC_Run("cm_MakeDir")
return

<DC_PreviousParallelDir>:
    SleepTime := 10

    ClipSaved := ClipboardAll
    Clipboard := ""
    DC_Run("cm_CopyCurrentPathToClip")
    ClipWait, 2

    OldPwd := Clipboard

    if (InStr(OldPwd, "\") == 1) {
        ; 网络文件系统比较慢
        SleepTime := 50
    }

    if (StrLen(OldPwd) == 3) {
        ; 在根分区

        Clipboard := ClipSaved
        ClipSaved := ""

        return
    }

    DC_Run("cm_ChangeDirToParent")
    Sleep, % SleepTime

    Send, {up}
    Sleep, % SleepTime

    Send, {right}

    Clipboard := ClipSaved
    ClipSaved := ""
return

<DC_NextParallelDir>:
    SleepTime := 10

    ClipSaved := ClipboardAll
    Clipboard := ""
    DC_Run("cm_CopyCurrentPathToClip")
    ClipWait, 2

    OldPwd := Clipboard

    if (InStr(OldPwd, "\") == 1) {
        ; 网络文件系统比较慢
        SleepTime := 50
    }

    if (StrLen(OldPwd) == 3) {
        ; 在根分区
        ; Gosub, <cm_GotoPreviousDrive>

        Clipboard := ClipSaved
        ClipSaved := ""

        return
    }

    DC_Run("cm_ChangeDirToParent")
    Sleep, % SleepTime

    Send, {down}
    Sleep, % SleepTime

    Send, {right}
    Sleep, % SleepTime

    Clipboard := ""
    DC_Run("cm_CopyCurrentPathToClip")
    ClipWait, 2

    if (InStr(OldPwd, Clipboard) == 1) {
        ; 下一个是文件
        DC_Run("cm_ViewHistoryPrev")
    }

    Clipboard := ClipSaved
    ClipSaved := ""
return

<DC_CreateNewFile>:
    ControlGetFocus, TLB, % DC
    ControlGetPos, xn, yn, , , % TLB, % DC

    Menu, NewFileMenu, Add
    Menu, NewFileMenu, DeleteAll
    Menu, NewFileMenu, Add , S >> 快捷方式, <DC_CreateFileShortcut>
    Menu, NewFileMenu, Icon, S >> 快捷方式, %A_WinDir%\system32\Shell32.dll, 264
    Menu, NewFileMenu, Add

    Loop, % DC_Dir . "\ShellNew\*.*" {
        ft := SubStr(A_LoopFileName, 1, 1) . " >> " . A_LoopFileName
        Menu, NewFileMenu, Add, % ft, DC_NewFileMenuAction
        Menu, NewFileMenu, Icon, % ft, %A_WinDir%\system32\Shell32.dll
    }

    Menu, NewFileMenu, Show, % xn, % yn + 2
return

DC_NewFileMenuAction:
    Filename := RegExReplace(A_ThisMenuItem, ".\s>>\s")
    FilePath := DC_Dir . "\ShellNew\" . Filename

    Gui, Destroy
    Gui, Add, Text, x12 y20 w50 h20 +Center, 模板源
    Gui, Add, Edit, x72 y20 w300 h20 Disabled, % FilePath
    Gui, Add, Text, x12 y50 w50 h20 +Center, 新建文件
    Gui, Add, Edit, x72 y50 w300 h20, % Filename
    Gui, Add, Button, x162 y80 w90 h30 gDC_NewFileOk default, 确认(&S)
    Gui, Add, Button, x282 y80 w90 h30 gDC_NewFileClose , 取消(&C)
    Gui, Show, w400 h120, 新建文件
return

DC_NewFileClose:
    Gui, Destroy
return

DC_NewFileOK:
    GuiControlGet, SrcFilePath, , Edit1
    GuiControlGet, NewFilename, , Edit2

    ClipSaved := ClipboardAll
    Clipboard :=
    DC_Run("cm_CopyCurrentPathToClip")
    ClipWait, 2
    DstPath := Clipboard
    Clipboard := ClipSaved
    ClipSaved := ""

    if (InStr(DstPath, "`r")) {
        DstPath := SubStr(DstPath, 1, InStr(DstPath, "`r") - 1)
    } else if (DstPath == "") {
        return
    }

    NewFilePath := DstPath . NewFilename
    if (FileExist(NewFilePath)) {
        MsgBox, 4, 新建文件, 新建文件已存在，是否覆盖？
        IfMsgBox No
            return
    }

    FileCopy, % SrcFilePath, % NewFilePath, 1

    ; TODO
    ; 好像无法实现定位到新创建的文件

    Gui, Destroy
return

<DC_Toggle>:
    if (WinExist(DC)) {
        WinGet, Ac, MinMax, % DC
        if (Ac == -1) {
            WinActivate, % DC
        } else {
            if (!WinActive(DC)) {
                WinActivate, % DC
            } else {
                WinMinimize, % DC
            }
        }
    } else {
        Run, % DC_Dir . "\doublecmd.exe --no-splash"
        WinWait, % DC

        if (!WinActive(DC)) {
            WinActivate, % DC
        }
    }
return

<DC_SortByName>:
    DC_Run("cm_SortByName")
return

<DC_SortByExt>:
    DC_Run("cm_SortByExt")
return

<DC_SortBySize>:
    DC_Run("cm_SortBySize")
return

<DC_SortByDate>:
    DC_Run("cm_SortByDate")
return

<DC_SortByAttr>:
    DC_Run("cm_SortByAttr")
return

<DC_ReverseOrder>:
    DC_Run("cm_ReverseOrder")
return

<DC_FocusSwap>:
    DC_Run("cm_FocusSwap")
    ; side=left/right
return

<DC_CopyCurrentPathToClip>:
    DC_Run("cm_CopyCurrentPathToClip")
return

<DC_OpenExplorer>:
    DC_Run(".")
return

<DC_MarkFile>:
    DC_Run("cm_EditComment")
    ; 不要在已有备注的文件使用
    Send, ^+{end}🖥{f2}
return

<DC_UnMarkFile>:
    DC_Run("cm_EditComment")
    ; 删除 DC_MarkFile 的文件标记，也可用于清空文件备注
    Send, ^+{end}{del}{f2}
return

<DC_ShowMainMenu>:
    DC_Run("cm_ShowMainMenu")
return

<DC_ShowButtonMenu>:
    DC_Run("cm_ShowButtonMenu")
return

<DC_OperationsViewer>:
    DC_Run("cm_OperationsViewer")
return

<DC_TreeView>:
    DC_Run("cm_TreeView")
return

<DC_FocusTreeView>:
    DC_Run("cm_FocusTreeView")
return

<DC_BriefView>:
    DC_Run("cm_BriefView")
return

<DC_ColumnsView1>:
    DC_ColumnsView("mine")
return

<DC_ColumnsView2>:
    DC_ColumnsView("test")
return

<DC_ThumbnailsView>:
    DC_Run("cm_ThumbnailsView")
    Gosub, <DC_ThumbnailsSwitchKey>
return

<DC_ThumbnailsSwitchKey>:
    InThumbsView := !InThumbsView

    if (InThumbsView) {
        vim.Map("l", "<right>", DC_Name)
    } else {
        vim.Map("l", "<enter>", DC_Name)
    }
return

<DC_ToggleShowInfo>:
    vim.GetWin(DC_Name).SetInfo(!vim.GetWin(DC_Name).info)
return

<DC_CopyFileContent>:
    Clipboard := ""
    DC_Run("cm_CopyFullNamesToClip")
    ClipWait, 2

    Fileread, Contents, % Clipboard
    Clipboard := Contents
return

<DC_CopyFilenamesOnly>:
    Clipboard := ""
    DC_Run("cm_CopyFullNamesToClip")
    ClipWait, 2

    SplitPath, Clipboard, OutFileName, , , OutFilenameNoExt

    if (InStr(FileExist(Clipboard), "D")) {
        Clipboard := OutFileName
    } else if (InStr(Clipboard, ".")) {
        Clipboard := OutFilenameNoExt
    }
return

<DC_CreateFileShortcut>:
    ClipSaved := ClipboardAll
    Clipboard := ""
    DC_Run("cm_CopyFullNamesToClip")
    ClipWait

    FilePath := Clipboard
    Clipboard := ClipSaved
    ClipSaved := ""


    OutVar := FileExist(FilePath)
    if (InStr(OutVar, "D")) {
        FileCreateShortcut, % FilePath, % FilePath . ".lnk"
    } else if (OutVar != "") {
        FileCreateShortcut, % FilePath, % RegExReplace(FilePath, "\.[^.]*$", ".lnk")
    }
return

<DC_Focus>:
    IfWinExist, % DC
        Winactivate, % DC
    else {
        Run, % DC_Dir . "\doublecmd.exe --no-splash"
        WinWait, % DC
        IfWinNotActive, % DC
            WinActivate, % DC
    }
return

<DC_MapKeys>:
	vim.Mode("normal", DC_Name)
    vim.Map("<S-Enter>", "<DC_SelectedCurrentDir>", DC_Name)
    vim.Map("<Esc>", "<DC_ReturnToCaller>", DC_Name)
return

<DC_UnMapKeys>:
	vim.Mode("normal", DC_Name)
    vim.Map("<S-Enter>", "<Default>", DC_Name)
    vim.Map("<Esc>", "<Default>", DC_Name)
return

; 返回调用者
<DC_ReturnToCaller>:
    gosub <DC_UnMapKeys>

    WinActivate, ahk_id %DC_CallerId%

    DC_CallerId := 0
return

; 非 TC 窗口按下后激活 TC 窗口
; TC 窗口按下后复制当前选中文件返回原窗口后粘贴
<DC_OpenDCDialog>:
    WinGetClass, name, A

    ; 在 DC 按下快捷键时，激活调用窗体并执行粘贴操作
    if (name == "DClass") {
        if (DC_CallerId != 0) {
            gosub <DC_Selected>
            DC_CallerId := 0
		}
    } else {
        DC_CallerId := WinExist("A")
        if (DC_CallerId == 0) {
            return
		}

        gosub <DC_Focus>
        gosub <DC_MapKeys>
    }
return

<DC_Selected>:
    gosub <DC_UnMapKeys>

    Clipboard := ""
    ; 不知道什么原因，必须加一个 MsgBox 功能才正常
    MsgBox, , , 处理中, 0.3

    DC_Run("cm_CopyCurrentPathToClip")

    ClipWait, 2
    pwd := Clipboard

    Clipboard := ""
    DC_Run("cm_CopyNamesToClip")
    ClipWait, 2

    WinActivate, ahk_id %DC_CallerId%
    WinWait, ahk_id %DC_CallerId%
    DC_CallerId := 0

    if (!InStr(Clipboard, "`n")) {
        Clipboard := pwd . Clipboard
        Send, {Home}
        Send, ^v
        Send, {Enter}

        return
    }

    ; 多选

    files := ""
    Loop, parse, Clipboard, `n, `r
        files .= """" . A_LoopField  . """ "

    ; 第一步：跳转到当前路径
    Clipboard := pwd
    Send, ^a
    Send, ^v
    Send, {Enter}
    sleep, 100

    ; 第二步：提交文件名
    Clipboard := files
    Send, ^v
    Send, {Enter}
return

<DC_SelectedCurrentDir>:
    gosub <DC_UnMapKeys>

    if (DC_CallerId == 0) {
        return
    }

    Clipboard := ""
    DC_Run("cm_CopyCurrentPathToClip")
    ClipWait

    ; 添加默认路径不带反斜杠，添加之

    Clipboard .= "\"

    WinActivate, ahk_id %DC_CallerId%
    WinWait, ahk_id %DC_CallerId%
    DC_CallerId := 0

    Send, {Home}
    Send, ^v
    Send, {Enter}
return

DC_OpenPath(Path, InNewTab := true, LeftOrRight := "") {
    LeftOfRight := DC_GetPanelInfo()[1]
    if (LeftOfRight == "right") {
        LeftOrRight := "-R"
    } else {
        LeftOrRight := "-L"
    }

    if (InNewTab) {
        Run, "%DC_Dir%\doublecmd.exe" --no-splash -T "%LeftOrRight%" "%Path%"
    } else {
        Run, "%DC_Dir%\doublecmd.exe" --no-splash "%LeftOrRight%" "%Path%"
    }
}
