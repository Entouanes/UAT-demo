#############################################################################################
#                                                                                           #
#   This script is designed to automate the UAT test process for a network environment.     #
#   It prompts the user to perform various tasks and provide feedback on the results.       #
#   It also runs additional commands to gather network information and saves the outputs.   #
#   The script saves the report and command outputs to a folder on the user's desktop.      #  
#                                                                                           #                                  
#   Note: The goal of this script is to provide a template for automating UAT tests.        #
#       The given URLs are examples and should be replaced with the actual URLs to test.    #
#       The script assumes that the user has a web browser installed and configured.        #
#                                                                                           #
#############################################################################################

# Set window title for better exe experience
$host.UI.RawUI.WindowTitle = "ABB UAT Automated Test"

# List of URLs to check
$urls = @(
    @{
        prompt = "`n
...........................................................................................
............................ WECLOME TO THE UAT AUTOMATED TEST ............................
...........................................................................................

>>> Please follow the instructions below to complete the test.
>>> If you cannot complete a task, simply press Enter to skip to the next task.

...........................................................................................
(Press Enter to continue)"
    },
    @{
        prompt = "`n
...........................................................................................
........... PERFORM THE NEXT STEPS CONNECTED TO AN ABB NETWORK, THROUGH THE LAN ...........
...........................................................................................
(Press Enter to continue)"
    },
    @{
        url="https://new.abb.com/"; 
        prompt = "Did the website load correctly? (yes/no)"
    },
    @{
        url= "https://www.bt.com"; 
        prompt = "Did the website load correctly? (yes/no)"
    },
    @{
        url="http://ip.zscaler.com/"; 
        prompt = "Did the website load correctly? (yes/no)"
    },
    @{
        url="https://insideplus.abb.com"; 
        prompt = "Log in with your ABB account. Did the page load successfully? (yes/no)"
    },
    @{
        url="https://abb.sharepoint.com/sites/ABBBusinessServices/default.aspx"; 
        prompt = "Log in with your ABB account. Did the page load successfully? (yes/no)"
    },
    @{
        url = "http://ifconfig.io"; 
        prompt = "Take a screenshot of 'Your Connection' table and save it to the folder NetworkTestOutputs on your desktop, press Enter to continue"
    }, 
    @{
        url = "https://www.whatsmyip.org/"; 
        prompt = "Enter the IP address displayed on the website"
    },
    @{
        prompt = "Open Microsoft Teams and initiate a Microsoft Teams call with 1 user, test audio, test screen sharing. Is the behavior as expected? (yes/no)"
    },
    @{
        prompt = "Open Microsoft Teams and initiate a Microsoft Teams call with more than 1 user, test audio and screen sharing. Is the behavior as expected? (yes/no)"
    },
    @{
        prompt = "Use Outlook to send and receive a test mail. (Can be coordinated with the assigned BT technician). Is the behavior as expected? (yes/no)"
    },
    @{
        url = "https://outlook.office365.com";
        prompt = "Log in to mailbox through OWA https://outlook.office365.com and send/receive test e-mail. (Can be coordinated with the assigned BT technician). Is the behavior as expected? (yes/no)"
    },
    @{
        prompt = "Access a Printer connected to the network and run a test print. Is the behavior as expected? (yes/no)"
    },
    @{
        url = "https://secure.eicar.org/eicar.com.txt";
        prompt = "Did the page load successfully? (yes/no) for ${url}"
    },
    @{
        prompt = "`n
......................................................................................................................
.............. PERFORM THE NEXT STEPS DISCONNECTED FROM THE LAN, CONNECTED THROUGH WIRELESS ABB NETWORK ..............
......................................................................................................................
(Press Enter to continue)"
    },
    @{
        prompt = "Provide the name of the Wireless Network that the user is connected to"
    },
    @{
        url="https://new.abb.com/"; 
        prompt = "Did the website load correctly? (yes/no)"
    },
    @{
        url= "https://www.bt.com"; 
        prompt = "Did the website load correctly? (yes/no)"
    },
    @{
        url="http://ip.zscaler.com/"; 
        prompt = "Did the website load correctly? (yes/no)"
    },
    @{
        url="https://insideplus.abb.com"; 
        prompt = "Log in with your ABB account. Did the page load successfully? (yes/no)"
    },
    @{
        url="https://abb.sharepoint.com/sites/ABBBusinessServices/default.aspx"; 
        prompt = "Log in with your ABB account. Did the page load successfully? (yes/no)"
    },
    @{
        prompt = "Open Microsoft Teams and initiate a Microsoft Teams call with 1 user, test audio, test screen sharing. Is the behavior as expected? (yes/no)"
    },
    @{
        prompt = "Open Microsoft Teams and initiate a Microsoft Teams call with more than 1 user, test audio and screen sharing. Is the behavior as expected? (yes/no)"
    },
    @{
        prompt = "Use Outlook to send and receive a test mail. (Can be coordinated with the assigned BT technician). Is the behavior as expected? (yes/no)"
    }
)

