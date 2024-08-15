import groovy.xml.*
import java.text.SimpleDateFormat
import java.util.Date

import groovy.lang.GroovyShell;
import org.codehaus.groovy.runtime.GroovySystem;


def writeLog(String msg) {
    // Get the current date and time
    def currentDate = new Date()
    def dateFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss")
    def formattedDate = dateFormat.format(currentDate)
    def logMessage = "${formattedDate} -- ${msg}\n"
    // Create the log file object
    def logFilePath = "/data/vm.log"  
    def logFile = new File(logFilePath)

    // Append the log message to the file, creating the file if it does not exist
    logFile << logMessage
    println logMessage
}

public class GroovyVersionCheck {
    public static void main(String[] args) {
        GroovyShell shell = new GroovyShell();
        String groovyVersion = GroovySystem.getVersion();
        writeLog("@@@@ Groovy Version: " + groovyVersion);

        // // Alternatively, you can execute a Groovy script that prints the version
        // shell.evaluate("println 'Groovy Version from script: ' + GroovySystem.version");
    }
}

def transform(String xml) {
    GroovyVersionCheck

    // Parse the existing XML
    writeLog("@@@@ Inside trasformer.groovy -- first line")
    def xmlParser = new XmlParser(false, false)
    writeLog("@@@@ Inside trasformer.groovy -- second line")
    def domain = xmlParser.parseText(xml)
    writeLog("@@@@ Inside trasformer.groovy -- third line domain: ${domain}")
    def vmName = domain.name.text()
    writeLog("@@@@ Inside trasformer.groovy -- VM Name: ${vmName}")

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
