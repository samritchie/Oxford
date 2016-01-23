/*
* Copyright © 2016 Sam Ritchie
*
* Permission is hereby granted, free of charge, to any person obtaining a copy of
* this software and associated documentation files (the "Software"), to deal in
* the Software without restriction, including without limitation the rights to
* use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
* of the Software, and to permit persons to whom the Software is furnished to do
* so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import Foundation

// MARK:- Extensions

extension String {
    func splitLine() -> [String] {
        // TODO: manage commas in quoted string elements.
        return self.componentsSeparatedByString(",")
            .map { $0.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: " \""))  }
    }
}

extension NSInputStream {
    func sequence(bufferSize: Int = 1024) -> BufferSequence {
        return BufferSequence(stream: self, bufferSize: bufferSize)
    }
    
    func lines() -> LineSequence {
        return LineSequence(buffer: sequence())
    }
}

// MARK:- SequenceTypes

struct BufferSequence: SequenceType {
    private let stream: NSInputStream
    private let bufferSize: Int
    
    func generate() -> AnyGenerator<[UInt8]> {
        stream.open()
        return anyGenerator {
            while self.stream.hasBytesAvailable {
                var buffer = [UInt8].init(count: self.bufferSize, repeatedValue: 0)
                let len = self.stream.read(&buffer, maxLength: buffer.count)
                if len > 0 {
                    return Array(buffer[0..<len])
                }
            }
            return nil
        }
    }
}

struct LineSequence: SequenceType {
    private let buffer: BufferSequence
    
    func generate() -> AnyGenerator<String> {
        var remaining: [UInt8] = []
        let bufferGenerator = buffer.generate()
        return anyGenerator {
            // TODO: handle CRLF in quotes
            if !remaining.contains(0x0A) {
                if let next = bufferGenerator.next() {
                    remaining = remaining + next
                }
            }
            while let firstChar = remaining.first where firstChar == 0x0A || firstChar == 0x0D {
                remaining.removeFirst()
            }
            if remaining.count == 0 { return nil }
            if let endLineIndex = remaining.indexOf(0x0D) ?? remaining.indexOf(0x0A) {
                let line = Array(remaining.prefixUpTo(endLineIndex))
                remaining.removeFirst(line.count)
                return self.convertToString(line)
            } else {
                let str = self.convertToString(remaining)
                remaining.removeAll()
                return str
            }
        }
    }
    
    private func convertToString(bytes: [UInt8]) -> String {
        var bytes = bytes
        let data = NSData(bytes: &bytes, length: bytes.count)
        // TODO: handle different file encodings
        return NSString(data: data, encoding: NSASCIIStringEncoding) as! String
    }
}

// MARK:- public types

public enum CSVError: ErrorType {
    case FileSystemError
    case EncodingError
    case FileEmptyError
    case FieldCountError
}

public struct CSVSequence: SequenceType {
    private let lineSequence: LineSequence
    
    init(lineSequence: LineSequence) {
        self.lineSequence = lineSequence
    }
    
    public init(path: String) throws {
        if let stream = NSInputStream(fileAtPath: path) {
            self.init(lineSequence: stream.lines())
        } else {
            throw CSVError.FileSystemError
        }
    }
    
    public func generate() -> AnyGenerator<[String: String]> {
        let lineGenerator = lineSequence.generate()
        guard let firstLine = lineGenerator.next() else { return anyGenerator(EmptyGenerator<[String: String]>()) }
        let headers = firstLine.splitLine()
        
        return anyGenerator {
            // TODO: How can we indicate failure if we hit invalid data at this point?
            guard let next = lineGenerator.next() else { return nil }
            let line = next.splitLine()
            return zip(headers, line).reduce([:]) { (acc: [String: String], p: (String, String)) in
                var dict = acc
                dict[p.0] = p.1
                return dict
            }
        }
    }
}
