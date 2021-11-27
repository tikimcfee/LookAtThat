// sweet spot
// -------------------

private let workerCount = 3
private lazy var concurrentWorkers =
    (0 ..< workerCount).map { DispatchQueue(
        label: "WorkerQC\($0)",
        qos: .userInteractive,
        attributes: .concurrent,
        autoreleaseFrequency: .workItem
    ) }

func nextConcurrentWorker() -> DispatchQueue {
    return concurrentWorkerIterator.next() ?? {
        concurrentWorkerIterator = concurrentWorkers.makeIterator()
        let next = concurrentWorkerIterator.next()!
        return next
    }()
}
