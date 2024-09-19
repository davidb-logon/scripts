import os
import re

def find_libvirt_classes_and_usage(directory):
    libvirt_classes = set()
    libvirt_usages = []
    tracked_variables = {}

    # Regex to find org.libvirt imports and extract the class name
    import_pattern = re.compile(r'import\s+org\.libvirt\.(\w+);')
    # Regex to find assignments and constructor invocations like "conn = new Connect(...)"
    assignment_pattern = re.compile(r'(\w+)\s+(\w+)\s*=\s*new\s+(\w+)\s*\(')
    # Regex to find method calls on tracked variables
    method_call_pattern = re.compile(r'(\w+)\.(\w+)\(')
    # Regex to find return statements
    return_pattern = re.compile(r'return\s+(\w+);')

    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith(".java") and file.startswith("LibvirtConnection"):
                with open(os.path.join(root, file), 'r') as f:
                    content = f.read()
                    lines = content.split("\n")
                    print(f"Processing: {file}")

                    # Step 1: Find all org.libvirt imports
                    for line in lines:
                        import_match = import_pattern.search(line)
                        if import_match:
                            class_name = import_match.group(1)
                            libvirt_classes.add(class_name)
                            print(f"DEBUG: Found libvirt class: {class_name}")

                    # Step 2: Search for assignments and constructor invocations
                    for line in lines:
                        print(f"DEBUG: Checking line for constructor: {line.strip()}")
                        assignment_match = assignment_pattern.search(line)
                        if assignment_match:
                            class_name = assignment_match.group(3)  # Class name from "new Class"
                            variable_name = assignment_match.group(2)  # Variable name (e.g., "conn")
                            constructor_call = f"new {class_name}()"  # Report constructor call
                            if class_name in libvirt_classes:
                                # Track the variable and report constructor invocation
                                libvirt_usages.append(f"Constructor: {constructor_call} assigned to {variable_name}")
                                tracked_variables[variable_name] = class_name
                                print(f"DEBUG: Found constructor - {constructor_call} assigned to {variable_name}")

                    # Step 3: Search for method calls on tracked variables
                    for line in lines:
                        print(f"DEBUG: Checking line for method calls: {line.strip()}")
                        method_call_match = method_call_pattern.search(line)
                        if method_call_match:
                            variable_name = method_call_match.group(1)
                            method_name = method_call_match.group(2)
                            if variable_name in tracked_variables:
                                libvirt_usages.append(f"Method Call: {tracked_variables[variable_name]}.{method_name}() on {variable_name}")
                                print(f"DEBUG: Found method call - {tracked_variables[variable_name]}.{method_name}() on {variable_name}")

                    # Step 4: Search for return statements involving libvirt objects
                    for line in lines:
                        print(f"DEBUG: Checking line for return statements: {line.strip()}")
                        return_match = return_pattern.search(line)
                        if return_match:
                            return_value = return_match.group(1)
                            if return_value in tracked_variables:
                                libvirt_usages.append(f"Return: {return_value} ({tracked_variables[return_value]})")
                                print(f"DEBUG: Found return - {return_value}")

    return libvirt_usages


# Correct path to your Java files directory
java_code_directory = '/Users/dbarta/wave_cs/git/cloudstack/plugins/hypervisors/kvm/src/main/java/com/cloud/hypervisor/kvm/resource'
libvirt_usages = find_libvirt_classes_and_usage(java_code_directory)

# Output the identified libvirt usages
for usage in libvirt_usages:
    print(usage)
