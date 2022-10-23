import Foundation

// MARK: - ECHO

let __DEBUG = true
func dprint(_ message: @autoclosure () -> [Any]) {
    guard __DEBUG else { return }
    print(message())
}

func dprint(_ message: @autoclosure () -> Any) {
    guard __DEBUG else { return }
    print(message())
}

let __DRY_RUN = true
func dry_runnable(
    _ name: @autoclosure () -> String,
    _ action: () throws -> Void
) rethrows {
    guard !__DRY_RUN else {
        print("dry_run_skip: \(name())")
        return
    }
    try action()
}

// MARK: - CLI

@discardableResult
func safeShell(_ command: String) throws -> String {
    let task = Process()
    task.arguments = ["-c", command]
    task.executableURL = URL(fileURLWithPath: "/bin/zsh")

    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = pipe
    task.standardInput = nil

    try task.run()

    let taskData = pipe.fileHandleForReading.readDataToEndOfFile()
    let taskDataString = String(data: taskData, encoding: .utf8)!

    return taskDataString
}

func getHashesCommand(_ searchString: String) -> String {
    """
    git log --format=format:"%H" --all --full-history -- "*\(searchString)*"
    """
}

func showFilesCommand(_ hash: String) -> String {
    """
    git show --pretty="" --name-only \(hash)
    """
}

func showFilesAtHashCommand(hash: String, file: String) -> String {
    """
    git show \(hash) -- \(file)
    """
}

func copyFileAtHashCommand(file: String, target: String) -> String {
    let fileURL = URL(string: file)!
    let parent = fileURL.deletingLastPathComponent().path
    let fileName = fileURL.lastPathComponent
    let copyTarget = "\(target)/\(parent)"

    return """
    mkdir -p \(copyTarget)
    cp \(file) \(copyTarget)/\(fileName)
    """
}

func checkoutAndMoveCommand(
    file: String,
    hash: String,
    hashPrefix: String,
    target: String
) -> String {
    let hashDirectory = "\(target)/\(hashPrefix)\(hash)"
    let hashFile = "\(hashDirectory)/\(file)"
    let copyFileAtHash = copyFileAtHashCommand(file: file, target: hashFile)

    return """
    git checkout \(hash) -- \(file)
    \(copyFileAtHash)
    """
}

// MARK: - SCRIPT CODE

func getHashesList(_ searchString: String) throws -> [String] {
    try safeShell(getHashesCommand(searchString))
        .components(separatedBy: CharacterSet.newlines)
}

func getUniqueFiles(hash: String, _ searchString: String) throws -> [String] {
    let filesCommand = showFilesCommand(hash)
    let commitFiles = try safeShell(filesCommand)
        .components(separatedBy: CharacterSet.newlines)

    let unique = commitFiles
        .reduce(into: [String: Int]()) { $0[$1] = 1 }
        .keys
        .filter { $0.contains(searchString) }

    return unique
}

func findFiles(_ searchString: String, savingHashesTo searchResultTargetPath: String) throws {
    let hashes = try getHashesList(searchString)

    for (index, hash) in hashes.enumerated() {
        let uniqueFileNames = try getUniqueFiles(hash: hash, searchString)
        guard !uniqueFileNames.isEmpty else { continue }

        let copyCommands = uniqueFileNames.map {
            dprint("- found [\(hash)]: \($0)")

            return checkoutAndMoveCommand(
                file: $0,
                hash: hash,
                hashPrefix: "\(index)_",
                target: searchResultTargetPath
            )
        }

        for copyTarget in copyCommands {
            try dry_runnable("copy-file \(hash)") {
                try safeShell(copyTarget)
            }
        }
    }
}

// MARK: - RUN

enum CLIError: Error {
    case badArgs(
        searchString: String? = nil,
        copyTargetDirectory: String? = nil
    )
}

func main() throws {
    let args = CommandLine.arguments

    var indexArgumentMap = [Int: String]()
    for (argumentIndex, argument) in args.enumerated() {
        indexArgumentMap[argumentIndex] = argument
    }

    let searchString = indexArgumentMap[1]
    let targetPath = indexArgumentMap[2]

    guard let searchString = searchString,
          let targetPath = targetPath
    else { throw CLIError.badArgs(
        searchString: searchString,
        copyTargetDirectory: targetPath
    ) }

    dprint("Searching for files in history with part: \(searchString)")
    dprint("Saving results to: \(targetPath)")

    try findFiles(searchString, savingHashesTo: targetPath)
}

do {
    try main()
} catch {
    print(error)
}
