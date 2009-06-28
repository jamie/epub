So....

I have a bunch of ePub books that I wanted access to from Stanza on my iPod Touch, and didn't feel like opening them all up in Stanza on my mac one by one and doing an ad-hoc copy.  Thankfully, there's documentation on creating a [catalog](http://www.lexcycle.com/developer) you can subscribe to from iTouch Stanza, and browse and download from there.

This project is currently an alpha/proof-of-concept catalog server, as well as an online book reader. I intend in the future to also include online editing of books, since I'm so good at finding typos.

## Running the Server

Check out the project, and from the root run `ruby bin/epub_server <epub_dir>`, where the argument to the server is a directory containing epub files, and optionally subdirectories containing the same. You can also provide [Sinatra](http://www.sinatrarb.com/intro.html) command line options to change the port, etc.

## Online Reading

Just hit [http://localhost:4567/](http://localhost:4567/), find a book, and go to it. See? Easy.

## Stanza Catalog

The catalog is located at [/catalog](http://localhost:4567/catalog) and linked from the index page if you forget. From Stanza, hit the Online Catalog, and then add a new entry.

## Known Issues

ePub files are simply renamed zip files, but it seems that some (such as files from [manybooks.net](http://manybooks.net), or ones converted from Stanza's desktop application) are incompatible with ruby's zip library. You'll know it when you see it, the error message is "can't dup NilClass". At the moment, the best fix I have is to simply unzip and re-zip the file with a normal zip utility, and it seems to clear the issue up.

If you find a non-DRM'd epub book that the server blows up on in a different way, add it to the [issues list](http://github.com/jamie/epub/issues).
