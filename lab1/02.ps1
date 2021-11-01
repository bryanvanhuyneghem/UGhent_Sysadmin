# Student: Bryan Van Huyneghem
# status: complete
# JSON is fetched and response is checked; SHA and message are selected from JSON. Messages with #XXXXX in them are filtered and selected;
# Pull request number is selected and added as a column

# Fetch JSON
$response = Invoke-WebRequest -Uri 'https://api.github.com/repos/microsoft/Typescript/commits?since=2020-12-01T00:00:00Z&until=2020-12-07T00:00:00Z' -Headers @{"accept"="application/vnd.github.v3+json"}

# Check response
if ($response.StatusCode -ge 200 -and $response.StatusCode -lt 300) {
    # Ok
    Write-Output "JSON was fetched successfully."
    $data = ConvertFrom-Json $response.Content 
    # Select SHA and Message from JSON
    $table = $data | Select-Object sha, commit | Select-Object * -ExpandProperty commit | Select-Object sha, message
    # Select only those entries that have #XXXXX in them
    $result = $table -match '^.*#\d+.*$'
    # Add a column with #XXXXX as entries
    $result | Select-Object sha, message, @{Name='PR_number'; Expression={$_.message -match "#(\d+)" | ForEach-Object {$matches[1]} } }
}
else {
    Write-Output "JSON could not be fetched from link. Something went wrong."
}
