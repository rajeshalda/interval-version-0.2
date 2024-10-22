# Teams Meeting Information Fetcher

This project provides methods to retrieve Microsoft Teams meeting details, including meeting IDs, attendance reports, and attendance records, using Microsoft Graph API or PowerShell. You can either retrieve the URL from Teams or fetch it programmatically from PowerShell, then use Microsoft Graph to extract more information about the meeting.

## Features

- Fetch Teams meeting ID via URL.
- Retrieve meeting details via Microsoft Graph API.
- Obtain attendance reports and attendance records for Teams meetings.
- PowerShell support for encoding and fetching data.

## Prerequisites

- **Microsoft Graph API Access**: You need to have appropriate permissions to access Microsoft Graph API. Ensure that the following APIs are enabled:
  - `OnlineMeetings.Read`
  - `AttendanceReports.Read`
- **PowerShell**: PowerShell is required to encode the meeting information if fetching programmatically.
- **Teams Meeting URL**: Make sure you have a valid Teams meeting URL.

## Installation

1. **Install Microsoft Graph PowerShell SDK**:
   ```powershell
   Install-Module Microsoft.Graph
   ```
2. **Login to Microsoft Graph**:
   ```powershell
   Connect-MgGraph -Scopes "OnlineMeetings.Read"
   ```

## Usage

### 1. Get Meeting URL via Teams

Copy the meeting URL directly from Microsoft Teams. It will look like the following format:

```
https://teams.microsoft.com/l/meetup-join/19%3ameeting_<MeetingDetails>@thread.v2/0?context=<ContextDetails>
```

### 2. Retrieve Meeting ID from Graph Explorer

Using Graph Explorer or any REST client, you can extract the meeting ID by making a `GET` request using the meeting URL.

#### Example:

**Endpoint**:
```http
https://graph.microsoft.com/v1.0/me/onlineMeetings?$filter=JoinWebUrl eq 'https://teams.microsoft.com/l/meetup-join/19%3ameeting_<MeetingDetails>@thread.v2/0?context=<ContextDetails>'
```

**Response**:
```json
{
    "id": "MSo5ZWY0NmY4My0xNGNlLTQyNjctYmJjOS00NjU2N2UyNWEyNWYqMCoqMTk6bWVldGluZ19NR0l5TVRsaVptTXRZV1l3WkMwME1tTTVMV0U0TmpBdE9Ea3pOak5rWVRFeU9UUmlAdGhyZWFkLnYy"
}
```

### 3. Fetch Meeting Details

Once you have the meeting ID, use the following Graph API endpoint to fetch detailed information about the meeting:

**Endpoint**:
```http
GET /me/onlineMeetings/{meetingId}
```

**Example**:
```http
https://graph.microsoft.com/v1.0/me/onlineMeetings/MSo5ZWY0NmY4My0xNGNlLTQyNjctYmJjOS00NjU2N2UyNWEyNWYqMCoqMTk6bWVldGluZ19NR0l5TVRsaVptTXRZV1l3WkMwME1tTTVMV0U0TmpBdE9Ea3pOak5rWVRFeU9UUmlAdGhyZWFkLnYy
```

### 4. Retrieve Attendance Reports

To get attendance reports for the meeting, use the following endpoint:

**Endpoint**:
```http
GET /me/onlineMeetings/{meetingId}/attendanceReports
```

**Example**:
```http
https://graph.microsoft.com/v1.0/me/onlineMeetings/MSo5ZWY0NmY4My0xNGNlLTQyNjctYmJjOS00NjU2N2UyNWEyNWYqMCoqMTk6bWVldGluZ19NR0l5TVRsaVptTXRZV1l3WkMwME1tTTVMV0U0TmpBdE9Ea3pOak5rWVRFeU9UUmlAdGhyZWFkLnYy/attendanceReports
```

**Response** (Example):
```json
{
    "id": "a7e97fd1-e0e8-4550-ac1c-afd5cdd41fd0"
}
```

### 5. Fetch Attendance Records

Use the report ID to retrieve the individual attendance records.

**Endpoint**:
```http
GET /me/onlineMeetings/{meetingId}/attendanceReports/{reportId}/attendanceRecords
```

**Example**:
```http
https://graph.microsoft.com/v1.0/me/onlineMeetings/MSo5ZWY0NmY4My0xNGNlLTQyNjctYmJjOS00NjU2N2UyNWEyNWYqMCoqMTk6bWVldGluZ19NR0l5TVRsaVptTXRZV1l3WkMwME1tTTVMV0U0TmpBdE9Ea3pOak5rWVRFeU9UUmlAdGhyZWFkLnYy/attendanceReports/a7e97fd1-e0e8-4550-ac1c-afd5cdd41fd0/attendanceRecords
```

**Response** (Example):
```json
{
    "id": "9ef46f83-14ce-4267-bbc9-46567e25a25f",
    "emailAddress": "intervaluser@M365x39618365.onmicrosoft.com",
    "totalAttendanceInSeconds": 496,
    "role": "Organizer",
    "identity": {
        "@odata.type": "#microsoft.graph.communicationsUserIdentity",
        "id": "9ef46f83-14ce-4267-bbc9-46567e25a25f",
        "displayName": "intervaluser",
        "tenantId": "22ee08ca-64e4-4a31-808d-9dc6b9e35882"
    }
}
```

## PowerShell Usage

### Encode Meeting URL in Base64

If using PowerShell to encode the meeting URL, you can run the following script:

```powershell
$meetingUrl = "https://teams.microsoft.com/l/meetup-join/19%3ameeting_MGIyMTliZmMtYWYwZC00MmM5LWE4NjAtODkzNjNkYTEyOTRi%40thread.v2/0?context=%7b%22Tid%22%3a%2222ee08ca-64e4-4a31-808d-9dc6b9e35882%22%2c%22Oid%22%3a%229ef46f83-14ce-4267-bbc9-46567e25a25f%22%7d"
$encodedUrl = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($meetingUrl))
Write-Host $encodedUrl
```

### Fetch Meeting Details Using PowerShell

You can use PowerShell to fetch meeting details after logging into Microsoft Graph:

```powershell
$meetingId = "<Your Base64 Encoded Meeting ID>"
$meetingDetails = Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/me/onlineMeetings/$meetingId" -Method GET -Headers @{Authorization = "Bearer $($accessToken)"}
$meetingDetails
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
