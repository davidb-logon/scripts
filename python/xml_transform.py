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

def update_xml_for_s390x(root):
    # Change the 'type' attribute of the 'domain' element to 'kvm' for s390x
    root.set('type', 'kvm')
    
    remove_input_tablet(root)
    update_cdrom_from_ide_to_scsi(root)
    remove_watchdog_model_in_devices(root)
    update_interfaces(root)
    
    # Update the OS node to reflect s390x architecture and appropriate machine type
    os_node = root.find('os')
    if os_node is not None:
        # Remove existing 'os' node
        root.remove(os_node)
        
        # Create a new 'os' element
        new_os_node = ET.Element('os')
        
        # Create and append the 'type' element
        type_element = ET.SubElement(new_os_node, 'type', arch='s390x', machine='s390-ccw-virtio-rhel8.6.0')
        type_element.text = 'hvm'
        
        # Create and append the 'boot' element
        boot_element = ET.SubElement(new_os_node, 'boot', dev='hd')
        
        # Replace the old 'os' element with the new one
        root.append(new_os_node)

    # Replace CPU configuration with s390x specific configuration
    new_cpu = ET.Element("cpu", mode="host-model", check="partial")
    cpu_node = root.find('cpu')
    if cpu_node is not None:
        root.remove(cpu_node)
    root.append(new_cpu)
    
    # Use the memory size from the input template
    memory_node = root.find('memory')
    current_memory_node = root.find('currentMemory')
    if memory_node is not None:
        memory_node.set('unit', 'KiB')
    if current_memory_node is not None:
        current_memory_node.set('unit', 'KiB')
    
    # Update the emulator path for s390x
    devices = root.find("devices")
    if devices is not None:
        emulator_node = devices.find('emulator')
        if emulator_node is None:
            emulator_node = ET.SubElement(devices, 'emulator')
        emulator_node.text = '/usr/libexec/qemu-kvm'
    
    # Update disk and device addresses for s390x
    for disk in devices.findall('disk'):
        target = disk.find('target')
        if target is not None and target.get('bus') == 'virtio':
            disk.find('address')
            disk.remove(disk.find('address'))  # Remove existing address if any
            ET.SubElement(disk, 'address', type='ccw', cssid='0xfe', ssid='0x0', devno='0x0000')
        if target is not None and target.get('dev') == 'sda':
            target.set('bus', 'scsi')
            disk.find('address')
            disk.remove(disk.find('address'))  # Remove existing address if any
            ET.SubElement(disk, 'address', type='drive', controller='0', bus='0', target='0', unit='0')
    
    # Add controllers specific to s390x, handling existing ones
    if devices is not None:
        # Remove existing controllers if necessary
        for controller in devices.findall('controller'):
            devices.remove(controller)
            
        # Remove existing input devices if necessary
        for input_device in devices.findall('input'):
            devices.remove(input_device)

        # Add a SCSI controller
        scsi_controller = ET.SubElement(devices, 'controller', type='scsi', index='0', model='virtio-scsi')
        ET.SubElement(scsi_controller, 'address', type='ccw', cssid='0xfe', ssid='0x0', devno='0x0002')
        
        # Add a PCI controller
        pci_controller = ET.SubElement(devices, 'controller', type='pci', index='0', model='pci-root')
        
        # Add a Virtio-Serial controller
        virtio_serial_controller = ET.SubElement(devices, 'controller', type='virtio-serial', index='0')
        ET.SubElement(virtio_serial_controller, 'address', type='ccw', cssid='0xfe', ssid='0x0', devno='0x0003')

        # Update the console type to sclp for s390x
        for console in devices.findall('console'):
            target = console.find('target')
            if target is not None:
                target.set('type', 'sclp')

        # Add a RNG device, handling existing ones
        for rng in devices.findall('rng'):
            devices.remove(rng)
        rng = ET.SubElement(devices, 'rng', model='virtio')
        ET.SubElement(rng, 'backend', model='random').text = '/dev/urandom'
        ET.SubElement(rng, 'address', type='ccw', cssid='0xfe', ssid='0x0', devno='0x0005')

        # Add a panic device for s390, handling existing ones
        for panic in devices.findall('panic'):
            devices.remove(panic)
        panic = ET.SubElement(devices, 'panic', model='s390')

