# Oxford

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
![Swift 2.1.1](https://img.shields.io/badge/Swift-2.1.1-orange.svg) ![platforms](https://img.shields.io/badge/platforms-iOS%20%7C%20OS%20X-lightgrey.svg)

Oxford is a streaming CSV parser written in Swift. It’s currently at an alpha stage, and it’s possible it will never progress beyond that. _Caveat clonor_.

## Usage

```swift
let csv = try! CSV(path: NSBundle.mainBundle.pathForResource("test", ofType: "csv")!)
for line in csv.rows {
    print(line["Name"])
}

```

## TODO

* Quoting isn’t implemented yet
* CSV generation
* Tests
* Documentation
* Cool logo
* Everythying, really

