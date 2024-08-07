import groovy.xml.*

def transform(String xml) {
    // Parse the existing XML
    def xmlParser = new XmlParser(false, false)
    def domain = xmlParser.parseText(xml)

    def vmName = domain.name.text()
    println "@@@@ Inside trasformer.groovy -- VM Name: ${vmName}"

    return xml

    // Example: Change domain type to 'kvm' from 'qemu'
    domain.@type = 'kvm'

    // Example: Add a custom disk element
    def devices = domain.devices[0]
    def newDisk = new Node(devices, 'disk')
    newDisk.@type = 'file'
    newDisk.@device = 'disk'
    new Node(newDisk, 'driver', [name: 'qemu', type: 'qcow2'])
    new Node(newDisk, 'source', [file: '/var/lib/libvirt/images/custom-disk.qcow2'])
    new Node(newDisk, 'target', [dev: 'vdb', bus: 'virtio'])
    new Node(newDisk, 'address', [type: 'pci', domain: '0x0000', bus: '0x00', slot: '0x05', function: '0x0'])

    // Example: Change network interface model
    def networkInterface = devices.interface[0]
    networkInterface.model[0].@type = 'virtio'

    // Serialize the modified XML back to a string
    def xmlOutput = new StringWriter()
    def printer = new XmlNodePrinter(new PrintWriter(xmlOutput))
    printer.setPreserveWhitespace(true)
    printer.print(domain)

    return xmlOutput.toString()
}
