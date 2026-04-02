#!/bin/sh -l

SCANFOLDER=$1
SOURCE_UUID="8c0ac08e-60ad-4a8a-9571-a2c56514b61a"
SCANID_STR="Scan launched successfully. Scan ID: "
if [ -z "${URL}" ]; then
  echo "[ERROR] Please set your Qualys Server URL in URL environment variable."
  exit 1
fi

AUTHTYPE_UPPER=$(echo "$AUTHTYPE" | tr '[:lower:]' '[:upper:]')

if [ "$AUTHTYPE_UPPER" = "OIDC" ]; then
  if [ -z "${CLIENTID}" ]; then
    echo "[ERROR] Please set your Qualys Client ID in CLIENTID environment variable."
    exit 1
  fi
  if [ -z "${CLIENTSECRET}" ]; then
    echo "[ERROR] Please set your Qualys Client Secret in CLIENTSECRET environment variable."
    exit 1
  fi
  UNAME=$CLIENTID
  PASS=$CLIENTSECRET
else
  if [ -z "${UNAME}" ]; then
    echo "[ERROR] Please set your Qualys Username in UNAME environment variable."
    exit 1
  fi
  if [ -z "${PASS}" ]; then
    echo "[ERROR] Please set your Qualys Password in PASS environment variable."
    exit 1
  fi
fi
echo "[INFO] GITHUB_REF: ${GITHUB_REF}"
echo "[INFO] GITHUB_REPOSITORY: ${GITHUB_REPOSITORY}"

git config --global --add safe.directory "$GITHUB_WORKSPACE"

echo "Action triggered by $GITHUB_EVENT_NAME event"

if [ $GITHUB_EVENT_NAME = "push" ] || [ $GITHUB_EVENT_NAME = "pull_request" ]
then
    if [ $(git diff --name-only --diff-filter=ACMRT HEAD^ HEAD | wc -l) -eq "0" ]; then 
        echo "There are no files/folders to scan."
        echo "{\"version\": \"2.1.0\",\"runs\": [{\"tool\": {\"driver\": {\"name\": \"QualysIaCSecurity\",\"organization\": \"Qualys\"}},\"results\": []}]}" > response.sarif
        exit 0
    else
        echo "From the below files, Only the files with extensions supported by IaC module are included in the scan."
        git diff --name-only --diff-filter=ACMRT HEAD^ HEAD
        foldername="qiacscanfolder_$(date +%Y%m%d%H%M%S)"
        mkdir "$foldername"
        git diff --name-only --diff-filter=ACMRT HEAD^ HEAD | while IFS= read -r file; do
            cp --parents "$file" "$foldername"
        done
        SCANFOLDER="$foldername"
    fi
else
    if [ "$SCANFOLDER" = "." ]
    then 
        echo "Scanning entire repository."
    else
        echo "Scan Directory Path is - $SCANFOLDER"
    fi
fi
 #Calling Iac CLI
 echo "[INFO] Scanning Started at - $(date +"%Y-%m-%d %H:%M:%S")"
 if [ "$AUTHTYPE_UPPER" = "OIDC" ]; then
    qiac scan -a $URL -u $UNAME -p $PASS -d $SCANFOLDER -m json -n GitHubActionScan --tag [{\"BRANCH_NAME\":\"$GITHUB_REF\"},{\"REPOSITORY_NAME\":\"$GITHUB_REPOSITORY\"}] -at OIDC > /result.json
 else
    qiac scan -a $URL -u $UNAME -p $PASS -d $SCANFOLDER -m json -n GitHubActionScan --tag [{\"BRANCH_NAME\":\"$GITHUB_REF\"},{\"REPOSITORY_NAME\":\"$GITHUB_REPOSITORY\"}] > /result.json
 fi
 if [ $? -ne 0 ]; then
    exit 1
 fi

 LEN=${#SCANID_STR}
 let "LEN+=1"
 SCAN_ID="$(grep "$SCANID_STR" /result.json  | cut -c $LEN-)"
 
 if [[ ! -z "$SCAN_ID" ]]
 then
    echo "[INFO] Scan ID:" $SCAN_ID
    if [ "$AUTHTYPE_UPPER" = "OIDC" ]; then
       qiac getresult -a $URL -u $UNAME -p $PASS -i $SCAN_ID -m SARIF -s -at OIDC > /raw_result.sarif
    else
       qiac getresult -a $URL -u $UNAME -p $PASS -i $SCAN_ID -m SARIF -s > /raw_result.sarif
    fi
 fi
 
 if [ -f scan_response_*.sarif ]; then
     mv scan_response_*.sarif response.sarif
     chmod 755 response.sarif
 else
    # Adding empty SARIF response in response.sarif file.
    # This issue is from github/codeql-action/upload-sarif@v1 side. 
    # Issue link: https://github.com/psalm/psalm-github-actions/issues/23
    # This issue is an open state when this issue is resolved from the GitHub side we will remove below code line. Same for line no 13.
    echo "{\"version\": \"2.1.0\",\"runs\": [{\"tool\": {\"driver\": {\"name\": \"QualysIaCSecurity\",\"organization\": \"Qualys\"}},\"results\": []}]}" > response.sarif
 fi

 echo "[INFO] Scanning Completed at - $(date +"%Y-%m-%d %H:%M:%S")"
 #process result for annotation
 echo " "
 echo "SCAN RESULT"
 cd /
 #cat result.json
 python resultParser.py result.json

