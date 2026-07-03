$current = (Get-ItemProperty -Path 'HKCU:\Environment' -Name PATH -ErrorAction SilentlyContinue).PATH
if ($null -eq $current) { $current = '' }
if ($current -notlike '*C:\Users\reyan\AppData\Local\Pub\Cache\bin*') {
  $new = 'C:\Users\reyan\AppData\Local\Pub\Cache\bin;' + $current
  Set-ItemProperty -Path 'HKCU:\Environment' -Name PATH -Value $new
  Write-Output 'HKCU_PATH_UPDATED'
  Write-Output $new
} else {
  Write-Output 'ALREADY_PRESENT'
  Write-Output $current
}