# Initialize a report variable
$report = @()

# Set the directory for saving command outputs to the current user's desktop
$outputDirectory = [Environment]::GetFolderPath("Desktop") + "\NetworkTestOutputs"
if (!(Test-Path -Path $outputDirectory)) {
    New-Item -ItemType Directory -Path $outputDirectory
}


# Iterate over each URL
foreach ($url in $urls) {
    try {
        # Open the URL in the default web browser
        # If there is a URL key in the hash table, open the URL
        if ($url.url) {
            # Start the process and wait for it to finish
            Start-Process $url.url
        }
        # Ask the user for feedback
        $response = Read-Host "$($url.prompt)"
        
        # Store the results in the report
        $report += [PSCustomObject]@{
            URL           = if ($url.url) { $url.url } else { "N/A" }
            UserFeedback  = $response
        }
    } catch {
        # Handle exceptions
        Write-Output "Failed to process ${url}: $($_.Exception.Message)"
        $report += [PSCustomObject]@{
            TASK          = $($url.task)
            URL           = $url
            UserFeedback  = "Error: $($_.Exception.Message)"
        }
    }
}

# Run the additional commands once and save their outputs
$ipconfigOutput = Join-Path -Path $outputDirectory -ChildPath "IPConfigOutput.txt"
$pingOutput = Join-Path -Path $outputDirectory -ChildPath "PingOutput.txt"
$tracertOutput = Join-Path -Path $outputDirectory -ChildPath "TracertOutput.txt"
$wlanOutput = Join-Path -Path $outputDirectory -ChildPath "WLANOutput.txt"

Write-Output "Running additional commands..."

# Function to save command output
function Save-CommandOutput {
    param (
        [string]$Command,
        [string]$OutputFile
    )
    try {
        Invoke-Expression $Command | Out-File -FilePath $OutputFile -Encoding UTF8
    } catch {
        Write-Output "Failed to run command ${Command}: $($_.Exception.Message)"
        Out-File -FilePath $OutputFile -InputObject "Error: $($_.Exception.Message)" -Encoding UTF8
    }
}

Save-CommandOutput -Command "ipconfig /all" -OutputFile $ipconfigOutput
Save-CommandOutput -Command "ping 10.16.124.1" -OutputFile $pingOutput
Save-CommandOutput -Command "tracert 10.16.124.1" -OutputFile $tracertOutput
Save-CommandOutput -Command "netsh wlan show all" -OutputFile $wlanOutput

Write-Output "Additional commands completed."

# Display the report
Write-Output "User Feedback Report:"
$report | Format-Table -AutoSize

# Save the report and command outputs as a CSV file
$reportFile = Join-Path -Path $outputDirectory -ChildPath "WebsiteFeedbackReport.csv"
$report | Export-Csv -Path $reportFile -NoTypeInformation -Encoding UTF8

Write-Output "Report saved to $reportFile"
Write-Output "Command outputs saved in $outputDirectory"