//
//  HelloWorldView.swift
//  businesscard
//
//  Created by Jules on 20/06/25.
//

import SwiftUI

struct HelloWorldView: View {
    @ObservedObject var viewModel: HelloWorldViewModel

    var body: some View {
        VStack {
            Spacer()
            Text(viewModel.greeting)
                .font(.largeTitle)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct HelloWorldView_Previews: PreviewProvider {
    static var previews: some View {
        HelloWorldView(viewModel: HelloWorldViewModel())
    }
}
