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

def should_update(root):
    # Find the name node
    name_node = root.find("name")
    
    if name_node is not None:
        # Check if the name starts with 's', 'v', or 'r'
        name_value = name_node.text.lower()
        
        if name_value.startswith(('s', 'v', 'r')):
            logger.info("@@@@ Domain name: " + name_value + " will be modified for x86_64")
            return True
    logger.info("@@@@ Domain name: " + name_value + " will not be modified")
    return False

def update_xml(xml_string):
    # Parse the XML string
    root = ET.fromstring(xml_string)
    
    if not should_update(root):
        return xml_string
    
    # Change the 'type' attribute of the 'domain' element to 'qemu'
    root.set('type', 'qemu')
    
    # remove_graphics(root)
    replace_os_node(root)
    replace_cpu_node(root)
    replace_memballoon_nodes(root)
    replace_input_nodes(root)
    replace_serial_node(root)
    
    # Convert the modified XML tree back to a string
    modified_xml_string = ET.tostring(root, encoding='unicode')
    
    return modified_xml_string

def remove_graphics(root):
    # Find all 'devices' elements
    for devices in root.findall('devices'):
        # Find and remove the 'graphics' element within each 'devices' element
        graphics = devices.find('graphics')
        if graphics is not None:
            devices.remove(graphics)

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

def replace_cpu_node(root):
    # Create the new CPU node
    new_cpu = ET.Element("cpu", mode="custom", match="exact", check="none")
    model = ET.SubElement(new_cpu, "model", fallback="forbid")
    model.text = "qemu64"
    
    # Find the existing CPU node and replace it
    for child in root:
        if child.tag == "cpu":
            root.remove(child)
            break
    
    root.append(new_cpu)
    
def replace_memballoon_nodes(root):
    # Find the devices node
    devices = root.find("devices")
    if devices is None:
        raise ValueError("No 'devices' node found in the XML structure")

    # Remove all existing memballoon nodes
    memballoon_nodes = devices.findall("memballoon")
    for memballoon_node in memballoon_nodes:
        devices.remove(memballoon_node)
    
    # Create the new memballoon node
    new_memballoon = ET.Element("memballoon", model="virtio")
    ET.SubElement(new_memballoon, "address", type="pci", domain="0x0000", bus="0x00", slot="0x04", function="0x0")
    
    # Append the new memballoon node to devices
    devices.append(new_memballoon)

def replace_input_nodes(root):
    # Find the devices node
    devices = root.find("devices")
    if devices is None:
        raise ValueError("No 'devices' node found in the XML structure")

    # Remove all existing input nodes
    input_nodes = devices.findall("input")
    for input_node in input_nodes:
        devices.remove(input_node)
    
    # Create the new input nodes
    new_input_mouse = ET.Element("input", type="mouse", bus="ps2")
    new_input_keyboard = ET.Element("input", type="keyboard", bus="ps2")
    
    # Append the new input nodes to devices
    devices.append(new_input_mouse)
    devices.append(new_input_keyboard)
    
def replace_serial_node(root):
    # Find the devices node
    devices = root.find("devices")
    if devices is None:
        raise ValueError("No 'devices' node found in the XML structure")

    # Remove all existing serial nodes
    serial_nodes = devices.findall("serial")
    for serial_node in serial_nodes:
        devices.remove(serial_node)
    
    # Create the new serial node
    new_serial = ET.Element("serial", type="pty")
    target = ET.SubElement(new_serial, "target", type="isa-serial", port="0")
    ET.SubElement(target, "model", name="isa-serial")
    
    # Append the new serial node to devices
    devices.append(new_serial)
        
def manipulate_xml(xml_input):
    logger.info("@@@@ Starting XML manipulation")
    
    modified_xml = update_xml(xml_input)
    
    return modified_xml

if __name__ == "__main__":
    xml_input = sys.stdin.read()
    result = manipulate_xml(xml_input)
    print(result)
