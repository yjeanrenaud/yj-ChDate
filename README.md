# yj-ChDate
Changes dates of files and folders under Win10/11, accepts relative time as input
I often need to modify dates of files. For my convenience, I made a PowerShell cmdlet that now is pourn into a module. It changes the time and date of a file or folder when they were created, written and last accessed under Windows 10/11. Obviously, this only works when you have admin permissionf for folders, but for files, it should always works. I only tested this using NTFS and SMB/CIFS as filesystems.

## Requirements
This is just a PowerShell Script. It runs on PS5 and PS7.
You might want to self-sign it so you can load it as a module:
- create self-signed code-signing certificate
```
$ModuleName = YJ-ChDate
# Create a self-signed code-signing certificate in CurrentUser\My
$cert = New-SelfSignedCertificate `
  -Subject "CN=$ModuleName Code Signing" `
  -Type CodeSigningCert `
  -KeyAlgorithm RSA -KeyLength 3072 `
  -CertStoreLocation Cert:\CurrentUser\My

# Export the public cert to a .cer file (for importing into trust stores)
$cerPath = Join-Path $env:USERPROFILE "Desktop\$ModuleName-CodeSigning.cer"
Export-Certificate -Cert $cert -FilePath $cerPath | Out-Null

# Trust the cert for this user (Trusted Publishers + Trusted Root)
Import-Certificate -FilePath $cerPath -CertStoreLocation Cert:\CurrentUser\TrustedPublisher | Out-Null
Import-Certificate -FilePath $cerPath -CertStoreLocation Cert:\CurrentUser\Root              | Out-Null

# Check where it landed
Get-ChildItem Cert:\CurrentUser\My\ | Where-Object { $_.Thumbprint -eq $cert.Thumbprint } | Format-List Subject,Issuer,NotAfter,Thumbprint
##$cert = Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert | Select-Object -First 1

```
- check for the powershell policies:
 ```Get-ExecutionPolicy -List```
you want something like this:
```
        Scope ExecutionPolicy
        ----- ---------------
MachinePolicy       Undefined
   UserPolicy       Undefined
      Process       Undefined
  CurrentUser       AllSigned
 LocalMachine       Undefined
```
if `CurrentUser` is not on `AllSigned` or `RemoteSigned`, then use `Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy AllSigned -Force`
- Sign the module files (psm1 + psd1)
```
# Use a timestamp server so signatures stay valid after cert expiry
$TimeStampServer = "http://timestamp.digicert.com"
$ModulePath = '.'
# Sign the implementation file
Set-AuthenticodeSignature `
  -FilePath (Join-Path $ModulePath "$ModuleName.psm1") `
  -Certificate $cert `
  -TimestampServer $TimeStampServer `
  | Format-List Status,StatusMessage,SignerCertificate,Path

# Sign the manifest
Set-AuthenticodeSignature `
  -FilePath (Join-Path $ModulePath "$ModuleName.psd1") `
  -Certificate $cert `
  -TimestampServer $TimeStampServer `
  | Format-List Status,StatusMessage,SignerCertificate,Path
```
- Verify signatures:
```
  Get-AuthenticodeSignature `
  (Join-Path $ModulePath "$ModuleName.psm1"),
  (Join-Path $ModulePath "$ModuleName.psd1") `
| Format-Table -Auto Path, Status, StatusMessage
```
- copy the module into the folder for PowerShell 5 and PowerShell 7 (if you use both, like I do)
```
# Per-user module paths for both shells
$WinPS5UserPath = Join-Path $env:USERPROFILE "Documents\WindowsPowerShell\Modules\$ModuleName"
$PS7UserPath    = Join-Path $env:USERPROFILE "Documents\PowerShell\Modules\$ModuleName"

# Create folders (ok if they already exist)
New-Item -ItemType Directory -Path $WinPS5UserPath,$PS7UserPath -Force | Out-Null

# Copy the signed files into both locations
Copy-Item -Path (Join-Path $ModulePath "*") -Destination $WinPS5UserPath -Recurse -Force
Copy-Item -Path (Join-Path $ModulePath "*") -Destination $PS7UserPath    -Recurse -Force
```
- Now, you may import the module in each PowerShell seprately:
```
Import-Module $ModuleName -Force
Get-Module $ModuleName | Format-List Name,Version,Path
```
- Done. Now you should see `Get-Module` putting out:
```
ModuleType Version    Name                                ExportedCommands
---------- -------    ----                                ----------------
Script     1.0        YJ-ChDate                           {Set-ChDate, chdate, yj-chdate}
```
## Usage
- You may now use `yj-chdate` and `chdate` to change the time and date of a file or folder when they were created, written and last accessed under Windows 10/11 using Powershell.
- parameters are easy: `yjchdate [filename] [datestring]`
- Datesring may be anything PowerShell recognises, from `"2022-01-01 12:01:01"` to `"now"`, `"yesterday 5pm"` or `"tomorrow 23:55"`.
- e.g. if you want a examplefile to be dated for the next day at 1pm, you may use `yj-chdate '.\examplefile' 'tomorrow 13:00'` or `yj-chdate '.\examplefile' 'tomorrow 1pm'`
