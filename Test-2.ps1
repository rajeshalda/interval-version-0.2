# Define the client ID of your app registration
$ClientId = "64083eeb-dfe6-4134-a720-f33fa67b237b"

# Connect using delegated permissions (required for /me endpoints)
Connect-MgGraph -ClientId $ClientId -Scopes "Calendars.Read", "OnlineMeetings.Read", "User.Read"

# Step 1: Get meetings from the last 5 days
$StartDate = (Get-Date).AddDays(-5).ToString("yyyy-MM-ddTHH:mm:ssZ")
$EndDate = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")

Write-Host "Retrieving meetings from $StartDate to $EndDate..."
$Meetings = Invoke-MgGraphRequest -Method Get -Uri "https://graph.microsoft.com/v1.0/me/events?\$filter=start/dateTime ge '$StartDate' and end/dateTime le '$EndDate'&\$select=subject,start,end,onlineMeeting,onlineMeetingUrl"

if ($Meetings.value) {
    # Print available meetings
    $Meetings.value | Format-Table subject, start, end, onlineMeetingUrl

    # Prompt the user to select a meeting
    $SelectedMeetingIndex = Read-Host "Enter the index of the meeting you want to retrieve (starting from 0):"

    # Retrieve the selected meeting details
    $SelectedMeeting = $Meetings.value[$SelectedMeetingIndex]
    Write-Host "You selected the meeting: $($SelectedMeeting.subject)" -ForegroundColor Green
} else {
    Write-Host "No meetings found in the last 5 days." -ForegroundColor Yellow
    Disconnect-MgGraph
    return
}

# Step 2: Extract Join URL and decode it
$JoinUrl = $SelectedMeeting.onlineMeeting.joinUrl
Write-Host "Join URL: $JoinUrl"

# Step 3: Decode the Join URL (if encoded)
$DecodedJoinUrl = [System.Web.HttpUtility]::UrlDecode($JoinUrl)
Write-Host "Decoded Join URL: $DecodedJoinUrl"

# Step 4: Extract Meeting ID and Organizer ID from the Join URL
if ($DecodedJoinUrl -match "19:meeting_([^@]+)@thread.v2") {
    $MeetingId = "19:meeting_" + $matches[1] + "@thread.v2"
    Write-Host "Extracted Meeting ID: $MeetingId" -ForegroundColor Cyan
}

# Extract the Organizer Oid from the context part of the URL
if ($DecodedJoinUrl -match '"Oid":"([^"]+)"') {
    $OrganizerOid = $matches[1]
    Write-Host "Organizer Oid: $OrganizerOid" -ForegroundColor Cyan
}

# Step 5: Format the Meeting ID as required by Microsoft Graph
$FormattedString = "1*${OrganizerOid}*0**${MeetingId}"
Write-Host "Formatted String for Microsoft Graph: $FormattedString"

# Step 6: Convert the formatted string to Base64
$Base64MeetingId = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($FormattedString))
Write-Host "Base64 Encoded Meeting ID: $Base64MeetingId" -ForegroundColor Cyan

# Step 7: Retrieve Attendance Report using Base64 encoded Meeting ID via /me/onlineMeetings
Write-Host "Retrieving attendance report for Base64 Meeting ID: $Base64MeetingId..."
$AttendanceReport = Invoke-MgGraphRequest -Method Get -Uri "https://graph.microsoft.com/v1.0/me/onlineMeetings/$Base64MeetingId/attendanceReports"

if ($AttendanceReport.value) {
    $ReportId = $AttendanceReport.value[0].id
    Write-Host "Attendance Report ID: $ReportId" -ForegroundColor Green
} else {
    Write-Host "No attendance report found for the specified meeting." -ForegroundColor Yellow
    Disconnect-MgGraph
    return
}

# Step 8: Retrieve Attendance Records
Write-Host "Retrieving attendance records for Report ID: $ReportId..."
$AttendanceRecords = Invoke-MgGraphRequest -Method Get -Uri "https://graph.microsoft.com/v1.0/me/onlineMeetings/$Base64MeetingId/attendanceReports/$ReportId/attendanceRecords"

# Add more debugging here
if ($AttendanceRecords.value) {
    Write-Host "Number of attendance records: $($AttendanceRecords.value.Count)" -ForegroundColor Yellow

    # Save raw response for further analysis if needed
    $AttendanceRecords | ConvertTo-Json | Out-File "C:\#MEETING CSV\AttendanceRecordsResponse.json"

    # Display the attendance records in a table
    $AttendanceRecords.value | Format-Table id, emailAddress, totalAttendanceInSeconds, role
    Write-Host "Attendance records retrieved." -ForegroundColor Green
} else {
    Write-Host "No attendance records found." -ForegroundColor Yellow
}

# Disconnect from Microsoft Graph
Disconnect-MgGraph
