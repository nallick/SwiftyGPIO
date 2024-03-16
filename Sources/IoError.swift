/*
 SwiftyGPIO

 Copyright (c) 2017 Umberto Raimondi
 Licensed under the MIT license, as follows:

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.)
 */

#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif
import Foundation

// To enable tracing errors back to the line of code where the error is thrown build your SwiftyGPIO client with the command:
//
//    swift build -Xswiftc -DTRACE_GPIO_ERRORS
//
// For example: "Couldn't open the I2C device, in openI2C() at line 409 of I2C.swift: No such file or directory"
// Instead of: "Couldn't open the I2C device: No such file or directory"
//
// This includes static strings of file paths and function names in your code, which can increase the build size by ~20K.
// In this case, the file name, function name, and line number will be logged before an uncaught error aborts the program.
// However, be aware this leaks the file paths of your build system as text within your compiled executable file,
// which might reveal details such as your home directory (and therefore your user name).
//

extension SwiftyGPIO {

    public static var abortLoggingFunction: (String) -> Void = { if errno != 0 { perror($0) } else { print($0) }}

    internal static func abort(logging error: Error) -> Never {
        SwiftyGPIO.abortLoggingFunction("\(error)")
#if os(Linux)
        Glibc.abort()
#else
        Darwin.abort()
#endif
    }

    // MARK: - IoError
    public struct IoError: Error, CustomStringConvertible {

        public enum ErrorType {
            case open
            case read
            case write
            case ioControl
            case valueUndefined
            case internalError
        }

        public let type: ErrorType
        public let detail: String

        #if TRACE_GPIO_ERRORS

        public let functionTrace: StaticString
        public let fileTrace: StaticString
        public let lineTrace: UInt

        public var description: String {
            let filename: String.SubSequence = fileTrace.description.split(separator: "/").last ?? "<unknown>"
            return "\(detail), in \(functionTrace) at line \(lineTrace) of \(filename)"
        }

        public init(_ type: ErrorType, detail: String,
                    function: StaticString = #function, file: StaticString = #file, line: UInt = #line) {
            self.type = type
            self.detail = detail
            self.functionTrace = function
            self.fileTrace = file
            self.lineTrace = line
        }

        #else

        public var description: String {
            return detail
        }

        public init(_ type: ErrorType, detail: String) {
            self.type = type
            self.detail = detail
        }

        #endif
    }
}
