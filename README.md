# *amx* - MTA AMX compatibility layer

Introduction
------------

*amx* is a software package that allows the execution of unmodified San
Andreas: MultiPlayer 0.2.2 gamemodes, filterscripts and plugins on Multi
Theft Auto: San Andreas 1.0 servers. It is open source, and a prebuilt
binary for Windows is available.

-   [License](#license)
-   [Compatibility](#compatibility)
-   [Extra features](#extra-features)
-   [Installation](#installation)
-   [Running gamemodes and filterscripts](#running-gamemodes-and-filterscripts)
-   [New Pawn scripting functions](#new-pawn-scripting-functions)
-   [New Lua scripting functions](#new-lua-scripting-functions)
-   [New MTA events](#new-mta-events)
-   [Pawn-Lua interaction](#pawn-lua-interaction)
-   [Limitations](#limitations)
-   [Author and thanks](#credits)

License
-------

*amx* is free and open source. You are allowed to use and modify it free
of charge in any way you please.

You are allowed to redistribute (modified) versions of *amx*, provided
that you:

-   do not charge for them,
-   keep the original credits and licence intact,
-   clearly list any modifications you made, and
-   do not present them as an official version.

Compatibility
-------------

Compatibility is quite high:

-   Almost all SA-MP **scripting functions** and **callbacks** are
    implemented.
-   **Database** functions (db\_\*) are implemented.
-   SA-MP server **plugins** work unmodified.
-   SA-MP style **rcon** commands are available from the server console
    and the ingame console.

See [Limitations](#limitations) for a list of features that are
currently missing.

Extra features
--------------

Apart from being compatible, *amx* also offers a number of extra
features:

-   **Scriptfiles** of a gamemode can not only be placed in a central
    folder like in SA-MP, they will also be detected when placed **in
    the gamemode\'s folder**. This means that files of different
    gamemodes are kept apart and can no longer conflict: you can have
    several gamemodes that use the same file names, and be assured they
    won\'t overwrite each other\'s files.

-   **New native scripting functions** (include a\_amx.inc to use
    these):

    -   [AddPlayerClothes](#AddPlayerClothes)
    -   [GetPlayerClothes](#GetPlayerClothes)
    -   [RemovePlayerClothes](#RemovePlayerClothes)
    -   [ShowPlayerMarker](#ShowPlayerMarker)
    -   [GetVehicleVelocity](#GetVehicleVelocity)
    -   [SetVehicleVelocity](#SetVehicleVelocity)
    -   [SetVehicleModel](#SetVehicleModel)

-   In addition to these new native functions, gamemodes run in *amx*
    can also **call Lua scripts**. Lua scripts can in turn call public
    Pawn functions.

    Using Lua not only gives you access to the wide range of MTA
    functions that offer a lot of functionality that SA-MP doesn\'t
    have, but also allows you to write code in a much more comfortable
    and efficient fashion than Pawn. For example, while Pawn is a subset
    of C and requires you to create a temporary buffer and call one or
    more functions to concatenate strings, you can simply do
    `str1 = str2 .. str3` in Lua.

-   You can **load plugins dynamically**, while the server is running.
    Use the `loadplugin` console command for this.

Installation
------------

*amx* consists of a binary server module (.dll/.so) and a Lua resource.
It will only run on MTA:SA 1.0 and later. Installation steps are lined
out below.

### Extracting

Extract the \"mods\" folder into your MTA \"server\" directory.

### Configuration

-   Open server/mods/deathmatch/mtaserver.conf in a text editor. Add the
    following line within the `<config>` node:

    ```xml
    <module src="king.dll"/>
    ```

    (Use \"king.so\" on Linux systems). This will instruct the MTA
    server to load the module on startup.

-   At this point you can add the *amx* resource to the autostart list
    if you want. Doing this will allow you to use SA-MP style rcon
    commands in the server console as soon as the server is started.

    ```xml
    <resource src="amx" startup="1" protected="0"/>
    ```

    Save and close mtaserver.conf.

-   After starting the MTA server you should see the following output:

    > Resource 'amx' requests some acl rights. Use the command 'aclrequest list amx'

    Run `aclrequest list amx` to see what ACL rights are needed, and
    if you are happy with the request, type `aclrequest allow amx all`.

    The following rights are used for the following purposes:

    - `general.ModifyOtherObjects`: to access files of `amx-*` resources
    - `function.startResource`  \
      `function.stopResource`  \
      `function.restartResource`:
        - to automatically (re)start filterscripts when `amx` starts
        - for rcon

### Migrating gamemodes, filterscripts, plugins from an SA-MP server

If you have an SA-MP server with a number of modes and scripts that you
would like to host on your MTA server, you can easily migrate these with
an automated tool. For Windows, a graphical click-through wizard is
provided: amxdeploy.exe (.NET Framework 2.0 required). For Linux there
is an interactive Perl script: amxdeploy.pl. Simply run the tool
appropriate for your operating system and follow the instructions. The
tool will:

-   install the selected SA-MP gamemodes and filterscripts as MTA
    resources,
-   copy the selected plugins to MTA,
-   copy all scriptfiles to MTA,
-   set up the MTA mapcycler resource according to the gamemode cycling
    configuration in SA-MP\'s server.cfg, and
-   set up the autostart filterscripts and plugins according to SA-MP\'s
    server.cfg.

#### Special note for Linux users infamiliar with Perl

amxdeploy.pl uses some modules that are not part of a standard Perl
installation. These are:

-   File::Copy::Recursive
-   XML::Twig

If you don\'t have these yet, you need to install them before you can
run the script. To do this, open a terminal, switch to root and start
`cpan`. If this is the first time you start `cpan`, it will walk you
through some configuration (selection of download mirrors etc.). After
it\'s set up, type `install <modname>` for each module to download and
install it, for example: `install XML::Twig`.

Once the modules are installed you should be able to run the script
without problems: `perl amxdeploy.pl`.

### Maintenance of your MTA server

The migration tool is mainly meant for moving over files from an SA-MP
server to a fresh *amx* install. To add SA-MP content to your MTA server
at a later point, you probably want to take the manual route.
Information about this is lined out below.

-   In SA-MP, there is one folder that contains all gamemodes and
    another that contains all filterscripts. In MTA, it is the
    convention to create a separate resource (i.e. folder) for each
    gamemode. *amx* follows the MTA convention for better integration,
    which means that a resource needs to be created for each gamemode
    and filterscript. The naming convention for these is amx-*name* for
    gamemodes and amx-fs-*name* for filterscripts.

    So, to **add a new gamemode or filterscript**, you create a folder
    in server/mods/deathmatch/resources/, place one or more .amx files
    and any external files (\"scriptfiles\") in it, and add an
    appropriate meta.xml. Alternatively you can dump all scriptfiles
    together in server/mods/deathmatch/resources/amx/scriptfiles, SA-MP
    style.

    The meta.xml files of gamemodes and filterscripts are slightly
    different. Two resources, amx-test and amx-fs-test, are included
    with the *amx* download as examples. Most times you can simply
    copy-paste these to a new resource and adjust the names in it.

-   To specify what **filterscripts to autostart** when *amx* loads,
    open server/mods/deathmatch/resources/amx/meta.xml and edit the
    \"filterscripts\" setting. Its value is a list of filterscript names
    separated by spaces. For example:

    `<setting name="filterscripts" value="adminspec vactions"/>`{.block     lang="xml"}

    This will start the resources amx-fs-adminspec and amx-fs-vactions.

-   **Plugins** go in server/mods/deathmatch/resources/amx/plugins.
    Additionally you need to specify what plugins to load when *amx*
    starts: open server/mods/deathmatch/resources/amx/meta.xml and edit
    the \"plugins\" setting. Its value consists of the names of the
    plugins to start, separated by spaces. For example:

    ```xml
    <setting name="plugins" value="irc sampmysql"/>
    ```

    This will load irc.dll and sampmysql.dll on Windows, or .so on
    Linux.

-   jbeta\'s mapcycler resource (shipped with the MTA server) is used
    for automatic **map cycling**. The cycling is configured in
    server/mods/deathmatch/resources/mapcycler/mapcycle.xml. For each
    gamemode, add a line like this:

    ```xml
    <game mode="amx" map="amx-name" rounds="1"/>
    ```

    By default, the gamemodes are run in the order in which they appear
    in the list; you can also opt to randomly select the next mode from
    the list by setting the `type` attribute of the root `<cycle>` node
    to `"shuffle"`.

    Automatic cycling will **only** happen when the mapcycler resource
    is started. You can start it manually (`start mapcycler`) or add it
    to the autostart list of your server (mtaserver.conf). If mapcycler
    is not started, *amx* will let players vote on the next mode
    instead.

### Finishing up

-   If you are planning to compile Pawn scripts that use the new native
    functions provided by *amx*, place a\_amx.inc in your Pawno
    \"include\" directory.

-   You are done!

Running gamemodes and filterscripts
-----------------------------------

Before you can run sa-mp modes or filterscripts, you need to start the
*amx* resource. Type this command in the server console or as admin in
the ingame console:

```bash
start amx
```

Alternatively you can add it to the autostart list of your server, in
mtaserver.conf. Once *amx* is started you can use the following commands
to start and stop gamemodes and filterscripts:

```bash
start amx-name
stop amx-name
start amx-fs-name
stop amx-fs-name
```

Alternatively, you can use the SA-MP style `changemode` and
(`un`)`loadfs` commands. At most one gamemode can be running at any
time, the number of running filterscripts is unlimited.

Go ahead and try starting the example gamemode (amx-test) and
filterscript (amx-fs-test).

New Pawn scripting functions
----------------------------

Here follows a quick reference for the new Pawn native functions *amx*
introduces. To use them, `#include <a_amx>` in Pawno.

### AddPlayerClothes

```pawn
native AddPlayerClothes ( playerid, type, index );
```

Applies the specified clothing to a player. See the [clothes
page](http://development.mtasa.com/index.php?title=CJ_Clothes) for a
list of valid type and index ID\'s. *Note:* this function only has a
visible effect on players with the CJ skin.

### GetPlayerClothes

```pawn
native GetPlayerClothes ( playerid, type );
```

Returns the clothes index of the specified type which the player is
currently wearing. See the [clothes
page](http://development.mtasa.com/index.php?title=CJ_Clothes) for a
list of valid type and index ID\'s. *Note:* the returned value is only
relevant for players with the CJ skin.

### RemovePlayerClothes

```pawn
native RemovePlayerClothes ( playerid, type );
```

Removes the specified clothing from a player. See the [clothes
page](http://development.mtasa.com/index.php?title=CJ_Clothes) for a
list of valid type ID\'s. *Note:* this function only has a visible
effect on players with the CJ skin.

### ShowPlayerMarker

```pawn
native ShowPlayerMarker ( playerid, show );
```

Shows or hides the blip of one specific player.

### GetVehicleVelocity

```pawn
native GetVehicleVelocity ( vehicleid, &Float:vx, &Float:vy, &Float:vz );
```

Returns the velocity of a vehicle along the x, y and z axes. No more
manual speed calculation with timers.

### SetVehicleVelocity

```pawn
native SetVehicleVelocity ( vehicleid, Float:vx, Float:vy, Float:vz );
```

Sets the velocity of a vehicle. Make it jump or suddenly come to a halt.

### SetVehicleModel

```pawn
native SetVehicleModel ( vehicleid, model )
```

Changes the model of a vehicle; more practical than destroying and
recreating it.

### lua

```pawn
native lua ( const fnName[], {Float,_}:... );
```

Calls a Lua function. The function must be defined in a .lua file in the
same resource as the calling .amx, and must have been registered earlier
with [amxRegisterLuaPrototypes](#amxRegisterLuaPrototypes). See also
[Pawn-Lua interaction](#pawnluainteraction).

Example:

```pawn
new playerid = lua("luaTestfn1", 1.3, "Test string");
```

### amxRegisterPawnPrototypes

```pawn
native amxRegisterPawnPrototypes ( const prototype[][] );
```

Registers prototypes for public functions that can be subsequently
called from Lua scripts with [pawn](#pawn). The prototype list
**must be terminated with an empty string**. See also [Pawn-Lua
interaction](#pawnluainteraction).

This example code registers two functions. The first one takes a float
and a string argument and returns a player ID, the second takes a player
ID and returns nothing:

```pawn
new prototypes[][] = {
    "p:pawnTestfn1", { "f", "s" },
    "pawnTestfn2", { "p" },
    ""
};
amxRegisterPawnPrototypes(prototypes);
```

### amxVersion

```pawn
native amxVersion ( &Float:ver );
```

Retrieves the *amx* version as a floating point number, e.g. `1.3`.

### amxVersionString

```pawn
native amxVersionString ( buffer[], size );
```

Retrieves the complete *amx* version string.

New Lua scripting functions
---------------------------

A number of new Lua functions were also introduced.

### pawn

```lua
variant pawn ( string fnName, ... )
```

Calls a Pawn function. The function must be public, must be defined in
an .amx file in the same resource as the calling .lua, and must have
been registered earlier with
[amxRegisterPawnPrototypes](#amxRegisterPawnPrototypes).

Example:

```lua
local player = pawn('pawnTestfn1', 0.5, 'Test string')
```

### amxIsPluginLoaded

```lua
bool amxIsPluginLoaded ( string pluginName )
```

Checks if a specific SA-MP server plugin is currently loaded. pluginName
is the name of the plugin without a file extension.

### amxRegisterLuaPrototypes

```lua
bool amxRegisterLuaPrototypes ( table prototypes )
```

Registers prototypes of Lua functions that can subsequently be called
from a Pawn script with [lua](#lua). See also [Pawn-Lua
interaction](#pawnluainteraction).

The following example code registers two functions - the first one takes
a float and a string argument and returns a player element, the second
takes a player element and returns nothing:

```lua
amxRegisterLuaPrototypes(
    {
        ['p:luaTestfn1'] = { 'f', 's' },
        ['luaTestfn2']   = { 'p' }
    }
)
```

### amxVersion

```lua
float amxVersion ( )
```

Returns the *amx* version as a floating point number, for example `1.3`.

### amxVersionString

```lua
string amxVersionString ( )
```

Returns the complete *amx* version string.

New MTA events
--------------

*amx* also provides events for detecting when .amx files are loaded and
unloaded.

### onAMXStart

```lua
onAMXStart ( resource res, string amxName )
```

Triggered when an .amx file has just finished loading and initializing.
The source of this event is the root element of the resource containing
the .amx file. `res` is the resource pointer to this resource. `amxName`
is the name of the .amx file minus the extension.

You should only call [pawn](#pawn) after this event has triggered;
if you call it in the main body of a Lua script, .amx files won\'t have
registered their functions yet.

### onAMXStop

```lua
onAMXStop ( resource res, string amxName )
```

Triggered when an .amx file was unloaded. The source of this event is
the root element of the resource containing the .amx file. `res` is the
resource pointer to this resource. `amxName` is the name of the .amx
file minus the extension.

Pawn-Lua interaction
--------------------

*amx* allows developers to enrich their gamemodes and other scripts with
Lua code, which is easier and more efficient to write than Pawn. To make
this possible, a new Pawn function, [lua](#lua) was added to call
Lua functions, and a Lua function called [pawn](#pawn)
correspondingly calls public Pawn functions.

A resource that uses the interaction functions will contain both one or
more .amx files (`<amx/>` in meta.xml) and serverside MTA scripts
(`<script/>`). Both Pawn and Lua scripts can only call other-language
scripts that are in the same resource.

### Registering prototypes

Before you can call a function with [lua](#lua) or [pawn](#pawn)
you need to define its prototype, which consists of the types of its
arguments and return value. Each type corresponds to a single letter:


Letter       | Type
-------------|---------------
<kbd>b</kbd> | `boolean`
<kbd>i</kbd> | `integer`
<kbd>f</kbd> | `floating point`
<kbd>s</kbd> | `string`
<kbd>p</kbd> | `player`
<kbd>v</kbd> | `vehicle`
<kbd>o</kbd> | `object`
<kbd>u</kbd> | `pickup`

Pawn functions are registered with
[amxRegisterPawnPrototypes](#amxRegisterPawnPrototypes), Lua
functions with
[amxRegisterLuaPrototypes](#amxRegisterLuaPrototypes). Both
functions associate a number of function names with their argument types
and (optionally) return type. To specify a return type, prepend the
function name with the type letter followed by a colon (:), for example:
`f:testfn`. If you do not specify a return type (i.e. only specify the
name, `testfn`), \"i\" will be assumed.

See the syntax sections of the two registration functions for the
precise syntax to use.

### Calling other-language functions

Use [lua](#lua) to call a Lua function from Pawn, and
[pawn](#pawn) to call a Pawn function from Lua. The functions have
the same syntax: a string containing the name of the function, followed
by the arguments to the function. *amx* takes care of any necessary
argument and return value conversions: for example an .amx vehicle ID
passed to [lua](#lua) will arrive in the Lua function as an MTA
vehicle element, and vice versa (provided the correct prototype was
registered for the Lua function).

### Passing arguments by reference

It is possible to pass arguments by-reference from Pawn to Lua - however
this is **not** possible in the opposite direction.

To make an argument be passed by reference, modifications in both the
Lua function\'s prototype and body are necessary. In the prototype,
prepend the type letter with a `&`. In the function\'s code, write
`_[argname]` instead of `argname` for reading and writing the argument
(`argname` holds the memory address in the .amx of the argument).

### Cross-language calling limitations

Some limitations apply to cross-language calling.

-   Only scalar values (numbers, players, vehicles\...) and strings can
    be passed as arguments; Pawn arrays and Lua tables are not
    supported.
-   Functions can only return scalar values (no strings or other
    arrays).
-   As stated in the previous section, by-reference arguments can only
    be passed from Pawn to Lua, not from Lua to Pawn.

### Example

This example code demonstrates registering prototypes and calling
other-language functions, with arguments passed by value and by
reference.

<details><summary>test.pwn</summary>

```pawn
#include <a_samp>
#include <a_amx>

main() {
    new prototypes[][] = {
       "p:testfn", { "p", "f", "s" },
       ""
    };
    amxRegisterPawnPrototypes(prototypes);
}

public testfn(playerid, Float:f, str[]) {
    printf("pawn> testfn: %d %.1f %s", playerid, f, str);
    return playerid;
}

public OnGameModeInit() {
    new vehicleid = CreateVehicle(415, 0.0, 0.0, 3.0, -90.0, 0, 1, 5000);
    new vehicletype = 0;
    // vehicletype is passed by reference
    new success = lua("getVehicleType", vehicleid, vehicletype, "Test text from Pawn");
    if(success)
        printf("pawn> Vehicle type: %d", vehicletype);

    SetGameModeText("Blank Script");
    AddPlayerClass(0, 1958.3783, 1343.1572, 15.3746, 269.1425, 0, 0, 0, 0, 0, 0);
    return 1;
}

public OnPlayerRequestClass(playerid, classid) {
    SetPlayerPos(playerid, 1958.3783, 1343.1572, 15.3746);
    SetPlayerCameraPos(playerid, 1958.3783, 1343.1572, 15.3746);
    SetPlayerCameraLookAt(playerid, 1958.3783, 1343.1572, 15.3746);
    return 1;
}
```

</details>

<details><summary>test.lua</summary>

```lua
function getVehicleType(vehicle, pVehicleType, str)
    print('lua> ' .. str)
    print('lua> ' .. _[pVehicleType])
    local model = getElementModel(vehicle)
    if model then
        _[pVehicleType] = model
        return true
    else
        return false
    end
end

addEventHandler('onAMXStart', root,
    function()
        -- Note that we are calling pawn() from the onAMXStart event instead of
        -- in the main script body. Calling it from the main body would fail as
        -- the Pawn functions have not yet been registered at that point.
        local player = pawn('testfn', getRandomPlayer(), 0.8, 'Test string from Lua')
        if player then
            print('lua> ' .. getClientName(player))
        else
            print('lua> No random player')
        end
    end
)

amxRegisterLuaPrototypes({
    ['b:getVehicleType'] = { 'v', '&i', 's' }
})
```

</details>

<details><summary>Sample output of this code</summary>

```
lua> Test text from Pawn
lua> 0
pawn> Vehicle type: 415
pawn> testfn: 1 0.8 Test string from Lua
lua> arc_
```

</details>

Limitations
-----------

Even though *amx* offers a high level of compatibility, not everything
is perfect. Below is a list of limitations that may or may not be
addressed in later versions of *amx* and Multi Theft Auto.

-   The following scripting functions are currently not implemented and
    will have no effect when called: AllowAdminTeleport,
    AllowInteriorWeapons, AllowPlayerTeleport,
    DisableInteriorEnterExits, EnableStuntBonusForAll,
    EnableStuntBonusForPlayer, EnableTirePopping (tire popping is always
    on), EnableZoneNames, LimitGlobalChatRadius, PlayerPlaySound,
    SendDeathMessage (use the \"killmessages\" resource on your server
    instead for graphical death messages), SetDeathDropAmount,
    SetDisabledWeapons, SetEchoDestination, SetNameTagDrawDistance,
    SetPlayerDisabledWeapons, SetTeamCount, SetVehicleNumberPlate,
    ShowPlayerNameTagForPlayer, TextDrawSetProportional,
    UsePlayerPedAnims.

Credits
-----------------

*amx* was developed by arc\_. Special thanks go out to:

-   Everyone who tested or participated in group tests during
    development, especially **MeKorea** who quite literally tried out
    every mode and filterscript he could find. His testing brought a
    large number of minor and not so minor flaws to light which could
    then be fixed.

-   **The MTA team**, for providing such a tremendous platform to
    develop on. Thanks to MTA I got to know the amazingly fast yet
    powerful scripting language Lua, and got a good bunch of C++
    practice as well.
