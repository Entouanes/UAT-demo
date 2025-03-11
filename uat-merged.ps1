<#
.SYNOPSIS
    ABB Network Connectivity User Acceptance Test Script
.DESCRIPTION
    IMPORTANT NOTE: This script comes with no warranty. It is used to demonstrate the functionality of the UAT process.
    
    This script automates network connectivity testing by combining functionality from multiple UAT scripts.
    It automatically checks website connectivity, network configuration, and prompts users for application tests.
    Results are saved to both a detailed text log and a structured CSV file.
.NOTES
    Author: Combined from scripts by Thomas Klein, Andreas Brandtner, Roman Hambsch
    Version: 2025.03
    Date: 2025-03-11
#>

#Requires -Version 5.0

#-----------------------------------------------------------
# Configuration Variables
#-----------------------------------------------------------

# Format strings for output
$successPrefix = "[SUCCESS] "
$errorPrefix = "[ERROR] "
$infoPrefix = "[INFO] "
$promptPrefix = "[INPUT NEEDED] "
$separatorLine = "=" * 80
$subSeparatorLine = "-" * 80

# Websites to test
$websites = @(
    "https://new.abb.com", 
    "https://www.bt.com", 
    "https://insideplus.abb.com", 
    "https://abb.sharepoint.com/sites/ABBBusinessServices/default.aspx", 
    "http://ip.zscaler.com/"
)

# Colors
$successColor = "Green"
$errorColor = "Red"
$infoColor = "Cyan" 
$promptColor = "Yellow"
$headerColor = "Magenta"

# Store test results for CSV export
$testResults = @()

#-----------------------------------------------------------
# Helper Functions
#-----------------------------------------------------------

function Write-SuccessMessage {
    param ([string]$Message)
    Write-Host $successPrefix -ForegroundColor $successColor -NoNewline
    Write-Host $Message
}

function Write-ErrorMessage {
    param ([string]$Message)
    Write-Host $errorPrefix -ForegroundColor $errorColor -NoNewline
    Write-Host $Message
}

function Write-InfoMessage {
    param ([string]$Message)
    Write-Host $infoPrefix -ForegroundColor $infoColor -NoNewline
    Write-Host $Message
}

function Write-PromptMessage {
    param ([string]$Message)
    Write-Host $promptPrefix -ForegroundColor $promptColor -NoNewline
    Write-Host $Message
}

function Write-Section {
    param ([string]$Title)
    Write-Host "`n$separatorLine" -ForegroundColor $headerColor
    Write-Host "  $Title" -ForegroundColor $headerColor
    Write-Host "$separatorLine`n" -ForegroundColor $headerColor
}

function Write-SubSection {
    param ([string]$Title)
    Write-Host "`n$subSeparatorLine" -ForegroundColor $infoColor
    Write-Host "  $Title" -ForegroundColor $infoColor
    Write-Host "$subSeparatorLine`n" -ForegroundColor $infoColor
}

function Test-Website {
    param ([string]$URL)
    try {
        $response = Invoke-WebRequest -Uri $URL -UseDefaultCredentials -ErrorAction Stop -TimeoutSec 10
        return $true, $response.StatusCode
    }
    catch {
        $statusCode = if ($_.Exception.Response) { $_.Exception.Response.StatusCode.value__ } else { 0 }
        return $false, $statusCode
    }
}

function Get-PublicIPInfo {
    try {
        $response = Invoke-RestMethod -Uri http://ipinfo.io -TimeoutSec 10
        return $true, $response
    }
    catch {
        return $false, $_
    }
}

function Get-PromptResponse {
    param (
        [string]$Prompt,
        [string[]]$ValidResponses = @("yes", "no", "y", "n")
    )
    
    $response = ""
    while ($ValidResponses -notcontains $response.ToLower()) {
        Write-PromptMessage $Prompt
        $response = Read-Host
    }
    return $response.ToLower()
}

