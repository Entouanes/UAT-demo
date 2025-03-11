# ABB_UAT2025_01.ps1
# Thomas Klein
# Andreas Brandtner
# improved 2025_01 Roman Hambsch

##################################################################################
# Variabeln
##################################################################################

#Datum
$date = Get-Date -Format "ddMMyy_HHmm"


#user
$user= $env:UserName
$hostname =$env:COMPUTERNAME


#Changenumber
$changenum = Read-Host -Prompt "Bitte geben Sie den Namen des Changes ein!"



##################################################################################
# Funktionen
##################################################################################

function Website_Aufrufen ([string]$URL,$Ausgabedatei)
{
try
{
    $response = Invoke-WebRequest -Uri $URL -UseDefaultCredentials -ErrorAction Stop
    # This will only execute if the Invoke-WebRequest is successful.
    $StatusCode = $Response.StatusCode
}
catch
{
    $StatusCode = $_.Exception.Response.StatusCode.value__
}

If ($StatusCode -eq 200) { 
    Write-Host -foregroundcolor green "The Site" $URL "is OK!" 
    "The Site "+$URL+" is OK!" >> $Ausgabedatei
}
Else {
    Write-Host -foregroundcolor red "Status Code" $StatusCode "Error! The Site" $URL "may be down, please check!"
    "Error! The Site "+$URL+" may be down, please check!" >> $Ausgabedatei
}
}


# Hauptprogramm
$error.clear()
CLS
set-location "$($env:UserProfile)\documents"
$Ausgabedatei = "UAT $changenum $date.txt"

Write-Host "Ausgabedatei:" $Ausgabedatei

"UAT Log for Change $changenum, performed by $user on device $hostname on $date" >> $Ausgabedatei


##################################################################################
# Start der Testschleifen
##################################################################################

$Connect01 = "1"


