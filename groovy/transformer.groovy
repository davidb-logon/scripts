import groovy.xml.*
import java.text.SimpleDateFormat
import java.util.Date

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

    return inputXml
}
