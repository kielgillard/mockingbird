//
//  FileGenerator.swift
//  MockingbirdCli
//
//  Created by Andrew Chang on 8/5/19.
//  Copyright © 2019 Bird Rides, Inc. All rights reserved.
//

import Foundation
import PathKit

// swiftlint:disable leading_whitespace

class FileGenerator {
  let mockableTypes: [String: MockableType]
  let targetName: String
  let outputPath: Path
  let shouldImportModule: Bool
  let preprocessorExpression: String?
  init(_ mockableTypes: [String: MockableType],
       for targetName: String,
       outputPath: Path,
       shouldImportModule: Bool,
       preprocessorExpression: String?) {
    self.mockableTypes = mockableTypes
    self.targetName = targetName
    self.outputPath = outputPath
    self.shouldImportModule = shouldImportModule
    self.preprocessorExpression = preprocessorExpression
  }
  
  var formattedDate: String {
    let date = Date()
    let format = DateFormatter()
    format.dateStyle = .short
    format.timeStyle = .none
    format.locale = Locale(identifier: "en_US")
    return format.string(from: date)
  }
  
  var outputFilename: String {
    return outputPath.components.last ?? "MockingbirdMocks.generated.swift"
  }
  
  private func generateFileHeader() -> String {
    let preprocessorDirective: String
    if let expression = preprocessorExpression {
      preprocessorDirective = "\n#if \(expression)\n"
    } else {
      preprocessorDirective = ""
    }
    
    var moduleImports = [
      "@testable import Mockingbird",
      "import Foundation"
    ]
    if shouldImportModule { moduleImports.insert("@testable import \(targetName)", at: 0) }
    
    return """
    //
    //  \(outputFilename)
    //  \(targetName)
    //
    //  Generated by Mockingbird on \(formattedDate).
    //  DO NOT EDIT
    //
    \(preprocessorDirective)
    \(moduleImports.joined(separator: "\n"))
    """
  }
  
  func generateFileBody() -> String {
    return mockableTypes
      .map({ $0.value })
      .sorted(by: <)
      .map({ $0.generate() })
      .joined(separator: "\n\n")
  }
  
  private func generateFileFooter() -> String {
    return (preprocessorExpression != nil ? "\n#endif\n" : "")
  }
  
  private func generateFileContents() -> String {
    return """
    \(generateFileHeader())
    
    \(generateFileBody())
    \(generateFileFooter())
    """
  }
  
  func generate() throws {
    try outputPath.write(generateFileContents(), encoding: .utf8)
  }
}