While ($Connect01 -NE "N") { 

#Connect01 Type LAN/WLAN/VPN		
$connect01 = Read-Host -Prompt "Bitte geben Sie an, ob Ihr Rechner via LAN, WLAN oder VPN verbunden ist! (WLAN/LAN/VPN)"
$Eingabe = Read-Host -Prompt "Bitte stellen sie sicher, dass der Rechner nur über $Connect01 verbunden ist (weiter mit Return)"

Write-Host "------------------------------------------------------------"
Write-Host "------------------------------------------------------------"
Write-Host "-- Der Test der Verbindung über $connect01 startet jetzt. --"
Write-Host "------------------------------------------------------------"
Write-Host "------------------------------------------------------------"
Write-Host " "
Write-Host " "
"======================================================================================" >> $Ausgabedatei
"======================================================================================" >> $Ausgabedatei
"==" >> $Ausgabedatei
"== PC is connected via $connect01" >> $Ausgabedatei
"==" >> $Ausgabedatei
"======================================================================================" >> $Ausgabedatei
"======================================================================================" >> $Ausgabedatei

# Prüfen der Erreichbarkeit der Internet und Intranetseiten
Write-Host "Check accessibility of internet and intranet sites"
"********************************************************************************************" >> $Ausgabedatei
"********************************************************************************************" >> $Ausgabedatei
"********************************************************************************************" >> $Ausgabedatei
" " >> $Ausgabedatei
"Check accessibility of internet and intranet sites" >> $Ausgabedatei
" " >> $Ausgabedatei
" " >> $Ausgabedatei
Website_Aufrufen -URL "https://new.abb.com" -Ausgabedatei $Ausgabedatei
Website_Aufrufen -URL "https://www.bt.com" -Ausgabedatei $Ausgabedatei
Website_Aufrufen -URL "https://insideplus.abb.com" -Ausgabedatei $Ausgabedatei
Website_Aufrufen -URL "https://abb.sharepoint.com/sites/ABBBusinessServices/default.aspx" -Ausgabedatei $Ausgabedatei
Website_Aufrufen -URL "http://ip.zscaler.com/" -Ausgabedatei $Ausgabedatei
Write-Host "======================================================================================"
Write-Host " "
"======================================================================================" >> $Ausgabedatei

# #RH public IP
Write-Host "Check publicIP"
# $wp = Invoke-RestMethod -Uri http://ipinfo.io
# $wp.Content
Write-Host "======================================================================================"
Write-Host " "

"********************************************************************************************" >> $Ausgabedatei
"********************************************************************************************" >> $Ausgabedatei
"********************************************************************************************" >> $Ausgabedatei
" " >> $Ausgabedatei
"Check publicIP" >> $Ausgabedatei
" " >> $Ausgabedatei
" " >> $Ausgabedatei

Invoke-RestMethod -Uri http://ipinfo.io >> $Ausgabedatei
$wp

##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
#
#Insert part from Microsoft Script, opening websites and asking if it looks fine
#Resultz --> $Ausgabedatei
#
#
#Insert also part from Microsoft Script to test  Outlook, OWA and Temas functionality
#
#Resultz --> $Ausgabedatei#
#
#
##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

"********************************************************************************************" >> $Ausgabedatei
"********************************************************************************************" >> $Ausgabedatei
"********************************************************************************************" >> $Ausgabedatei
" " >> $Ausgabedatei
"Check ipconfig" >> $Ausgabedatei
" " >> $Ausgabedatei
" " >> $Ausgabedatei
# ipconfig /all
Write-Host "ipconfig /all"
ipconfig /all
Write-Host "======================================================================================"
Write-Host " "
"ipconfig /all" >> $Ausgabedatei
ipconfig /all >> $Ausgabedatei
"======================================================================================" >> $Ausgabedatei

"********************************************************************************************" >> $Ausgabedatei
"********************************************************************************************" >> $Ausgabedatei
"********************************************************************************************" >> $Ausgabedatei
" " >> $Ausgabedatei
"Check ping" >> $Ausgabedatei
" " >> $Ausgabedatei
" " >> $Ausgabedatei
# ping
Write-Host "ping 10.16.124.1"
ping 10.16.124.1
Write-Host "======================================================================================"
Write-Host " "
"ping 10.16.124.1" >> $Ausgabedatei
ping 10.16.124.1 >> $Ausgabedatei
"======================================================================================" >> $Ausgabedatei

"********************************************************************************************" >> $Ausgabedatei
"********************************************************************************************" >> $Ausgabedatei
"********************************************************************************************" >> $Ausgabedatei
" " >> $Ausgabedatei
"Check tracert" >> $Ausgabedatei
" " >> $Ausgabedatei
" " >> $Ausgabedatei

# tracert
Write-Host "tracert 10.16.124.1"
tracert 10.16.124.1
Write-Host "======================================================================================"
Write-Host " "
"tracert 10.16.124.1" >> $Ausgabedatei
tracert 10.16.124.1 >> $Ausgabedatei
"======================================================================================" >> $Ausgabedatei

"********************************************************************************************" >> $Ausgabedatei
"********************************************************************************************" >> $Ausgabedatei
"********************************************************************************************" >> $Ausgabedatei
" " >> $Ausgabedatei
"Check netsh" >> $Ausgabedatei
" " >> $Ausgabedatei
" " >> $Ausgabedatei
# netsh
Write-Host "netsh wlan show all"
netsh wlan show all
Write-Host "======================================================================================"
Write-Host " "
"netsh wlan show all" >> $Ausgabedatei
netsh wlan show all >> $Ausgabedatei
"======================================================================================" >> $Ausgabedatei

##################################################################################
# Tests über andere Connections?
##################################################################################
$connect01 = Read-Host -Prompt "Wollen Sie eine weitere Verbindungsart testen? (J/N)"

		} 
