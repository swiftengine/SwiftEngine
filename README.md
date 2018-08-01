# SwiftEngine Design Overview

SwiftEngine is aimed at being a highly resilient and scalable server-side platform, as such the goal of the platform is to overcome some of the inherent vulanrabilities of other modern platforms currently in the market. A key example of what this means for production deployments is that each request and endpoint is contained within it's own process, a crash for one request does not bring down the entire server; similarly a memory leaks or other bugs are ephemeral and only live for the duration of the request, instead of trasncending in the lifetime of the server.   

In addition to being a highly resilient and scalable, SwiftEngine is also hihgly performant due to the pre-compiled nature of all the endpoints, beacuse inder the hood SwiftEngine is using Swift as its core langauge, all code that is executed on the server is a compiled (native object code) version of the source code.  Thus no processing power is spent on maintaing a runtime environemnt. 

Lastly, by not least(ly), SwiftEngine aim and being a highly productive enviroment, while abstracting away some of the mandain build and devops related tasks.  As such, SwiftEningine is an complete autonomous solution.  This means that no manual compilation and configuration is required by the developer.  SwiftEngine is built from ground up in order automatically build its source files, with full debugging capabilites.   This means that as a developer, all one has to do is save their .swift files within the desiganted site directory and SwiftEngine will handle the rest.   Any compiletime and runtime errors, are also handles by SwiftEngine, and are provided to the developer is beatifull and easy to follow interfece.  With SwiftEngine, long gone are the day of manual compilation and dealing with shell log dumps, simple save a file and request the URL, SwiftEngine will automatically compile, cache, and serve the requested results.  

In order to achieve these goals, there is a slight change of a paradign in methodology of how a typicaly Swift project functions.  The primary shift is in the independently isosynchronous processing of the various endpoints.  This means that each one of the endpoints are compiled and maintained on their own, thus an introduction of a bug within one endpoint has no effect on the functionality of the entire site, but it's rather contained to that specific endpoint only.

## Routing Logic

One of the root concepts in SwiftEngine is it's highly spohisitcaled routing logic.  Out of the box, SwiftEngine has a smart routing logic which will automatically attempt to match the http requests to a specific .swift file as it's endpoint.  However, for more advanced usage, a Router.swift file can be included within the root folder of the site, and can be used for close control and customization of the request handling of the server.

