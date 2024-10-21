# Import the Microsoft Graph module
Import-Module Microsoft.Graph

# Connect to Microsoft Graph with permission to read shared calendars
Connect-MgGraph -Scopes "Calendars.Read.Shared"

# Define the user whose calendar you want to access
$userId = "intervaluser@M365x39618365.onmicrosoft.com"

# Fetch calendar events from the default calendar of the specified user
$events = Get-MgUserCalendarEvent -UserId $userId -CalendarId "Calendar"

# Check if any events are returned and display them
if ($events) {
    foreach ($event in $events) {
        $eventSubject = $event.Subject
        $eventStart = $event.Start.DateTime
        $eventEnd = $event.End.DateTime
        $eventOrganizer = $event.Organizer.EmailAddress.Name
        Write-Host "Event: $eventSubject"
        Write-Host "Start: $eventStart"
        Write-Host "End: $eventEnd"
        Write-Host "Organizer: $eventOrganizer"
        Write-Host "----------------------------"
    }
} else {
    Write-Host "No upcoming events found."
}

# Disconnect from Microsoft Graph
Disconnect-MgGraph
