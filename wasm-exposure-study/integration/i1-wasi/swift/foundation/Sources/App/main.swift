// What the Swift documentation leads to first: Foundation's FileHandle.
import Foundation

let data = FileHandle.standardInput.readDataToEndOfFile()
FileHandle.standardOutput.write(data)