![N|Solid](http://www.plantuml.com/plantuml/svg/bP5FSzem4CNl-XGxES4bt4dR96tAj8Sc6K8_W2gjiH9Bwqgh05FuxaKMs9v0_i01nEhjy_izNmMMdgEjH7WohfPUMf2ApRFX5VmJ05-bUffxYav_eueyB4h3cERaDVey-rDjHGBWnaXBJXzTWUx-sEgrzxJeZpQYbsZxpOODkHofjp_tSjLe4uOO_vZDxc6AVoC6tlugDC-enw9ahiUZaIOhZJjNP4UVS2bjNU6N2s4A64mfClhpi305Gs4g15oQmE5o25oYWy4Amr10ByZPuKf5SwFEceW0oVMNP5NkdA0W3pudU-cQFeFl-vD6bgfi_c0LC1dz3E2Rnu4bZV0P0dkZ68uQJLunWe6ZV9L7Jfj206n4TodoKFGmhoEJbMmKPE34b-dsDIyCbnJRsXXTCEGEagMLjlN3fa_kfFKQQInah3XxdcgNYJjRdwbGvt2b392DEpIuF0gd2GFirk4btqbuyDQhp87VJYmTSOc-5tbGigtMZ_LyNRlv-Z6GMoEhuGTGKB-7yV0AniSeyc4Zacmd429LCxxtf30a6WsuH1KPstuVsdx3XGXCjH0fntYA7BrB8I6mPACQJIkPT9BRknbCxdxVta39N3Vg642HtgklqEbeg_y0)

Just to do a walk through example for the automatic routing when an extension is not specified (for example: `http://somedomain.com/componenet1/component2/componenet3/componenet4`), since a Swift file can serve as the base executable in various positions within the url path, the automatic URL router will use the following logic, and select the first available in the flowing order.

![N|Solid](http://www.plantuml.com/plantuml/svg/pPFFRjGm4CRlVefHJzaSkkBFAJtGGgaujTMoF82n9yseYITunbrMLTyTEsp1GdlWK24i9R4_V-FVvrW-5xLHqpGQkQSmssWdi4xfWNGFZmRWlNNtTv5Jy1zuv0YxWHIBpj5Z_Abz7RCfQvTa9mx-Q0bKyqTABsBaNIqzcIfHVYifSO37Fz1tqUwBTzc6wJvjjxUmmMy9HVFN8JsWxyoWEdVhjV24dYTBuTJnjCxFp043wgjVVNrToM-g_jipOypl72SNIVDAIWusd1GZD86Xfn41loi6AIQPqL5Fw5SdIt3geQcfRNigE-grRPyhILJUhK073D3iKLO6bjPyVEvvLEk6FC1Hi43BH1a6Jxqv0gcszgzvzQzySVRVe-jJ_4zYhDlMOs_Jg2yIfpgG9zDShSp1OqmfwsuZEnG16tmce4kA40-Nv7F1Bt0vCw8yczpA4jq6DSK0rpTRkBhvSdq9vHQ1gDKauDZZmN-UoMaQVm00)

## SwiftEngine Compiler Processor Logic 

### `Require` directive 
In order to maintain resiliancy and endpoint independece, SwiftEngine takes a slightly different approach to how a individual files are compiled.   With a typical Swift based project, all the files are compiled together, and as a result the entire app either works or it does not.  Within SwiftEngine each one of the requested endpoints is compiled independely, thus a bug introduced in one area of the code does not effect any other unrelated endpoints.   In order to acheive this, the developer needs to specify (within each file) any of the other files within SwiftEngine that need to be used within that specific Swift file. The SEProcessor will itteratively process all the files with `require` directive, thus the developer only needs to specifies what is needed with the Swift page that needs to use it.

As an example, if example1.swift file depends on a class that is declared withing example2.swift file, then the developer will need to specify the dependecy with example1.swift file via a custom `require` directive such as this `//se: require directory/example2.swift`.   This will inform SwiftEngine compilation preprocessor logic that Example2.swift file should be used along with Example.swift file during the compilation process.

Following is a high-level logic for SwiftEngine preprocessor `require` directives:

![N|Solid](http://www.plantuml.com/plantuml/svg/RL9DRzim3BthL_3e14C3xEWC_UY6dOVj5p0HdH2LHLUIcsN3_lj8sQWJD08IIoJVu-EJ7dF1LCO-kFp2SS24FU2-y1kNC_nr0C-uVpaa6QF_Aa4Id8vSoEAIFAKfjWjQfB5lZBr4VnC2I_uMz2abELs6_haBHVfVkB34AkaIVqXuhhKsXcj_91gIx2bdpVso6FcjQpag6WF_8LYl4xsEd0W2vx9U0oQbs6GgMzSyhPodWlkZg_is4Nh89-uAT1n8cJgE7Z24XKSfl7xCCygjsoXL2tCEilJqNOBAtT1lx8T0d-ygtzOvxg2vpGATcVUmWdAa2CsPyie1w6Y4nO4kWtvPkEytqu43tK_qAj6qdwjp8DsLN1lyYhjoKiW4JHHhPQj5xw781yEsSzuCcdPH2a7Ymz74JUjdrMezhZgRYTaqPOu7c6yA9C8xaDHy3P1fDZJtWzWbJj1FWD4lnJroBFghbMFar_7M_UO5OCI783iCDNit9oZwEeIR3zpfpis6s_CDwamlwNgOH1qbYZe2u1jom5sW1pLpCT9DNAvvNjwLxTi1SvxDE74vSlmekyZyyFRI3rgPN6EbTTGaKYhSXhE06L43gwtBHGRtg9t7Flm7)



# SECGIHandler

A description of this package.