<#
.SYNOPSIS
    ABB Network Connectivity User Acceptance Test Script
.DESCRIPTION
    IMPORTANT NOTE: This script comes with no warranty. It is used to demonstrate the functionality of the UAT process.
    
    This script automates network connectivity testing by combining functionality from multiple UAT scripts.
    It automatically checks website connectivity, network configuration, and prompts users for application tests.
    Results are saved to a detailed text log file.
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

#-----------------------------------------------------------
# Determine Output Base Path
#-----------------------------------------------------------
function Get-OutputBasePath {
    $downloadPath = Join-Path -Path $env:UserProfile -ChildPath "Downloads"
    if (Test-Path $downloadPath -PathType Container) {
        return $downloadPath
    } else {
        # Try to find OneDrive folder - first check environment variable
        if ($env:OneDrive -and (Test-Path $env:OneDrive -PathType Container)) {
            return $env:OneDrive
        } 
        # Then check standard location
        $oneDrivePath = Join-Path -Path $env:UserProfile -ChildPath "OneDrive"
        if (Test-Path $oneDrivePath -PathType Container) {
            return $oneDrivePath
        }
        # Fall back to UserProfile if OneDrive isn't found
        Write-Warning "Downloads and OneDrive folders not found. Saving results to the UserProfile folder."
        return $env:UserProfile
    }
}

$script:OutputBasePath = Get-OutputBasePath
Write-InfoMessage "Script results will be saved to: $script:OutputBasePath"

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
    Write-Host "[$Message]"
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
        # Attempt alternative source: api.ipify.org
        try {
            $response = Invoke-RestMethod -Uri "https://api.ipify.org?format=json" -TimeoutSec 10
            $result = [PSCustomObject]@{
                ip       = $response.ip
                hostname = "N/A"
                city     = "N/A"
                region   = "N/A"
                country  = "N/A"
                org      = "N/A"
            }
            return $true, $result
        }
        catch {
            return $false, $_
        }
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
        [string]$ChangeNumber
    )
    
    # Create a single text file for all connection types
    $date = Get-Date -Format "yyyyMMdd_HHmmss"
    # Use the determined base path for the text file
    $outputFile = Join-Path -Path $script:OutputBasePath -ChildPath "UAT_$ChangeNumber`_$date.txt"
    
    # Create header in text file
    @"
================================================================================
                    ABB USER ACCEPTANCE TEST REPORT
================================================================================
Change Number: $ChangeNumber
User: $env:USERNAME
Computer: $env:COMPUTERNAME
Date/Time: $(Get-Date)
================================================================================

"@ | Out-File -FilePath $outputFile

    # Return the text file path
    return $outputFile
}

#-----------------------------------------------------------
# Main Script
#-----------------------------------------------------------

Clear-Host

Write-Section "ABB NETWORK CONNECTIVITY USER ACCEPTANCE TEST"

# Get initial information
Write-InfoMessage "This script will perform network connectivity testing for ABB systems."
Write-InfoMessage "The test will check website accessibility, network configuration, and prompt for application tests."
Write-InfoMessage "Results will be saved to a text log file in your Documents folder."
Write-Host ""

$changeNumber = Read-Host "Please enter the Change Number or ID"
if ([string]::IsNullOrWhiteSpace($changeNumber)) {
    $changeNumber = "UAT_$(Get-Date -Format 'yyyyMMdd')"
    Write-InfoMessage "Using default change number: $changeNumber"
}

# Initialize a single output file for all test results
$outputFile = Initialize-TestFiles -ChangeNumber $changeNumber

Write-InfoMessage "Output will be saved to:"
Write-InfoMessage "  - Text log: $outputFile"

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
    
    Write-InfoMessage "Please ensure your computer is connected via $connectionType only."
    Wait-ForConfirmation
    
    # Add a clear connection type separator in the text file for better readability
    @"
================================================================================
                     CONNECTION TYPE: $connectionType
================================================================================
"@ | Out-File -FilePath $outputFile -Append
    
    #-----------------------------------------------------------
    # Website Connectivity Tests
    #-----------------------------------------------------------
    
    Write-Section "WEBSITE CONNECTIVITY TESTS ($connectionType)"
    @"

--------------------------------------------------------------------------------
                  WEBSITE CONNECTIVITY TESTS ($connectionType)
