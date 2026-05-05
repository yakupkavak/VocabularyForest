//
//  GetAnimal.swift
//  Domain
//
//  Created by Codex on 4.05.2026.
//

import Alamofire
import CoreAPI
import Foundation
import YakoSwift
import zlib

@DefaultInit
public enum GetAnimal: EndPoint {

    case animal(_ value: GetAnimalRequestModel, baseURL: String)

    public var baseURL: String {
        switch self {
        case .animal(_, let baseURL):
            return baseURL
        }
    }

    public var path: String {
        switch self {
        case .animal(let model, _):
            return model.animalPath
        }
    }

    public var method: HTTPMethod {
        .get
    }

    var parameters: [String: Any] {
        [:]
    }

    public var headers: [String: String] {
        [:]
    }
}

public struct AnimalBundleModel: Sendable {
    public let archiveData: Data
    public let manifest: AnimalBundleManifest

    public init(archiveData: Data, manifest: AnimalBundleManifest) {
        self.archiveData = archiveData
        self.manifest = manifest
    }
}

public struct AnimalBundleManifest: Codable, Sendable {
    public let bundleId: String?
    public let version: String?
    public let format: String?
    public let posterFrame: String?
    public let animations: [String: [String]]

    public init(
        bundleId: String?,
        version: String?,
        format: String?,
        posterFrame: String?,
        animations: [String: [String]]
    ) {
        self.bundleId = bundleId
        self.version = version
        self.format = format
        self.posterFrame = posterFrame
        self.animations = animations
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        bundleId = try container.decodeIfPresent(String.self, forKey: .bundleId)
        version = try container.decodeIfPresent(String.self, forKey: .version)
        format = try container.decodeIfPresent(String.self, forKey: .format)
        posterFrame = try container.decodeIfPresent(String.self, forKey: .posterFrame)
        animations = try container.decodeIfPresent([String: [String]].self, forKey: .animations) ?? [:]
    }

    enum CodingKeys: String, CodingKey {
        case bundleId
        case version
        case format
        case posterFrame
        case animations
    }
}

public extension GetAnimal {
    static func decode(data: Data) throws -> AnimalBundleModel {
        let manifestData = try ZipArchiveDecoder.manifestData(from: data)
        let manifest = try JSONDecoder().decode(AnimalBundleManifest.self, from: manifestData)
        return AnimalBundleModel(archiveData: data, manifest: manifest)
    }
}

enum AnimalBundleDecodeError: LocalizedError {
    case archiveIsEmpty
    case endOfCentralDirectoryNotFound
    case centralDirectoryNotFound
    case invalidCentralDirectoryEntry
    case manifestEntryNotFound
    case localFileHeaderNotFound
    case unsupportedCompressionMethod(UInt16)
    case inflateFailed(Int32)
    case invalidFileName

    var errorDescription: String? {
        switch self {
        case .archiveIsEmpty:
            return "Animal archive is empty."
        case .endOfCentralDirectoryNotFound:
            return "Animal archive end record was not found."
        case .centralDirectoryNotFound:
            return "Animal archive central directory could not be read."
        case .invalidCentralDirectoryEntry:
            return "Animal archive contains an invalid central directory entry."
        case .manifestEntryNotFound:
            return "Animal archive manifest.json could not be found."
        case .localFileHeaderNotFound:
            return "Animal archive local file header could not be read."
        case .unsupportedCompressionMethod(let method):
            return "Animal archive compression method \(method) is not supported."
        case .inflateFailed(let code):
            return "Animal archive inflate failed with code \(code)."
        case .invalidFileName:
            return "Animal archive contains an invalid file name."
        }
    }
}

private enum ZipArchiveDecoder {
    private static let endOfCentralDirectorySignature: UInt32 = 0x06054b50
    private static let centralDirectorySignature: UInt32 = 0x02014b50
    private static let localFileHeaderSignature: UInt32 = 0x04034b50
    private static let storedMethod: UInt16 = 0
    private static let deflatedMethod: UInt16 = 8
    private static let minimumEndOfCentralDirectorySize = 22
    private static let maximumCommentLength = 65_535
    private static let centralDirectoryHeaderSize = 46
    private static let localFileHeaderSize = 30

