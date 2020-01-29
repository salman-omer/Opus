#!/usr/bin/swift

import Foundation


func readFile(_ path: String) -> Int {

    let text = "some text"

    if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
        
        print("doing some sick file stuff")

        let fileURL = dir.appendingPathComponent(path)

        print(fileURL)
        //writing
        do {
            try text.write(to: fileURL, atomically: false, encoding: .utf8)
        }
        catch{ print("AAAAH")}

        //reading
        do {
            let text2 = try String(contentsOf: fileURL, encoding: .utf8)
            print(text2)
        }
        catch {print("big problem boys")}


    }
    return 0
}

readFile("Capstone/sample.txt")