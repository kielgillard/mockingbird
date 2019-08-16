//
//  MockGenerator.swift
//  MockingbirdCli
//
//  Created by Andrew Chang on 8/6/19.
//  Copyright © 2019 Bird Rides, Inc. All rights reserved.
//

import Foundation

// swiftlint:disable leading_whitespace

private enum Constants {
  static let objectProtocolPrefixes = Set(["NS", "CB", "UI"])
  static let mockProtocolName = "MockingbirdMock"
}

extension MockableType {
  func generate() -> String {
    return """
    // MARK: - Mocked \(name)
    
    public final class \(name)Mock: \(allInheritedTypes) {
      static let staticMock = \(name)StaticMock()
      public let mockingContext = MockingbirdMockingContext()
      public let stubbingContext = MockingbirdStubbingContext()
    
    \(body)
    }
    """
  }
  
  var allInheritedTypes: String {
    return [subclass,
            inheritedProtocol,
            Constants.mockProtocolName]
      .compactMap({ $0 })
      .joined(separator: ", ")
  }
  
  var subclass: String? {
    guard kind != .class else { return name }
    let prefix = String(name.prefix(2))
    if Constants.objectProtocolPrefixes.contains(prefix) {
      return "NSObject"
    } else {
      return nil
    }
  }
  
  var inheritedProtocol: String? {
    guard kind == .protocol else { return nil }
    return name
  }
  
  var body: String {
    return [allVariables,
            equatableConformance,
            codeableInitializer,
            allMethods,
            staticMock].filter({ !$0.isEmpty }).joined(separator: "\n\n")
  }
  
  var equatableConformance: String {
    return """
      public static func ==(lhs: \(name)Mock, rhs: \(name)Mock) -> Bool {
        return true
      }
    """
  }
  
  var codeableInitializer: String {
    guard inheritedTypes.contains(where: { $0.name == "Codable" || $0.name == "Decodable" }) else {
      return ""
    }
    guard !methods.contains(where: { $0.name == "init(from:)" }) else { return "" }
    return """
      public required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
      }
    """
  }
  
  var allVariables: String {
    return variables.map({ $0.generate(in: self) }).joined(separator: "\n\n")
  }
  
  var allMethods: String {
    return methods.map({ $0.generate(in: self) }).joined(separator: "\n\n")
  }
  
  var staticMock: String {
    return """
      internal final class \(name)StaticMock: MockingbirdMock {
        public let mockingContext = MockingbirdMockingContext()
        public let stubbingContext = MockingbirdStubbingContext()
      }
    """
  }
  
  func specializeTypeName(_ typeName: String, unwrapOptional: Bool = false) -> String {
    guard typeName != "Self" else { return name }
    guard unwrapOptional, typeName.hasSuffix("?") else { return typeName }
    return typeName.replacingOccurrences(of: "?", with: "")
  }
}