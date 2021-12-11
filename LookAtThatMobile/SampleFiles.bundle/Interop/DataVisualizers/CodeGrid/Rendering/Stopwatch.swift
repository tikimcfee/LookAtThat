// Copyright (c) 2017 Kristopher Johnson
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
// CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
// TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// This module provide three implementations of a stopwatch:
//
// - ModernStopwatch: Requires iOS 10+, macOS 10.12+, tvOS 10+, watchOS 3+.
// - LegacyStopwatch: Compatible with all OS versions, but slower.
// - UnsynchronizedStopwatch: Fastest, but not thread-safe.
//
// The typealias "Stopwatch" is set to ModernStopwatch.  Change that
// if you want to use one of the other implementations by default.

// ------------------------------------------------------------------
// Hi I'm Ivan I also modified this file and am using it because I consider it
// to be a valuable, free and open contribution to the community. I appreciate
// it and apply my personal license on top of this as well, and if it turns out
// that in doing so the above Kristopher Johnson finds reasonable cause to
// rescind the license, then they have the right to do so, and the issue should
// be resolved beteween the parties as they agree. Complicated right?
// ------------------------------------------------------------------

import Foundation
import QuartzCore


// MARK:- AbstractStopwatch

/// Methods supported by an implementation of a stopwatch.
public protocol AbstractStopwatch: AnyObject {
    
    /// Start the timing operation.
    ///
    /// Any previous elapsed time is retained, and new elapsed
    /// time is added to it.
    ///
    /// Calling start() on a stopwatch that is already started has no effect.
    func start()
    
    /// Stop the timing operation.
    ///
    /// Elapsed time is retained.
    ///
    /// Calling stop() on a stopwatch that is stopped
    /// has no effect.
    func stop()
    
    /// Stop the stopwatch and reset elapsed time to zero.
    func reset()
    
    /// Reset elapsed time to zero and start the stopwatch.
    func restart()
    
    /// Return total elapsed time.
    func elapsedTimeInterval() -> CFTimeInterval
    
    /// Return true if in the "started" state, or false otherwise.
    func isRunning() -> Bool
}


// Common methods for objects that conform to AbstractStopwatch
public extension AbstractStopwatch {
    
    /// Return total elapsed time, in milliseconds.
    func elapsedMilliseconds() -> Int {
        return Int(elapsedTimeInterval() * 1000)
    }
    
    /// Return total elapsed time, in microseconds.
    func elapsedMicroseconds() -> Int {
        return Int(elapsedTimeInterval() * 1_000_000)
    }
    
    /// Return elapsed time in textual form.
    ///
    /// If elapsed time is less than a second, it will be rendered as milliseconds.
    /// Otherwise it will be rendered as seconds.
    ///
    /// - returns: `String`
    func elapsedTimeString() -> String {
        let interval = elapsedTimeInterval()
        if interval < 1.0 {
            return String(format:"%.1f ms", Double(interval * 1000))
        }
        else {
            return String(format:"%.2f s", Double(interval))
        }
    }
    
    /// Calculate the time elapsed for a block.
    ///
    /// Restarts the stopwatch, runs the block, then stops the stopwatch.
    func measure(_ block: () -> Void) {
        restart()
        block()
        stop()
    }
}


// MARK:- SynchronizedStopwatch<>

/// Protocol for a mutex object used by SynchronizedStopwatch.
public protocol StopwatchMutex {
    init()
    mutating func lock()
    mutating func unlock()
}

/// Generic implementation of AbstractStopwatch.
public class SynchronizedStopwatch<Mutex: StopwatchMutex>: AbstractStopwatch {
    
    private var mutex = Mutex()
    private var accumulatedTime: CFTimeInterval = 0
    private var isStarted: Bool
    private var startTime: CFTimeInterval
    
    /// Default constructor.
    public init() {
        isStarted = false
        startTime = 0
    }
    
    /// Constructor.
    ///
    /// - parameter running: If true, start the new stopwatch immediately.
    public init(running: Bool) {
        isStarted = running
        startTime = running ? CACurrentMediaTime() : 0
    }
    
    /// Start the timing operation.
    ///
    /// Any previous elapsed time is retained, and new elapsed
    /// time is added to it.
    ///
    /// Calling start() on a stopwatch that is already started has no effect.
    public func start() {
        mutex.lock()
        
        if !isStarted {
            isStarted = true
            startTime = CACurrentMediaTime()
        }
        
        mutex.unlock()
    }
    
    /// Stop the timing operation.
    ///
    /// Elapsed time is retained.
    ///
    /// Calling stop() on a stopwatch that is stopped
    /// has no effect.
    public func stop() {
        mutex.lock()
        
        if isStarted {
            let endTime = CACurrentMediaTime()
            accumulatedTime += endTime - startTime
            isStarted = false
        }
        
        mutex.unlock()
    }
    
