import Foundation

func fileData(_ name: String, _ type: String = "") -> Data {
    return fileHandle(name, type)?.availableData ?? Data()
}

func fileHandle(_ name: String, _ type: String = "") -> FileHandle? {
    guard let filepath = Bundle.main.path(
        forResource: name, ofType: type
    ) else { return nil }

    return FileHandle(forReadingAtPath: filepath)
}

extension Array {
    func slices(sliceSize: Int) -> [ArraySlice<Element>] {
        return (0...(count / sliceSize)).reduce(into: [ArraySlice<Element>]()) { result, slicePosition in
            let sliceStart = slicePosition * sliceSize
            let sliceEnd = Swift.min(sliceStart + sliceSize, count)
            result.append(self[sliceStart..<sliceEnd])
        }
    }
}
