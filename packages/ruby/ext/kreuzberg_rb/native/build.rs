fn main() {
    let target = std::env::var("TARGET").unwrap();

    // Configure platform-specific linker settings
    if target.contains("darwin") {
        println!("cargo:rustc-link-arg=-Wl,-undefined,dynamic_lookup");
        println!("cargo:rustc-link-arg=-Wl,-rpath,@loader_path");
    } else if target.contains("linux") {
        println!("cargo:rustc-link-arg=-Wl,-rpath,$ORIGIN");
    }

    // kreuzberg-ffi is a cargo dependency that will be linked via Cargo's build system
    println!("cargo:rerun-if-changed=build.rs");
}
