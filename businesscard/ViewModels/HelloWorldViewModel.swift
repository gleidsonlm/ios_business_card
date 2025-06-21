//
//  HelloWorldViewModel.swift
//  businesscard
//
//  Created by Jules on 20/06/25.
//

import Foundation

class HelloWorldViewModel: ObservableObject {
    @Published var greeting: String = "Hello, World!"
}
