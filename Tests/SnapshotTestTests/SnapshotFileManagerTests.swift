//
//  SnapshotFileManagerTests.swift
//  SnapshotTest
//
//  Copyright © 2017 SnapshotTest. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  1. Redistributions of source code must retain the above copyright notice,
//  this list of conditions and the following disclaimer.
//
//  2. Redistributions in binary form must reproduce the above copyright notice,
//  this list of conditions and the following disclaimer in the documentation and/or
//  other materials provided with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
//  IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
//  INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
//  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
//  OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
//  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
//  OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

@testable import SnapshotTest
import XCTest

class SnapshotFileManagerTests: XCTestCase {
    
    var sut: SnapshotFileManager!
    
    var fileManagerMock: FileManagerMock!
    var dataHandlerMock: DataHandlerMock!
    var processInfo: ProcessEnvironmentMock!

    let testImage = createTestImageInCode()
    // let testImage = UIImage(testFilename: "redSquare", ofType:  "png")!

    class func createTestImageInCode() -> UIImage {
        // $ openssl base64 -in redSquare.png
        let str =  "iVBORw0KGgoAAAANSUhEUgAAAGQAAABkCAYAAABw4pVUAAAAAXNSR0IArs4c6QAAABxpRE9UAAAAAgAAAAAAAAAyAAAAKAAAADIAAAAyAAAA9cAyiXQAAADBSURBVHgB7NWhEQAxEMPA67/p/HwDxgILgsyike7e3fM6f3BgdGD8LACJFQIQQFqJqCWbIQxhyLKSIQxhCENiFgACiCwtC9bmqMfsAQQQOZOsmAWAACJLy4K1OeoxewABRM4kK2YBIIDI0rJgbY56zB5AAJEzyYpZAAggsrQsWJujHrMHEEDkTLJiFgACiCwtC9bmqMfsAQQQOZOsmAWAACJLy4K1OeoxewABRM4kK2YBIIDI0rJgbY56zB5AYkA+AAAA///FySv9AAAAvklEQVTt1aERADEQw8Drv+n8fAPGAguCzKKR7t7d8zp/cGB0YPwsAIkVAhBAWomoJZshDGHIspIhDGEIQ2IWAAKILC0L1uaox+wBBBA5k6yYBYAAIkvLgrU56jF7AAFEziQrZgEggMjSsmBtjnrMHkAAkTPJilkACCCytCxYm6MeswcQQORMsmIWAAKILC0L1uaox+wBBBA5k6yYBYAAIkvLgrU56jF7AAFEziQrZgEggMjSsmBtjnrMHkBiQD5Kb9Zk9Tk5jQAAAABJRU5ErkJggg=="
        let data = NSData(base64Encoded: str)
        return UIImage(data: data! as Data)!
    }

    override func setUp() {
        super.setUp()

        fileManagerMock = FileManagerMock()
        dataHandlerMock = DataHandlerMock()
        processInfo = ProcessEnvironmentMock()
        sut = SnapshotFileManager(fileManager: fileManagerMock, dataHandler: dataHandlerMock, processInfo: processInfo)
    }
    
    override func tearDown() {
        sut = nil
        fileManagerMock = nil
        dataHandlerMock = nil
        processInfo = nil
        super.tearDown()
    }
    
    func testSnapshotFileManager_byDefault_shouldHaveFileManagerBeDefaultFileManager() {
        // Given
        sut = SnapshotFileManager()
        
        // Then
        XCTAssertEqual(sut.fileManager, FileManager.default)
    }
    
    func testSnapshotFileManager_byDefault_shouldHaveDataWriterBeInstanceOfDataWriter() {
        // Given
        sut = SnapshotFileManager()
        
        // Then
        XCTAssertTrue(sut.dataHandler is DataHandler)
    }
    
    func testSnapshotFileManager_byDefault_shouldHaveProcessToBeProcessInfoFromProcessInfo() {
        // Given
        sut = SnapshotFileManager()
        
        // Then
        XCTAssert(sut.processInfo === ProcessInfo.processInfo as ProcessEnvironment)
    }

    // MARK: Save
    
    func testSave_withReferenceImageDirectoryAsEnvironmentalVariable_shouldCheckIfDirectoryExists() throws {
        // Given
        let referenceImageDirectory = "/Environmental/Variable/ReferenceImages"
        processInfo.environment["REFERENCE_IMAGE_DIR"] = referenceImageDirectory

        // When
        try sut.save(referenceImage: testImage, filename: "filename-doesnt-matter-in-this-test", className: "CustomViewTests")
        
        // Then
        XCTAssertEqual(fileManagerMock.fileExistsInvokeCount, 1)
        XCTAssertEqual(fileManagerMock.fileExistsPathArgument, "file:///Environmental/Variable/ReferenceImages/CustomViewTests")
    }