<# Write-host -foregroundcolor yellow "######################################################################################"
$Eingabe = Read-Host -Prompt "Bitte entfernen Sie jetzt das LAN Kabel (weiter mit Return)"
$Eingabe = Read-Host -Prompt "Bitte stellen Sie sicher, dass der PC mit dem WLAN verbunden ist (weiter mit Return)"
Write-Host "Der PC ist jetzt mit dem WLAN verbunden"
Write-Host " "
"======================================================================================" >> $Ausgabedatei
"######################################################################################" >> $Ausgabedatei
"======================================================================================" >> $Ausgabedatei
"PC is connected to WLAN" >> $Ausgabedatei
"======================================================================================" >> $Ausgabedatei

# Prüfen der Erreichbarkeit der Internet und Intranetseiten
Write-Host "Check accessibility of internet and intranet sites"
"Check accessibility of internet and intranet sites" >> $Ausgabedatei
Website_Aufrufen -URL "https://new.abb.com" -Ausgabedatei $Ausgabedatei
Website_Aufrufen -URL "https://www.bt.com" -Ausgabedatei $Ausgabedatei
Website_Aufrufen -URL "https://insideplus.abb.com" -Ausgabedatei $Ausgabedatei
Website_Aufrufen -URL "https://abb.sharepoint.com/sites/ABBBusinessServices/default.aspx" -Ausgabedatei $Ausgabedatei
Write-Host "======================================================================================"
Write-Host " "
"======================================================================================" >> $Ausgabedatei

# #RH public IP
Write-Host "Check publicIP"
$wp = Invoke-RestMethod -Uri http://ipinfo.io
$wp.Content
Write-Host "======================================================================================"
Write-Host " "
"Check publicIP" >> $Ausgabedatei
$wp.Content -split "`n" >> $Ausgabedatei
$wp
"======================================================================================" >> $Ausgabedatei

# whats my ip --> ***********************************Funktioniert nicht****************************************
# Write-Host "What's my IP"
# $wp = Invoke-WebRequest "http://www.whatsmyip.org/"
# $pw1 = -split $wp.AllElements
# Write-Host "My IP Address is" $pw1[122].substring(8,$pw1[122].IndexOf("</")-8)
# Write-Host "======================================================================================"
# Write-Host " "
# "What's my IP" >> $Ausgabedatei
# "My IP Address is "+$pw1[122].substring(8,$pw1[122].IndexOf("</")-8) >> $Ausgabedatei
# "======================================================================================" >> $Ausgabedatei

# ipconfig /all
Write-Host "ipconfig /all"
ipconfig /all
Write-Host "======================================================================================"
Write-Host " "
"ipconfig /all" >> $Ausgabedatei
ipconfig /all >> $Ausgabedatei
"======================================================================================" >> $Ausgabedatei

# ping
Write-Host "ping 10.16.124.1"
ping 10.16.124.1
Write-Host "======================================================================================"
Write-Host " "
"ping 10.16.124.1" >> $Ausgabedatei
ping 10.16.124.1 >> $Ausgabedatei
"======================================================================================" >> $Ausgabedatei

# tracert
Write-Host "tracert 10.16.124.1"
tracert 10.16.124.1
Write-Host "======================================================================================"
Write-Host " "
"tracert 10.16.124.1" >> $Ausgabedatei
tracert 10.16.124.1 >> $Ausgabedatei
"======================================================================================" >> $Ausgabedatei

# netsh
Write-Host "netsh wlan show all"
netsh wlan show all
Write-Host "======================================================================================"
Write-Host " "
"netsh wlan show all" >> $Ausgabedatei
netsh wlan show all >> $Ausgabedatei
"======================================================================================" >> $Ausgabedatei #>

if ($error) { 
"======================================================================================" >> $Ausgabedatei
"Script Errors:" >> $Ausgabedatei
$error >> $Ausgabedatei}

Write-Host " "
Write-Host "Die automatisierten Prüfungen sind jetzt beendet."
$Eingabe = Read-Host -Prompt "Soll die Ergebnisdatei jetzt angezeigt werden (J/N)"
If (($Eingabe -eq "j") -or ($Eingabe -eq "J")) {notepad $Ausgabedatei}

