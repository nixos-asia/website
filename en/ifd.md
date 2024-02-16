# Import From Derivation (IFD)

[[nix|Nix]] expressions are *evaluated* to produce #[[drv|derivations]] (among other values). These derivations when *realized* usually produce the compiled binary packages. Sometimes, realizing a derivation can produce a Nix expression representing another derivation. This generated Nix expression too needs to be *evaluated* to its derivation before it can be *realized*. This secondary evaluation is achieved by `import`ing from the derivation being evaluated, and is called "import from derivation" or IFD. 

For detailed explanation, see [this blog post](https://blog.hercules-ci.com/2019/08/30/native-support-for-import-for-derivation/).
