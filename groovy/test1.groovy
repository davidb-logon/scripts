
import groovy.xml.*

def xmlFile = new File('systemvm-1.xml')
def xml = new XmlParser().parse(xmlFile)
println "changing systemvm-1.xml"
// Change domain type
xml.@type = 'qemu'

// Change architecture
def osType = xml.os.type[0]
osType.@arch = 'x86_64'
osType.@machine = 'pc-i440fx-5.1'

// Write changes back to the file
def writer = new StringWriter()
def printer = new XmlNodePrinter(new PrintWriter(writer))
printer.setPreserveWhitespace(true)
printer.print(xml)

xmlFile.withWriter('UTF-8') { out ->
    out.write(writer.toString())
}

println 'XML updated successfully'
