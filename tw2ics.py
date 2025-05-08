import json
import os
from datetime import datetime, timezone

def format_datetime(dt_str):
    """
    Convert an ISO 8601 datetime string to ICS format.
    Example: '2023-03-25T14:30:00Z' -> '20230325T143000Z'
    """
    try:
        # First try to parse a datetime string ending with 'Z' (UTC)
        dt = datetime.strptime(dt_str, "%Y-%m-%dT%H:%M:%SZ")
    except ValueError:
        try:
            # Fallback: parse datetime with possible timezone info
            dt = datetime.fromisoformat(dt_str)
            dt = dt.astimezone(timezone.utc)
        except Exception as e:
            print(f"Error parsing datetime '{dt_str}': {e}")
            return None
    return dt.strftime("%Y%m%dT%H%M%SZ")

def task_to_event(task):
    """
    Convert a single Taskwarrior task (dict) into an ICS VEVENT string.
    Only tasks with a 'due' field are converted.
    """
    uid = task.get('uuid', 'no-uuid')
    summary = task.get('description', 'No description')
    due = task.get('due')
    if not due:
        return None  # Skip tasks without a due date
    dtstart = format_datetime(due)
    if not dtstart:
        return None

    dtstamp = datetime.utcnow().strftime("%Y%m%dT%H%M%SZ")

    event_lines = [
        "BEGIN:VEVENT",
        f"UID:{uid}",
        f"DTSTAMP:{dtstamp}",
        f"DTSTART:{dtstart}",
        f"SUMMARY:{summary}"
    ]

    # Optionally add extra task details into DESCRIPTION
    details = []
    for key, value in task.items():
        if key not in ['uuid', 'description', 'due']:
            details.append(f"{key}: {value}")
    if details:
        event_lines.append("DESCRIPTION:" + "\\n".join(details))

    event_lines.append("END:VEVENT")
    return "\n".join(event_lines)

def tasks_to_ics(tasks):
    """
    Convert a list of Taskwarrior tasks into a complete ICS calendar string.
    """
    ics_lines = [
        "BEGIN:VCALENDAR",
        "VERSION:2.0",
        "PRODID:-//Taskwarrior to ICS Converter//EN",
        "CALSCALE:GREGORIAN"
    ]

    for task in tasks:
        event = task_to_event(task)
        if event:
            ics_lines.append(event)

    ics_lines.append("END:VCALENDAR")
    return "\n".join(ics_lines)

def convert_json_to_ics(input_filename):
    """
    Convert the given Taskwarrior JSON file to an ICS file.
    The output file will have the same base name with an .ics extension.
    """
    # Create the output filename by replacing the extension with .ics
    base, _ = os.path.splitext(input_filename)
    output_filename = base + ".ics"

    # Load tasks from the JSON file
    with open(input_filename, "r") as f:
        tasks = json.load(f)

    # Convert tasks to ICS content
    ics_content = tasks_to_ics(tasks)

    # Write the ICS content to the output file
    with open(output_filename, "w") as f:
        f.write(ics_content)

    print(f"ICS file created: {output_filename}")

# Example usage
if __name__ == "__main__":
    import sys
    if len(sys.argv) < 2:
        print("Usage: python script.py inputfile.json")
    else:
        input_file = sys.argv[1]
        convert_json_to_ics(input_file)
