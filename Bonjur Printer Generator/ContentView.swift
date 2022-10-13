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
        GroupBox(label: Text("Add a ptinter").font(.title)) {
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
        GroupBox(label: Text("Printer list").font(.title)) {
            List(viewModel.servers, id: \.hashValue){server in
                ServerCellView(server: server)
                
            }.listStyle(.inset(alternatesRowBackgrounds: true))
            
        }
        .padding()
    }
}


struct ServerCellView : View {
    @ObservedObject var server: BonjourServer
    var body: some View {
        HStack {
            Image(systemName: "printer.fill")
                .padding(10) // Width of the border
                .background(Color.blue) // Color of the border
                .cornerRadius(8) // Outer corner radius
                .padding()
            VStack(alignment: .leading,spacing: 3 ) {
                Text(server.name)
                    .font(.title3)
                Text("Manufacturer: \(server.manifacturer) - Model: \(server.model) ")
                    .font(.caption)
                    
                
                HStack(alignment: .center, spacing: 3) {
                    Text("•")
                        .font(.title)
                        .foregroundColor(server.status.color)
                    
                    Text(server.status.description)
                        .font(.caption)
                    Spacer()
                    Toggle("start", isOn: $server.isRunning )
                        
                }.padding(.top, -8)
                Divider()
                
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
