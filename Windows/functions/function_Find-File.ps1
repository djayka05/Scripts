function find-file($name) {
        $name = Read-Host -Prompt 'enter text'
        Get-ChildItem -recurse -filter "*${name}*" -ErrorAction SilentlyContinue | Foreach-Object {
                $place_path = $_.directory
                Write-Output "${place_path}\${_}"
        }
}