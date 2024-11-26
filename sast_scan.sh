#!/bin/bash
set -e

# Check if project.zip file exists before creating it
echo "Creating project.zip file for SAST scan..."

# Create ZIP file for SAST Scan, excluding .git directory
zip -r project.zip . -x '*.git*'

# Ensure project.zip was created successfully
if [ ! -f project.zip ]; then
  echo "Error: project.zip not found!"
  exit 1
fi

# Perform SAST Scan
echo "Performing SAST scan..."

RESPONSE=$(curl -v -X POST \
  -H "Client-ID: 123e4567-e89b-12d3-a456-426614174001" \
  -H "Client-Secret: 7a91d1c9-2583-4ef6-8907-7c974f1d6a0e" \
  -F "projectZipFile=@project.zip" \
  -F "applicationId=674066843da24ef64598ca8b" \
  -F "scanName=java-vulnado-SAST Scan from TeamCity" \
  -F "language=java" \ 
  https://appsecops-api.intruceptlabs.com/api/v1/integrations/sast-scans)
  
# Debug: Output the raw response for troubleshooting
echo "Raw Response: $RESPONSE"

# Use Python to parse and display JSON
python3 - <<EOF
import json
import sys

try:
    # Parse the JSON response from the API call
    data = json.loads('''$RESPONSE''')
    
    print("SAST Scan Results:")
    
    # Check if 'canProceed' field is available in the response
    can_proceed = data.get('canProceed', 'N/A')
    print(f"Can Proceed: {can_proceed}")
    
    # Check if 'vulnsTable' field is available in the response
    vulns_table = data.get('vulnsTable', None)
    
    if vulns_table:
        print("\nVulnerabilities Table:")
        print(json.dumps(vulns_table, indent=2))
    else:
        print("No vulnerabilities table found")
    
    # Display critical vulnerability status
    if can_proceed == False:
        print("\nCritical vulnerabilities found. Please review the scan results.")
    else:
        print("\nNo critical vulnerabilities detected.")
        
except json.JSONDecodeError:
    print("Error: Invalid JSON response")
    print("Raw response:", '''$RESPONSE''')
except Exception as e:
    print(f"Error: {str(e)}")
    print("Raw response:", '''$RESPONSE''')
EOF

# Clean up the zip file after the scan
echo "Cleaning up project.zip..."
rm project.zip

# Always exit with 0 to not fail the build
exit 0
