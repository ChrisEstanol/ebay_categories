## Set up

Configure Ebay API credentials in `config/ebay.rb`

```
development:
  dev_name: <dev_name>
  app_name: <app_name>
  cert_name: <cert_name>
  uri: https://api.sandbox.ebay.com/ws/api.dll
  auth_token: <auth_token>
```
Install the following gems:

```
gem install httparty
gem install sqlite3
```

## Usage

It can be executed from the command line with the following options

`./categories.rb --rebuild`

Create and populate the ebay categories database

`./categories.rb --render <CATEGORY_ID>`

Output a file named CATEGORY_ID.html that contains a simple web page displaying the category tree rooted at the given ID

`--help` for help

## Permission Denied

If you are new to using the shell on Mac OS X or Linux, what do you do when you get a message like this?

`-bash: ./categories.rb: Permission denied`

This reply most likely means that the file is not set up as an executable. To fix this, change the access control on the file using the chmod command by typing:

`chmod 755 categories.rb`

755 makes the control list read rwxr-xr-x (where r means read, w write, and x execute). This means that the file is readable and executable by everyone (owner, group, and others, in that order), but writable only by the owner. To find out more about chmod, type man chmod at a shell prompt.
