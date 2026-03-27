import sys, json, os 

def print_error_message(result):
    error_message = ""
    failed_checks = False
    passed_files = set()
    failed_files = set()

    if result.get("results").get("parsingErrors"):
        print("::error::Parsing error file paths="+str(result.get("results").get("parsingErrors")))
        failed_checks = True
    if result.get("results").get("failedChecks"):
        for r in result.get("results").get("failedChecks"):
            file_path = r.get("filePath", "Unknown")
            failed_files.add(file_path)
            line_range = "None"
            keys = ["filePath", "checkId", "checkName", "criticality", "remediation"]
            keys_names = ["File Name", "Qualys CID", "Control Name", "Criticality", "Remediation"]
            error_message += "::error::"
            for k in range(0, len(keys)):
                if r.get(keys[k]):
                    error_message += keys_names[k] + "=" + r.get(keys[k]) + ", "
                else:
                    error_message += keys_names[k] + "=None" + ", "
            if error_message.endswith(", "):
                error_message = error_message[:-2]

            print(error_message)
            failed_checks = True
            error_message = ""
    if result.get("results").get("passedChecks"):
        for r in result.get("results").get("passedChecks"):
            file_path = r.get("filePath", "Unknown")
            if file_path not in failed_files:
                passed_files.add(file_path)
    for file_path in passed_files:
        print("::notice::File Name=" + file_path + " - All checks passed")
    return failed_checks


def print_failed_checks(output):
    if output.get("status") != "FINISHED":
        exit(-1)
    failed_checks = False
    for result in output.get("result"):
        if print_error_message(result):
            failed_checks = True
    failBuild = os.getenv("failBuild", "true").lower() == "true"
    if failed_checks:
        if failBuild :
            print("Pipeline status will be - Failed")
            exit(-1)
        else:
            print("Pipeline status will be - Successful")

# Press the green button in the gutter to run the script.
if __name__ == '__main__':

    fp = open(sys.argv[1], "r")
    data = fp.read()
    raw_data = data
    fp.close()
    message = "The scan result is successfully retrieved. JSON output is as follows:"
    pos = data.find(message)
    pos += len(message)
    data = data[pos:]
    try:
        json_data = json.loads(data)
    except:
        print ("Error occured while scanning. Please find the error logs below :")
        print(raw_data)
        exit(0)
    print_failed_checks(json_data)
