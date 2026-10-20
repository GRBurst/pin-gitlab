import re
import sys

def extract_pins_from_log(log_file_path):
    pinned_deps = {}

    with open(log_file_path, 'r', encoding='utf-8') as file:
        current_package = None
        current_tag = None

        for line in file:
            pkg_match = re.search(r'"packageName":\s*"([^"]+)"', line)
            if pkg_match:
                current_package = pkg_match.group(1)

            curr_match = re.search(r'"currentValue":\s*"([^"]+)"', line)
            if curr_match and current_package:
                current_tag = curr_match.group(1)
                # Initialize or update the dictionary with the current tag
                if current_package not in pinned_deps:
                    pinned_deps[current_package] = {'current': current_tag, 'new': current_tag}
                else:
                    pinned_deps[current_package]['current'] = current_tag

            new_match = re.search(r'"newValue":\s*"([^"]+)"', line)
            if new_match and current_package:
                # Update the new tag if Renovate found one
                pinned_deps[current_package]['new'] = new_match.group(1)

    return pinned_deps

if __name__ == "__main__":
    log_file = sys.argv[1] if len(sys.argv) > 1 else 'renovate.log'

    try:
        deps = extract_pins_from_log(log_file)
        # Output format: package|current_tag|new_tag
        for pkg, tags in deps.items():
            print(f"{pkg}|{tags['current']}|{tags['new']}")

    except FileNotFoundError:
        print(f"Error: Could not find '{log_file}'.", file=sys.stderr)
        sys.exit(1)