    static func manifestData(from archiveData: Data) throws -> Data {
        guard !archiveData.isEmpty else {
            throw AnimalBundleDecodeError.archiveIsEmpty
        }

        let endRecordOffset = try locateEndRecord(in: archiveData)
        let centralDirectory = try readCentralDirectory(from: archiveData, endRecordOffset: endRecordOffset)
        guard let manifestEntry = centralDirectory.first(where: { isManifestPath($0.fileName) }) else {
            throw AnimalBundleDecodeError.manifestEntryNotFound
        }

        return try extract(entry: manifestEntry, from: archiveData)
    }

    private static func locateEndRecord(in data: Data) throws -> Int {
        guard data.count >= minimumEndOfCentralDirectorySize else {
            throw AnimalBundleDecodeError.endOfCentralDirectoryNotFound
        }

        let lowerBound = max(0, data.count - minimumEndOfCentralDirectorySize - maximumCommentLength)
        for offset in stride(from: data.count - minimumEndOfCentralDirectorySize, through: lowerBound, by: -1) {
            if data.uint32(at: offset) == endOfCentralDirectorySignature {
                return offset
            }
        }

        throw AnimalBundleDecodeError.endOfCentralDirectoryNotFound
    }

    private static func readCentralDirectory(from data: Data, endRecordOffset: Int) throws -> [CentralDirectoryEntry] {
        guard let entryCount = data.uint16(at: endRecordOffset + 10),
              let directoryOffset = data.uint32(at: endRecordOffset + 16) else {
            throw AnimalBundleDecodeError.centralDirectoryNotFound
        }

        var entries: [CentralDirectoryEntry] = []
        var cursor = Int(directoryOffset)

        for _ in 0..<Int(entryCount) {
            guard data.uint32(at: cursor) == centralDirectorySignature,
                  let compressionMethod = data.uint16(at: cursor + 10),
                  let compressedSize = data.uint32(at: cursor + 20),
                  let uncompressedSize = data.uint32(at: cursor + 24),
                  let fileNameLength = data.uint16(at: cursor + 28),
                  let extraFieldLength = data.uint16(at: cursor + 30),
                  let fileCommentLength = data.uint16(at: cursor + 32),
                  let localHeaderOffset = data.uint32(at: cursor + 42) else {
                throw AnimalBundleDecodeError.invalidCentralDirectoryEntry
            }

            let fileNameStart = cursor + centralDirectoryHeaderSize
            let fileNameEnd = fileNameStart + Int(fileNameLength)
            guard let fileNameData = data.slice(from: fileNameStart, length: Int(fileNameLength)),
                  let fileName = String(data: fileNameData, encoding: .utf8) else {
                throw AnimalBundleDecodeError.invalidFileName
            }

            entries.append(
                CentralDirectoryEntry(
                    fileName: fileName,
                    compressionMethod: compressionMethod,
                    compressedSize: Int(compressedSize),
                    uncompressedSize: Int(uncompressedSize),
                    localHeaderOffset: Int(localHeaderOffset)
                )
            )

            cursor = fileNameEnd + Int(extraFieldLength) + Int(fileCommentLength)
        }

        return entries
    }

    private static func extract(entry: CentralDirectoryEntry, from data: Data) throws -> Data {
        let headerOffset = entry.localHeaderOffset
        guard data.uint32(at: headerOffset) == localFileHeaderSignature,
              let fileNameLength = data.uint16(at: headerOffset + 26),
              let extraFieldLength = data.uint16(at: headerOffset + 28) else {
            throw AnimalBundleDecodeError.localFileHeaderNotFound
        }

        let dataOffset = headerOffset + localFileHeaderSize + Int(fileNameLength) + Int(extraFieldLength)
        guard let compressedData = data.slice(from: dataOffset, length: entry.compressedSize) else {
            throw AnimalBundleDecodeError.localFileHeaderNotFound
        }

        switch entry.compressionMethod {
        case storedMethod:
            return compressedData
        case deflatedMethod:
            return try inflate(data: compressedData, expectedSize: entry.uncompressedSize)
        default:
            throw AnimalBundleDecodeError.unsupportedCompressionMethod(entry.compressionMethod)
        }
    }

