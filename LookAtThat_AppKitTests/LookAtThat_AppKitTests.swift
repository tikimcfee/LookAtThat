import XCTest
import SwiftSyntax
import SwiftParser
import SceneKit
@testable import LookAtThat_AppKit

class LookAtThat_AppKitTests: XCTestCase {

	var bundle: TestBundle!

    override func setUpWithError() throws {
        // Fields reset on each test!
        bundle = TestBundle()
		try bundle.setUpWithError()
    }

    override func tearDownWithError() throws {
		try bundle.tearDownWithError()
    }

    func test_runningAWorker() throws {
        printStart()
        let expectation = XCTestExpectation(description: "The worker runs")

        let worker = BackgroundWorker()
        worker.run {
            print("Hey there folks, I'm '\(Thread.current)'.")
            expectation.fulfill()
            print("What a funny thing to code against. 'Fulfill expectation'. Heh.")
            worker.stop()
        }

        wait(for: [expectation], timeout: 3)
        printEnd()
    }

    func test_writingStreams() throws {
        printStart()

        let worker = BackgroundWorker()

        let dataDecoded = XCTestExpectation(description: "Data decoded")
        let decodeData = { (data: Data) in
            let inputStream = InputStream(data: data)
            inputStream.schedule(in: .current, forMode: .default)
            inputStream.open()

            let reader = InputStreamReader(stream: inputStream)
            let outputData = try! reader.readData()
            let outputString = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(outputData) as? String

            print("So what did we write?:\n\t", outputString as Any)

            inputStream.close()
            dataDecoded.fulfill()
        }

        let dataEncoded = XCTestExpectation(description: "Data encoded")
        worker.run {
            let outputStream = OutputStream.toMemory()
            outputStream.schedule(in: .current, forMode: .default)
            outputStream.open()

            let message = "Thanks, internet person: https://gist.github.com/lucasecf/bde1d9bd3492f29b7534"
            let data = try! NSKeyedArchiver.archivedData(withRootObject: message, requiringSecureCoding: false)
            let writtenData = outputStream.writeDataWithBoundPointer(data)
            print("Well. It wrote: \(writtenData)")

            decodeData(data)

            outputStream.close()
            dataEncoded.fulfill()
        }

        wait(for: [dataEncoded, dataDecoded], timeout: 10)
        printEnd()
    }
	
	func testSemanticBuilder() {
		
	}
    
    func testKeyboardInterecptor() {
        
    }
}


enum TestLine {
    case none
    case message(String)
}

func printSeparator() {
    print(Array(repeating: "-", count: 22).joined())
}

func printStart(_ testLine: TestLine = .none) {
    print("------------------------------- Starting -------------------------------\n\n")
    switch testLine {
    case .none: break
    case .message(let message): print(message)
    }
}

func printEnd(_ testLine: TestLine = .none) {
    print("\n\n------------------------------- Done -------------------------------" )
    switch testLine {
    case .none: break
    case .message(let message): print(message)
    }
}
