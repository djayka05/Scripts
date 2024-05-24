function pkill($name) {
        $name = Read-Host -Prompt "process name"
        Get-Process $name -ErrorAction SilentlyContinue | Stop-Process
}