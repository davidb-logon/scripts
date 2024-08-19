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

def update_xml(xml_string):
    # Parse the XML string
    root = ET.fromstring(xml_string)
    
    # Change the 'type' attribute of the 'domain' element to 'qemu'
    root.set('type', 'qemu')
    
    # Find all 'devices' elements
    for devices in root.findall('devices'):
        # Find and remove the 'graphics' element within each 'devices' element
        graphics = devices.find('graphics')
        if graphics is not None:
            devices.remove(graphics)
        
    replace_os_node(root)
    
    # Convert the modified XML tree back to a string
    modified_xml_string = ET.tostring(root, encoding='unicode')
    
    return modified_xml_string

def replace_os_node(root):
    # Find the 'os' element
    os_node = root.find('os')
    
    # Replace the 'os' element with the new structure
    if os_node is not None:
        # Create a new 'os' element
        new_os_node = ET.Element('os')
        
        # Create and append the 'type' element
        type_element = ET.SubElement(new_os_node, 'type', arch='x86_64', machine='pc-i440fx-5.1')
        type_element.text = 'hvm'
        
        # Create and append the 'boot' element
        boot_element = ET.SubElement(new_os_node, 'boot', dev='hd')
        
        # Replace the old 'os' element with the new one
        root.remove(os_node)
        root.append(new_os_node)


def manipulate_xml(xml_input):
    logger.info("@@@@ Starting XML manipulation")
    
    modified_xml = update_xml(xml_input)
    
    return modified_xml

if __name__ == "__main__":
    xml_input = sys.stdin.read()
    result = manipulate_xml(xml_input)
    print(result)
