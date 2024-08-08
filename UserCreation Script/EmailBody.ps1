function Get-HTMLFormattedEmailBody {
  param (
      [string]$Username,
      [string]$FullName,
      [string]$Password,
      [string]$Groups,
      [string]$Domain
  )

  # Hardcoded image path
  $ImagePath = "\\File\CommonRepository\ManagementScripts\User_Management_Scripts\Create RDS User Gui - Protego\AMSProtego Logo.png"

  # Convert image to base64
  $imageBase64 = ""
  if (Test-Path $ImagePath) {
      try {
          $imageBytes = [System.IO.File]::ReadAllBytes($ImagePath)
          $imageBase64 = [System.Convert]::ToBase64String($imageBytes)
          $imageExtension = [System.IO.Path]::GetExtension($ImagePath).TrimStart('.')
          $imageBase64 = "data:image/$imageExtension;base64,$imageBase64"
      }
      catch {
          Write-Warning "Failed to read image file: $_"
      }
  }
  else {
      Write-Warning "Image not found at $ImagePath. Email will be sent without logo."
  }

  $body = @"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>New User Created - AMS Protego</title>
  <style>
      body {
          font-family: Arial, sans-serif;
          line-height: 1.6;
          color: #333;
          max-width: 600px;
          margin: 0 auto;
          padding: 20px;
      }
      .header {
          background-color: #663399;
          color: white;
          padding: 20px;
          text-align: center;
      }
      h1 {
          margin: 0;
          font-size: 24px;
      }
      .content {
          background-color: #f8f9fa;
          border: 1px solid #dee2e6;
          border-radius: 5px;
          padding: 20px;
          margin-top: 20px;
      }
      table {
          width: 100%;
          border-collapse: collapse;
          margin-bottom: 20px;
      }
      th, td {
          padding: 12px;
          text-align: left;
          border-bottom: 1px solid #dee2e6;
      }
      th {
          background-color: #e9ecef;
          font-weight: bold;
          width: 40%;
      }
      .footer {
          margin-top: 20px;
          text-align: center;
          font-size: 0.9em;
          color: #6c757d;
      }
      .logo {
          max-width: 200px;
          margin: 20px auto;
          display: block;
      }
  </style>
</head>
<body>
  <div class="header">
      <h1>New User Created - AMS Protego</h1>
  </div>
  <div class="content">
      $(if ($imageBase64) {
          "<img src='$imageBase64' alt='AMS Protego Logo' class='logo'>"
      })
      <p>A new user account has been created in AMS Protego. Please review the details below:</p>
      <table>
          <tr>
              <th>Full Name</th>
              <td>$FullName</td>
          </tr>
          <tr>
              <th>Username</th>
              <td>$Username</td>
          </tr>
          <tr>
              <th>Password</th>
              <td>$Password</td>
          </tr>
          <tr>
              <th>Access Groups</th>
              <td>$Groups</td>
          </tr>
          <tr>
              <th>Access Domain</th>
              <td>$Domain</td>
          </tr>
      </table>
      <p>If you have any questions or require further assistance, please contact the AMS Support department.</p>
  </div>
  <div class="footer">
      <p>&copy; 2024 AMS Protego. All rights reserved.</p>
  </div>
</body>
</html>
"@
  return $body
}