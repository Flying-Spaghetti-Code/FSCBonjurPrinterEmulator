//
//  ContentView.swift
//  Bonjur Printer Generator
//
//  Created by Giovanni Trovato on 10/10/22.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel = ContentViewModel()
    var body: some View {
        GroupBox(label: Text("Simulated printers")) {
            VStack {
                TextField("Printer name", text: $viewModel.name)
                    .padding(.top)
                TextField("Manufacturer", text: $viewModel.manufacturer)
                    .padding(.top)
                TextField("Model", text: $viewModel.model)
                    .padding(.vertical)
                Button("Add in list", action: viewModel.didTapAdd)
                    .padding()
                    .disabled(viewModel.addingDisabled)
            }.padding()
        }
        .padding()
        GroupBox(label: Text("Printer list")) {
            List(viewModel.servers, id: \.hashValue){server in
                ServerCellView(server: server)
            }
            
        }
        .padding()
    }
}


struct ServerCellView : View {
    var server: BonjourServer
    var body: some View {
        HStack {
            Image(systemName: "printer.fill")
//                .cornerRadius(7)
                .padding(8) // Width of the border
                .background(Color.blue) // Color of the border
                .cornerRadius(8) // Outer corner radius
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
