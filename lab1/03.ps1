# Student: Bryan Van Huyneghem
# Status: completed.
# Produces folder & files, downloads template image, changes file extensions to jpg, copies template, adds number, changes modified/created with 5 minute interval,
# outputs file that contains image paths between 7 AM and 8 AM, and counts files per hour bucket (+ output)

# ! I have to add this line, otherwise my code errors out, stating it cannot find System.Drawing
Add-Type -AssemblyName System.Drawing

################ A) ################
$ErrorActionPreference = "stop"
# Important variables that can be changed at will
$number_of_images = 100
$template_image_url = 'https://www.iter.org/img/resize-600-85/www/content/com/Lists/Stories/Attachments/3236/webcam_view_ED.jpg'
# Start time
$start = [DateTime]::Today.AddHours(7)
# End time
$end = $start.AddHours(1)

# Test if the path .\camera exists. If not, create it
if (Test-Path '.\camera') {
    Write-Output " -> Path exists. Continuing."
}
else {
    New-Item -Path . -Name '\camera' -ItemType Directory
    Write-Output " -> Path didn't exit; creating path."
}

# Download template image
Write-Output " -> Downloading template image..."
$jpg_response = Invoke-WebRequest -Uri $template_image_url
if ($jpg_response.StatusCode -ge 200 -and $jpg_response.StatusCode -lt 300) {
    # Write the file
    Set-Content -Path '.\camera\template_image.jpg' -Encoding Byte -Value $jpg_response.Content
}
Write-Output " -> Done downloading template image."
# Add 100 random, empty files to this subfolder
## Helper-function
function Get-RandomFilename {
    [IO.Path]::GetFileNameWithoutExtension([System.IO.Path]::GetRandomFileName())
}
## Verify whether there are already files present; if yes, we remove these files.
if ((Get-ChildItem -Path '.\camera' | Measure-Object).Count -ne 1) {
    Write-Output " -> Files present; removing old test files."
    Remove-Item -Path '.\camera\*.*' -Exclude 'template_image.jpg'
}
" -> Creating " + $number_of_images + " test files..." | Write-Output
for ($i = 0; $i -lt $number_of_images; $i++) {
    New-Item -Name $(Get-RandomFilename)  -ItemType File -Path '.\camera' > $null
}
" -> Done creating " + $number_of_images + " files." | Write-Output

# Change these files to jpg
Write-Output " -> Changing file extensions..."
Get-ChildItem -Path '.\camera' | Rename-Item -NewName { [io.path]::ChangeExtension($_.Name, "jpg") }
Write-Output " -> File extension change complete."

# Set template image for each file.
Write-Output " -> Setting template to all files..."
$files = Get-ChildItem -Path '.\camera'
foreach ($file in $files) {
    if ($file.Name -ne 'template_image.jpg') {
        Copy-Item -Path '.\camera\template_image.jpg' -Destination $file.FullName
    }
}
Write-Output " -> Done setting template to all files."

# Add numbers to the image and advance modified/creation date by 5 minutes each file.
$font = [System.Drawing.Font]::new("Calibri", 48)
## Helper-function
function DrawNumber {
    Param(
        [Parameter(Mandatory, Position = 0)]
        [String] $path,
        [Parameter(Mandatory, Position = 1)]
        [int] $number
    )
    $stream = [System.IO.File]::OpenRead($path)
    $bmp = [System.Drawing.Bitmap]::FromStream($stream)
    $stream.Dispose()
    $gfx = [System.Drawing.Graphics]::FromImage($bmp)
    $gfx.DrawString($number, $font, [System.Drawing.Brushes]::Yellow, 0, 0)
    $bmp.Save($path)
}

$files = Get-ChildItem -Path '.\camera' | Where-Object { $_.Name -ne 'template_image.jpg'}
if ($files.Count -eq $number_of_images | Where-Object {$_.Extension -ne 'txt'}) {
    Write-Output " -> Drawing numbers and changing creation/modified time..."
    $num = 1
    foreach($file in $files) {
        DrawNumber -path $file.FullName -number $num
        $file.CreationTime = [DateTime]::Today.AddMinutes(($($num-1)*5))   
        $file.LastWriteTime = [DateTime]::Today.AddMinutes($(($num-1)*5))
        $num++
    }
    Write-Output " -> Done drawing numbers and changing creation/modified time."
}
else {
    Write-Output "ERROR: Mismatch of number of images folder. Did not draw anything."
}

################ B) ################
# Write all file paths on a certain date (here: the day when the script is run), between 7 AM and 8 AM to the file 'inputfile_imagemagick.txt'
Write-Output " -> Writing image paths for images between 7 AM and 8 AM to .\camera\inputfile_imagemagick.txt ..."
(Get-ChildItem -Path '.\camera' | Where-Object { 
                                                ($_.Name -ne 'template_image.jpg') -and 
                                                ($_.CreationTime.Date -eq [DateTime]::Today) -and 
                                                ($_.CreationTime.DateTime -ge $start.DateTime -and $_.CreationTime.DateTime -lt $end.DateTime) 
                                               } | Sort-Object -Property CreationTime).FullName | Out-File ".\camera\inputfile_imagemagick.txt"

Write-Output " -> Done writing to file."

################ C) ################
# Count the files per hour and show an overview hour - # files
$items = Get-ChildItem -Path '.\camera' | Where-Object { $_.Name -ne 'template_image.jpg' -and $_.Name -ne 'inputfile_imagemagick.txt'}
$items | Group-Object -Property { $_.CreationTime.ToString('HH:00') } | Sort-Object -Property { [DateTime]$_.Name} | Select-Object -Property @{Label='Hour'; Expression={$_.Name}}, Count

# Output: 
<#
Hour  Count
----  -----
00:00    12
01:00    12
02:00    12
03:00    12
04:00    12
05:00    12
06:00    12
07:00    12
08:00     4
#>
