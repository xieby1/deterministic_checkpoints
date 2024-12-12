# Examples

TODO:

## Embedding Deterload into Your Project

In your project, you should replace `../.` into the path of Deterload.
For example:
* Local path: `~/Codes/MyRepos/Deterload`
* URL path:
  ```nix
  (builtins.fetchTarball {
    url = "https://github.com/OpenXiangShan/Deterload/archive/<rev>.tar.gz";
    # Get sha256: `nix-prefetch-url --unpack https://github.com/OpenXiangShan/Deterload/archive/<rev>.tar.gz`
    sha256 = "...";
  })
  ```

You need to pass the compulsory arg `spec2006-src` through command line, for example:

```nix
nix-build simple.nix --arg spec2006-src <PATH_OF_SPEC2006_SRC> -A spec2006.cpt
```

The command will runs for several hours, depending on the network and performance of your computer.
The spec2006 checkpoints will be saved in the `result/` folder.

Command line args overrides the configuration in file.
