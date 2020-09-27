import Foundation

class AutoListValueDict<Key: Hashable, Value> {
    var map = [Key: Array<Value>]()
    subscript(index: Key) -> [Value] {
        get {
            return (map[index] ?? {
                let collection = [Value]()
                map[index] = collection
                return collection
            }())
        }
        set(newValue) {
            map[index] = newValue
        }
    }
}
