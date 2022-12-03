# Frobots Client

The **frobots_client** repository contains the client app and simulator GUI that you need to run the FUBARs arena to develop your own Frobots locally.  It connects with the game simulator through websockets.

# Getting Started

## 1. Ensure that you can Login to Beta Server

Website is at `https://dashboard.frobots.io/`.

But you need to login with the invite link you recieved in your email. The first time you login, you will be asked to change your password.  The dashboard is where you can see the Leaderboard of all other Frobots.

## 2. Dependencies

The client uses Elixir's Scenic library for GUI, which is a library made for IoT interfaces, but works well enough for our purposes. It requires GLEW and GFW dependencies.  You need to install them according to your operating system. While relatively simple on Linux (tested on Debian based distros) and MacOS, it is likely you can get it running on the windows 11 using windows subsystem for Linux, though you are on your own. Older versions of windows have major issues getting XWindows apps running due to Windows and XWindows not playing nicely together, so I doubt it would work, but I suppose if you could get linux UI apps to run then theoretically Frobots will as well.  The final game will be in a web platform, so these sorts of issues will go away.

1. Install OpenGL dependencies
<https://hexdocs.pm/scenic/install_dependencies.html#content>

2. If you have not created a frobot before, you should create a new frobot, create a `bots` dir in your $HOME dir,
and create a `.lua` file. The name of the file will be your FROBOT name

   ```bash
   $HOME/bots/[myfrobot].lua
   ```

3. While not necessary, a version manager makes your life easier. We recommend [asdf](https://asdf-vm.com/guide/getting-started.html).

4. Ensure you have `Elixir 1.13` installed and `Erlang 24`, as there are some incompatibilities with Erlang 25 with some of the dependencies.

5. If you need to switch versions, use a version manager like  follow its instructions to ensure you have installed the correct versions of Elixir. The below steps are assuming you are using asdf.

    ```bash
    asdf plugin add erlang
    ```

    ```bash
    asdf plugin add elixir
    ```

    ```bash
    asdf install erlang 24.3.4
    ```

    ```bash
    asdf install elixir 1.13.3-otp-24
    ```

    ```bash
    asdf global erlang 24.3.4
    ```

    ```bash
    asdf global elixir 1.13.3-otp-24
    ```

6. If necessary, add these versions to the `.tool-versions` file that should be created in your frobots directory

    Ensure the right version is active

    ```bash
    elixir --version
    ```

    You should see something like this

    ```bash
    Erlang/OTP 24 [erts-12.3.2.2] [source] [64-bit] [smp:8:8] [ds:8:8:10] [async-threads:1] [jit]

    Elixir 1.13.4 (compiled with Erlang/OTP 23)
    
    ```

    Note that the version is 1.13.4 and built on Erlang/OTP 24, that is important.

## 3. Building (MacOS, or other Linux distro, and maybe Windows 11)

1. Clone the game client repository

    ```shell
    git clone git@github.com:endymion621/frobots.git --recurse-submodules
    ```

2. Update your needed deps and build a release binary for the client using the following command:

   ```bash
   mix deps.get
   ```

3. Then build a prod release using the MIX_ENV=prod

   ```bash
   MIX_ENV=prod mix release frobots
   ```

4. Start the app

   ```bash
    # To start your system
   _build/prod/rel/frobots/bin/frobots start
   ```

## 4. Running Frobots

1. If you have not created a frobot before, you should create a new frobot, create a `bots` dir in your $HOME dir,
and create a `.lua` file. The name of the file will be your FROBOT name

   ```bash
   $HOME/bots/[myfrobot].lua
   ```

2. You can use any editor or IDE to create and edit the `.lua` file, and you may find it easiest to keep the file open. Save it.
3. LOGIN to the frobots server login screen with your FROBOTS BETA credentials.
4. On the client, upload your FROBOT to the beta server with the **Upload** button. The client looks for all `*.lua` files in your `$HOME/bots` dir.
5. If you previously updoaded FROBOTS but have deleted the local copies of their brain files, you can press the **Download** button to get saved Frobots. These FROBOTs will overwrite any in your `/bots` directory.
6. Once uploaded, you should be able to see you FROBOT in the dropdown list, to choose to battle.
7. Click `FIGHT` to start the match.
8. After the match, the results will be recorded. You can check the results on the beta console's Leaderboard page.
9. You should upload your FROBOTs code often, as it is only the copy that is on the server which is used in matches, not your local editable copy.
10. Instructions on how to program your FROBOT can be found on the beta console page, but you can experiment!
11. You can only play your FROBOT against proto-bots for the beta. After the game is released you will be able to pit your FROBOT against other users FROBOTs in FUBARs.
12. You can create as many FROBOTS as you like. But only a maximum of 3 will be preserved post-beta. The rest will go into the recycle parts bin!
