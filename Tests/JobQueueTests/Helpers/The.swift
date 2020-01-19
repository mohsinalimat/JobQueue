//
//  File.swift
//  
//
//  Created by George Cox on 1/20/20.
//

import Foundation
import Quick

public func the(_ description: String, flags: FilterFlags = [:], file: FileString = #file, line: UInt = #line, closure: @escaping () -> Void) {
  it(description, flags: flags, file: file, line: line, closure: closure)
}