--------------------------------------------------------------------------------
"@ | Out-File -FilePath $outputFile -Append
    
    foreach ($website in $websites) {
        Write-InfoMessage "Testing connectivity to $website..."
        $result, $statusCode = Test-Website -URL $website
        
        if ($result) {
            Write-SuccessMessage "Successfully connected to $website (Status code: $statusCode)"
            "SUCCESS: $website is accessible (Status code: $statusCode)" | Out-File -FilePath $outputFile -Append
        }
        else {
            Write-ErrorMessage "Failed to connect to $website (Status code: $statusCode)"
            "ERROR: $website is not accessible (Status code: $statusCode)" | Out-File -FilePath $outputFile -Append
        }
    }
    
    #-----------------------------------------------------------
    # Public IP Information
    #-----------------------------------------------------------
    
    Write-SubSection "Public IP Information"
    @"

--------------------------------------------------------------------------------
                      PUBLIC IP INFORMATION ($connectionType)
--------------------------------------------------------------------------------
"@ | Out-File -FilePath $outputFile -Append
    
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
    }
    else {
        Write-ErrorMessage "Could not retrieve public IP information"
        "ERROR: Could not retrieve public IP information" | Out-File -FilePath $outputFile -Append
    }
    
    #-----------------------------------------------------------
    # Network Configuration
    #-----------------------------------------------------------
    
    Write-SubSection "Network Configuration"
    @"

--------------------------------------------------------------------------------
                    NETWORK CONFIGURATION ($connectionType)
--------------------------------------------------------------------------------
"@ | Out-File -FilePath $outputFile -Append
    
    # Get IP Configuration
    Write-InfoMessage "Running ipconfig /all..."
    $ipConfigOutput = ipconfig /all | Out-String
    $ipConfigOutput | Out-File -FilePath $outputFile -Append
    
    # Run ping test
    Write-InfoMessage "Running ping test to 10.16.124.1..."
    $pingTarget = "10.16.124.1"
    $pingOutput = ping $pingTarget | Out-String
    $pingOutput | Out-File -FilePath $outputFile -Append
    
    # Run tracert
    Write-InfoMessage "Running tracert to 10.16.124.1..."
    $tracertTarget = "10.16.124.1"
    $tracertOutput = tracert -h 15 -w 1000 $tracertTarget | Out-String
    $tracertOutput | Out-File -FilePath $outputFile -Append
    
    # Get WLAN information if applicable
    if ($connectionType -eq "WLAN") {
        Write-InfoMessage "Getting WLAN information..."
        $wlanOutput = netsh wlan show all | Out-String
        $wlanOutput | Out-File -FilePath $outputFile -Append
    }
    
    #-----------------------------------------------------------
    # Application Tests (User Input Required)
    #-----------------------------------------------------------
    
    Write-Section "APPLICATION TESTS ($connectionType)"
    @"

--------------------------------------------------------------------------------
                     APPLICATION TESTS ($connectionType)
