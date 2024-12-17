# Initialize an array to collect the results
$output = @()

# Collect exclusions and format each category
$output += (Get-MpPreference).ExclusionPath | ForEach-Object { "Path: $_" }
$output += (Get-MpPreference).ExclusionExtension | ForEach-Object { "Extension: $_" }
$output += (Get-MpPreference).ExclusionIpAddress | ForEach-Object { "IP Address: $_" }
$output += (Get-MpPreference).ExclusionProcess | ForEach-Object { "Process: $_" }

# Join all results into a single line with semicolons separating entries
$outputString = $output -join "; "

# Output the combined single-line string
Write-Output $outputString