def remove_input_tablet(root):

    # Find all devices elements
    devices_elements = root.findall('.//devices')

    for devices in devices_elements:
        # Find all input elements within each devices element
        inputs = devices.findall('input')

        for input_element in inputs:
            # Check if the input element has the required attributes
            if input_element.attrib.get('bus') == 'usb': # and input_element.attrib.get('type') == 'tablet':
                # Remove the input element
                devices.remove(input_element)

def update_cdrom_from_ide_to_scsi(root):
    # Iterate over all 'disk' elements in 'devices'
    for devices in root.findall(".//devices"):
        for device in devices.findall('disk'):
            if (device.attrib.get('device') == 'cdrom' and 
                device.attrib.get('type') == 'file' and 
                device.find('driver').attrib.get('name') == 'qemu' and 
                device.find('driver').attrib.get('type') == 'raw' and 
                device.find('target').attrib.get('bus') == 'ide' and 
                device.find('target').attrib.get('dev') == 'hdc'):
                
                # Create the new disk element
                new_disk = ET.Element('disk', type='file', device='cdrom')
                ET.SubElement(new_disk, 'driver', name='qemu', type='raw')
                ET.SubElement(new_disk, 'target', dev='sda', bus='scsi')
                ET.SubElement(new_disk, 'readonly')
                ET.SubElement(new_disk, 'address', 
                              type='drive', controller='0', 
                              bus='0', target='0', unit='0')
                
                # Replace the old disk element with the new one
                devices.remove(device)
                devices.append(new_disk)
                
def remove_watchdog_model_in_devices(root):
    # Iterate over all 'devices' elements
    for devices in root.findall(".//devices"):
        # Find the 'watchdog' element inside each 'devices' element
        for watchdog in devices.findall('watchdog'):
            devices.remove(watchdog)
            # if watchdog.attrib.get('model') == 'i6300esb':
            #     # Replace the model attribute with 'ibm,expired-timeout'
            #     watchdog.set('model', 'ibm,expired-timeout')

def update_xml_for_x86(root):
   
    # Change the 'type' attribute of the 'domain' element to 'qemu'
    root.set('type', 'qemu')
    
    # remove_graphics(root)
    replace_os_node(root)
    replace_cpu_node(root)
    replace_memballoon_nodes(root)
    replace_input_nodes(root)
    replace_serial_node(root)
    
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

def update_interfaces(root):
     for interface in root.findall(".//interface"):
        # Find the rom element within the interface
        rom_element = interface.find("rom")
        if rom_element is not None:
            # Remove the rom element
            interface.remove(rom_element)


def manipulate_xml(xml_input):
    logger.info("@@@@ Started xml_tarnsform.py")
    logger.info("========================================================================================")
    logger.info("@@@@ xml input:\n" + xml_input)
    logger.info("========================================================================================")
    root = ET.fromstring(xml_input)
    name_node = root.find("name")
    if name_node is not None:
        # Check if the name starts with 's', 'v', or 'r', which means it is a systemVM
        name_value = name_node.text.lower()
        if name_value.startswith(('s', 'v', 'r')):
            logger.info("@@@@ Domain name: " + name_value + " will be modified for x86_64")
            #update_xml_for_x86(root)
            update_xml_for_s390x(root)
        else:
            logger.info("@@@@ Domain name: " + name_value + " will be modified for s390x")
            update_xml_for_s390x(root)
    
        # Convert the modified XML tree back to a string
        modified_xml_string = ET.tostring(root, encoding='unicode')
        logger.info("@@@@ Ended xml_transform.py, returned modified xml:\n")
        logger.info("@@@@ xml output:\n" + modified_xml_string)
        logger.info("========================================================================================")
        
        return modified_xml_string   
    else:
        logger.info("@@@@ Ended xml_transform.py, returned original xml")
        return xml_input 

if __name__ == "__main__":
    xml_input = sys.stdin.read()
    result = manipulate_xml(xml_input)
    print(result)