--------------------------------------------------------------------------------
"@ | Out-File -FilePath $outputFile -Append
    
    # Teams 1:1 Call Test
    Write-SubSection "Microsoft Teams 1:1 Call Test"
    Write-InfoMessage "Please open Microsoft Teams and initiate a 1:1 call, test audio and screen sharing. "
    $result = Get-PromptResponse "Was the Teams 1:1 call successful? (yes/no)"
    $notes = ""
    
    if ($result -in @("yes", "y")) {
        Write-SuccessMessage "Teams 1:1 call test successful"
        "SUCCESS: Teams 1:1 call test" | Out-File -FilePath $outputFile -Append
    } else {
        Write-ErrorMessage "Teams 1:1 call test failed"
        "ERROR: Teams 1:1 call test" | Out-File -FilePath $outputFile -Append
        $notes = Read-Host "Please describe the issue"
        "Notes: $notes" | Out-File -FilePath $outputFile -Append
    }
    
    # Teams Group Call Test
    Write-SubSection "Microsoft Teams Group Call Test"
    Write-InfoMessage "Please open Microsoft Teams and initiate a call with multiple users, test audio and screen sharing."
    $result = Get-PromptResponse "Was the Teams group call successful? (yes/no)"
    $notes = ""
    
    if ($result -in @("yes", "y")) {
        Write-SuccessMessage "Teams group call test successful"
        "SUCCESS: Teams group call test" | Out-File -FilePath $outputFile -Append
    } else {
        Write-ErrorMessage "Teams group call test failed"
        "ERROR: Teams group call test" | Out-File -FilePath $outputFile -Append
        $notes = Read-Host "Please describe the issue"
        "Notes: $notes" | Out-File -FilePath $outputFile -Append
    }
    
    # Outlook Email Test
    Write-SubSection "Outlook Email Test"
    Write-InfoMessage "Please open Outlook and send/receive a test email."
    $result = Get-PromptResponse "Was the Outlook email test successful? (yes/no)"
    $notes = ""
    
    if ($result -in @("yes", "y")) {
        Write-SuccessMessage "Outlook email test successful"
        "SUCCESS: Outlook email test" | Out-File -FilePath $outputFile -Append
    } else {
        Write-ErrorMessage "Outlook email test failed"
        "ERROR: Outlook email test" | Out-File -FilePath $outputFile -Append
        $notes = Read-Host "Please describe the issue"
        "Notes: $notes" | Out-File -FilePath $outputFile -Append
    }
    
    # Outlook Web Access Test
    Write-SubSection "Outlook Web Access (OWA) Test"
    Write-InfoMessage "Please open https://outlook.office365.com in your browser, log in, and send/receive a test email."
    $result = Get-PromptResponse "Was the OWA email test successful? (yes/no)"
    $notes = ""
    
    if ($result -in @("yes", "y")) {
        Write-SuccessMessage "OWA email test successful"
        "SUCCESS: OWA email test" | Out-File -FilePath $outputFile -Append
    } else {
        Write-ErrorMessage "OWA email test failed"
        "ERROR: OWA email test" | Out-File -FilePath $outputFile -Append
        $notes = Read-Host "Please describe the issue"
        "Notes: $notes" | Out-File -FilePath $outputFile -Append
    }
    
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
        } else {
            Write-ErrorMessage "Network printer test failed"
            "ERROR: Network printer test" | Out-File -FilePath $outputFile -Append
            $notes = Read-Host "Please describe the issue"
            "Notes: $notes" | Out-File -FilePath $outputFile -Append
        }
    } else {
        Write-InfoMessage "Network printer test skipped"
        "SKIPPED: Network printer test" | Out-File -FilePath $outputFile -Append
    }
    
    # Security Test (EICAR test file)
    Write-SubSection "Security Test (EICAR test file)"
    Write-InfoMessage "This test will check if your antivirus blocks the EICAR test file"
    $performTest = Get-PromptResponse "Would you like to perform the EICAR test file download? (yes/no)"
    
    if ($performTest -in @("yes", "y")) {
        Write-InfoMessage "Opening default web browser to https://secure.eicar.org/eicar.com.txt..."
        Start-Process "https://secure.eicar.org/eicar.com.txt"
        $result = Get-PromptResponse "Was the EICAR test file blocked by your security software? (yes/no)"
        if ($result -in @("yes", "y")) {
            Write-SuccessMessage "Security test successful - EICAR test file was blocked"
            "SUCCESS: Security test - EICAR test file was blocked" | Out-File -FilePath $outputFile -Append
        } else {
            Write-ErrorMessage "Security test failed - EICAR test file was not blocked!"
            "ERROR: Security test - EICAR test file was not blocked" | Out-File -FilePath $outputFile -Append
        }
    } else {
        Write-InfoMessage "EICAR test file download skipped"
        "SKIPPED: EICAR test file download" | Out-File -FilePath $outputFile -Append
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

Write-InfoMessage "Tests completed for connection types: $($connectionTypes -join ", ")"
Write-InfoMessage "Report file has been created at '$script:OutputBasePath':"
Write-InfoMessage "  - Text Log: $(Split-Path $outputFile -Leaf)"

Write-PromptMessage "Would you like to add any additional comments to the report? (yes/no)"
$addComments = Read-Host
if ($addComments -in @("yes", "y")) {
    Write-PromptMessage "Please enter your comments (press Enter when done):"
    $comments = Read-Host
    
    # Add comments to the text log
    "`nADDITIONAL COMMENTS:" | Out-File -FilePath $outputFile -Append
    @"

--------------------------------------------------------------------------------
                                COMMENTS
--------------------------------------------------------------------------------
"@ | Out-File -FilePath $outputFile -Append
    $comments | Out-File -FilePath $outputFile -Append
}

Write-Section "TEST COMPLETED"
Write-InfoMessage "Thank you for completing the ABB Network Connectivity User Acceptance Test."