    private static func inflate(data: Data, expectedSize: Int) throws -> Data {
        if data.isEmpty {
            return Data()
        }

        var stream = z_stream()
        let windowBits = -MAX_WBITS
        let status = inflateInit2_(&stream, windowBits, ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size))
        guard status == Z_OK else {
            throw AnimalBundleDecodeError.inflateFailed(status)
        }

        defer {
            inflateEnd(&stream)
        }

        let minimumCapacity = 1_024
        var output = Data(count: max(expectedSize, minimumCapacity))
        let inflateStatus: Int32 = try data.withUnsafeBytes { inputBuffer in
            guard let inputBaseAddress = inputBuffer.bindMemory(to: Bytef.self).baseAddress else {
                throw AnimalBundleDecodeError.inflateFailed(Z_DATA_ERROR)
            }

            stream.next_in = UnsafeMutablePointer(mutating: inputBaseAddress)
            stream.avail_in = uInt(data.count)

            var currentStatus: Int32 = Z_OK

            repeat {
                if Int(stream.total_out) >= output.count {
                    output.count += max(expectedSize, minimumCapacity)
                }

                let outputOffset = Int(stream.total_out)
                let availableOutput = output.count - outputOffset

                currentStatus = try output.withUnsafeMutableBytes { outputBuffer in
                    guard let outputBaseAddress = outputBuffer.bindMemory(to: Bytef.self).baseAddress else {
                        throw AnimalBundleDecodeError.inflateFailed(Z_MEM_ERROR)
                    }

                    stream.next_out = outputBaseAddress.advanced(by: outputOffset)
                    stream.avail_out = uInt(availableOutput)
                    return zlib.inflate(&stream, Z_NO_FLUSH)
                }

                if currentStatus != Z_OK && currentStatus != Z_STREAM_END {
                    throw AnimalBundleDecodeError.inflateFailed(currentStatus)
                }
            } while currentStatus != Z_STREAM_END

            return currentStatus
        }

        guard inflateStatus == Z_STREAM_END else {
            throw AnimalBundleDecodeError.inflateFailed(inflateStatus)
        }

        output.count = Int(stream.total_out)
        return output
    }

    private static func isManifestPath(_ path: String) -> Bool {
        path == "manifest.json" || path.hasSuffix("/manifest.json")
    }
}

private struct CentralDirectoryEntry {
    let fileName: String
    let compressionMethod: UInt16
    let compressedSize: Int
    let uncompressedSize: Int
    let localHeaderOffset: Int
}

private extension Data {
    func uint16(at offset: Int) -> UInt16? {
        guard offset >= 0, offset + 2 <= count else { return nil }
        return withUnsafeBytes { buffer in
            let baseAddress = buffer.baseAddress?.assumingMemoryBound(to: UInt8.self)
            guard let baseAddress else { return nil }
            let lower = UInt16(baseAddress[offset])
            let upper = UInt16(baseAddress[offset + 1]) << 8
            return lower | upper
        }
    }

    func uint32(at offset: Int) -> UInt32? {
        guard offset >= 0, offset + 4 <= count else { return nil }
        return withUnsafeBytes { buffer in
            let baseAddress = buffer.baseAddress?.assumingMemoryBound(to: UInt8.self)
            guard let baseAddress else { return nil }
            let byte0 = UInt32(baseAddress[offset])
            let byte1 = UInt32(baseAddress[offset + 1]) << 8
            let byte2 = UInt32(baseAddress[offset + 2]) << 16
            let byte3 = UInt32(baseAddress[offset + 3]) << 24
            return byte0 | byte1 | byte2 | byte3
        }
    }

    func slice(from offset: Int, length: Int) -> Data? {
        guard offset >= 0, length >= 0, offset + length <= count else { return nil }
        return subdata(in: offset..<(offset + length))
    }
}
