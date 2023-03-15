# FSCBonjurPrinterEmulator

## Introduction
Sometimes, it is hard to simulate a test environment, when there are multiple printers in the same network and, even worse, if it is needed to have: some printers with well known driver and some others with rare drivers or even exotic manufacturer. This small guide introduces Bonjur Printer Generator and explain how to setup a custom environment for testing all the ezeep Blue clients that offers the "Nearby printing" feature.


## Summary
Bonjur Printer Generator is a small tool that generates fake printers in the network and allows the user to start / stop them, all together or e separately. This guide is focused on iOS client, but the principles, described below, are universal and they can be applied to all clients. For the screenshots is used macOS Ventura 13.1. Please take care to find the proper setting on your macOS version.

## Requirements
Unfortunately this tool runs just on macOS 12.0 and newer.

## Procedure
First of all download Bonjur Printer Generator zip and extract it in a folder: 

The program is stand alone and doesn't need to be installed but, if you want, you may move it into Application folder
open it just double clicking. if it doesn't run you may need to allow the run permission for macOS 
Open settings under privacy & security and select AppStore and identified developer.

Follow the guide: Open a Mac app from an unidentified developer
You can finally launch the application safely. From now on it will be enough just double clicking on the icon . You should be able to see the main screen:

You can add a single printer just filling the "Printer name", "Manufacturer" and "Model" fields than tapping on "Add in list"

Then start it clicking on "start" or "start all". the current state of the single printing service is visible below the printer manufacturer and model

Once your list is complete. you can also save it and restore for another session using save and load functionalities 
if you prefer to create bunch of fake printers at once, you may also create a json file like this:


## Printer list example
```json
[
 {
  "name" : "HP OfficeJet R45",
  "manufacturer" : "HP",
  "model" : "OfficeJet R45"
 },
 {
  "name" : "HP No match",
  "manufacturer" : "HP",
  "model" : "No match"
 },
 {
  "name" : "Ugly Manufacturer pro",
  "manufacturer" : "Ugly Manufacturer",
  "model" : "pro"
 },
 {
  "name" : "Empty fields"
 }
]
```

Once done just Load the list tapping on open button and selecting the just created json file (Remember, the file must have a .json extension). One important thing to keep in mind is that when you have open a json file the current list is overwritten.
