# Define the client ID of your app registration
$ClientId = "64083eeb-dfe6-4134-a720-f33fa67b237b"

# Connect using delegated permissions (required for /me endpoints)
Connect-MgGraph -ClientId $ClientId -Scopes "Calendars.Read", "OnlineMeetings.Read", "User.Read"

# Step 1: Get the current user ID via the /me endpoint
Write-Host "Retrieving current user information..."
$CurrentUser = Invoke-MgGraphRequest -Method Get -Uri "https://graph.microsoft.com/v1.0/me"
$CurrentUserId = $CurrentUser.id
Write-Host "Current User ID: $CurrentUserId" -ForegroundColor Cyan

# Step 2: Get meetings from the last 7 days
$StartDate = (Get-Date).AddDays(-7).ToString("yyyy-MM-ddTHH:mm:ssZ")
$EndDate = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")

Write-Host "Retrieving meetings from $StartDate to $EndDate..."
$Meetings = Invoke-MgGraphRequest -Method Get -Uri "https://graph.microsoft.com/v1.0/me/events?\$filter=start/dateTime ge '$StartDate' and end/dateTime le '$EndDate'&\$select=subject,start,end,onlineMeeting,onlineMeetingUrl"

if ($Meetings.value) {
    # Loop through each meeting and get attendance records
    foreach ($Meeting in $Meetings.value) {
        Write-Host "`nProcessing meeting: $($Meeting.subject)" -ForegroundColor Green
        
        # Check if the meeting has an OnlineMeeting (Teams meeting)
        if ($Meeting.onlineMeeting) {
            # Extract Join URL
            $JoinUrl = $Meeting.onlineMeeting.joinUrl
            Write-Host "Join URL: $JoinUrl"
            
            # Decode the Join URL
            $DecodedJoinUrl = [System.Web.HttpUtility]::UrlDecode($JoinUrl)
            Write-Host "Decoded Join URL: $DecodedJoinUrl"

            # Extract Meeting ID and Organizer Oid
            if ($DecodedJoinUrl -match "19:meeting_([^@]+)@thread.v2") {
                $MeetingId = "19:meeting_" + $matches[1] + "@thread.v2"
                Write-Host "Extracted Meeting ID: $MeetingId" -ForegroundColor Cyan
            }

            if ($DecodedJoinUrl -match '"Oid":"([^"]+)"') {
                $OrganizerOid = $matches[1]
                Write-Host "Organizer Oid: $OrganizerOid" -ForegroundColor Cyan
            }

            # Format the Meeting ID for Microsoft Graph
            $FormattedString = "1*${OrganizerOid}*0**${MeetingId}"
            Write-Host "Formatted String for Microsoft Graph: $FormattedString"

            # Convert to Base64
            $Base64MeetingId = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($FormattedString))
            Write-Host "Base64 Encoded Meeting ID: $Base64MeetingId" -ForegroundColor Cyan

            # Retrieve Attendance Report
            Write-Host "Retrieving attendance report for Base64 Meeting ID: $Base64MeetingId..."
            $AttendanceReport = Invoke-MgGraphRequest -Method Get -Uri "https://graph.microsoft.com/v1.0/me/onlineMeetings/$Base64MeetingId/attendanceReports"

            if ($AttendanceReport.value) {
                $ReportId = $AttendanceReport.value[0].id
                Write-Host "Attendance Report ID: $ReportId" -ForegroundColor Green

                # Step 3: Retrieve Attendance Records
                $AttendanceRecords = Invoke-MgGraphRequest -Method Get -Uri "https://graph.microsoft.com/v1.0/me/onlineMeetings/$Base64MeetingId/attendanceReports/$ReportId/attendanceRecords"
                
                if ($AttendanceRecords.value) {
                    # Filter attendance records for the current user ID
                    $UserAttendanceRecord = $AttendanceRecords.value | Where-Object { $_.id -eq $CurrentUserId }

                    if ($UserAttendanceRecord) {
                        # Display the total attendance time for this meeting
                        $TotalTime = $UserAttendanceRecord.totalAttendanceInSeconds
                        Write-Host "You attended this meeting for: $TotalTime seconds" -ForegroundColor Cyan
                    } else {
                        Write-Host "No attendance record found for the current user in this meeting." -ForegroundColor Yellow
                    }
                } else {
                    Write-Host "No attendance records found for this meeting." -ForegroundColor Yellow
                }
            } else {
                Write-Host "No attendance report found for this meeting." -ForegroundColor Yellow
            }
        } else {
            Write-Host "This meeting does not have online meeting data (not a Teams meeting)." -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "No meetings found in the last 7 days." -ForegroundColor Yellow
}

# Disconnect from Microsoft Graph
Disconnect-MgGraph
