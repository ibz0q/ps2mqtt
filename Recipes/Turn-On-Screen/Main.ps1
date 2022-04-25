(Add-Type -MemberDefinition "[DllImport(""user32.dll"")]`npublic static extern int SendMessage(int hWnd, int hMsg, int wParam, int lParam);" -Name "Win32SendMessage" -Namespace Win32Functions -PassThru)::SendMessage(0xffff, 0x0112, 0xF170, -1)

$Signature = @"
[DllImport("user32.dll")]
public static extern IntPtr SendMessage(IntPtr hWnd, UInt32 Msg, IntPtr wParam, IntPtr lParam);

[DllImport("user32.dll")]
public static extern void mouse_event(Int32 dwFlags, Int32 dx, Int32 dy, Int32 dwData, UIntPtr dwExtraInfo);
"@

$ShowWindowAsync = Add-Type -MemberDefinition $Signature -Name "Win32ShowWindowAsync" -Namespace Win32Functions -PassThru -ErrorAction Ignore 

[System.Int64]$MOUSEEVENTF_MOVE = 0x0001;

$ShowWindowAsync::mouse_event($MOUSEEVENTF_MOVE, 0, 10, 10, [System.UIntPtr]::Zero);

$myshell = New-Object -com "Wscript.Shell"
$myshell.sendkeys(" ")

