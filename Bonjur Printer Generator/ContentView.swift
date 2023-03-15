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
            
            HStack{
                
                GroupBox(label: Text("Add a printer manually").font(.title)) {
                    VStack {
                        TextField("Printer name", text: $viewModel.name)
                        
                        TextField("Manufacturer", text: $viewModel.manufacturer)
                        
                        TextField("Model", text: $viewModel.model)
                        
                        Button(action: viewModel.didTapAdd){
                            Label("Add in list", systemImage: "rectangle.stack.badge.plus")
                        }
                        .padding(.top)
                        .disabled(viewModel.addingDisabled)
                    }.padding()
                }
                
            }
            .padding()
            
            GroupBox(label: Text("Printer list").font(.title)) {
                HStack(spacing: 5){
                    Spacer()
                    Button(action: {
                        guard let url = viewModel.showOpenPanel() else {return}
                        viewModel.didTapLoad(url)
                    }){
                        Label("Open", systemImage: "square.and.arrow.up")
                    }
                    
                    
                    Button(action: {
                        guard let url = viewModel.showSavePanel() else {return}
                        viewModel.didTapSave(url)
                    }){
                        Label("Save", systemImage: "square.and.arrow.down")
                    }
                    .disabled(viewModel.servers.isEmpty)
                    
                    Button(action: viewModel.didTapClear){
                        Label("Clear", systemImage: "trash")
                    }
                    .disabled(viewModel.servers.isEmpty)
                    
                    Button(action: viewModel.didTapStartAll){
                        Label("Start all", systemImage: "play.fill")
                    }
                    .disabled(viewModel.servers.isEmpty)
                    
                    Button(action: viewModel.didTapStopAll){
                        Label("Stop all", systemImage: "stop.fill")
                    }
                    .disabled(viewModel.servers.isEmpty)
                    
                }
                .buttonStyle(.bordered)
                List(viewModel.servers, id: \.hashValue){server in
                    ServerCellView(server: server)
                        .contextMenu {
                            Button("Delete",  action: {viewModel.didTapRemove(server)})
                        }
                }
            }
            .padding()
            .frame(minWidth: 600,  minHeight: 200)
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
                    Text(server.printer.name)
                        .font(.title3)
                    Text(
                        "Manufacturer: \(server.printer.manufacturerText) - Model: \(server.printer.modelText) ")
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
