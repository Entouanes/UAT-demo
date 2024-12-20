# UAT demo
A simple demo for a semi-automated User Acceptance Test (UAT).
## Steps to run
1. Open a PowerShell terminal (Start > Windows PowerShell)
2. Copy the path to file (Right click on file > Click "Copy as path" in the context menu)
3. Run the script in the terminal (Write the following command, replace your file path and press "Enter"):
   
   ```
   powershell -ExecutionPolicy Bypass -File <your-file-path>
   ```
5. Read the instructions and answer the prompts
6. Find the results in your Desktop folder

## Notes
The script might not be able to run depending on the execution policies set in your environment. The "Bypass" policy is an approach for ad-hoc policy override, but might not always apply. Read more [here](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.security/set-executionpolicy?view=powershell-7.4).
