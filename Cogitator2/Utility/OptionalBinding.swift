//
//  OptionalBinding.swift
//  Cogitator2
//
//  Created by Danilo Campos on 10/27/23.
//

import SwiftUI

func ??<T>(lhs: Binding<Optional<T>>, rhs: T) -> Binding<T> {
    Binding(
        get: { lhs.wrappedValue ?? rhs },
        set: { lhs.wrappedValue = $0 }
    )
}
