[![SwiftEngine](https://i.imgur.com/X6hLAmn.jpg)](https://swiftengine.io)

### _We work for :star2:’s and :fork_and_knife:’s ... please Star our repo_

:raising_hand: __Hey there!__   
Please note: This project is still in Alpha Version and we’re actively working on forking over a lot of nifty features from SwiftEngine to make it compatible with SwiftNIO.   We appreciate any contributors or testers joining our project!

## Features :heart_eyes:

* ___Swift on Back-End___ - Improve productivity by using the modern Swift language for all your app's development needs ([learn more](/TechnicalOverview.md))
* ___Auto compilation___ - Increase the speed of your endpoints as each file is individually compiled. If a file has not been modified since it was last used, it won't need to be recompiled ([learn more](/TechnicalOverview.md))
* ___Automated Routing Logic___ - Avoid writing custom routers; SwiftEngine will automagically route each request to the desired file ([learn more](/TechnicalOverview.md))
* ___Uptime Resiliency___ - Reduce risk by leveraging a fail-safe and high-availability operating environment where each client requests functions independently ([learn more](/TechnicalOverview.md))
* ___Easy web based run-time error analysis___ - Save time by not having to dig through shell dumps; SwiftEngine displays the full error trace on your browser for easy debugging ([learn more](/TechnicalOverview.md))


## Getting Started :boom:
These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See deployment for notes on how to deploy the project on a live system.

## Prerequisites :exclamation:
What are the dependencies we need to get this to work?  

OS  | Version
------------- | -------------
macOS | 10.13+
Ubuntu  | 14.04, 16.04, 16.10

## Getting started with the project :thumbsup:

1. Clone this repo: `git clone https://github.com/swiftengine/SwiftEngine.git`
2. `cd` to `SwiftEngine` directory and run `sudo ./install.sh`
3. Run `./run.sh`
This should start the server running and listening on port `8887`

## Using :star:

Programming your site:
1. Create a new `mypage.swift` file within the `/var/swiftengine/www/` directory (see example below)
2. From the browser, enter the following url `http://<machine_ip>:8887/mypage` (by default this is `localhost:8887`)

That's it!  No compilation or dealing with shell dumps required!  Your requested endpoints will be automagically compiled during the first request, and results will be shown.

Any swift file you place in `/var/swiftengine/www` will be accessible through the browser without the `.swift` extension.
Read more about SwiftEngine's autonomous system and routing logic ([here](/TechnicalOverview.md))

## Example of a SwiftEngine based `.swift` file  :trophy:

```swift
// Import SwiftEngine essentials
import SwiftEngine


// specify other required files for this file
//se: require /common.swift

// Entry Point function; where all code begins
func entryPoint(ctx: RequestContext) {

	// add GET handlers to the request context
	ctx.addHandler(forMethod:"GET", withRoute:"*"){
		req, res in
		res.write("Hello from SwiftEngine!")
	}

	// add POST handlers to the request context
	ctx.addHandler(forMethod:"POST", withRoute:"*"){
		req, res in
		res.write("Handle for POST request method")
	}

	// add catch-all handlers to the request context
	ctx.addHandler(forMethod:"*", withRoute:"*"){
		req, res in
		res.write("Handle for catch-all")
	}

}
```

## Built With :sunny:
* [**SwiftNIO**](https://github.com/apple/swift-nio)



## Contributing :family:
We would love to hear your thoughts and feedback about SwiftEngine. If you would like to contribute to our project or have an issue you would like to open, please visit our [CONTRIBUTING](/CONTRIBUTING.md) document for more details.

## Authors :factory:
* Spartak Buniatyan - Founder - [SpartakB](https://github.com/spartakb)
* Brandon Holden - Developer - [brandon-holden](https://github.com/brandon-holden)

## Contact Us :factory:
* You can reach us at github@swiftengine.io
* For issues surrounding conduct. Email us - conduct@swiftengine.io

## License :notes:

This project is licensed under the Mozilla Public License Version 2.0 - see the [LICENSE](/LICENSE.txt) file for details