function Wait-ForConfirmation {
    param ([string]$Message = "Press Enter to continue...")
    
    Write-PromptMessage $Message
    Read-Host | Out-Null
}

function Initialize-TestFiles {
    param (
        [string]$ChangeNumber,
        [string]$ConnectionType
    )
    
    $date = Get-Date -Format "yyyyMMdd_HHmmss"
    $outputFile = "$($env:UserProfile)\Documents\UAT_$ChangeNumber`_$ConnectionType`_$date.txt"
    $csvFile = "$($env:UserProfile)\Documents\UAT_$ChangeNumber`_Report_$date.csv"
    
    # Create header in text file
    @"
========================================================================
                ABB USER ACCEPTANCE TEST REPORT
========================================================================
Change Number: $ChangeNumber
Connection Type: $ConnectionType
User: $env:USERNAME
Computer: $env:COMPUTERNAME
Date/Time: $(Get-Date)
========================================================================

"@ | Out-File -FilePath $outputFile

    # Create CSV file with headers if it doesn't exist
    if (-not (Test-Path $csvFile)) {
        @"
"Timestamp","Change Number","Connection Type","Test Category","Test Name","Status","Details"
"@ | Out-File -FilePath $csvFile -Encoding UTF8
    }

    return @{
        TextFile = $outputFile
        CsvFile = $csvFile
    }
}

