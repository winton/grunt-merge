##Stencil

Project template manager.

###Install

npm install stencil

###What is a project template?

A project template is a git repository that you base your projects off of.

###Example project template branching structure

Within the project template repository, you typically have branches that add extra functionality to the template:

    master
      -> backbone
      	 -> backbone-bookshelf
         -> backbone-bookshelf-mysql
         -> backbone-bookshelf-postgres
      -> express
         -> express-sessions
      -> express-grunt
      -> grunt

If you commit to master, you'll need an easy way to merge them into all the sub-branches. Stencil helps you do this.

###Add stencil.json to your project template

    {
        "backbone": [ "master" ],
        "backbone-bookshelf-mysql": [ "master" ],
        "express":  [ "master" ],
        "express-sessions": [ "master", "express" ],
        "express-grunt":    [ "master", "grunt", "express" ],
        "grunt":    [ "master" ]
    }

The `stencil.json` file defines what branches should merge into it.

### Stay up to date

[Watch this project](https://github.com/winton/stencil#) on Github.

[Follow Winton Welsh](http://twitter.com/intent/user?screen_name=wintonius) on Twitter.
