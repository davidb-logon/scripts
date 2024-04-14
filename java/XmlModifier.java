import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamResult;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;
import java.io.StringReader;
import java.io.StringWriter;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.transform.OutputKeys;
import javax.xml.transform.TransformerException;
import org.xml.sax.InputSource;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.io.IOException;


public class XmlModifier {

    public String modifyXml(String xmlInput) throws Exception {
        // Parse the input XML string to a Document object
        DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
        DocumentBuilder builder = factory.newDocumentBuilder();
        Document document = builder.parse(new InputSource(new StringReader(xmlInput)));

        // Modify the 'domain' element attributes
        Element domain = (Element) document.getElementsByTagName("domain").item(0);
        domain.setAttribute("type", "qemu");
        // domain.setAttribute("id", "14");

        // Replace the CPU element entirely
        replaceCpuElement(document, domain);

        // Modify the OS element
        replaceOsElement(document, domain);

        // Adjust the vCPU element
        replaceVcpuElement(document, domain);

        // Add the resource element
        addResourceElement(document, domain);

        // Replace devices entirely
        replaceDevicesElement(document, domain);

        // Transform the Document back into a string
        TransformerFactory transformerFactory = TransformerFactory.newInstance();
        Transformer transformer = transformerFactory.newTransformer();
        transformer.setOutputProperty(OutputKeys.INDENT, "yes");
        DOMSource source = new DOMSource(document);

        StringWriter writer = new StringWriter();
        StreamResult result = new StreamResult(writer);
        transformer.transform(source, result);

        return writer.toString();
    }

    private void replaceCpuElement(Document doc, Element domain) {
        NodeList cpus = doc.getElementsByTagName("cpu");
        if (cpus.getLength() > 0) {
            Node cpu = cpus.item(0);
            domain.removeChild(cpu);
        }

        Element newCpu = doc.createElement("cpu");
        newCpu.setAttribute("mode", "custom");
        newCpu.setAttribute("match", "exact");
        newCpu.setAttribute("check", "full");
        Element model = doc.createElement("model");
        model.setAttribute("fallback", "forbid");
        model.setTextContent("qemu64");
        newCpu.appendChild(model);
        createFeature(doc, newCpu, "hypervisor");
        createFeature(doc, newCpu, "lahf_lm");
        domain.appendChild(newCpu);
    }

    private void replaceOsElement(Document doc, Element domain) {
        NodeList oss = doc.getElementsByTagName("os");
        if (oss.getLength() > 0) {
            Node os = oss.item(0);
            domain.removeChild(os);
        }

        Element newOs = doc.createElement("os");
        Element type = doc.createElement("type");
        type.setAttribute("arch", "x86_64");
        type.setAttribute("machine", "pc-i440fx-5.1");
        type.setTextContent("hvm");
        newOs.appendChild(type);
        Element boot = doc.createElement("boot");
        boot.setAttribute("dev", "hd");
        newOs.appendChild(boot);
        domain.appendChild(newOs);
    }

    private void replaceVcpuElement(Document doc, Element domain) {
        NodeList vcpus = doc.getElementsByTagName("vcpu");
        if (vcpus.getLength() > 0) {
            Node vcpu = vcpus.item(0);
            domain.removeChild(vcpu);
        }

        Element newVcpu = doc.createElement("vcpu");
        newVcpu.setAttribute("placement", "static");
        newVcpu.setTextContent("1");
        domain.appendChild(newVcpu);
    }

    private void addResourceElement(Document doc, Element domain) {
        Element resource = doc.createElement("resource");
        Element partition = doc.createElement("partition");
        partition.setTextContent("/machine");
        resource.appendChild(partition);
        domain.appendChild(resource);
    }

