# SwiftEngine.io
Serveless-Swift Platform for App Development

## Features
* ___Swift on Back-End___ - Improve productivity by using the modern Swift language for all your app development needs
* ___Uptime Resiliency___ - Reduce risk by leveraging a fail-safe and high-availability operating environment where each client request functions independently
* ___API Support___ - Save time and increase productivity by leveraging popular API interfaces out of the box
* ___Automated Routing Logic___ - 
* ___Auto compilation___ - 
* ___Easy web based compilation and run-time error analysis___ -

## Getting Started
These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See deployment for notes on how to deploy the project on a live system.

## Prerequisites
What are the dependencies we need to get this to work?  

OS  | Version
------------- | -------------
OSX | 10.13.2
Linux  | 14.04
Linux  | 16.04
Linux  | 16.10

## Installing
Installing and starting the server:
1. `wget -qO se swiftengine.io/se && sudo bash se` # install swiftengine

Programming your site:
1. From the browser, enter the following url `http://<machine_ip>:8887`
2. Make edits to your site by editing `/var/swiftengine/www/default.swift`
3. Any swift file you place in `/var/swiftengine/www` will be accessible through the browser without the `.swift` extension

## Built With
* __SwiftNIO__

## Contributing
Please read CONTRIBUTING.md for details on our code of conduct, and the process for submitting pull requests to us.
Contributing to SwiftEngine Project:

1. git clone `git clone https://github.com/brandon-holden/SwiftEngine.git`
    1. `git checkout dev`
2. run following command to install `sudo ./install.sh`
3. run following command to start the SwiftEngine server `./run.sh`

## Authors
* Spartak Buniatyan - Founder - [SpartakB](https://github.com/spartakb)
* Branden Holden - Developer - [brandone-holden](https://github.com/brandon-holden)

## License
This project is licensed under the Mozilla Public License Version 2.0 - see the LICENSE.md file for details
