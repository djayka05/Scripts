<#

The script simplifies the task of renaming files using MD5 hashes, providing a convenient method to uniquely identify and manage files within a directory.

#>

function Rename-FilesWithMD5 {
    param(
        [string]$Path
    )

    $files = Get-ChildItem $Path

    foreach ($file in $files) {
        $md5 = (Get-FileHash $file.FullName -Algorithm MD5).Hash
        $newName = "$md5$file.Extension"
        Rename-Item -Path $file.FullName -NewName $newName
    }
}
