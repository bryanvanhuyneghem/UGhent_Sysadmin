# Student: Bryan Van Huyneghem
# status: completed
# check if the csv has already been downloaded, otherwise download it;
# read csv file and parse it; create the request object and convert it to JSON; make the request; parse the response and verify 

$schema = @'
{
    "$schema": "http://json-schema.org/draft-04/schema#",
    "type": "array",
    "items": {
        "type": "object",
        "properties": {
            "status": {
                "type": "string"
            },
            "locations": {
                "type": "array",
                "items": {
                    "type": "object", 
                    "properties": {
                        "straat": {
                            "type": "string"
                        },
                        "huisnr": {
                            "type": "string"
                        },
                        "status": {
                            "type": "string"
                        }
                    },
                    "required": [
                        "straat",
                        "huisnr",
                        "status"
                    ]
                }
            }
        },
        "required" : [
            "status",
            "locations"
        ]
    }
}
'@

$csvResponse = $null

# Test if the file .\dataset.csv exists; do not download it again if it exists.
if (Test-Path '.\dataset.csv') {
    Write-Output " -> File exists."
}
else {
    $csvResponse = Invoke-WebRequest -Uri 'https://data.stad.gent/explore/dataset/fietsenstallingen-gent/download/?format=csv&timezone=Europe/Brussels&lang=en&use_labels_for_header=true&csv_separator=%3B'
    if ( $csvResponse.StatusCode -ge 200 -and $csvResponse.StatusCode -lt 300) {
        # write the file
        Set-Content -Path ".\dataset.csv" -Encoding Byte -Value $csvResponse.Content
        Write-Output "Dataset ready."
    }
}

# Read the csv file into a variable
$bicycleStoragePositions = Import-Csv '.\dataset.csv' -Delimiter ';' | Where-Object { $_.status -ne 'In gebruik' -and $_.beschikbaarheid -eq 'Permanent'} | Select-Object straat, huisnr, status

# Group data based on status and the convert it to JSON. Adapt object structure to use status and locations instead of Name and Group
$data = $bicycleStoragePositions | Get-Unique -AsString | Group-Object "status" | Foreach-Object {@{status = $_.Name; locations = $_.Group } }

# Create the request object; note conversion of schema from JSON format
$req = [PSCustomObject]@{
    schema = ConvertFrom-Json $schema;
    json = $data
}

# Convert request to JSON format
$reqJson = $req | ConvertTo-Json -Depth 7 # technically, 7 suffices but could just put a higher number too

# We can view the result in the file final_result
$reqJson > '.\final_result'

# Capture the response from the request to the schema verification website
try {
    $response = Invoke-WebRequest -Uri 'https://assertible.com/json' -Method POST -Body $reqJson -ContentType 'application/json;charset=utf-8'
    if (($response.Content | ConvertFrom-Json).valid) {
        Write-Output "Success."
    }
}
catch {
    Write-Host $_
}
