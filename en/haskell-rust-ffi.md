# How do you make using rust functions in haskell easier?

Recently at work, there was a [[rust]] library that had a use case in most of the projects. The only problem being, we use a varietly of languages and re-rewriting the same code in all of them means: 1000s of developer hours down the drain. So, the maintainers decide to pull out the big guns: [FFI (Foreign Function Interface)](https://en.wikipedia.org/wiki/Foreign_function_interface). In simple words, languages decide to talk to each other by interoping with C (although not always, or atleast in the case of this blog post, yes).

Everything is going well, the rust library outputs architecture specific binary files and the lanugage making the FFI call is able to do so by pointing to the binary files. Again, everything seems to be going well, like it did, until:

- You need to run on someone else's machine, all that endless instructions to install rust, run `cargo build` and then, assuming you are doing FFI from [[haskell]], you need to install haskell build tools and run it, pffft, it's a nightmare.
- You write a library that does the FFI for you, then another package uses this library, only to realise that I can't run this without knowing where to find the rust binary files.

