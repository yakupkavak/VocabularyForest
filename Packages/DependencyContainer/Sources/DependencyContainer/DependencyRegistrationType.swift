//
//  DependencyRegistrationType.swift
//  DependencyContainer
//
//  Created by Yakup Kavak on 21.03.2026.
//

import Foundation

public enum DependencyContainerRegistrationType {
    case singleInstance(AnyObject)
    case closureBased(() -> Any)
}
