# AR/VR Code Visualizing
See Swift in Space

<table style="padding:10px">
  <tr>
    <td><img src="./repo_info/DemoAnimation-Gif.gif"      alt="A visualization of Swift code being rapidly highlighted in green" width = 384 ></td>
    <td><img src="./repo_info/DemoAnimation-iOS-Gif.gif"  alt="An iOS app displaying Swift code in an AR display in an outside backyard during the day" width = 384 ></td>
  </tr>
</table>

### What?

A tool to load up Swift files, render them into a SceneKit layer, and view the results in a 3D VR (macOS) or AR (iOS) environment.

### Why?

Plenty of reasons why. Here are some smarter people with better presentation skills and more carefully studied reasons:

- https://embodiedcode.net/
- https://divan.dev/posts/visual_programming_go/
- https://futureofcoding.org/
- https://stars.library.ucf.edu/etd/5511/ (<3 UCF)
- <your name here / link here>
  
### How?

Lots and lots of other people's tools and code suggestions. Primarily:

- SceneKit and a light AR wrapper for iOS support.
- [SwiftSyntax](https://github.com/apple/swift-syntax) for parsing Swift files and grabbing an Abstract Syntax Tree.
- [SwiftTrace](https://github.com/johnno1962/SwiftTrace) to capture executation traces and generate small tracing corpuses for visualization.
- [FileKit](https://github.com/nvzqz/FileKit) just because it's a nice abstraction.

### When?

Whenever I can, and even sooner if you help! All questions, contributors, ideas, thoughts, issues, suggestions, hopes, dreams, and pull requests are welcome!

## How to run it

You will need everything in this repository, including the syntax parsing libraries for SwiftSyntax targeting macOS and iOS. iPad support is totally unknown.

The current goal is to allow you to:

- Pull the project
- Run it from XCode, targeting your iPhone or Mac laptop
- See code in space

At the moment, none of the important things with respect to building a functioning release binary are in place. Everything is experimental, unstable, and ready to explode at any moment. It's very exciting.

## How can I help?

Anything is fine, and if something might be project related, feel free to create an Issue. It's a boring but functional discussion place, and doesn't require bumping around to other chat platforms or external wikis. We can get there later if needed.

You can also free fring to ping me directly from my GitHub profile. And, if you can't seem to find a pingagle thing, make an issue and bug me about it! I want to make sure those with interest in working on this have an easy way to get a hold of me, and everyone else with a curious eye.
