# Set source and destination paths
$sourcePath = "C:\SourceFolder"
$destinationURL = "https://yoursharepointsite.sharepoint.com/sites/YourSiteName"
$destinationLibraryName = "Documents"

# Connect to SharePoint Online
Connect-PnPOnline -Url $destinationURL -UseWebLogin

# Get list of all files in source directory and its subdirectories
$files = Get-ChildItem -Path $sourcePath -Recurse -File

# Loop through each file
foreach ($file in $files) {
    # Calculate relative path of file
    $relativePath = $file.FullName.Substring($sourcePath.Length + 1)

    # Construct destination URL for file
    $destinationFileURL = $destinationURL + "/" + $destinationLibraryName + "/" + $relativePath.Replace("\", "/")

    # Upload file to SharePoint
    Add-PnPFile -Path $file.FullName -Folder $destinationLibraryName -NewFileName $file.Name -ErrorAction SilentlyContinue
}
