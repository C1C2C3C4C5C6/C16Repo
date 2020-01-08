#________________________________________________________#
#Active Directory      | MFA CHECK SCRIPT                #
#--------------------------------------------------------#
#Author : C1C2C3C4C5C6 | github.com/C1C2C3C4C5C6/C16REPO #
#________________________________________________________#
$LOC = get-location | select Path -ExpandProperty Path

import-module MSOnline
Connect-MsolService 
Remove-item "$LOC\MFAAuthMethodCheck.csv"
add-content "$LOC\MFAAuthMethodCheck.csv" -Value "Username, AuthMethods, Validation"
#var
$email = Read-Host("Enter the email address to send from: ")
$smtp = Read-Host("Enter the smtp server to send from: ")
$company = Read-Host("Enter your Company Name: ")
$supportnumber = Read-Host("Enter your IT Support Number: ")
$supportemail = Read-host("Enter your IT Support Email: ")



$users = Get-MsolUser -MaxResults 5000 | ?{$_.isLicensed -eq "True"}
$authcount = 0
$notcount = 0
$nocount = 0
$totalcount = $users.Count
    foreach($user in $users){
        $upn = $user.UserPrincipalName
        $authmethods = $user.StrongAuthenticationMethods.MethodType
        $validate = [string]$authmethods
            if(($validate -match 'PhoneAppOTP') -or ($validate -match 'PhoneAppNotification'))
                {$validate = "Already Registered"
                $authcount += 1}

            elseif(($validate -ne 'Already Registered') -and (($user.StrongAuthenticationMethods.Count -ne 0) -or ($user.StrongAuthenticationUserDetails -ne $null))){
                $validate = "Requires App Registration"
                $notcount += 1}
            else{
                $validate = "NO MFA AUTH METHODS REGISTERED"
                $nocount += 1
                }

write-host($upn + "| $authmethods | $validate")
add-content "$LOC\MFAAuthMethodCheck.csv" "$upn, $authmethods, $validate"}
cls
write-host("Current Amount of users that have Authenticator Enabled: $authcount / $totalcount" ) -ForegroundColor Green
write-host("Current Amount of users that don't have Authenticator Enabled: $notcount / $totalcount") -ForegroundColor Yellow
write-host("Current Amount of users that don't have any MFA methods Enabled: $nocount / $totalcount") -ForegroundColor Red

######################## MFA EMAIL SEND ################################

$list = import-csv "$LOC\MFAAuthMethodCheck.csv"
    foreach($record in $list){
        $upn = $record.Username
        $validation = $record.Validation

            if($validation -match "Already Registered"){
                $accessiblity = “Full Accessibility - Authenticator Is Registered”
                $accessmessage = "No Further Action Required"}
            else{$accessiblity = "No Accessibility - Authenticator Is Not Registered"
                $accessmessage = "<br><a href = 'https://www.microsoft.com/en-us/account/authenticator' target =  '_self' >Install the Microsoft Authenticator Application</a>
                  <br><a href = 'https://account.activedirectory.windowsazure.com/Proofup.aspx' target = '_self' >Setup your authentication options</a>"}
                $firstname = $upn.Split(".")[0]
                $firstname = ($firstname.Substring(0,1).ToUpper()) + ($firstname.Substring(1).ToLower())
Send-MailMessage -To "$upn" -from $email -Subject 'Current MFA Settings' -Body ("Dear $firstname,<br><br>

Multi-factor authentication (MFA) is used at $company to make Office-365 and VPN signin more secure, requiring a username, password and the MFA to permit logon when out of the office.
Recent developments mean that SMS and Voice Call methods are not as secure as we would like. <br>
<br>
Hence, all colleagues using SMS or Voice call as an MFA should migrate to the Microsoft Authenticator Application during the coming month <br><br>
<b><span style='background-color: #FFFF00'> Your Account Status: $accessiblity</b></span>
<br>$accessmessage
<br>
<br>
If you require any assistance with installing the Microsoft Authenticator Application, please contact<br>
the ICT Service Desk as normal 
<ul type-'disc'>
<li><b>By Telephone:</b> $supportnumber</li>
<li><b>By email:</b> $supportemail</li>
</ul>
Regards,<br>
The ICT Cyber Team<br>

")-SmtpServer $smtp -BodyAsHtml
}