    private void replaceDevicesElement(Document doc, Element domain) {
        NodeList devicesList = doc.getElementsByTagName("devices");
        if (devicesList.getLength() > 0) {
            Node devices = devicesList.item(0);
            domain.removeChild(devices);
        }

        Element newDevices = doc.createElement("devices");
        addEmulator(doc, newDevices);
        addMemballoon(doc, newDevices);
        addController(doc, newDevices, "usb", "piix3-uhci", 0, "0x00", "0x01", "0x2");
        addController(doc, newDevices, "pci", "pci-root", 0, "0x0000", "0x00", "0x00");
        addSerialConsole(doc, newDevices, "/dev/pts/1");
        domain.appendChild(newDevices);
    }

    private void createFeature(Document doc, Element parent, String name) {
        Element feature = doc.createElement("feature");
        feature.setAttribute("policy", "require");
        feature.setAttribute("name", name);
        parent.appendChild(feature);
    }

    private void addEmulator(Document doc, Element devices) {
        Element emulator = doc.createElement("emulator");
        emulator.setTextContent("/usr/local/bin/qemu-system-x86_64");
        devices.appendChild(emulator);
    }

    private void addMemballoon(Document doc, Element devices) {
        Element memballoon = doc.createElement("memballoon");
        memballoon.setAttribute("model", "virtio");
        Element alias = doc.createElement("alias");
        alias.setAttribute("name", "balloon0");
        memballoon.appendChild(alias);
        Element address = doc.createElement("address");
        address.setAttribute("type", "pci");
        address.setAttribute("domain", "0x0000");
        address.setAttribute("bus", "0x00");
        address.setAttribute("slot", "0x04");
        address.setAttribute("function", "0x0");
        memballoon.appendChild(address);
        devices.appendChild(memballoon);
    }

    private void addController(Document doc, Element devices, String type, String model, int index, String domain, String bus, String slot) {
        Element controller = doc.createElement("controller");
        controller.setAttribute("type", type);
        controller.setAttribute("index", String.valueOf(index));
        controller.setAttribute("model", model);
        Element alias = doc.createElement("alias");
        alias.setAttribute("name", type);
        controller.appendChild(alias);
        Element address = doc.createElement("address");
        address.setAttribute("type", "pci");
        address.setAttribute("domain", domain);
        address.setAttribute("bus", bus);
        address.setAttribute("slot", slot);
        controller.appendChild(address);
        devices.appendChild(controller);
    }

    private void addSerialConsole(Document doc, Element devices, String path) {
        Element serial = doc.createElement("serial");
        serial.setAttribute("type", "pty");
        Element source = doc.createElement("source");
        source.setAttribute("path", path);
        serial.appendChild(source);
        Element target = doc.createElement("target");
        target.setAttribute("type", "isa-serial");
        target.setAttribute("port", "0");
        serial.appendChild(target);
        Element model = doc.createElement("model");
        model.setAttribute("name", "isa-serial");
        target.appendChild(model);
        Element alias = doc.createElement("alias");
        alias.setAttribute("name", "serial0");
        serial.appendChild(alias);
        devices.appendChild(serial);

        Element console = doc.createElement("console");
        console.setAttribute("type", "pty");
        console.setAttribute("tty", path);
        Element consoleSource = doc.createElement("source");
        consoleSource.setAttribute("path", path);
        console.appendChild(consoleSource);
        Element consoleTarget = doc.createElement("target");
        consoleTarget.setAttribute("type", "serial");
        consoleTarget.setAttribute("port", "0");
        console.appendChild(consoleTarget);
        Element consoleAlias = doc.createElement("alias");
        consoleAlias.setAttribute("name", "serial0");
        console.appendChild(consoleAlias);
        devices.appendChild(console);
    }

    public static void main(String[] args) {
        XmlModifier modifier = new XmlModifier();
        Path filePath = Paths.get("/home/davidb/logon/systemvm-from-cs.xml");
        String xmlInput="";
        try {
            xmlInput = Files.readString(filePath);
            //System.out.println("File content: " + content);
        } catch (IOException e) {
            System.err.println("Cannot read the file: " + e.getMessage());
        }
        
        try {
            // if name does not start with "i-"
            String modifiedXml = modifier.modifyXml(xmlInput);
            System.out.println(modifiedXml);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
