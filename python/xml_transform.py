import sys
import logging
import xml.etree.ElementTree as ET

# Configure the logger
log_file_path = '/data/vm.log'
logging.basicConfig(
    filename=log_file_path,
    level=logging.INFO,  # You can adjust the log level as needed (e.g., DEBUG, WARNING, ERROR)
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger()

def change_domain_type(xml_string):
    # Parse the XML string
    root = ET.fromstring(xml_string)
    
    # Change the 'type' attribute of the 'domain' element to 'qemu'
    root.set('type', 'qemu')
    
    # Convert the modified XML tree back to a string
    modified_xml_string = ET.tostring(root, encoding='unicode')
    
    return modified_xml_string


def manipulate_xml(xml_input):
    logger.info("@@@@ Starting XML manipulation")
    # Perform your XML manipulation here
    # For demonstration purposes, we'll just return the input string
    
    modified_xml = change_domain_type(xml_input)
    
    return modified_xml

if __name__ == "__main__":
    xml_input = sys.stdin.read()
    result = manipulate_xml(xml_input)
    print(result)
