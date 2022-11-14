//
//  Person.swift
//  Project10.1
//
//  Created by Maks Vogtman on 21/09/2022.
//

import UIKit

// What if we want to hold an array of people? Well, the solution is to create a custom class.

// NSObject is what's called a universal base class for all Cocoa Touch classes. That means all UIKit classes ultimately come from NSObject, including all of UIKit.

// NSCoding is a great way to read and write data when using UserDefaults, and is the most common option when you must write Swift code that lives alongside Objective-C code.

// However, if you’re only writing Swift, the Codable protocol is much easier. We already used it to load petition JSON back in project 7, but now we’ll be loading and saving JSON.

// There are three primary differences between the two solutions:

// 1. The Codable system works on both classes and structs. We made Person a class because NSCoding only works with classes, but if you didn’t care about Objective-C compatibility you could make it a struct and use Codable instead.

// 2. When we implemented NSCoding in the previous chapter we had to write encode() and init() calls ourself. With Codable this isn’t needed unless you need more precise control - it does the work for you.

// 3. When you encode data using Codable you can save to the same format that NSCoding uses if you want, but a much more pleasant option is JSON – Codable reads and writes JSON natively.

// All three of those combined means that you can define a struct to hold data, and have Swift create instances of that struct directly from JSON with no extra work from you.

// Let’s modify the Person class so that it conforms to Codable:

class Person: NSObject, Codable {
    
    var name: String
    var image: String
    
    init(name: String, image: String) {
        self.name = name
        self.image = image
    }
}

// …and that’s it. Yes, just adding Codable to the class definition is enough to tell Swift we want to read and write this thing. So, now we can go back to ViewController.swift and add code to load and save the people array.