function Add-TestResultToCSV {
    param (
        [string]$CsvFile,
        [string]$ChangeNumber,
        [string]$ConnectionType,
        [string]$TestCategory,
        [string]$TestName,
        [string]$Status,
        [string]$Details
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    # Escape quotes in details for CSV format
    $escapedDetails = $Details -replace '"', '""'
    
    # Add to global test results array for final report
    $script:testResults += [PSCustomObject]@{
        Timestamp = $timestamp
        ChangeNumber = $ChangeNumber
        ConnectionType = $ConnectionType
        TestCategory = $TestCategory
        TestName = $TestName
        Status = $Status
        Details = $Details
    }
    
    # Write directly to CSV
    "`"$timestamp`",`"$ChangeNumber`",`"$ConnectionType`",`"$TestCategory`",`"$TestName`",`"$Status`",`"$escapedDetails`"" | 
        Out-File -FilePath $CsvFile -Append -Encoding UTF8
}

#-----------------------------------------------------------
# Main Script
#-----------------------------------------------------------

Clear-Host

Write-Section "ABB NETWORK CONNECTIVITY USER ACCEPTANCE TEST"

# Get initial information
Write-InfoMessage "This script will perform network connectivity testing for ABB systems."
Write-InfoMessage "The test will check website accessibility, network configuration, and prompt for application tests."
Write-InfoMessage "Results will be saved to both text and CSV files in your Documents folder."
Write-Host ""

$changeNumber = Read-Host "Please enter the Change Number or ID"
if ([string]::IsNullOrWhiteSpace($changeNumber)) {
    $changeNumber = "UAT_$(Get-Date -Format 'yyyyMMdd')"
    Write-InfoMessage "Using default change number: $changeNumber"
}

# Initialize CSV report
$date = Get-Date -Format "yyyyMMdd_HHmmss"
$csvReport = "$($env:UserProfile)\Documents\UAT_$changeNumber`_Report_$date.csv"
"Timestamp,Change Number,Connection Type,Test Category,Test Name,Status,Details" | 
    Out-File -FilePath $csvReport -Encoding UTF8

# Connection type loop
$continueConnectionTests = $true
$connectionTypes = @()

while ($continueConnectionTests) {
    Write-SubSection "CONNECTION TYPE SELECTION"
    Write-InfoMessage "Please select the connection type to test:"
    Write-InfoMessage "1. LAN"
    Write-InfoMessage "2. WLAN (Wireless)"
    Write-InfoMessage "3. VPN"
    
    $connectionChoice = Read-Host "Enter your choice (1-3)"
    switch ($connectionChoice) {
        "1" { $connectionType = "LAN" }
        "2" { $connectionType = "WLAN" }
        "3" { $connectionType = "VPN" }
        default {
            Write-ErrorMessage "Invalid choice. Defaulting to LAN."
            $connectionType = "LAN"
        }
    }
    
    $connectionTypes += $connectionType
    
    # Initialize output files for this connection type
    $files = Initialize-TestFiles -ChangeNumber $changeNumber -ConnectionType $connectionType
    $outputFile = $files.TextFile
    $csvFile = $files.CsvFile
    
    Write-InfoMessage "Output will be saved to:"
    Write-InfoMessage "  - Text log: $outputFile"
    Write-InfoMessage "  - CSV report: $csvFile"
    Write-InfoMessage "Please ensure your computer is connected via $connectionType only."
    Wait-ForConfirmation
    
    #-----------------------------------------------------------
    # Website Connectivity Tests
    #-----------------------------------------------------------
    
    Write-Section "WEBSITE CONNECTIVITY TESTS ($connectionType)"
    "WEBSITE CONNECTIVITY TESTS ($connectionType)" | Out-File -FilePath $outputFile -Append
    
    foreach ($website in $websites) {
        Write-InfoMessage "Testing connectivity to $website..."
        $result, $statusCode = Test-Website -URL $website
        
        if ($result) {
            Write-SuccessMessage "Successfully connected to $website (Status code: $statusCode)"
            "SUCCESS: $website is accessible (Status code: $statusCode)" | Out-File -FilePath $outputFile -Append
            
            # Add to CSV report
            Add-TestResultToCSV -CsvFile $csvReport `
                -ChangeNumber $changeNumber `
                -ConnectionType $connectionType `
                -TestCategory "Website" `
                -TestName $website `
                -Status "Success" `
                -Details "Status code: $statusCode"
        }
        else {
            Write-ErrorMessage "Failed to connect to $website (Status code: $statusCode)"
            "ERROR: $website is not accessible (Status code: $statusCode)" | Out-File -FilePath $outputFile -Append
            
            # Add to CSV report
            Add-TestResultToCSV -CsvFile $csvReport `
                -ChangeNumber $changeNumber `
                -ConnectionType $connectionType `
                -TestCategory "Website" `
                -TestName $website `
                -Status "Error" `
                -Details "Status code: $statusCode"
        }
    }
    
    #-----------------------------------------------------------
    # Public IP Information
    #-----------------------------------------------------------
    
    Write-SubSection "Public IP Information"
    "PUBLIC IP INFORMATION" | Out-File -FilePath $outputFile -Append
    
    $result, $ipInfo = Get-PublicIPInfo
    if ($result) {
        Write-InfoMessage "IP Information Retrieved:"
        Write-Host "  IP: $($ipInfo.ip)"
        Write-Host "  Hostname: $($ipInfo.hostname)"
        Write-Host "  City: $($ipInfo.city)"
        Write-Host "  Region: $($ipInfo.region)"
        Write-Host "  Country: $($ipInfo.country)"
        Write-Host "  Organization: $($ipInfo.org)"
        
        # Save to text file
        "IP: $($ipInfo.ip)" | Out-File -FilePath $outputFile -Append
        "Hostname: $($ipInfo.hostname)" | Out-File -FilePath $outputFile -Append
        "City: $($ipInfo.city)" | Out-File -FilePath $outputFile -Append
        "Region: $($ipInfo.region)" | Out-File -FilePath $outputFile -Append
        "Country: $($ipInfo.country)" | Out-File -FilePath $outputFile -Append
        "Organization: $($ipInfo.org)" | Out-File -FilePath $outputFile -Append
        
        # Add to CSV report
        Add-TestResultToCSV -CsvFile $csvReport `
            -ChangeNumber $changeNumber `
            -ConnectionType $connectionType `
            -TestCategory "Network" `
            -TestName "Public IP" `
            -Status "Success" `
            -Details "IP: $($ipInfo.ip), Location: $($ipInfo.city), $($ipInfo.country), ISP: $($ipInfo.org)"
    }
    else {
        Write-ErrorMessage "Could not retrieve public IP information"
        "ERROR: Could not retrieve public IP information" | Out-File -FilePath $outputFile -Append
        
        # Add to CSV report
        Add-TestResultToCSV -CsvFile $csvReport `
            -ChangeNumber $changeNumber `
            -ConnectionType $connectionType `
            -TestCategory "Network" `
            -TestName "Public IP" `
            -Status "Error" `
            -Details "Failed to retrieve IP information"
    }
    
    #-----------------------------------------------------------
    # Network Configuration
    #-----------------------------------------------------------
    
    Write-SubSection "Network Configuration"
    "NETWORK CONFIGURATION" | Out-File -FilePath $outputFile -Append
    
    # Get IP Configuration
    Write-InfoMessage "Running ipconfig /all..."
    $ipConfigOutput = ipconfig /all | Out-String
    $ipConfigOutput | Out-File -FilePath $outputFile -Append
    
    # Add to CSV report
    Add-TestResultToCSV -CsvFile $csvReport `
        -ChangeNumber $changeNumber `
        -ConnectionType $connectionType `
        -TestCategory "Network" `
        -TestName "IP Configuration" `
        -Status "Info" `
        -Details "IP configuration captured in text log"
    
    # Run ping test
    Write-InfoMessage "Running ping test to 10.16.124.1..."
    $pingTarget = "10.16.124.1"
    $pingOutput = ping $pingTarget | Out-String
    $pingOutput | Out-File -FilePath $outputFile -Append
    
    # Check if ping was successful
    if ($pingOutput -match "Reply from") {
        Add-TestResultToCSV -CsvFile $csvReport `
            -ChangeNumber $changeNumber `
            -ConnectionType $connectionType `
            -TestCategory "Network" `
            -TestName "Ping Test" `
            -Status "Success" `
            -Details "Target: $pingTarget - Reply received"
    } else {
        Add-TestResultToCSV -CsvFile $csvReport `
            -ChangeNumber $changeNumber `
            -ConnectionType $connectionType `
            -TestCategory "Network" `
            -TestName "Ping Test" `
            -Status "Error" `
            -Details "Target: $pingTarget - No reply received"
    }
    
    # Run tracert
    Write-InfoMessage "Running tracert to 10.16.124.1..."
    $tracertTarget = "10.16.124.1"
    $tracertOutput = tracert -h 15 -w 1000 $tracertTarget | Out-String
    $tracertOutput | Out-File -FilePath $outputFile -Append
    
    Add-TestResultToCSV -CsvFile $csvReport `
        -ChangeNumber $changeNumber `
        -ConnectionType $connectionType `
        -TestCategory "Network" `
        -TestName "Traceroute" `
        -Status "Info" `
        -Details "Target: $tracertTarget - Details in text log"
    
    # Get WLAN information if applicable
    if ($connectionType -eq "WLAN") {
        Write-InfoMessage "Getting WLAN information..."
        $wlanOutput = netsh wlan show all | Out-String
        $wlanOutput | Out-File -FilePath $outputFile -Append
        
        if ($wlanOutput -match "SSID") {
            # Extract SSID name
            $ssidPattern = "SSID name\s+:\s+(.+)"
            $ssidMatches = [regex]::Match($wlanOutput, $ssidPattern)
            $ssidName = if ($ssidMatches.Success) { $ssidMatches.Groups[1].Value } else { "Unknown" }
            
            Add-TestResultToCSV -CsvFile $csvReport `
                -ChangeNumber $changeNumber `
                -ConnectionType $connectionType `
                -TestCategory "Network" `
                -TestName "WLAN Info" `
                -Status "Success" `
                -Details "Connected to SSID: $ssidName"
        } else {
            Add-TestResultToCSV -CsvFile $csvReport `
                -ChangeNumber $changeNumber `
                -ConnectionType $connectionType `
                -TestCategory "Network" `
                -TestName "WLAN Info" `
                -Status "Info" `
                -Details "WLAN information captured in text log"
        }
    }
    
    #-----------------------------------------------------------
    # Application Tests (User Input Required)
    #-----------------------------------------------------------
    
    Write-Section "APPLICATION TESTS ($connectionType)"
    "APPLICATION TESTS ($connectionType)" | Out-File -FilePath $outputFile -Append
    
    # Teams 1:1 Call Test
    Write-SubSection "Microsoft Teams 1:1 Call Test"
    Write-PromptMessage "Please open Microsoft Teams and initiate a 1:1 call, test audio and screen sharing"
    Wait-ForConfirmation "Press Enter once you've completed this test"
    $result = Get-PromptResponse "Was the Teams 1:1 call successful? (yes/no)"
    $notes = ""
    
    if ($result -in @("yes", "y")) {
        Write-SuccessMessage "Teams 1:1 call test successful"
        "SUCCESS: Teams 1:1 call test" | Out-File -FilePath $outputFile -Append
        $status = "Success"
    } else {
        Write-ErrorMessage "Teams 1:1 call test failed"
        "ERROR: Teams 1:1 call test" | Out-File -FilePath $outputFile -Append
        $notes = Read-Host "Please describe the issue"
        "Notes: $notes" | Out-File -FilePath $outputFile -Append
        $status = "Error"
    }
    
    Add-TestResultToCSV -CsvFile $csvReport `
        -ChangeNumber $changeNumber `
        -ConnectionType $connectionType `
        -TestCategory "Application" `
        -TestName "Teams 1:1 Call" `
        -Status $status `
        -Details $notes
    
    # Teams Group Call Test
    Write-SubSection "Microsoft Teams Group Call Test"
    Write-PromptMessage "Please open Microsoft Teams and initiate a call with multiple users, test audio and screen sharing"
    Wait-ForConfirmation "Press Enter once you've completed this test"
    $result = Get-PromptResponse "Was the Teams group call successful? (yes/no)"
    $notes = ""
    
    if ($result -in @("yes", "y")) {
        Write-SuccessMessage "Teams group call test successful"
        "SUCCESS: Teams group call test" | Out-File -FilePath $outputFile -Append
        $status = "Success"
    } else {
        Write-ErrorMessage "Teams group call test failed"
        "ERROR: Teams group call test" | Out-File -FilePath $outputFile -Append
        $notes = Read-Host "Please describe the issue"
        "Notes: $notes" | Out-File -FilePath $outputFile -Append
        $status = "Error"
    }
    
    Add-TestResultToCSV -CsvFile $csvReport `
        -ChangeNumber $changeNumber `
        -ConnectionType $connectionType `
        -TestCategory "Application" `
        -TestName "Teams Group Call" `
        -Status $status `
        -Details $notes
    
    # Outlook Email Test
    Write-SubSection "Outlook Email Test"
    Write-PromptMessage "Please open Outlook and send/receive a test email"
    Wait-ForConfirmation "Press Enter once you've completed this test"
    $result = Get-PromptResponse "Was the Outlook email test successful? (yes/no)"
    $notes = ""
    
    if ($result -in @("yes", "y")) {
        Write-SuccessMessage "Outlook email test successful"
        "SUCCESS: Outlook email test" | Out-File -FilePath $outputFile -Append
        $status = "Success"
    } else {
        Write-ErrorMessage "Outlook email test failed"
        "ERROR: Outlook email test" | Out-File -FilePath $outputFile -Append
        $notes = Read-Host "Please describe the issue"
        "Notes: $notes" | Out-File -FilePath $outputFile -Append
        $status = "Error"
    }
    
    Add-TestResultToCSV -CsvFile $csvReport `
        -ChangeNumber $changeNumber `
        -ConnectionType $connectionType `
        -TestCategory "Application" `
        -TestName "Outlook Desktop" `
        -Status $status `
        -Details $notes
    
    # Outlook Web Access Test
    Write-SubSection "Outlook Web Access (OWA) Test"
    Write-PromptMessage "Please open https://outlook.office365.com in your browser, log in, and send/receive a test email"
    Wait-ForConfirmation "Press Enter once you've completed this test"
    $result = Get-PromptResponse "Was the OWA email test successful? (yes/no)"
    $notes = ""
    
    if ($result -in @("yes", "y")) {
        Write-SuccessMessage "OWA email test successful"
        "SUCCESS: OWA email test" | Out-File -FilePath $outputFile -Append
        $status = "Success"
    } else {
        Write-ErrorMessage "OWA email test failed"
        "ERROR: OWA email test" | Out-File -FilePath $outputFile -Append
        $notes = Read-Host "Please describe the issue"
        "Notes: $notes" | Out-File -FilePath $outputFile -Append
        $status = "Error"
    }
    
    Add-TestResultToCSV -CsvFile $csvReport `
        -ChangeNumber $changeNumber `
        -ConnectionType $connectionType `
        -TestCategory "Application" `
        -TestName "Outlook Web Access" `
        -Status $status `
        -Details $notes
    
    # Network Printer Test
    Write-SubSection "Network Printer Test"
    Write-PromptMessage "If applicable, please test printing to a network printer"
    $performTest = Get-PromptResponse "Would you like to perform the network printer test? (yes/no)"
    
    if ($performTest -in @("yes", "y")) {
        Wait-ForConfirmation "Press Enter once you've completed this test"
        $result = Get-PromptResponse "Was the network printer test successful? (yes/no)"
        $notes = ""
        
        if ($result -in @("yes", "y")) {
            Write-SuccessMessage "Network printer test successful"
            "SUCCESS: Network printer test" | Out-File -FilePath $outputFile -Append
            $status = "Success"
        } else {
            Write-ErrorMessage "Network printer test failed"
            "ERROR: Network printer test" | Out-File -FilePath $outputFile -Append
            $notes = Read-Host "Please describe the issue"
            "Notes: $notes" | Out-File -FilePath $outputFile -Append
            $status = "Error"
        }
        
        Add-TestResultToCSV -CsvFile $csvReport `
            -ChangeNumber $changeNumber `
            -ConnectionType $connectionType `
            -TestCategory "Application" `
            -TestName "Network Printer" `
            -Status $status `
            -Details $notes
    } else {
        Write-InfoMessage "Network printer test skipped"
        "SKIPPED: Network printer test" | Out-File -FilePath $outputFile -Append
        
        Add-TestResultToCSV -CsvFile $csvReport `
            -ChangeNumber $changeNumber `
            -ConnectionType $connectionType `
            -TestCategory "Application" `
            -TestName "Network Printer" `
            -Status "Skipped" `
            -Details "Test not performed"
    }
    
    # Security Test (EICAR test file)
    Write-SubSection "Security Test (EICAR test file)"
    Write-PromptMessage "This test will check if your antivirus blocks the EICAR test file"
    $performTest = Get-PromptResponse "Would you like to perform the EICAR test file download? (yes/no)"
    
    if ($performTest -in @("yes", "y")) {
        Write-InfoMessage "Attempting to access https://secure.eicar.org/eicar.com.txt..."
        try {
            $eicarResult = Invoke-WebRequest -Uri "https://secure.eicar.org/eicar.com.txt" -ErrorAction SilentlyContinue -TimeoutSec 10
            Write-ErrorMessage "Security test failed - EICAR test file was not blocked!"
            "ERROR: Security test - EICAR test file was not blocked" | Out-File -FilePath $outputFile -Append
            
            Add-TestResultToCSV -CsvFile $csvReport `
                -ChangeNumber $changeNumber `
                -ConnectionType $connectionType `
                -TestCategory "Security" `
                -TestName "EICAR Test File" `
                -Status "Error" `
                -Details "Test file was not blocked - security concern"
        } catch {
            Write-SuccessMessage "Security test successful - EICAR test file was blocked"
            "SUCCESS: Security test - EICAR test file was blocked" | Out-File -FilePath $outputFile -Append
            
            Add-TestResultToCSV -CsvFile $csvReport `
                -ChangeNumber $changeNumber `
                -ConnectionType $connectionType `
                -TestCategory "Security" `
                -TestName "EICAR Test File" `
                -Status "Success" `
                -Details "Test file was blocked by security software as expected"
        }
    } else {
        Write-InfoMessage "EICAR test file download skipped"
        "SKIPPED: EICAR test file download" | Out-File -FilePath $outputFile -Append
        
        Add-TestResultToCSV -CsvFile $csvReport `
            -ChangeNumber $changeNumber `
            -ConnectionType $connectionType `
            -TestCategory "Security" `
            -TestName "EICAR Test File" `
            -Status "Skipped" `
            -Details "Test not performed"
    }
    
    # Ask if user wants to test another connection type
    $anotherTest = Get-PromptResponse "Would you like to test another connection type? (yes/no)"
    if ($anotherTest -notin @("yes", "y")) {
        $continueConnectionTests = $false
    }
}

#-----------------------------------------------------------
# Test Summary
#-----------------------------------------------------------

Write-Section "TEST SUMMARY"

# Calculate statistics for the CSV report
$successCount = ($testResults | Where-Object { $_.Status -eq "Success" }).Count
$errorCount = ($testResults | Where-Object { $_.Status -eq "Error" }).Count
$skippedCount = ($testResults | Where-Object { $_.Status -eq "Skipped" }).Count
$totalCount = $testResults.Count

Write-InfoMessage "Test Summary Statistics:"
Write-Host "  Total Tests   : $totalCount"
Write-Host "  Successful    : $successCount"
Write-Host "  Failed        : $errorCount"
Write-Host "  Skipped       : $skippedCount"
Write-Host ""

Write-InfoMessage "Tests completed for connection types: $($connectionTypes -join ", ")"
Write-InfoMessage "Report files have been created in your Documents folder:"

# Show both output file types
Write-InfoMessage "  - CSV Report: $csvReport"
foreach ($connType in $connectionTypes) {
    $date = Get-Date -Format "yyyyMMdd_HHmmss"
    $file = "$($env:UserProfile)\Documents\UAT_$changeNumber`_$connType`_$date.txt"
    Write-InfoMessage "  - Text Log ($connType): $file"
}

# Add summary statistics to CSV report
Add-TestResultToCSV -CsvFile $csvReport `
    -ChangeNumber $changeNumber `
    -ConnectionType "ALL" `
    -TestCategory "Summary" `
    -TestName "Test Statistics" `
    -Status "Info" `
    -Details "Total: $totalCount, Success: $successCount, Error: $errorCount, Skipped: $skippedCount"

# Additional comments
Write-PromptMessage "Would you like to add any additional comments to the report? (yes/no)"
$addComments = Read-Host
if ($addComments -in @("yes", "y")) {
    Write-PromptMessage "Please enter your comments (press Enter when done):"
    $comments = Read-Host
    
    # Add comments to CSV report
    Add-TestResultToCSV -CsvFile $csvReport `
        -ChangeNumber $changeNumber `
        -ConnectionType "ALL" `
        -TestCategory "Comments" `
        -TestName "User Comments" `
        -Status "Info" `
        -Details $comments
    
    # Add comments to all text logs
    foreach ($connType in $connectionTypes) {
        $date = Get-Date -Format "yyyyMMdd_HHmmss"
        $file = "$($env:UserProfile)\Documents\UAT_$changeNumber`_$connType`_$date.txt"
        "`nADDITIONAL COMMENTS:" | Out-File -FilePath $file -Append
        $comments | Out-File -FilePath $file -Append
    }
}

Write-Section "TEST COMPLETED"
Write-InfoMessage "Thank you for completing the ABB Network Connectivity User Acceptance Test."
Write-InfoMessage "The CSV report can be opened with Excel for further analysis."