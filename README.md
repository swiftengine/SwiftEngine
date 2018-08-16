# SwiftEngine.io
Completely Autonoumous and Downtime Resilient Serverside-Swift Platform for App Development

## Features

* ___Swift on Back-End___ - Improve productivity by using the modern Swift language for all your app's development needs ([learn more](/TechnicalOverview.md))
* ___Auto compilation___ - Increase the speed of your endpoints as each file is individually compiled. If a file has not been modified since it was last used, it won't need to be recompiled ([learn more](/TechnicalOverview.md))
* ___Automated Routing Logic___ - Avoid writing custom routers; SwiftEngine will automagically route each request to the desired file ([learn more](/TechnicalOverview.md))
* ___Uptime Resiliency___ - Reduce risk by leveraging a fail-safe and high-availability operating environment where each client requests functions independently ([learn more](/TechnicalOverview.md))
* ___Easy web based run-time error analysis___ - Save time by not having to dig through shell dumps; SwiftEngine displays the full error trace on your browser for easy debugging ([learn more](/TechnicalOverview.md))


## Getting Started
These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See deployment for notes on how to deploy the project on a live system.

## Prerequisites
What are the dependencies we need to get this to work?  

OS  | Version
------------- | -------------
macOS | 10.13+
Ubuntu  | 14.04, 16.04, 16.10

## Getting started with the project
1. Clone this repo: `git clone https://github.com/swiftengine/SwiftEngine.git`
2. `cd` to `SwiftEngine` directory and run `sudo ./install.sh`
3. Run `./run.sh`
This should start the server running and listening on port `8887`

## Using

Programming your site:
1. From the browser, enter the following url `http://<machine_ip>:8887` (by default this is `localhost:8887`)
2. Make edits to your site by editing `/var/swiftengine/www/default.swift`
3. Any swift file you place in `/var/swiftengine/www` will be accessible through the browser without the `.swift` extension

## Built With
* __SwiftNIO__

## Contributing
Please read CONTRIBUTING.md for details on our code of conduct, and the process for submitting pull requests to us.
Contributing to SwiftEngine Project:

1. Fork the repo by clicking the button at the top left of the screen
2. After it has finished forking, click the green "Clone or download" button, copy the URL displayed, and enter the command `git clone [URL]`
3. Make the changes you wish and push them back to your repo
4. Submit a pull request

## Authors
* Spartak Buniatyan - Founder - [SpartakB](https://github.com/spartakb)
* Brandon Holden - Developer - [brandon-holden](https://github.com/brandon-holden)

## License
This project is licensed under the Mozilla Public License Version 2.0 - see the LICENSE.md file for details
