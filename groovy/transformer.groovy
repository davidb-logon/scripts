def transform(String xml) {
    try {
        // Parse the original XML
        def rootNode = new XmlSlurper().parseText(xml)

        // Make your modifications here!
        // For example, let's add a custom tag to the root element:
        rootNode.appendNode {
            customTag('Hello from CloudStack!')
        }

        // Convert the modified XML back to a string
        def transformedXml = new StringWriter().with { writer ->
            new XmlNodePrinter(new PrintWriter(writer)).print(rootNode)
            writer.toString()
        }

        // Log the input and output XML
        writeLog("Input XML:\n$xml")
        writeLog("Output XML:\n$transformedXml")

        return transformedXml
    } catch (Exception e) {
        // Handle any exceptions gracefully
        println("Error transforming XML: ${e.message}")
        return xml
    }
}

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

// Example usage:
def originalXml = """
<domain>
    <!-- Your original VM XML here -->
</domain>
"""

def transformedXml = transform(originalXml)
println("Transformed XML:\n$transformedXml")
