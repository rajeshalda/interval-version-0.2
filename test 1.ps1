# Define user email and the output CSV file path
$UserEmail = "intervaluser@M365x39618365.onmicrosoft.com"
$OutputCsvPath = "C:\#MEETING CSV\UserCalendarEvents.csv"

# Connect to Microsoft Graph with delegated permissions
# Ensure that you have necessary permissions like Calendars.Read
Connect-MgGraph -Scopes "Calendars.Read"

# Initialize an array to store event details
$EventData = @()

# Check connection and fetch user's calendar events
try {
    # Fetch only the top 5 calendar events where the user is the attendee or organizer
    $UserCalendar = Get-MgUserEvent -UserId $UserEmail -Top 5

    if ($UserCalendar) {
        Write-Host "User $UserEmail can access the calendar and read events." -ForegroundColor Green

        # Loop through each event and output relevant information
        $UserCalendar | ForEach-Object {
            # Calculate meeting duration (Start time and End time must be in DateTime format)
            $StartTime = [datetime]$_.Start.DateTime
            $EndTime = [datetime]$_.End.DateTime
            $Duration = $EndTime - $StartTime
            $MeetingId = $_.Id  # Extract the unique Meeting ID

            # Check if the user is the organizer of the event
            $IsUserOrganizer = ($_.Organizer.EmailAddress.Address -eq $UserEmail)

            # Check if the user is an attendee of the event
            $IsUserAttendee = $_.Attendees | ForEach-Object {
                if ($_.EmailAddress.Address -eq $UserEmail) {
                    return $true
                }
            }

            # Proceed only if the user is the organizer or attendee
            if ($IsUserOrganizer -or $IsUserAttendee) {
                # Store event details in the array
                $EventData += [pscustomobject]@{
                    Subject    = $_.Subject
                    Start      = $StartTime
                    End        = $EndTime
                    Duration   = $Duration.TotalMinutes
                    MeetingID  = $MeetingId
                    IsOrganizer = $IsUserOrganizer
                }
            } else {
                Write-Host "Skipping event: $($_.Subject) as the user is not involved." -ForegroundColor Yellow
            }
        }

        # Export the collected event data to a CSV file
        $EventData | Export-Csv -Path $OutputCsvPath -NoTypeInformation
        Write-Host "Calendar events exported to $OutputCsvPath" -ForegroundColor Green
    }
} catch {
    # If an error occurs (e.g., insufficient permissions or policy blocks), output the error message
    Write-Host "User $UserEmail does NOT have permission to access the calendar or there is a policy blocking it." -ForegroundColor Red
    Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Disconnect after completion
Disconnect-MgGraph