    /// Stop the stopwatch and reset elapsed time to zero.
    public func reset() {
        mutex.lock()
        
        isStarted = false
        accumulatedTime = 0
        
        mutex.unlock()
    }
    
    /// Reset elapsed time to zero and start the stopwatch.
    public func restart() {
        mutex.lock()
        
        accumulatedTime = 0
        isStarted = true
        startTime = CACurrentMediaTime()
        
        mutex.unlock()
    }
    
    /// Return total elapsed time.
    public func elapsedTimeInterval() -> CFTimeInterval {
        mutex.lock()
        
        var result = accumulatedTime
        
        if isStarted {
            result += CACurrentMediaTime() - startTime
        }
        
        mutex.unlock()
        return result
    }
    
    /// Return true if stopwatch is in the "started" state.
    public func isRunning() -> Bool {
        mutex.lock()
        
        let result = isStarted
        
        mutex.unlock()
        return result
    }
    
    /// Create and start a stopwatch, run a block, then return stopped stopwatch.
    public static func measure(_ block: () -> Void) -> SynchronizedStopwatch {
        let s = SynchronizedStopwatch()
        s.measure(block)
        return s
    }
}


// MARK:- ModernStopwatch

/// Implementation of StopwatchMutex that uses os_unfair_lock.
///
/// Only available on iOS 10+ and macOS 10.12+.
@available(iOS 10, OSX 10.12, tvOS 10, watchOS 3, *)
public struct UnfairLockMutex: StopwatchMutex {
    private var unfairLock = os_unfair_lock()
    
    public init() {}
    public mutating func lock()   { os_unfair_lock_lock(&unfairLock) }
    public mutating func unlock() { os_unfair_lock_unlock(&unfairLock) }
}

/// Implementation of AbstractStopwatch that uses os_unfair_lock.
///
/// Only available on iOS 10+ and macOS 10.12+.
@available(iOS 10, OSX 10.12, tvOS 10, watchOS 3, *)
public typealias ModernStopwatch = SynchronizedStopwatch<UnfairLockMutex>


// MARK:- LegacyStopwatch

/// Implementation of StopwatchMutex that uses DispatchSemaphore.
///
/// Not as fast as UnfairLockMutex, but usable on all operating
/// system versions that Swift supports.
public struct SemaphoreMutex: StopwatchMutex {
    private var semaphore = DispatchSemaphore(value: 1)
    
    public init() {}
    public mutating func lock()   { semaphore.wait() }
    public mutating func unlock() { semaphore.signal() }
}

/// Implementation of AbstractStopwatch that uses DispatchSemaphore.
///
/// Not as fast as UnfairLockMutex, but usable on all operating
/// system versions that Swift supports.
public typealias LegacyStopwatch = SynchronizedStopwatch<SemaphoreMutex>


// MARK:- UnsynchronizedStopwatch

/// Implementation of StopwatchMutex that does not actually do any locking.
///
/// Use this for minimial overhead when thread-safety is not a concern.
public struct NoMutex: StopwatchMutex {
    public init() {}
    
    public func lock() {}
    public func unlock() {}
}

/// Implementation of AbstractStopwatch with no synchronization.
///
/// Use this for minimial overhead when thread-safety is not an issue.
public typealias UnsynchronizedStopwatch = SynchronizedStopwatch<NoMutex>


// MARK:- Stopwatch

/// Default implementation of stopwatch.
///
/// Set this to ModernStopwatch, LegacyStopwatch, or UnsynchronizedStopwatch.
public typealias Stopwatch = ModernStopwatch


// MARK:- Standalone functions

/// Start a stopwatch, run the block, stop the stopwatch, and return elapsed time.
///
/// - parameter block: Block whose execution is to be timed.
/// - returns: TimeInterval
public func measureTimeInterval(_ block: () -> Void) -> TimeInterval {
    let s = UnsynchronizedStopwatch.measure(block)
    return s.elapsedTimeInterval()
}

/// Start a stopwatch, run the block, stop the stopwatch, and return elapsed time.
///
/// - parameter block: Block whose execution is to be timed.
/// - returns: Number of milliseconds.
public func measureMilliseconds(_ block: () -> Void) -> Int {
    let s = UnsynchronizedStopwatch.measure(block)
    return s.elapsedMilliseconds()
}

/// Start a stopwatch, run the block, stop the stopwatch, and return elapsed time.
///
/// - parameter block: Block whose execution is to be timed.
/// - returns: Number of microseconds.
public func measureMicroseconds(_ block: () -> Void) -> Int {
    let s = UnsynchronizedStopwatch.measure(block)
    return s.elapsedMicroseconds()
}
