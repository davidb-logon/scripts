import groovy.xml.*
import java.text.SimpleDateFormat
import java.util.Date
//import org.apache.log4j.Logger



// Define the log file path


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

def transform(String inputXml) {
    // Parse the input XML
    def parsedInputXml = new XmlParser().parseText(inputXml)
    
    // Extract the name and uuid from the input XML
    def name = parsedInputXml.name.text()
    def uuid = parsedInputXml.uuid.text()
 
    writeLog("@@@@ Inside trasformer.groovy -- VM Name: ${name} uuid: ${uuid}")


    // The template XML to be modified
    def templateXml = '''<domain type='qemu'>
      <name>systemvm-1</name>
      <uuid>e4d4cb4b-2cec-4b6d-9549-cfa5cac9adfe</uuid>
      <memory unit='KiB'>1048576</memory>
      <currentMemory unit='KiB'>1048576</currentMemory>
      <vcpu placement='static'>1</vcpu>
      <os>
        <type arch='x86_64' machine='pc-i440fx-5.1'>hvm</type>
        <boot dev='hd'/>
      </os>
      <features>
        <acpi/>
        <apic/>
        <pae/>
      </features>
      <cpu mode='custom' match='exact' check='none'>
        <model fallback='forbid'>qemu64</model>
      </cpu>
      <clock offset='utc'/>
      <on_poweroff>destroy</on_poweroff>
      <on_reboot>restart</on_reboot>
      <on_crash>destroy</on_crash>
      <devices>
        <emulator>/usr/local/bin/qemu-system-x86_64</emulator>
        <disk type='file' device='disk'>
          <driver name='qemu' type='qcow2'/>
          <source file='/data/test_qemu/systemvmtemplate-4.19.1-kvm.qcow2'/>
          <target dev='vda' bus='virtio'/>
          <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x0'/>
        </disk>
        <controller type='usb' index='0' model='piix3-uhci'>
          <address type='pci' domain='0x0000' bus='0x00' slot='0x01' function='0x2'/>
        </controller>
        <controller type='pci' index='0' model='pci-root'/>
        <interface type='network'>
          <mac address='52:54:00:ad:62:fd'/>
          <source network='default'/>
          <model type='rtl8139'/>
          <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x0'/>
        </interface>
        <serial type='pty'>
          <target type='isa-serial' port='0'>
            <model name='isa-serial'/>
          </target>
        </serial>
        <console type='pty'>
          <target type='serial' port='0'/>
        </console>
        <input type='mouse' bus='ps2'/>
        <input type='keyboard' bus='ps2'/>
        <audio id='1' type='none'/>
        <memballoon model='virtio'>
          <address type='pci' domain='0x0000' bus='0x00' slot='0x04' function='0x0'/>
        </memballoon>
      </devices>
    </domain>'''

    // Parse the template XML
    def parsedTemplateXml = new XmlParser().parseText(templateXml)

    // Replace the name and uuid in the template XML
    parsedTemplateXml.name[0].value = name
    parsedTemplateXml.uuid[0].value = uuid

    // Serialize the modified XML back to a string
    def xmlOutput = new StringWriter()
    def printer = new XmlNodePrinter(new PrintWriter(xmlOutput))
    printer.setPreserveWhitespace(true)
    printer.print(parsedTemplateXml)

    writeLog "Updated XML: ${xmlOutput.toString()}"
    return { parsedTemplateXml } // xmlOutput.toString()
}

// // Example usage:
// def inputXml = '''<domain type='kvm'>
//     <name>s-2196-VM</name>
//     <uuid>b6f51660-5651-49bf-b0d6-99cc03816ab9</uuid>
//     <description>Debian GNU/Linux 5.0 (64-bit)</description>
//     <!-- Rest of the XML omitted for brevity -->
// </domain>'''

// def updatedXml = transform(inputXml)
// println updatedXml







