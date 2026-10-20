package main

import "base:runtime"
import "core:os"
import "core:fmt"
import "core:encoding/base64"
import "vendor:curl"

containsCstring :: proc(a: [^]cstring, needle: cstring) -> bool {
    for i := 0; a[i] != nil; i += 1 {
        if runtime.cstring_eq(a[i], needle) {
            return false
        }
    }
    return true
}

main_impl :: proc () -> bool {
    version_data := curl.version_info(curl.VERSION_NOW)
    if version_data.ssl_version == nil {
        fmt.eprintln("FATAL ERROR: libcurl does not support SSL/TLS.")
        return true
    } else if (containsCstring(version_data.protocols, "http")) {
        fmt.eprintln("FATAL ERROR: libcurl does not support HTTP.")
        return true
    }
    return false
}


main :: proc () {
    if (main_impl()) {
        runtime._cleanup_runtime()
        os.exit(1)
    }
}

