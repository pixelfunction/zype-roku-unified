# Zype Roku Template App

## Setup

1. You will need your Zype APP key and OAuth credentials. You can find these in the [Zype Platform](https://admin.zype.com/) under the 'Settings' and 'Video Apps' menu.

2. Clone the repo

3. Update the following commands:

  * ROKU\_DEV\_TARGET: The IP address of your Roku device on your local network.
  * DEVPASSWORD: Your Roku's developer password.

4. Update your Zype configuration. Update the config located here under [source/configs/api_config.brs](source/objects/config.brs), and enter the following values:

  * app: Your Roku App Key
  * client\_id, client\_secret: Your Roku OAuth Credentials

5. Run the *clean_up* shell script to remove git (and instruction files to help make Roku 1 compatibile.)


7. Build and sideload the Roku app

  * Run *make install* in your project directory

## License

[![Creative Commons License][image-1]][1]  
This work is licensed under a [Creative Commons Attribution 4.0 International License][1].

[1]:    http://creativecommons.org/licenses/by/4.0/

[image-1]:  https://i.creativecommons.org/l/by/4.0/88x31.png
