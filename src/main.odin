package main

import "base:runtime"
import "core:os"
import "core:fmt"
import "core:strings"
import "core:encoding/base64"
import "vendor:curl"

contains_cstring :: proc(a: [^]cstring, needle: cstring) -> bool {
    for i := 0; a[i] != nil; i += 1 {
        if runtime.cstring_eq(a[i], needle) {
            return true
        }
    }
    return false
}

write_callback :: proc "c" (buffer: [^]u8, _: uint, ntimes: uint, output:rawptr) -> int {
    context = runtime.default_context()
    output := transmute(^strings.Builder)output
    return strings.write_bytes(output, buffer[:ntimes])
}

main_impl :: proc () -> bool {
    if curl.global_init(curl.GLOBAL_SSL) != curl.code.E_OK {
        fmt.eprintln("FATAL ERROR: error initializing curl.")
        return true
    }
    version_data := curl.version_info(curl.VERSION_NOW)
    if version_data.ssl_version == nil {
        fmt.eprintln("FATAL ERROR: libcurl does not support SSL/TLS.")
        return true
    } else if (!contains_cstring(version_data.protocols, "https")) {
        fmt.eprintln("FATAL ERROR: libcurl does not support HTTPS.")
        return true
    }
    handle := curl.easy_init()
    if handle == nil {
        fmt.eprintln("FATAL ERROR: handle could not be created.")
        return true
    }
    curl.easy_setopt(handle, curl.option.URL, "http://localhost:8000/test.txt")
    curl.easy_setopt(handle, curl.option.WRITEFUNCTION, write_callback)
    server_return := strings.builder_make_none()
    curl.easy_setopt(handle, curl.option.WRITEDATA, &server_return)
    success := curl.easy_perform(handle)
    if success != curl.code.E_OK {
        fmt.eprintln("FATAl ERROR: ", success)
        return true
    }
    contents := strings.to_string(server_return)
    fmt.print(contents)
    

    return false
}


main :: proc () {
    if (main_impl()) {
        runtime._cleanup_runtime()
        os.exit(1)
    }
}

