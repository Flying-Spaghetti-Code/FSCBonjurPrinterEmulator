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
        VStack{
            GroupBox(label: Text("Add a printer").font(.title)) {
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
                        .contextMenu {
                            Button("Delete",  action: {viewModel.didTapRemove(server)})
                        }
                }
            }
            .padding()
            .frame(minWidth: 600,  minHeight: 200)
            HStack{
                Button("Clear", action: viewModel.didTapClear)
                    .padding()
                    .disabled(viewModel.servers.isEmpty)
                Button("Start all", action: viewModel.didTapStartAll)
                    .padding()
                    .disabled(viewModel.servers.isEmpty)
                Button("Stop All", action: viewModel.didTapStopAll)
                    .padding()
                    .disabled(viewModel.servers.isEmpty)
                
            }
            .frame(minHeight: 80)
        }
    }
}


struct ServerCellView : View {
    @ObservedObject var server: BonjourServer
    var body: some View {
        VStack{
            HStack {
                Image(systemName: "printer.fill")
                    .padding(10)
                    .background(Color.blue)
                    .cornerRadius(8)
                    .padding()
                VStack(alignment: .leading,spacing: 3 ) {
                    Text(server.name)
                        .font(.title3)
                    Text(
                        "Manufacturer: \(server.manifacturer.isEmpty ? "[EMPTY!]" : server.manifacturer) - Model: \(server.model.isEmpty ? "[EMPTY!]" : server.model) ")
                        .font(.caption)
                        
                    
                    HStack(alignment: .center, spacing: 3) {
                        Text("•")
                            .font(.title)
                            .foregroundColor(server.status.color)
                        
                        Text(server.status.description)
                            .font(.caption)
                        
                            
                    }.padding(.top, -8)
                    
                }
                Spacer()
                Toggle( server.isRunning ? "Stop" : "Start", isOn: $server.isRunning )
                    .toggleStyle(.button)
                
                
            }
            Divider()
        }
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