    func testSave_withReferenceImageDirectoryDoesNotExist_shouldCreateDirectory() throws {
        // Given
        let referenceImageDirectory = "/NonExistingDirectory"
        processInfo.environment["REFERENCE_IMAGE_DIR"] = referenceImageDirectory
        fileManagerMock.fileExistsReturnValue = false
        
        // When
        try sut.save(referenceImage: testImage, filename: "filename-doesnt-matter-in-this-test", className: "CustomViewTests")
        
        // Then
        XCTAssertEqual(fileManagerMock.createDirectoryInvokeCount, 1)
        XCTAssertEqual(fileManagerMock.createDirectoryUrlArgument, URL(fileURLWithPath: "/NonExistingDirectory/CustomViewTests"))
    }
    
    func testSave_withReferenceImageDirectoryDoesExist_shouldNotCreateDirectory() throws {
        // Given
        let referenceImageDirectory = "/ExistingDirectory"
        processInfo.environment["REFERENCE_IMAGE_DIR"] = referenceImageDirectory
        fileManagerMock.fileExistsReturnValue = true
        
        // When
        try sut.save(referenceImage: testImage, filename: "filename-doesnt-matter-in-this-test", className: "CustomViewTests")
        
        // Then
        XCTAssertEqual(fileManagerMock.createDirectoryInvokeCount, 0)
    }
    
    func testSave_withReferenceImageDirectoryDoesExist_shouldWriteDataToCorrectPath() throws {
        // Given
        processInfo.environment["REFERENCE_IMAGE_DIR"] = "/ReferenceImageDirectory"
        fileManagerMock.fileExistsReturnValue = true
        
        // When
        try sut.save(referenceImage: testImage, filename: "testFunctionName", className: "CustomViewTests")
        
        // Then
        XCTAssertEqual(dataHandlerMock.writeInvokeCount, 1)
        XCTAssertEqual(dataHandlerMock.writePathArgument, URL(fileURLWithPath: "/ReferenceImageDirectory/CustomViewTests/testFunctionName.png"))
    }
    
    func testSave_withReferenceImageDirectoryDoesExist_shouldReturnPathToSavedFile() throws {
        // Given
        processInfo.environment["REFERENCE_IMAGE_DIR"] = "/ReferenceImageDirectory"
        fileManagerMock.fileExistsReturnValue = true
        
        // When
        let path = try sut.save(referenceImage: testImage, filename: "testFunctionName", className: "CustomViewTests")
        
        // Then
        XCTAssertEqual(path, URL(fileURLWithPath: "/ReferenceImageDirectory/CustomViewTests/testFunctionName.png"))
    }

    // MARK: Reference Image
    
    func testReferenceImage_forFunctionName_shouldWriteDataToCorrectPath() throws {
        // Given
        processInfo.environment["REFERENCE_IMAGE_DIR"] = "/ReferenceImageDirectory"
        fileManagerMock.fileExistsReturnValue = true

        // let testImage = UIImage(testFilename: "redSquare", ofType: "png")!
        // $ openssl base64 -in redSquare.png
        let str =  "iVBORw0KGgoAAAANSUhEUgAAAGQAAABkCAYAAABw4pVUAAAAAXNSR0IArs4c6QAAABxpRE9UAAAAAgAAAAAAAAAyAAAAKAAAADIAAAAyAAAA9cAyiXQAAADBSURBVHgB7NWhEQAxEMPA67/p/HwDxgILgsyike7e3fM6f3BgdGD8LACJFQIQQFqJqCWbIQxhyLKSIQxhCENiFgACiCwtC9bmqMfsAQQQOZOsmAWAACJLy4K1OeoxewABRM4kK2YBIIDI0rJgbY56zB5AAJEzyYpZAAggsrQsWJujHrMHEEDkTLJiFgACiCwtC9bmqMfsAQQQOZOsmAWAACJLy4K1OeoxewABRM4kK2YBIIDI0rJgbY56zB5AYkA+AAAA///FySv9AAAAvklEQVTt1aERADEQw8Drv+n8fAPGAguCzKKR7t7d8zp/cGB0YPwsAIkVAhBAWomoJZshDGHIspIhDGEIQ2IWAAKILC0L1uaox+wBBBA5k6yYBYAAIkvLgrU56jF7AAFEziQrZgEggMjSsmBtjnrMHkAAkTPJilkACCCytCxYm6MeswcQQORMsmIWAAKILC0L1uaox+wBBBA5k6yYBYAAIkvLgrU56jF7AAFEziQrZgEggMjSsmBtjnrMHkBiQD5Kb9Zk9Tk5jQAAAABJRU5ErkJggg=="
        let data = NSData(base64Encoded: str)
        let testImage = UIImage(data: data! as Data)!

        // When
        try sut.save(referenceImage: testImage, filename: "testFunctionName", className: "CustomViewTests")
        
        // Then
        XCTAssertEqual(dataHandlerMock.writeInvokeCount, 1)
        XCTAssertEqual(dataHandlerMock.writePathArgument, URL(fileURLWithPath: "/ReferenceImageDirectory/CustomViewTests/testFunctionName.png"))
    }
    
}
