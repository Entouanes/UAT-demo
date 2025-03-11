# Converting PowerShell Scripts to Executables

## Instructions

### Installation
1. Open PowerShell as administrator
2. Install the PS2EXE module:
   ```powershell
   Install-Module -Name PS2EXE -Scope CurrentUser
   ```

### Basic Usage
Convert your PowerShell script to an executable:
```powershell
ps2exe -inputFile "C:\path\to\your\script.ps1" -outputFile "C:\path\to\your\script.exe"
```

### Troubleshooting Module Loading Issues
If you encounter the error "module could not be loaded":

1. Set execution policy:
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

2. Import the module explicitly to check for errors:
   ```powershell
   Import-Module ps2exe
   ```

3. Reinstall the module if needed:
   ```powershell
   Uninstall-Module -Name ps2exe
   Install-Module -Name ps2exe -Scope CurrentUser
   ```

4. Verify the module is properly installed:
   ```powershell
   Get-Module -ListAvailable -Name ps2exe
   ```

### Additional Options
View all available options for PS2EXE:
```powershell
Get-Help ps2exe -Full
```

## Security Considerations

⚠️ **Important**: Executables generated from PowerShell scripts may trigger antivirus alerts. This is because converting scripts to executables is a technique sometimes used for malware distribution.

- Consider signing your executable with a code signing certificate for better trust
- Be mindful that users running your executable will not see the source code
- The executable will run with the same permissions as the user executing it

## Additional Resources

- [PS2EXE GitHub Repository](https://github.com/MScholtes/PS2EXE)
- [PowerShell Gallery - PS2EXE](https://www.powershellgallery.com/packages/ps2exe)
- [Microsoft PowerShell Documentation](https://docs.microsoft.com/en-us/powershell/)

## Alternative Tools

- [SAPIEN PowerShell Studio](https://www.sapien.com/software/powershell_studio) - Commercial tool with more advanced packaging options
- [PowerShell Script Packager](https://www.powershellgallery.com/packages/ScriptPackager) - Another free alternative
- [Inno Setup](https://jrsoftware.org/isinfo.php) - For creating installers that include PowerShell scripts