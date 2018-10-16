# Edit VM bulk
# By: Tim Bentley
# This will modify the CPU, memory, or both of each VM in a list

#Work in progress...

#get creds for vcenter & connect
$vcenter = Read-Host "Enter a vcenter name"
$cred = Get-Credential
Connect-VIServer -Server $vcenter -Credential $cred

#prompt for direction...

Write-Host
Write-Host "What would you like to to?"
Write-Host "Choose a letter..."
Write-Host
$decision = Read-Host "(M)emory, (C)PU, (B)oth"
Write-Host

#Dialog box
function Get-ClipboardText() {
    Add-Type -AssemblyName System.Windows.Forms
    $tb = New-Object System.Windows.Forms.TextBox
    $tb.Multiline = $true
    $tb.Paste()
    $tb.Text
}

function Read-MultiLineInputBoxDialog([string]$Message, [string]$WindowTitle, [string]$DefaultText)
{
<#
    .SYNOPSIS
    Prompts the user with a multi-line input box and returns the text they enter, or null if they cancelled the prompt.
     
    .DESCRIPTION
    Prompts the user with a multi-line input box and returns the text they enter, or null if they cancelled the prompt.
     
    .PARAMETER Message
    The message to display to the user explaining what text we are asking them to enter.
     
    .PARAMETER WindowTitle
    The text to display on the prompt window's title.
     
    .PARAMETER DefaultText
    The default text to show in the input box.
     
    .EXAMPLE
    $userText = Read-MultiLineInputDialog "Input some text please:" "Get User's Input"
     
    Shows how to create a simple prompt to get mutli-line input from a user.
     
    .EXAMPLE
    # Setup the default multi-line address to fill the input box with.
    $defaultAddress = @'
    John Doe
    123 St.
    Some Town, SK, Canada
    A1B 2C3
    '@
     
    $address = Read-MultiLineInputDialog "Please enter your full address, including name, street, city, and postal code:" "Get User's Address" $defaultAddress
    if ($address -eq $null)
    {
        Write-Error "You pressed the Cancel button on the multi-line input box."
    }
     
    Prompts the user for their address and stores it in a variable, pre-filling the input box with a default multi-line address.
    If the user pressed the Cancel button an error is written to the console.
     
    .EXAMPLE
    $inputText = Read-MultiLineInputDialog -Message "If you have a really long message you can break it apart`nover two lines with the powershell newline character:" -WindowTitle "Window Title" -DefaultText "Default text for the input box."
     
    Shows how to break the second parameter (Message) up onto two lines using the powershell newline character (`n).
    If you break the message up into more than two lines the extra lines will be hidden behind or show ontop of the TextBox.
     
    .NOTES
    Name: Show-MultiLineInputDialog
    Author: Daniel Schroeder (originally based on the code shown at http://technet.microsoft.com/en-us/library/ff730941.aspx)
    Version: 1.0
#>
    Add-Type -AssemblyName System.Drawing
    Add-Type -AssemblyName System.Windows.Forms
     
    # Create the Label.
    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Size(10,10) 
    $label.Size = New-Object System.Drawing.Size(280,20)
    $label.AutoSize = $true
    $label.Text = $Message
     
    # Create the TextBox used to capture the user's text.
    $textBox = New-Object System.Windows.Forms.TextBox 
    $textBox.Location = New-Object System.Drawing.Size(10,40) 
    $textBox.Size = New-Object System.Drawing.Size(575,200)
    $textBox.AcceptsReturn = $true
    $textBox.AcceptsTab = $false
    $textBox.Multiline = $true
    $textBox.ScrollBars = 'Both'
    $textBox.Text = $DefaultText
     
    # Create the OK button.
    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Location = New-Object System.Drawing.Size(415,250)
    $okButton.Size = New-Object System.Drawing.Size(75,25)
    $okButton.Text = "OK"
    $okButton.Add_Click({ $form.Tag = $textBox.Text; $form.Close() })
     
    # Create the Cancel button.
    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Location = New-Object System.Drawing.Size(510,250)
    $cancelButton.Size = New-Object System.Drawing.Size(75,25)
    $cancelButton.Text = "Cancel"
    $cancelButton.Add_Click({ $form.Tag = $null; $form.Close() })
     
    # Create the form.
    $form = New-Object System.Windows.Forms.Form 
    $form.Text = $WindowTitle
    $form.Size = New-Object System.Drawing.Size(610,320)
    $form.FormBorderStyle = 'FixedSingle'
    $form.StartPosition = "CenterScreen"
    $form.AutoSizeMode = 'GrowAndShrink'
    $form.Topmost = $True
    $form.AcceptButton = $okButton
    $form.CancelButton = $cancelButton
    $form.ShowInTaskbar = $true
     
    # Add all of the controls to the form.
    $form.Controls.Add($label)
    $form.Controls.Add($textBox)
    $form.Controls.Add($okButton)
    $form.Controls.Add($cancelButton)
     
    # Initialize and show the form.
    $form.Add_Shown({$form.Activate()})
    $form.ShowDialog() > $null   # Trash the text of the button that was clicked.
     
    # Return the text that the user entered.
    return $form.Tag
}

#function CPU change

function cpuchange() {
    ForEach ($VM in $VMs) {
        Write-Host "Changing VMs..."

        Try{
            Set-VM -VM $VM -NumCpu $cpu -confirm:$false
            $r = Start-VM -VM $VM    
            Write-Host "CPU Changed and powering up..."
        }
        Catch{
            Write-Host "Something went wrong for $VM" 
        }
    }
}

#function memory change

function memorychange() {

$mem = $memgb*1024

    ForEach ($VM in $VMs) {
        Write-Host "Changing VMs..."

        Try{
            Set-VM -VM $VM -MemoryMB $mem -confirm:$false
            $r = Start-VM -VM $VM    
            Write-Host "CPU Changed and powering up..."
        }
        Catch{
            Write-Host "Something went wrong for $VM" 
        }
    }
}    

#function both

function changeboth() {

$mem = $memgb*1024

    ForEach ($VM in $VMs) {
        Write-Host "Changing VMs..."

        Try{
            Set-VM -VM $VM -MemoryMB $mem -NumCpu $cpu -confirm:$false
            $r = Start-VM -VM $VM    
            Write-Host "CPU Changed and powering up..."
        }
        Catch{
            Write-Host "Something went wrong for $VM" 
        }
    }
}

#prompt for servers...

$multiLineText = Read-MultiLineInputBoxDialog -Message "Enter Server Names..." -WindowTitle "Enter Server Names..." -DefaultText $null

$hostList = $multiLineText.Split("`r`n") | ?{ $_ }
$VMs = @()

ForEach ($VM in $hostList) {
    $VMs += $VM
}

#Power off each VM...

ForEach ($VM in $VMs) {
    Write-Host "Shutting down Guest OS on $VM..."
    $r = Stop-VMGuest -Confirm:$false -VM $VM 
}

#Check if VMs are powered off before continuing...

ForEach ($VM in $VMs) {
    Do {
        $status = Get-VM $VM | Select PowerState
        Write-Host -NoNewline "."
        sleep 7
        } Until ($status.PowerState -eq 'PoweredOff')
    Write-Host
   }


If ($decision eq "M") {
    Write-Host
    $memgb = Read-Host "Enter TOTAL memory size in GB"
    Write-Host
    memorychange
    }
Elseif ($decision eq "C") {
    Write-Host
    $cpu = Read-Host "Enter the TOTAL amount of CPUs on the VM"
    Write-Host
    cpuchange
    }
Elseif ($decision eq "B") {
    Write-Host
    $memgb = Read-Host "Enter TOTAL memory size in GB"
    $cpu = Read-Host "Enter the TOTAL amount of CPUs on the VM"
    Write-Host
    changeboth
    }
Else {
    Write-Host
    Write-Host "No information was made/incorrect response"
    Write-Host "Exiting..."
    Write-Host
    }

Disconnect-VIServer -Server * -Force -Confirm:$FALSE