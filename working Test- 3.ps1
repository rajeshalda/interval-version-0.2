# Define the client ID of your app registration
$ClientId = "64083eeb-dfe6-4134-a720-f33fa67b237b"

# Connect using delegated permissions (required for /me endpoints)
Connect-MgGraph -ClientId $ClientId -Scopes "Calendars.Read", "OnlineMeetings.Read", "User.Read"

# Step 1: Get the current user ID via the /me endpoint
Write-Host "Retrieving current user information..."
$CurrentUser = Invoke-MgGraphRequest -Method Get -Uri "https://graph.microsoft.com/v1.0/me"
$CurrentUserId = $CurrentUser.id
Write-Host "Current User ID: $CurrentUserId" -ForegroundColor Cyan

# Step 2: Get meetings from the last 5 days
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

# Step 3: Extract Join URL and decode it
$JoinUrl = $SelectedMeeting.onlineMeeting.joinUrl
Write-Host "Join URL: $JoinUrl"

# Step 4: Decode the Join URL (if encoded)
$DecodedJoinUrl = [System.Web.HttpUtility]::UrlDecode($JoinUrl)
Write-Host "Decoded Join URL: $DecodedJoinUrl"

# Step 5: Extract Meeting ID and Organizer ID from the Join URL
if ($DecodedJoinUrl -match "19:meeting_([^@]+)@thread.v2") {
    $MeetingId = "19:meeting_" + $matches[1] + "@thread.v2"
    Write-Host "Extracted Meeting ID: $MeetingId" -ForegroundColor Cyan
}

# Extract the Organizer Oid from the context part of the URL
if ($DecodedJoinUrl -match '"Oid":"([^"]+)"') {
    $OrganizerOid = $matches[1]
    Write-Host "Organizer Oid: $OrganizerOid" -ForegroundColor Cyan
}

# Step 6: Format the Meeting ID as required by Microsoft Graph
$FormattedString = "1*${OrganizerOid}*0**${MeetingId}"
Write-Host "Formatted String for Microsoft Graph: $FormattedString"

# Step 7: Convert the formatted string to Base64
$Base64MeetingId = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($FormattedString))
Write-Host "Base64 Encoded Meeting ID: $Base64MeetingId" -ForegroundColor Cyan

# Step 8: Retrieve Attendance Report using Base64 encoded Meeting ID
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

# Step 9: Retrieve Attendance Records for the Meeting
try {
    Write-Host "Retrieving attendance records for Base64 Meeting ID: $Base64MeetingId and Report ID: $ReportId..."
    
    # Use the Base64 encoded Meeting ID in the URI
    $Uri = "https://graph.microsoft.com/v1.0/me/onlineMeetings/$Base64MeetingId/attendanceReports/$ReportId/attendanceRecords"
    Write-Host "Attendance Records URI: $Uri" -ForegroundColor Cyan

    # Fetch the attendance records
    $AttendanceRecords = Invoke-MgGraphRequest -Method Get -Uri $Uri
    
    if ($AttendanceRecords.value) {
        # Step 10: Display all attendance records with only name and attendance time (totalAttendanceInSeconds)
        Write-Host "Displaying all attendance records (Name and Total Attendance Time):"
        $AttendanceRecords.value | ForEach-Object {
            $Name = $_.identity.displayName
            $AttendanceTime = $_.totalAttendanceInSeconds
            Write-Host "Name: $Name, Attendance Time (seconds): $AttendanceTime"
        }

        # Step 11: Filter attendance records for the current user ID and display name and attendance time
        $UserAttendanceRecord = $AttendanceRecords.value | Where-Object { $_.id -eq $CurrentUserId }

        if ($UserAttendanceRecord) {
            Write-Host "`nFiltered Attendance Record for the Current User (Name and Total Attendance Time):" -ForegroundColor Green
            $UserAttendanceRecord | ForEach-Object {
                $UserName = $_.identity.displayName
                $UserAttendanceTime = $_.totalAttendanceInSeconds
                Write-Host "Name: $UserName, Attendance Time (seconds): $UserAttendanceTime"
            }
        } else {
            Write-Host "No attendance record found for the current user." -ForegroundColor Yellow
        }
    } else {
        Write-Host "No attendance records found for this report." -ForegroundColor Yellow
    }
} catch {
    # Catch and display any errors during the request
    Write-Host "Error fetching attendance records: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Details: $($_.Exception.InnerException)" -ForegroundColor Red
}




# Disconnect from Microsoft Graph
Disconnect-MgGraph
