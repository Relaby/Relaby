```lua
--==================================================
-- DQ REBORN
--==================================================

-- documentation
-- https://raw.githubusercontent.com/Relaby/Dear-ReGui/refs/heads/main/readme.md

local ReGui = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/hunterss25/Dear-ReGui/refs/heads/main/ReGui.lua"
))()

--==================================================
-- SERVICES
--==================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local PlayerName = LocalPlayer.Name
local UserId = tostring(LocalPlayer.UserId)

--==================================================
-- FILE SYSTEM
--==================================================

local ConfigFolder = "DQ Reborn/Configs"
local AutoloadFile = ConfigFolder .. "/Autoload_" .. UserId .. ".txt"

if not isfolder("DQ Reborn") then
    makefolder("DQ Reborn")
end

if not isfolder(ConfigFolder) then
    makefolder(ConfigFolder)
end

--==================================================
-- REMOTES
--==================================================

local Remotes = ReplicatedStorage:WaitForChild("remotes")
local ReloadFunction = Remotes:WaitForChild("reloadInvy")
local SellEvent = Remotes:WaitForChild("sellItemEvent")

--==================================================
-- SELL SETTINGS
--==================================================

local SellRarity = {
    common = false,
    uncommon = false,
    rare = false,
    epic = false,
    legendary = false,
}

local SellType = {
    helmet = false,
    chest = false,
    weapon = false,
    ability = false,
}

--==================================================
-- BLACKLIST
--==================================================

local BlacklistedItems = {}

--==================================================
-- CONSOLE
--==================================================

local ConsoleColors = {
    INFO = "100,200,255",
    SUCCESS = "80,220,120",
    WARN = "255,190,50",
    ERROR = "255,70,70",
    DEBUG = "180,120,255",
    SELL = "255,140,80",
    BLACKLIST = "200,100,255",
    CONFIG = "100,220,220",
    AUTOLOAD = "120,255,180",
}

--==================================================
-- MAIN WINDOW
--==================================================

local MainWindow = ReGui:Window({
    Title = "DQ Reborn",
    Size = UDim2.fromOffset(650, 300),
}):Center()

--==================================================
-- CONSOLE WINDOW
--==================================================

local ConsoleWindow = ReGui:Window({
    Title = "DQ Reborn - Console",
    Size = UDim2.fromOffset(600, 300),
    NoClose = true,
})

local ConsoleOpen = false

pcall(function()
    ConsoleWindow:SetVisible(false)
end)

local AdvancedConsole = ConsoleWindow:Console({
    ReadOnly = true,
    AutoScroll = true,
    RichText = true,
    MaxLines = 100,
    Size = UDim2.fromOffset(583, 263),
})

--==================================================
-- CONSOLE HELPERS
--==================================================

local function EscapeRichText(Value)
    Value = tostring(Value or "")
    Value = Value:gsub("&", "&amp;")
    Value = Value:gsub("<", "&lt;")
    Value = Value:gsub(">", "&gt;")
    return Value
end

local function GetTime()
    return DateTime.now():FormatLocalTime(
        "h:mm:ss A",
        "en-us"
    )
end

local function ConsoleLog(Type, Message)
    Type = tostring(Type or "INFO")

    local Color = ConsoleColors[Type] or ConsoleColors.INFO
    local Time = EscapeRichText(GetTime())
    local SafeType = EscapeRichText(Type)
    local SafeMessage = EscapeRichText(Message)

    pcall(function()
        AdvancedConsole:AppendText(
            string.format(
                '<font color="rgb(150,150,150)">[%s]</font> ' ..
                '<font color="rgb(%s)">[%s]</font> %s',
                Time,
                Color,
                SafeType,
                SafeMessage
            )
        )
    end)
end

local function Log(Message)
    ConsoleLog("INFO", Message)
end

local function LogSuccess(Message)
    ConsoleLog("SUCCESS", Message)
end

local function LogWarn(Message)
    ConsoleLog("WARN", Message)
end

local function LogError(Message)
    ConsoleLog("ERROR", Message)
end

local function LogDebug(Message)
    ConsoleLog("DEBUG", Message)
end

local function LogSell(Message)
    ConsoleLog("SELL", Message)
end

local function LogBlacklist(Message)
    ConsoleLog("BLACKLIST", Message)
end

local function LogConfig(Message)
    ConsoleLog("CONFIG", Message)
end

local function LogAutoload(Message)
    ConsoleLog("AUTOLOAD", Message)
end

--==================================================
-- CONSOLE CONTROL
--==================================================

local function SetConsoleVisible(State)
    ConsoleOpen = State

    pcall(function()
        ConsoleWindow:SetVisible(State)
    end)
end

local function ToggleConsole()
    SetConsoleVisible(not ConsoleOpen)

    if ConsoleOpen then
        Log("Console opened.")
    end
end

--==================================================
-- BLACKLIST FUNCTIONS
--==================================================

local function IsBlacklisted(ItemName)
    if not ItemName then
        return false
    end

    ItemName = tostring(ItemName):lower()

    for _, BlacklistName in ipairs(BlacklistedItems) do
        BlacklistName = tostring(BlacklistName):lower()

        if ItemName:find(BlacklistName, 1, true) then
            return true
        end
    end

    return false
end

local function AddBlacklistItem(ItemName)
    ItemName = tostring(ItemName or "")
    ItemName = ItemName:gsub("^%s+", "")
    ItemName = ItemName:gsub("%s+$", "")

    if ItemName == "" then
        return false
    end

    for _, ExistingName in ipairs(BlacklistedItems) do
        if ExistingName:lower() == ItemName:lower() then
            return false
        end
    end

    table.insert(
        BlacklistedItems,
        ItemName
    )

    return true
end

local function RemoveBlacklistItem(Index)
    local RemovedName = BlacklistedItems[Index]

    if not RemovedName then
        return false
    end

    table.remove(
        BlacklistedItems,
        Index
    )

    LogBlacklist(
        "Removed: " .. tostring(RemovedName)
    )

    return true
end

--==================================================
-- BLACKLIST SERIALIZATION
--==================================================

local BLACKLIST_BEGIN = "__DQ_BLACKLIST_BEGIN__"
local BLACKLIST_END = "__DQ_BLACKLIST_END__"

local function SerializeBlacklist()
    local Lines = {
        BLACKLIST_BEGIN,
    }

    for _, ItemName in ipairs(BlacklistedItems) do
        table.insert(
            Lines,
            ItemName
        )
    end

    table.insert(
        Lines,
        BLACKLIST_END
    )

    return table.concat(
        Lines,
        "\n"
    )
end

local function ParseBlacklist(ConfigData)
    local StartPosition = ConfigData:find(
        BLACKLIST_BEGIN,
        1,
        true
    )

    if not StartPosition then
        return
    end

    local EndPosition = ConfigData:find(
        BLACKLIST_END,
        StartPosition + #BLACKLIST_BEGIN,
        true
    )

    if not EndPosition then
        return
    end

    local BlacklistData = ConfigData:sub(
        StartPosition + #BLACKLIST_BEGIN,
        EndPosition - 1
    )

    table.clear(
        BlacklistedItems
    )

    for Line in BlacklistData:gmatch("[^\r\n]+") do
        Line = Line:gsub("^%s+", "")
        Line = Line:gsub("%s+$", "")

        if Line ~= "" then
            AddBlacklistItem(Line)
        end
    end

    LogBlacklist(
        "Loaded " ..
        #BlacklistedItems ..
        " blacklisted item(s)."
    )
end

local function ExtractIniData(ConfigData)
    local StartPosition = ConfigData:find(
        BLACKLIST_BEGIN,
        1,
        true
    )

    if not StartPosition then
        return ConfigData
    end

    return ConfigData:sub(
        1,
        StartPosition - 1
    )
end

--==================================================
-- CONFIGURATION SYSTEM
--==================================================

local function BuildFullConfig()
    return ReGui:DumpIni(true)
        .. "\n"
        .. SerializeBlacklist()
end

local function LoadFullConfig(ConfigData)
    if not ConfigData or ConfigData == "" then
        return false, "Empty configuration"
    end

    local IniData = ExtractIniData(
        ConfigData
    )

    local Success, Error = pcall(function()
        ReGui:LoadIni(
            IniData,
            true
        )
    end)

    if not Success then
        return false, Error
    end

    ParseBlacklist(
        ConfigData
    )

    return true
end

--==================================================
-- AUTOLOAD / LAST LOADED CONFIG
--==================================================

local function GetAutoload()
    if not isfile(AutoloadFile) then
        return nil
    end

    local Success, Data = pcall(function()
        return readfile(AutoloadFile)
    end)

    if not Success or not Data then
        return nil
    end

    Data = Data:gsub("^%s+", "")
    Data = Data:gsub("%s+$", "")

    if Data == "" then
        return nil
    end

    return Data
end

local function SetAutoload(ConfigName)
    ConfigName = tostring(ConfigName or "")
    ConfigName = ConfigName:gsub("^%s+", "")
    ConfigName = ConfigName:gsub("%s+$", "")

    if ConfigName == "" then
        return false, "Invalid configuration name"
    end

    local Success, Error = pcall(function()
        writefile(
            AutoloadFile,
            ConfigName
        )
    end)

    if not Success then
        return false, Error
    end

    return true
end

local function ClearAutoload()
    if not isfile(AutoloadFile) then
        return true
    end

    local Success, Error = pcall(function()
        delfile(AutoloadFile)
    end)

    if not Success then
        return false, Error
    end

    return true
end

--==================================================
-- REMEMBER LAST LOADED CONFIG
--==================================================

local function SetLastLoadedConfig(ConfigName)
    local Success, Error = SetAutoload(
        ConfigName
    )

    if Success then
        LogAutoload(
            "Remembered last loaded configuration: " ..
            tostring(ConfigName)
        )
    end

    return Success, Error
end

--==================================================
-- UI SECTIONS
--==================================================

local FarmOptions = MainWindow:CollapsingHeader({
    Title = "Farming",
})

local LobbyOptions = MainWindow:CollapsingHeader({
    Title = "Lobby",
})

local PlayerOptions = MainWindow:CollapsingHeader({
    Title = "Player",
})

local SellOptions = MainWindow:CollapsingHeader({
    Title = "Selling",
})

--==================================================
-- FARM SETTINGS
--==================================================

FarmOptions:Separator()

local FarmRow = FarmOptions:Row()

FarmRow:Checkbox({
    Label = "Auto Farm - Mob Distance:"
})

FarmRow:SliderInt({
    Label = "",
    Format = "%.d/%s",
    Value = 5,
    Minimum = 1,
    Maximum = 32,
    ReadOnly = false,
}):SetValue(8)

local FarmRow2 = FarmOptions:Row()

FarmRow2:Checkbox({
    Label = "Auto Hit - Hit Delay (s):"
})

FarmRow2:DragFloat({
    Label = "",
    Maximum = 2,
    Minimum = 0,
    Value = 0.5
})

local FarmRow3 = FarmOptions:Row()

FarmRow3:Checkbox({
    Label = "Show Route "
})

FarmRow3:Checkbox({
    Label = "Look At Mobs "
})

FarmRow3:Checkbox({
    Label = "Auto Start "
})

FarmRow3:Checkbox({
    Label = "Show Danger Zones "
})

FarmRow3:Checkbox({
    Label = "Auto Cast Ability"
})

--==================================================
-- LOBBY SETTINGS
--==================================================

LobbyOptions:Separator()

local LobbyRow = LobbyOptions:Row()

LobbyRow:Checkbox({
    Label = "Auto Start Best Dungeon"
})

LobbyRow:Checkbox({
    Label = "Claim Daily"
})

local LobbyRow2 = LobbyOptions:Row()

LobbyRow2:Checkbox({
    Label = "Dungeon Request Spam"
})

LobbyRow2:InputText({
    Placeholder = "Enter username",
    Label = "",
    Value = ""
})

local LobbyRow3 = LobbyOptions:Row()

LobbyRow3:Checkbox({
    Label = "Raid Request Spam"
})

--==================================================
-- RARITY SETTINGS
--==================================================

SellOptions:Separator({
    Text = "Rarity",
})

local RarityRow = SellOptions:Row()

local RaritySettings = {
    {
        Label = "Common",
        Flag = "SellCommon",
        Key = "common",
    },
    {
        Label = "Uncommon",
        Flag = "SellUncommon",
        Key = "uncommon",
    },
    {
        Label = "Rare",
        Flag = "SellRare",
        Key = "rare",
    },
    {
        Label = "Epic",
        Flag = "SellEpic",
        Key = "epic",
    },
    {
        Label = "Legendary",
        Flag = "SellLeg",
        Key = "legendary",
    },
}

for _, Setting in ipairs(RaritySettings) do
    RarityRow:Checkbox({
        Label = Setting.Label,
        IniFlag = Setting.Flag,
        Value = false,

        Callback = function(_, Value)
            SellRarity[Setting.Key] = Value

            LogDebug(
                Setting.Label ..
                " selling: " ..
                tostring(Value)
            )
        end,
    })
end

--==================================================
-- TYPE SETTINGS
--==================================================

SellOptions:Separator({
    Text = "Item Type",
})

local TypeRow = SellOptions:Row()

local TypeSettings = {
    {
        Label = "Helmets",
        Flag = "HelmetType",
        Key = "helmet",
    },
    {
        Label = "Chestpieces",
        Flag = "ArmorType",
        Key = "chest",
    },
    {
        Label = "Weapons",
        Flag = "WeaponType",
        Key = "weapon",
    },
    {
        Label = "Spells",
        Flag = "SpellType",
        Key = "ability",
    },
}

for _, Setting in ipairs(TypeSettings) do
    TypeRow:Checkbox({
        Label = Setting.Label,
        IniFlag = Setting.Flag,
        Value = false,

        Callback = function(_, Value)
            SellType[Setting.Key] = Value

            LogDebug(
                Setting.Label ..
                " selling: " ..
                tostring(Value)
            )
        end,
    })
end

--==================================================
-- BLACKLIST SECTION
--==================================================

SellOptions:Separator({
    Text = "Blacklist",
})

local ItemBlacklist = SellOptions:TreeNode({
    Title = "Blacklisted Items",
})

local BlacklistInput = ItemBlacklist:InputText({
    Label = "Example: jotunn helm",
    Placeholder = "Enter item name or partial name...",
})

ItemBlacklist:Label({
    Text = "Blacklisted item names will apply to all item types.",
    TextWrapped = true,
})

--==================================================
-- CURRENT BLACKLIST
--==================================================

local BlacklistList = ItemBlacklist:TreeNode({
    Title = "Current Blacklist",
})

local function RefreshBlacklist()
    for _, Child in ipairs(
        BlacklistList:GetChildren()
    ) do
        pcall(function()
            Child:Destroy()
        end)
    end

    if #BlacklistedItems == 0 then
        BlacklistList:Label({
            Text = "No blacklisted items.",
            TextWrapped = true,
        })

        return
    end

    for Index, ItemName in ipairs(BlacklistedItems) do
        local CurrentIndex = Index

        BlacklistList:Button({
            Text = "Delete: " .. ItemName,

            Callback = function()
                if RemoveBlacklistItem(CurrentIndex) then
                    RefreshBlacklist()
                end
            end,
        })
    end
end

--==================================================
-- ADD BLACKLIST
--==================================================

ItemBlacklist:Button({
    Text = "Blacklist Item",

    Callback = function()
        local ItemName = BlacklistInput:GetValue()

        if not ItemName or ItemName == "" then
            LogWarn(
                "Enter an item name first."
            )

            return
        end

        ItemName = ItemName:gsub(
            "^%s+",
            ""
        )

        ItemName = ItemName:gsub(
            "%s+$",
            ""
        )

        if ItemName == "" then
            return
        end

        if AddBlacklistItem(ItemName) then
            LogBlacklist(
                "Added: " .. ItemName
            )
        else
            LogWarn(
                "Already blacklisted: " ..
                ItemName
            )
        end

        RefreshBlacklist()
    end,
})

RefreshBlacklist()

--==================================================
-- SELLING FUNCTIONS
--==================================================

local function ShouldSellRarity(Rarity)
    if not Rarity then
        return false
    end

    Rarity = tostring(Rarity):lower()

    return SellRarity[Rarity] == true
end

local function GetItemNumber(ItemKey)
    if tonumber(ItemKey) then
        return tonumber(ItemKey)
    end

    local Number = tostring(ItemKey):match(
        "%d+"
    )

    if Number then
        return tonumber(Number)
    end

    return nil
end

--==================================================
-- INVENTORY CATEGORY PROCESSOR
--==================================================

local function ProcessInventoryCategory(
    InventoryCategory,
    SellCategory,
    DisplayName,
    Enabled
)
    local Results = {}

    if not Enabled then
        LogDebug(
            DisplayName ..
            " disabled."
        )

        return Results
    end

    LogSell(
        "Checking " ..
        DisplayName:lower() ..
        "..."
    )

    for ItemKey, Item in pairs(
        InventoryCategory or {}
    ) do
        if Item
            and ShouldSellRarity(Item.rarity)
            and not IsBlacklisted(Item.name)
        then
            local Number = GetItemNumber(
                ItemKey
            )

            if Number then
                table.insert(
                    Results,
                    Number
                )

                LogSell(
                    string.format(
                        "[%s] %s | %s | %s | ID: %s",
                        SellCategory,
                        tostring(ItemKey),
                        tostring(Item.name),
                        tostring(Item.rarity),
                        tostring(Number)
                    )
                )
            end
        end
    end

    return Results
end

--==================================================
-- BUILD SELL LIST
--==================================================

local function BuildSellList()
    LogSell(
        "Refreshing inventory..."
    )

    local Inventory = ReloadFunction:InvokeServer()

    local SellList = {
        helmet = {},
        chest = {},
        weapon = {},
        ability = {},
    }

    SellList.weapon =
        ProcessInventoryCategory(
            Inventory.weapons,
            "WEAPON",
            "Weapons",
            SellType.weapon
        )

    SellList.helmet =
        ProcessInventoryCategory(
            Inventory.helmets,
            "HELMET",
            "Helmets",
            SellType.helmet
        )

    SellList.chest =
        ProcessInventoryCategory(
            Inventory.chests,
            "CHEST",
            "Chestpieces",
            SellType.chest
        )

    SellList.ability =
        ProcessInventoryCategory(
            Inventory.abilities,
            "SPELL",
            "Spells",
            SellType.ability
        )

    return SellList
end

--==================================================
-- SELL SELECTED ITEMS
--==================================================

local function SellSelectedItems()
    LogSell(
        "================================"
    )

    LogSell(
        "SELLING SELECTED ITEMS"
    )

    LogSell(
        "================================"
    )

    local Success, SellList = pcall(
        BuildSellList
    )

    if not Success then
        LogError(
            "Failed to build sell list: " ..
            tostring(SellList)
        )

        return
    end

    LogSell(
        "Helmets: " ..
        #SellList.helmet
    )

    LogSell(
        "Chestpieces: " ..
        #SellList.chest
    )

    LogSell(
        "Weapons: " ..
        #SellList.weapon
    )

    LogSell(
        "Spells: " ..
        #SellList.ability
    )

    LogSell(
        "================================"
    )

    if #SellList.helmet == 0
        and #SellList.chest == 0
        and #SellList.weapon == 0
        and #SellList.ability == 0
    then
        LogWarn(
            "No items matched the current selling settings."
        )

        return
    end

    local FireSuccess, FireError =
        pcall(function()
            SellEvent:FireServer(
                SellList
            )
        end)

    if not FireSuccess then
        LogError(
            "Sell request failed: " ..
            tostring(FireError)
        )

        return
    end

    LogSuccess(
        "Sell request sent!"
    )
end

--==================================================
-- SELL TOGGLE
--==================================================

SellOptions:Separator({})

SellOptions:Checkbox({
    Label = "Sell Selected",
    IniFlag = "SellItems",
    Value = false,

    Callback = function(_, Value)
        if Value then
            LogSell(
                "Sell Selected activated."
            )

            SellSelectedItems()
        else
            LogDebug(
                "Sell Selected deactivated."
            )
        end
    end,
})

--==================================================
-- MENU BAR
--==================================================

local MenuBar = MainWindow:MenuBar()

local FileMenu = MenuBar:MenuItem({
    Text = "File",
})

local ViewMenu = MenuBar:MenuItem({
    Text = "View",
})

--==================================================
-- VIEW MENU
--==================================================

ViewMenu:Selectable({
    Text = "Console",

    Callback = function()
        ToggleConsole()
    end,
})

ViewMenu:Selectable({
    Text = "UI Settings",

    Callback = function()
        LogConfig(
            "Opening UI settings."
        )

        local UISettings = MainWindow:PopupModal({
            Title = "UI Settings",
        })

        UISettings:Checkbox({
            Label = "Show Console on Startup",
            IniFlag = "ConsoleStartup",
            Value = false,

            Callback = function(_, Value)
                if Value then
                    SetConsoleVisible(true)

                    LogConfig(
                        "Console enabled on startup."
                    )
                else
                    SetConsoleVisible(false)

                    LogConfig(
                        "Console disabled on startup."
                    )
                end
            end,
        })

        UISettings:Keybind({
            Value = Enum.KeyCode.K,
            Label = "UI Visibility",

            Callback = function()
                MainWindow:ToggleVisibility()
            end,
        })

        UISettings:Button({
            Text = "Close",

            Callback = function()
                UISettings:ClosePopup()
            end,
        })
    end,
})

--==================================================
-- IMPORT CONFIGURATION
--==================================================

FileMenu:Selectable({
    Text = "Import File",

    Callback = function()
        LogConfig(
            "Opening import configuration."
        )

        local ImportModal = MainWindow:PopupModal({
            Title = "Import Configuration",
        })

        ImportModal:Label({
            Text = "Paste your configuration below:",
            TextWrapped = true,
        })

        local ConfigInput = ImportModal:InputText({
            Placeholder = "Paste configuration data here...",
            MultiLine = true,
        })

        ImportModal:Button({
            Text = "Import",

            Callback = function()
                local ConfigData =
                    ConfigInput:GetValue()

                if not ConfigData
                    or ConfigData == ""
                then
                    LogWarn(
                        "No configuration data."
                    )

                    return
                end

                local Success, Error =
                    LoadFullConfig(
                        ConfigData
                    )

                if not Success then
                    LogError(
                        "Failed to import configuration: " ..
                        tostring(Error)
                    )

                    return
                end

                RefreshBlacklist()

                LogSuccess(
                    "Configuration imported!"
                )

                ImportModal:ClosePopup()
            end,
        })

        ImportModal:Button({
            Text = "Close",

            Callback = function()
                ImportModal:ClosePopup()

                LogConfig(
                    "Import cancelled."
                )
            end,
        })
    end,
})

--==================================================
-- SAVE CONFIGURATION
--==================================================

FileMenu:Selectable({
    Text = "Save File",

    Callback = function()
        LogConfig(
            "Opening save configuration."
        )

        local SaveModal = MainWindow:PopupModal({
            Title = "Save Configuration",
        })

        SaveModal:Label({
            Text = "Enter a name for your configuration:",
            TextWrapped = true,
        })

        local NameInput = SaveModal:InputText({
            Placeholder = "Example: Default",
        })

        SaveModal:Button({
            Text = "Save",

            Callback = function()
                local ConfigName =
                    NameInput:GetValue()

                if not ConfigName
                    or ConfigName == ""
                then
                    LogWarn(
                        "Please enter a configuration name!"
                    )

                    return
                end

                ConfigName = ConfigName:gsub(
                    "[\\/:*?\"<>|]",
                    ""
                )

                ConfigName = ConfigName:gsub(
                    "^%s+",
                    ""
                )

                ConfigName = ConfigName:gsub(
                    "%s+$",
                    ""
                )

                if ConfigName == "" then
                    LogWarn(
                        "Invalid configuration name!"
                    )

                    return
                end

                local ConfigData =
                    BuildFullConfig()

                local FilePath =
                    ConfigFolder
                    .. "/"
                    .. ConfigName
                    .. ".ini"

                local Success, Error =
                    pcall(function()
                        writefile(
                            FilePath,
                            ConfigData
                        )
                    end)

                if not Success then
                    LogError(
                        "Failed to save configuration: " ..
                        tostring(Error)
                    )

                    return
                end

                LogSuccess(
                    "Configuration saved: " ..
                    FilePath
                )

                SaveModal:ClosePopup()
            end,
        })

        SaveModal:Button({
            Text = "Close",

            Callback = function()
                SaveModal:ClosePopup()

                LogConfig(
                    "Save cancelled."
                )
            end,
        })
    end,
})

--==================================================
-- READ CONFIG FILE
--==================================================

local function ReadConfigFile(FilePath)
    local Success, Data =
        pcall(function()
            return readfile(FilePath)
        end)

    if not Success or not Data then
        return false, nil
    end

    return true, Data
end

--==================================================
-- SAVED CONFIGURATIONS
--==================================================

local function OpenSavedConfigs()
    LogConfig(
        "Opening saved configurations."
    )

    local SavedModal = MainWindow:PopupModal({
        Title = "Saved Configurations",
    })

    SavedModal:Label({
        Text = "Load, copy, autoload, or delete a saved configuration.",
        TextWrapped = true,
    })

    local Files = {}

    local Success, Result =
        pcall(function()
            return listfiles(ConfigFolder)
        end)

    if Success and Result then
        Files = Result
    else
        LogError(
            "Failed to list configuration files."
        )
    end

    local AutoloadName =
        GetAutoload()

    local ConfigCount = 0

    for _, FilePath in ipairs(Files) do
        if FilePath:lower():sub(-4) == ".ini" then
            local FileName =
                FilePath:match(
                    "([^/\\]+)%.ini$"
                )

            if FileName then
                ConfigCount += 1

                local DisplayName =
                    FileName

                if AutoloadName == FileName then
                    DisplayName =
                        FileName ..
                        " [AUTOLOAD]"
                end

                SavedModal:Separator({
                    Text = DisplayName,
                })

                local ConfigRow =
                    SavedModal:Row()

                --==================================================
                -- LOAD
                --==================================================

                ConfigRow:Button({
                    Text = "Load",

                    Callback = function()
                        LogConfig(
                            "Loading configuration: " ..
                            FileName
                        )

                        local ReadSuccess,
                            ConfigData =
                            ReadConfigFile(
                                FilePath
                            )

                        if not ReadSuccess then
                            LogError(
                                "Failed to read configuration: " ..
                                FilePath
                            )

                            return
                        end

                        local LoadSuccess,
                            Error =
                            LoadFullConfig(
                                ConfigData
                            )

                        if not LoadSuccess then
                            LogError(
                                "Failed to load configuration: " ..
                                tostring(Error)
                            )

                            return
                        end

                        RefreshBlacklist()

                        local AutoSuccess,
                            AutoError =
                            SetLastLoadedConfig(
                                FileName
                            )

                        if not AutoSuccess then
                            LogWarn(
                                "Failed to remember last loaded config: " ..
                                tostring(AutoError)
                            )
                        end

                        LogSuccess(
                            "Loaded configuration: " ..
                            FileName
                        )

                        SavedModal:ClosePopup()
                    end,
                })

                --==================================================
                -- COPY
                --==================================================

                ConfigRow:Button({
                    Text = "Copy",

                    Callback = function()
                        local ReadSuccess,
                            ConfigData =
                            ReadConfigFile(
                                FilePath
                            )

                        if not ReadSuccess then
                            LogError(
                                "Failed to read configuration: " ..
                                FilePath
                            )

                            return
                        end

                        if not setclipboard then
                            LogWarn(
                                "setclipboard is not supported."
                            )

                            return
                        end

                        local CopySuccess,
                            Error =
                            pcall(function()
                                setclipboard(
                                    ConfigData
                                )
                            end)

                        if not CopySuccess then
                            LogError(
                                "Failed to copy configuration: " ..
                                tostring(Error)
                            )

                            return
                        end

                        LogSuccess(
                            "Copied configuration data: " ..
                            FileName
                        )
                    end,
                })

                --==================================================
                -- AUTOLOAD
                --==================================================

                ConfigRow:Button({
                    Text = "Autoload",

                    Callback = function()
                        local SetSuccess,
                            SetError =
                            SetAutoload(
                                FileName
                            )

                        if not SetSuccess then
                            LogError(
                                "Failed to set autoload: " ..
                                tostring(SetError)
                            )

                            return
                        end

                        LogAutoload(
                            "Set autoload: " ..
                            FileName ..
                            " for " ..
                            PlayerName ..
                            " (" ..
                            UserId ..
                            ")"
                        )

                        SavedModal:ClosePopup()

                        task.defer(
                            OpenSavedConfigs
                        )
                    end,
                })

                --==================================================
                -- DELETE
                --==================================================

                ConfigRow:Button({
                    Text = "Delete",

                    Callback = function()
                        if GetAutoload() == FileName then
                            local ClearSuccess,
                                ClearError =
                                ClearAutoload()

                            if not ClearSuccess then
                                LogError(
                                    "Failed to clear autoload: " ..
                                    tostring(ClearError)
                                )

                                return
                            end

                            LogAutoload(
                                "Cleared autoload: " ..
                                FileName
                            )
                        end

                        local DeleteSuccess,
                            Error =
                            pcall(function()
                                delfile(
                                    FilePath
                                )
                            end)

                        if not DeleteSuccess then
                            LogError(
                                "Failed to delete configuration: " ..
                                tostring(Error)
                            )

                            return
                        end

                        LogSuccess(
                            "Deleted configuration: " ..
                            FileName
                        )

                        SavedModal:ClosePopup()

                        task.defer(
                            OpenSavedConfigs
                        )
                    end,
                })
            end
        end
    end

    if ConfigCount == 0 then
        SavedModal:Label({
            Text = "No saved configurations.",
            TextWrapped = true,
        })

        LogConfig(
            "No saved configurations found."
        )
    else
        LogConfig(
            "Found " ..
            ConfigCount ..
            " saved configuration(s)."
        )
    end

    SavedModal:Button({
        Text = "Close",

        Callback = function()
            SavedModal:ClosePopup()

            LogConfig(
                "Saved configurations closed."
            )
        end,
    })
end

--==================================================
-- SAVED FILES MENU
--==================================================

FileMenu:Selectable({
    Text = "Saved Files",

    Callback = function()
        OpenSavedConfigs()
    end,
})

--==================================================
-- AUTOMATICALLY LOAD LAST CONFIG
--==================================================

task.defer(function()
    local AutoloadName =
        GetAutoload()

    if not AutoloadName then
        LogAutoload(
            "No previously loaded configuration found."
        )

        return
    end

    LogAutoload(
        "Found last loaded configuration: " ..
        AutoloadName
    )

    local AutoloadPath =
        ConfigFolder ..
        "/" ..
        AutoloadName ..
        ".ini"

    if not isfile(AutoloadPath) then
        LogWarn(
            "Last loaded configuration no longer exists: " ..
            AutoloadName
        )

        local ClearSuccess,
            ClearError =
            ClearAutoload()

        if not ClearSuccess then
            LogError(
                "Failed to clear invalid autoload: " ..
                tostring(ClearError)
            )
        end

        return
    end

    local ReadSuccess,
        ConfigData =
        ReadConfigFile(
            AutoloadPath
        )

    if not ReadSuccess then
        LogError(
            "Failed to read last loaded configuration: " ..
            AutoloadName
        )

        return
    end

    local LoadSuccess,
        Error =
        LoadFullConfig(
            ConfigData
        )

    if not LoadSuccess then
        LogError(
            "Failed to load last loaded configuration: " ..
            tostring(Error)
        )

        return
    end

    RefreshBlacklist()

    LogAutoload(
        "Automatically loaded: " ..
        AutoloadName ..
        " for " ..
        PlayerName ..
        " (" ..
        UserId ..
        ")"
    )
end)

--==================================================
-- AUTOSPINS LOADER
--==================================================

local ScriptURL =
    "https://raw.githubusercontent.com/Relaby/Relaby/refs/heads/main/scripts/autospins.lua"

local AutoSpinsLoader = [[
loadstring(game:HttpGet("]] .. ScriptURL .. [["))()
]]

local function LoadAutoSpins()
    LogAutoload(
        "Loading AutoSpins..."
    )

    local Success, Error =
        pcall(function()
            loadstring(AutoSpinsLoader)()
        end)

    if Success then
        LogSuccess(
            "AutoSpins loaded successfully."
        )
    else
        LogError(
            "Failed to load AutoSpins: " ..
            tostring(Error)
        )
    end

    if queueonteleport then
        local QueueSuccess,
            QueueError =
            pcall(function()
                queueonteleport(
                    AutoSpinsLoader
                )
            end)

        if QueueSuccess then
            LogAutoload(
                "AutoSpins queued for teleport."
            )
        else
            LogWarn(
                "Failed to queue AutoSpins: " ..
                tostring(QueueError)
            )
        end
    else
        LogWarn(
            "queueonteleport is not supported."
        )
    end
end

--==================================================
-- STARTUP
--==================================================

Log(
    "DQ Reborn console initialized."
)

Log(
    "Player: " ..
    PlayerName
)

Log(
    "UserId: " ..
    UserId
)

LogSuccess(
    "DQ Reborn initialized successfully."
)

task.defer(function()
    LoadAutoSpins()
end)
```