def transform1(String xml) {
    // Parse the existing XML
    def xmlParser = new XmlParser(false, false)
    def domain = xmlParser.parseText(xml)

    def vmName = domain.name.text()
    writeLog("@@@@ Inside trasformer.groovy -- VM Name: ${vmName}")

    // return xml

    // Example: Change domain type to 'kvm' from 'qemu'
    domain.@type = 'qemu'

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
    
/*
<domain type='kvm'>
    <name>s-2196-VM</name>
    <uuid>b6f51660-5651-49bf-b0d6-99cc03816ab9</uuid>
    <description>Debian GNU/Linux 5.0 (64-bit)</description>
    <cpu></cpu>
    <sysinfo type='smbios'>
        <system>
            <entry name='manufacturer'>Apache Software Foundation</entry>
            <entry name='product'>CloudStack KVM Hypervisor</entry>
            <entry name='uuid'>b6f51660-5651-49bf-b0d6-99cc03816ab9</entry>
        </system>
    </sysinfo>
    <os>
        <type arch='x86_64' machine='pc'>hvm</type>
        <boot dev='cdrom' />
        <boot dev='hd' />
        <smbios mode='sysinfo' />
    </os>
    <on_reboot>restart</on_reboot>
    <on_poweroff>destroy</on_poweroff>
    <on_crash>destroy</on_crash>
    <memory>524288</memory>
    <currentMemory>524288</currentMemory>
    <devices>
        <memballoon model='virtio'>
            <stats period='0' />
        </memballoon>
    </devices>
    <vcpu current="1">1</vcpu>
    <features>
        <pae />
        <apic />
        <acpi />
    </features>
    <cputune>
        <shares>500</shares>
    </cputune>
    <clock offset='utc'>
        <timer name='kvmclock'>
        </timer>
    </clock>
    <devices>
        <emulator></emulator>
        <watchdog model='i6300esb' action='none' />
        <console type='pty'>
            <target port='0' />
        </console>
        <disk device='disk' type='file'>
            <driver name='qemu' type='qcow2' cache='none' />
            <source
                file='/mnt/1eb22c9a-3d86-3b7e-b2e8-36f3978df707/b68ac67e-7ded-4844-b476-98891d1f326f' />
            <target dev='vda' bus='virtio' />
            <serial>b68ac67e7ded4844b476</serial>
        </disk>
        <disk device='cdrom' type='file'>
            <driver name='qemu' type='raw' />
            <source file='' />
            <target dev='hdc' bus='ide' />
        </disk>
        <serial type='pty'>
            <target port='0' />
        </serial>
        <graphics type='vnc' autoport='yes' listen='192.168.122.1' passwd='aAtHpVGl' />
        <channel type='unix'>
            <source mode='bind' path='/var/lib/libvirt/qemu/s-2196-VM.org.qemu.guest_agent.0' />
            <address type='virtio-serial' />
            <target type='virtio' name='org.qemu.guest_agent.0' />
        </channel>
        <input type='tablet' bus='usb' />
        <interface type='bridge'>
            <source bridge='cloud0' />
            <mac address='0e:00:a9:fe:b1:bb' />
            <model type='virtio' />
            <rom bar='off' file='' />
            <link state='up' />
        </interface>
        <interface type='bridge'>
            <source bridge='cloudbr0' />
            <mac address='1e:00:09:00:00:02' />
            <model type='virtio' />
            <rom bar='off' file='' />
            <link state='up' />
        </interface>
        <interface type='bridge'>
            <source bridge='cloudbr0' />
            <mac address='1e:00:3a:00:00:13' />
            <model type='virtio' />
            <rom bar='off' file='' />
            <link state='up' />
        </interface>
    </devices>
</domain>




<domain type='qemu'>
  <name>systemvm-1</name>
  <uuid>e4d4cb4b-2cec-4b6d-9549-cfa5cac9adfe</uuid>
  <memory unit='KiB'>1048576</memory>
  <currentMemory unit='KiB'>1048576</currentMemory>
  <vcpu placement='static'>1</vcpu>
  <os>
    <type arch='x86_64' machine='pc-i440fx-5.1'>hvm</type>
    <boot dev='hd'/>
  </os>
  <features>
    <acpi/>
    <apic/>
    <pae/>
  </features>
  <cpu mode='custom' match='exact' check='none'>
    <model fallback='forbid'>qemu64</model>
  </cpu>
  <clock offset='utc'/>
  <on_poweroff>destroy</on_poweroff>
  <on_reboot>restart</on_reboot>
  <on_crash>destroy</on_crash>
  <devices>
    <emulator>/usr/local/bin/qemu-system-x86_64</emulator>
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2'/>
      <source file='/data/test_qemu/systemvmtemplate-4.19.1-kvm.qcow2'/>
      <target dev='vda' bus='virtio'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x0'/>
    </disk>
    <controller type='usb' index='0' model='piix3-uhci'>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x01' function='0x2'/>
    </controller>
    <controller type='pci' index='0' model='pci-root'/>
    <interface type='network'>
      <mac address='52:54:00:ad:62:fd'/>
      <source network='default'/>
      <model type='rtl8139'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x0'/>
    </interface>
    <serial type='pty'>
      <target type='isa-serial' port='0'>
        <model name='isa-serial'/>
      </target>
    </serial>
    <console type='pty'>
      <target type='serial' port='0'/>
    </console>
    <input type='mouse' bus='ps2'/>
    <input type='keyboard' bus='ps2'/>
    <audio id='1' type='none'/>
    <memballoon model='virtio'>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x04' function='0x0'/>
    </memballoon>
  </devices>
</domain>


*/
