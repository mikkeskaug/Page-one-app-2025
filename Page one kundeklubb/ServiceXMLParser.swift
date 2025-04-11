//
//  ServiceXMLParser.swift
//  Page one kundeklubb
//
//  Created by Service on 05/02/2025.
//

import Foundation
// 📌 XML Parser for Extracting `<ServiceStatus>` Field
class ServiceXMLParser: NSObject, XMLParserDelegate {
    var currentElement = ""
    var currentFieldName = ""
    var xmlStages: [String: String] = [:]

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName

        if elementName == "field", let fieldName = attributeDict["name"] {
            currentFieldName = fieldName
            print("🆕 Found field: \(fieldName)")
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let trimmedString = string.trimmingCharacters(in: .whitespacesAndNewlines)

        if ["XMLmottatt", "XMLventerDeler", "XMLunderRep", "XMLferdig", "Deler", "Faktura_belop"].contains(currentFieldName) {
            xmlStages[currentFieldName] = trimmedString
            print("✅ Found Value: \(currentFieldName) = \(trimmedString)")
        }
    }
}
