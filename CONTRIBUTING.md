# Contributing

Thank you for visiting our repository and for your interest in helping improve SwiftEngine! We appreciate feedback of any kind, the only thing we asking of you is that you follow our [Code of Conduct](/CODE_OF_CONDUCT.md). 

Please choose the option below that fits you best:

### How to Contribute

The `master` branch will always contain the most stable release, while `dev` will contain features currently in progress. Be sure to comment your code appropriately. 

Please follow the steps below to contribute:

- Fork our repo
- Create a feature branch off the `dev` branch titled `dev-xxx` where `xxx` is the feature you are adding or fixing
- (optional) Generate an Xcode project to work within via the command `swift package generate-xcodeproj`
- Make your awesome change(s)  
- Commit your code with a descriptive message
- Submit a pull request against the `dev` branch
- Done!

### Submit a Bug Report

Is something in SwiftEngine not working as intended? Please open an issue and include the following:

- A couple sentences generally describing the issue you encountered
- The _simplest_ possible steps we need to take to reproduce this issue
- Your operating system by running the command `uname -a` in a terminal
- Anything else you think might aid us in resolving the issue

You may use the following example as a template to report an issue:

```
Context:
My server logs are not rotating properly after I have specified a max log size and that size is exceeded. 

Steps to Reproduce:
1. ...
2. ...
3. ...

$ uname -a 
Darwin Kernel Version 17.7.0: Thu Jun 21 22:53:14 PDT 2018; root:xnu-4570.71.2~1/RELEASE_X86_64 x86_64
```


We thank you for taking the time to help improve SwiftEngine!

