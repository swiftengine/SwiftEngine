# SwiftEngine Design Overview

SwiftEngine is aimed at being a highly resilient and scalable server-side platform, and as such the goal of the platform is to overcome some of the inherent vulnerabilities of other modern platforms currently in the market. A key example of what this means for production deployments is that each request and endpoint is contained within its own process; a crash for one request does not bring down the entire server. Similarly, memory leaks or other bugs are ephemeral and only live for the duration of the request, instead of transcending the lifetime of the server.

In addition to being a resilient and scalable, SwiftEngine is also highly performant due to the pre-compiled nature of all the endpoints because under the hood SwiftEngine uses Swift as its core language. All code that is executed on the server is a compiled (native object code) version of the source code. Thus, no processing power is spent on maintain a runtime environment. 


All the developer has to do is save their .swift files within the designated site directory and SwiftEngine will handle the rest. Any compile time and runtime errors are handled by SwiftEngine, and are provided to the developer in a beautiful and easy to follow interface. With SwiftEngine, long gone are the days of manual compilation and dealing with shell log dumps. Simply save a file and request the URL, and SwiftEngine will automatically compile, cache, and serve the requested results.  

In order to achieve these goals, there is a slight paradigm change compared to how a typical Swift project functions. The primary difference is the independently asynchronous processing of the various endpoints. Each one of the endpoints are compiled and maintained on their own; the introduction of a bug within one endpoint has no effect on the functionality of the rest of the site, but rather it's contained to that specific endpoint only.


## Routing Logic

One of the root concepts in SwiftEngine is its sophisticated routing logic. Out of the box, SwiftEngine has a smart routing logic that automatically attempts to match the http requests to a specific .swift file as its endpoint. However, for more advanced usage, a Router.swift file can be included within the root folder of the site for close control and customization of the request handling of the server.

![N|Solid](http://www.plantuml.com/plantuml/svg/bP5FSzem4CNl-XGxES4bt4dR96tAj8Sc6K8_W2gjiH9Bwqgh05FuxaKMs9v0_i01nEhjy_izNmMMdgEjH7WohfPUMf2ApRFX5VmJ05-bUffxYav_eueyB4h3cERaDVey-rDjHGBWnaXBJXzTWUx-sEgrzxJeZpQYbsZxpOODkHofjp_tSjLe4uOO_vZDxc6AVoC6tlugDC-enw9ahiUZaIOhZJjNP4UVS2bjNU6N2s4A64mfClhpi305Gs4g15oQmE5o25oYWy4Amr10ByZPuKf5SwFEceW0oVMNP5NkdA0W3pudU-cQFeFl-vD6bgfi_c0LC1dz3E2Rnu4bZV0P0dkZ68uQJLunWe6ZV9L7Jfj206n4TodoKFGmhoEJbMmKPE34b-dsDIyCbnJRsXXTCEGEagMLjlN3fa_kfFKQQInah3XxdcgNYJjRdwbGvt2b392DEpIuF0gd2GFirk4btqbuyDQhp87VJYmTSOc-5tbGigtMZ_LyNRlv-Z6GMoEhuGTGKB-7yV0AniSeyc4Zacmd429LCxxtf30a6WsuH1KPstuVsdx3XGXCjH0fntYA7BrB8I6mPACQJIkPT9BRknbCxdxVta39N3Vg642HtgklqEbeg_y0)

As an example for the automatic routing when an extension is not specified, consider the following URL: `http://somedomain.com/componenet1/component2/componenet3/componenet4`

Since a Swift file can serve as the base executable in various positions within the URL path, the automatic URL router will use the following logic, and select the first available in the following order.

![N|Solid](http://www.plantuml.com/plantuml/svg/pPFFRjGm4CRlVefHJzaSkkBFAJtGGgaujTMoF82n9yseYITunbrMLTyTEsp1GdlWK24i9R4_V-FVvrW-5xLHqpGQkQSmssWdi4xfWNGFZmRWlNNtTv5Jy1zuv0YxWHIBpj5Z_Abz7RCfQvTa9mx-Q0bKyqTABsBaNIqzcIfHVYifSO37Fz1tqUwBTzc6wJvjjxUmmMy9HVFN8JsWxyoWEdVhjV24dYTBuTJnjCxFp043wgjVVNrToM-g_jipOypl72SNIVDAIWusd1GZD86Xfn41loi6AIQPqL5Fw5SdIt3geQcfRNigE-grRPyhILJUhK073D3iKLO6bjPyVEvvLEk6FC1Hi43BH1a6Jxqv0gcszgzvzQzySVRVe-jJ_4zYhDlMOs_Jg2yIfpgG9zDShSp1OqmfwsuZEnG16tmce4kA40-Nv7F1Bt0vCw8yczpA4jq6DSK0rpTRkBhvSdq9vHQ1gDKauDZZmN-UoMaQVm00)

## SwiftEngine Compiler Processor Logic 

### `require` directive 
In order to maintain resiliency and endpoint independence, SwiftEngine takes a slightly different approach in how individual files are compiled. With a typical Swift based project, all the files are compiled together, and as a result the entire app either works or it does not. Conversely, within SwiftEngine, each one of the requested endpoints is compiled independently, so a bug introduced in one area of the code does not affect any other endpoint. In order to achieve this, the developer needs to specify (within each file) any other files within SwiftEngine that need to be used within that specific Swift file. The SEProcessor will iteratively process all the files with the `require` directive, so the developer only needs to specify what other Swift files are needed within the first Swift file.

As an example, if the example1.swift file depends on a class that is declared within example2.swift, the developer will need to specify example2.swift as a dependency via our custom `require` directive. To do so, one must only add the following line to example1.swift:
`//se: require directory/example2.swift`

This will inform SEProcessor that the example2.swift file should be used along with example1.swift file during the compilation process.

The following is a high-level logic for SwiftEngine preprocessor `require` directives:

![N|Solid](http://www.plantuml.com/plantuml/svg/RL9DRzim3BthL_3e14C3xEWC_UY6dOVj5p0HdH2LHLUIcsN3_lj8sQWJD08IIoJVu-EJ7dF1LCO-kFp2SS24FU2-y1kNC_nr0C-uVpaa6QF_Aa4Id8vSoEAIFAKfjWjQfB5lZBr4VnC2I_uMz2abELs6_haBHVfVkB34AkaIVqXuhhKsXcj_91gIx2bdpVso6FcjQpag6WF_8LYl4xsEd0W2vx9U0oQbs6GgMzSyhPodWlkZg_is4Nh89-uAT1n8cJgE7Z24XKSfl7xCCygjsoXL2tCEilJqNOBAtT1lx8T0d-ygtzOvxg2vpGATcVUmWdAa2CsPyie1w6Y4nO4kWtvPkEytqu43tK_qAj6qdwjp8DsLN1lyYhjoKiW4JHHhPQj5xw781yEsSzuCcdPH2a7Ymz74JUjdrMezhZgRYTaqPOu7c6yA9C8xaDHy3P1fDZJtWzWbJj1FWD4lnJroBFghbMFar_7M_UO5OCI783iCDNit9oZwEeIR3zpfpis6s_CDwamlwNgOH1qbYZe2u1jom5sW1pLpCT9DNAvvNjwLxTi1SvxDE74vSlmekyZyyFRI3rgPN6EbTTGaKYhSXhE06L43gwtBHGRtg9t7Flm7)


