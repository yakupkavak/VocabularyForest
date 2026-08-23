//
//  GetZipRequestModel.swift
//  Domain
//
//  Created by Yakup Kavak on 30.05.2026.
//

public struct GetZipRequestModel {
    public let remotePath: String

    public init(remotePath: String) {
        self.remotePath = remotePath
    }
}
