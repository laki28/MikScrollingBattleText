-------------------------------------------------------------------------------
-- Title: Mik's Scrolling Battle Text Profiles
-- Author: Mikord
-------------------------------------------------------------------------------

-- Create module and set its name.
local module = {}
local moduleName = "Profiles"
MikSBT[moduleName] = module


-------------------------------------------------------------------------------
-- Imports.
-------------------------------------------------------------------------------

-- Local references to various modules for faster access.
local L = MikSBT.translations

-- Local references to various functions for faster access.
local string_find = string.find
local string_gsub = string.gsub
local string_format = string.format
local CopyTable = MikSBT.CopyTable
local EraseTable = MikSBT.EraseTable
local SplitString = MikSBT.SplitString
local Print = MikSBT.Print
local GetSkillName = MikSBT.GetSkillName

local IsClassic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC


-------------------------------------------------------------------------------
-- Private constants.
-------------------------------------------------------------------------------

local DEFAULT_PROFILE_NAME = "Default"

-- The .toc entries for saved variables.
local SAVED_VARS_NAME			= "MSBTProfiles_SavedVars"
local SAVED_VARS_PER_CHAR_NAME	= "MSBTProfiles_SavedVarsPerChar"
local SAVED_MEDIA_NAME			= "MSBT_SavedMedia"

-- Localized pet name followed by a space.
local PET_SPACE = PET .. " "

-- Flags used by the combat log.
local FLAG_YOU 					= 0xF0000000
local TARGET_TARGET				= 0x00010000
local REACTION_HOSTILE			= 0x00000040


-- Spell IDs.

-------------------------------------------------------------------------------
-- Private variables.
-------------------------------------------------------------------------------

--- Prevent tainting global _.
local _

-- Dynamically created frame for receiving events.
local eventFrame

-- Meta table for the differential profile tables.
local differentialMap = {}
local differential_mt = { __index = function(t,k) return differentialMap[t][k] end }
local differentialCache = {}

-- Holds variables to be saved between sessions.
local savedVariables
local savedVariablesPerChar
local savedMedia

-- Currently selected profile.
local currentProfile

-- Path information for setting differential options.
local pathTable = {}

-- Flag to hold whether or not this is the first load.
local isFirstLoad


-------------------------------------------------------------------------------
-- Master profile utility functions.
-------------------------------------------------------------------------------

-- ****************************************************************************
-- Returns a table to be used for the settings of the passed class using color
-- information from the default class colors table.
-- ****************************************************************************
local function CreateClassSettingsTable(class)
	-- Return disabled settings if the class doesn't exist in the default class colors table for some reason.
	if (not RAID_CLASS_COLORS[class]) then return { disabled = true, colorR = 1, colorG = 1, colorB = 1 } end
	-- Return a table using the default class color.
	return { colorR = RAID_CLASS_COLORS[class].r, colorG = RAID_CLASS_COLORS[class].g, colorB = RAID_CLASS_COLORS[class].b }
end



-------------------------------------------------------------------------------
-- Master profile.
-------------------------------------------------------------------------------

local masterProfile
	masterProfile = {
		-- Scroll area settings.
		scrollAreas = {
			Incoming = {
				name					= L.MSG_INCOMING,
				offsetX					= -140,
				offsetY					= -160,
				animationStyle			= "Parabola",
				direction				= "Down",
				behavior				= "CurvedLeft",
				stickyBehavior			= "Jiggle",
				textAlignIndex			= 3,
				stickyTextAlignIndex	= 3,
			},
			Outgoing = {
				name					= L.MSG_OUTGOING,
				offsetX					= 100,
				offsetY					= -160,
				animationStyle			= "Parabola",
				direction				= "Down",
				behavior				= "CurvedRight",
				stickyBehavior			= "Jiggle",
				textAlignIndex			= 1,
				stickyTextAlignIndex	= 1,
				iconAlign				= "Right",
			},
			Notification = {
				name					= L.MSG_NOTIFICATION,
				offsetX					= -175,
				offsetY					= 120,
				scrollHeight			= 200,
				scrollWidth				= 350,
			},
			Static = {
				name					= L.MSG_STATIC,
				offsetX					= -20,
				offsetY					= -300,
				scrollHeight			= 125,
				animationStyle			= "Static",
				direction				= "Down",
			},
		},


		-- Built-in event settings.
		events = {
			INCOMING_DAMAGE = {
				colorR		= 0.80, 
				colorG		= 0.35,
				colorB		= 0.35,
				message		= "(%n) -%a",
				scrollArea	= "Incoming",
			},
			INCOMING_DAMAGE_CRIT = {
				colorR		= 0.80, 
				colorG		= 0.35,
				colorB		= 0.35,
				message		= "(%n) -%a",
				scrollArea	= "Incoming",
				isCrit		= true,
			},
			INCOMING_MISS = {
				colorR		= 0.35 ,
				colorG		= 0.35,
				colorB      = 0.80,
				message		= MISS .. "!",
				scrollArea	= "Incoming",
			},
			INCOMING_DODGE = {
				colorR		= 0.35 ,
				colorG		= 0.35,
				colorB      = 0.80,
				message		= DODGE .. "!",
				scrollArea	= "Incoming",
			},
			INCOMING_PARRY = {
				colorR		= 0.35 ,
				colorG		= 0.35,
				colorB      = 0.80,
				message		= PARRY .. "!",
				scrollArea	= "Incoming",
			},
			INCOMING_BLOCK = {
				colorR		= 0.35 ,
				colorG		= 0.35,
				colorB      = 0.80,
				message		= BLOCK .. "!",
				scrollArea	= "Incoming",
			},
			INCOMING_DEFLECT = {
				colorR		= 0.35 ,
				colorG		= 0.35,
				colorB      = 0.80,
				message		= DEFLECT .. "!",
				scrollArea	= "Incoming",
			},
			INCOMING_ABSORB = {
				colorR		= 1 ,
				colorG		= 0.85,
				colorB      = 0.72,
				message		= ABSORB .. "! <%a>",
				scrollArea	= "Incoming",
			},
			INCOMING_IMMUNE = {
				colorR		= 1 ,
				colorG		= 0.85,
				colorB      = 0.72,
				message		= IMMUNE .. "!",
				scrollArea	= "Incoming",
			},
			INCOMING_SPELL_DAMAGE = {
				colorR		= 0.80, 
				colorG		= 0.35,
				colorB		= 0.35,
				message		= "(%s) -%a",
				scrollArea	= "Incoming",
			},
			INCOMING_SPELL_DAMAGE_CRIT = {
				colorR		= 0.80, 
				colorG		= 0.35,
				colorB		= 0.35,
				message		= "(%s) -%a",
				scrollArea	= "Incoming",
				isCrit		= true,
			},
			INCOMING_SPELL_DAMAGE_SHIELD = {
				colorR		= 0.80, 
				colorG		= 0.35,
				colorB		= 0.35,
				message		= "(%s) -%a",
				scrollArea	= "Incoming",
			},
			INCOMING_SPELL_DAMAGE_SHIELD_CRIT = {
				colorR		= 0.80, 
				colorG		= 0.35,
				colorB		= 0.35,
				message		= "(%s) -%a",
				scrollArea	= "Incoming",
				isCrit		= true,
			},
			INCOMING_SPELL_DOT = {
				colorR		= 0.80, 
				colorG		= 0.35,
				colorB		= 0.35,
				message		= "(%s) -%a",
				scrollArea	= "Incoming",
			},
			INCOMING_SPELL_DOT_CRIT = {
				colorR		= 0.80, 
				colorG		= 0.35,
				colorB		= 0.35,
				message		= "(%s) -%a",
				scrollArea	= "Incoming",
				isCrit		= true,
			},
			INCOMING_SPELL_MISS = {
				colorR		= 0.35 ,
				colorG		= 0.35,
				colorB      = 0.80,
				message		= "(%s) " .. MISS .. "!",
				scrollArea	= "Incoming",
			},
			INCOMING_SPELL_DODGE = {
				colorR		= 0.35 ,
				colorG		= 0.35,
				colorB      = 0.80,
				message		= "(%s) " .. DODGE .. "!",
				scrollArea	= "Incoming",
			},
			INCOMING_SPELL_PARRY = {
				colorR		= 0.35 ,
				colorG		= 0.35,
				colorB      = 0.80,
				message		= "(%s) " .. PARRY .. "!",
				scrollArea	= "Incoming",
			},
			INCOMING_SPELL_BLOCK = {
				colorR		= 0.35 ,
				colorG		= 0.35,
				colorB      = 0.80,
				message		= "(%s) " .. BLOCK .. "!",
				scrollArea	= "Incoming",
			},
			INCOMING_SPELL_DEFLECT = {
				colorR		= 0.35 ,
				colorG		= 0.35,
				colorB      = 0.80,
				message		= "(%s) " .. DEFLECT .. "!",
				scrollArea	= "Incoming",
			},
			INCOMING_SPELL_RESIST = {
				colorR		= 0.5,
				colorG		= 0,
				colorB		= 0.5,
				message		= "(%s) " .. RESIST .. "!",
				scrollArea	= "Incoming",
			},
			INCOMING_SPELL_ABSORB = {
				colorR		= 1 ,
				colorG		= 0.85,
				colorB      = 0.72,
				message		= "(%s) " .. ABSORB .. "! <%a>",
				scrollArea	= "Incoming",
			},
			INCOMING_SPELL_IMMUNE = {
				colorR		= 1 ,
				colorG		= 0.85,
				colorB      = 0.72,
				message		= "(%s) " .. IMMUNE .. "!",
				scrollArea	= "Incoming",
			},
			INCOMING_SPELL_REFLECT = {
				colorR		= 0.5,
				colorG		= 0,
				colorB		= 0.5,
				message		= "(%s) " .. REFLECT .. "!",
				scrollArea	= "Incoming",
			},
			INCOMING_SPELL_INTERRUPT = {
				colorR		= 1 ,
				colorG		= 0.85,
				colorB      = 0.72,
				message		= "(%s) " .. INTERRUPT .. "!",
				scrollArea	= "Incoming",
			},
			INCOMING_HEAL = {
				colorR		= 0.60,
				colorG		= 0.80,
				colorB      = 0.20,
				message		= "(%s - %n) +%a",
				scrollArea	= "Incoming",
			},
			INCOMING_HEAL_CRIT = {
				colorR		= 0.60,
				colorG		= 0.80,
				colorB      = 0.20,
				message		= "(%s - %n) +%a",
				fontSize		= 22,
				scrollArea	= "Incoming",
				isCrit		= true,
			},
			INCOMING_HOT = {
				colorR		= 0.60,
				colorG		= 0.80,
				colorB      = 0.20,
				message		= "(%s - %n) +%a",
				scrollArea	= "Incoming",
			},
			INCOMING_HOT_CRIT = {
				colorR		= 0.60,
				colorG		= 0.80,
				colorB      = 0.20,
				message		= "(%s - %n) +%a",
				scrollArea	= "Incoming",
				isCrit		= true,
			},
			SELF_HEAL = {
				colorR		= 0.60,
				colorG		= 0.80,
				colorB      = 0.20,
				message		= "(%s - %n) +%a",
				scrollArea	= "Incoming",
			},
			SELF_HEAL_CRIT = {
				colorR		= 0.60,
				colorG		= 0.80,
				colorB      = 0.20,
				message		= "(%s - %n) +%a",
				fontSize		= 22,
				scrollArea	= "Incoming",
				isCrit		= true,
			},
			SELF_HOT = {
				colorR		= 0.60,
				colorG		= 0.80,
				colorB      = 0.20,
				message		= "(%s - %n) +%a",
				scrollArea	= "Incoming",
			},
			SELF_HOT_CRIT = {
				colorR		= 0.60,
				colorG		= 0.80,
				colorB      = 0.20,
				message		= "(%s - %n) +%a",
				scrollArea	= "Incoming",
				isCrit		= true,
			},
			INCOMING_ENVIRONMENTAL = {
				colorR		= 0.80, 
				colorG		= 0.35,
				colorB		= 0.35,
				message		= "-%a %e",
				scrollArea	= "Incoming",
			},


			OUTGOING_DAMAGE = {
				message		= "%a",
				scrollArea	= "Outgoing",
			},
			OUTGOING_DAMAGE_CRIT = {
				message		= "%a",
				scrollArea	= "Outgoing",
				isCrit		= true,
			},
			OUTGOING_MISS = {
				message		= MISS .. "!",
				scrollArea	= "Outgoing",
			},
			OUTGOING_DODGE = {
				message		= DODGE .. "!",
				scrollArea	= "Outgoing",
			},
			OUTGOING_PARRY = {
				message		= PARRY .. "!",
				scrollArea	= "Outgoing",
			},
			OUTGOING_BLOCK = {
				message		= BLOCK .. "!",
				scrollArea	= "Outgoing",
			},
			OUTGOING_DEFLECT = {
				message		= DEFLECT.. "!",
				scrollArea	= "Outgoing",
			},
			OUTGOING_ABSORB = {
				colorR		= 1 ,
				colorG		= 0.85,
				colorB      = 0.72,
				message		= "<%a> " .. ABSORB .. "!",
				scrollArea	= "Outgoing",
			},
			OUTGOING_IMMUNE = {
				colorR		= 1 ,
				colorG		= 0.85,
				colorB      = 0.72,
				message		= IMMUNE .. "!",
				scrollArea	= "Outgoing",
			},
			OUTGOING_EVADE = {
				colorG		= 0.5,
				colorB		= 0,
				message		= EVADE .. "!",
				fontSize		= 22,
				scrollArea	= "Outgoing",
			},
			OUTGOING_SPELL_DAMAGE = {
				colorR		= 1 ,
				colorG		= 0.85,
				colorB      = 0.72,
				message		= "%a (%s)",
				scrollArea	= "Outgoing",
			},
			OUTGOING_SPELL_DAMAGE_CRIT = {
				colorR		= 1 ,
				colorG		= 0.85,
				colorB      = 0.72,
				message		= "%a (%s)",
				scrollArea	= "Outgoing",
				isCrit		= true,
			},
			OUTGOING_SPELL_DAMAGE_SHIELD = {
				colorR		= 1 ,
				colorG		= 0.85,
				colorB      = 0.72,
				message		= "%a (%s)",
				scrollArea	= "Outgoing",
			},
			OUTGOING_SPELL_DAMAGE_SHIELD_CRIT = {
				colorR		= 1 ,
				colorG		= 0.85,
				colorB      = 0.72,
				message		= "%a (%s)",
				scrollArea	= "Outgoing",
				isCrit		= true,
			},
			OUTGOING_SPELL_DOT = {
				colorR		= 1 ,
				colorG		= 0.85,
				colorB      = 0.72,
				message		= "%a (%s)",
				scrollArea	= "Outgoing",
			},
			OUTGOING_SPELL_DOT_CRIT = {
				colorR		= 1 ,
				colorG		= 0.85,
				colorB      = 0.72,
				message		= "%a (%s)",
				scrollArea	= "Outgoing",
				isCrit		= true,
			},
			OUTGOING_SPELL_MISS = {
				message		= MISS .. "! (%s)",
				scrollArea	= "Outgoing",
			},
			OUTGOING_SPELL_DODGE = {
				message		= DODGE .. "! (%s)",
				scrollArea	= "Outgoing",
			},
			OUTGOING_SPELL_PARRY = {
				message		= PARRY .. "! (%s)",
				scrollArea	= "Outgoing",
			},
			OUTGOING_SPELL_BLOCK = {
				message		= BLOCK .. "! (%s)",
				scrollArea	= "Outgoing",
			},
			OUTGOING_SPELL_DEFLECT = {
				message		= DEFLECT .. "! (%s)",
				scrollArea	= "Outgoing",
			},
			OUTGOING_SPELL_RESIST = {
				colorR		= 0.5,
				colorG		= 0.5,
				colorB		= 0.698,
				message		= RESIST .. "! (%s)",
				scrollArea	= "Outgoing",
			},
			OUTGOING_SPELL_ABSORB = {
				colorR		= 1 ,
				colorG		= 0.85,
				colorB      = 0.72,
				message		= "<%a> " .. ABSORB .. "! (%s)",
				scrollArea	= "Outgoing",
			},
			OUTGOING_SPELL_IMMUNE = {
				colorR		= 1 ,
				colorG		= 0.85,
				colorB      = 0.72,
				message		= IMMUNE .. "! (%s)",
				scrollArea	= "Outgoing",
			},
			OUTGOING_SPELL_REFLECT = {
				colorR		= 1 ,
				colorG		= 0.85,
				colorB      = 0.72,
				message		= REFLECT .. "! (%s)",
				scrollArea	= "Outgoing",
			},
			OUTGOING_SPELL_INTERRUPT = {
				colorR		= 1 ,
				colorG		= 0.85,
				colorB      = 0.72,
				message		= INTERRUPT .. "! (%s)",
				scrollArea	= "Outgoing",
			},
			OUTGOING_SPELL_EVADE = {
				colorG		= 0.5,
				colorB		= 0,
				message		= EVADE .. "! (%s)",
				fontSize		= 22,
				scrollArea	= "Outgoing",
			},
			OUTGOING_HEAL = {
				colorR		= 0.60,
				colorG		= 0.80,
				colorB      = 0.20,
				message		= "+%a (%s - %n)",
				scrollArea	= "Outgoing",
			},
			OUTGOING_HEAL_CRIT = {
				colorR		= 0.60,
				colorG		= 0.80,
				colorB      = 0.20,
				message		= "+%a (%s - %n)",
				fontSize		= 22,
				scrollArea	= "Outgoing",
				isCrit		= true,
			},
			OUTGOING_HOT = {
				colorR		= 0.60,
				colorG		= 0.80,
				colorB      = 0.20,
				message		= "+%a (%s - %n)",
				scrollArea	= "Outgoing",
			},
			OUTGOING_HOT_CRIT = {
				colorR		= 0.60,
				colorG		= 0.80,
				colorB      = 0.20,
				message		= "+%a (%s - %n)",
				scrollArea	= "Outgoing",
				isCrit		= true,
			},
			OUTGOING_DISPEL = {
				colorB		= 0.5,
				message		= L.MSG_DISPEL .. "! (%s)",
				scrollArea	= "Outgoing",
			},


			PET_INCOMING_DAMAGE = {
				colorG		= 0.41,
				colorB		= 0.41,
				message		= "(%n) " .. PET .. " -%a",
				scrollArea	= "Incoming",
			},
			PET_INCOMING_DAMAGE_CRIT = {
				colorG		= 0.41,
				colorB		= 0.41,
				message		= "(%n) " .. PET .. " -%a",
				scrollArea	= "Incoming",
				isCrit		= true,
			},
			PET_INCOMING_MISS = {
				colorR		= 0.57,
				colorG		= 0.58,
				message		= PET .. " " .. MISS .. "!",
				scrollArea	= "Incoming",
			},
			PET_INCOMING_DODGE = {
				colorR		= 0.57,
				colorG		= 0.58,
				message		= PET .. " " .. DODGE .. "!",
				scrollArea	= "Incoming",
			},
			PET_INCOMING_PARRY = {
				colorR		= 0.57,
				colorG		= 0.58,
				message		= PET .. " " .. PARRY .. "!",
				scrollArea	= "Incoming",
			},
			PET_INCOMING_BLOCK = {
				colorR		= 0.57,
				colorG		= 0.58,
				message		= PET .. " " .. BLOCK .. "!",
				scrollArea	= "Incoming",
			},
			PET_INCOMING_DEFLECT = {
				colorR		= 0.57,
				colorG		= 0.58,
				message		= PET .. " " .. DEFLECT .. "!",
				scrollArea	= "Incoming",
			},
			PET_INCOMING_ABSORB = {
				colorB		= 0.57,
				message		= PET .. " " .. ABSORB .. "! <%a>",
				scrollArea	= "Incoming",
			},
			PET_INCOMING_IMMUNE = {
				colorB		= 0.57,
				message		= PET .. " " .. IMMUNE .. "!",
				scrollArea	= "Incoming",
			},
			PET_INCOMING_SPELL_DAMAGE = {
				colorG		= 0.41,
				colorB		= 0.41,
				message		= "(%s) " .. PET .. " -%a",
				scrollArea	= "Incoming",
			},
			PET_INCOMING_SPELL_DAMAGE_CRIT = {
				colorG		= 0.41,
				colorB		= 0.41,
				message		= "(%s) " .. PET .. " -%a",
				scrollArea	= "Incoming",
				isCrit		= true,
			},
			PET_INCOMING_SPELL_DAMAGE_SHIELD = {
				colorG		= 0.41,
				colorB		= 0.41,
				message		= "(%s) " .. PET .. " -%a",
				scrollArea	= "Incoming",
			},
			PET_INCOMING_SPELL_DAMAGE_SHIELD_CRIT = {
				colorG		= 0.41,
				colorB		= 0.41,
				message		= "(%s) " .. PET .. " -%a",
				scrollArea	= "Incoming",
				isCrit		= true,
			},
			PET_INCOMING_SPELL_DOT = {
				colorG		= 0.41,
				colorB		= 0.41,
				message		= "(%s) " .. PET .. " -%a",
				scrollArea	= "Incoming",
			},
			PET_INCOMING_SPELL_DOT_CRIT = {
				colorG		= 0.41,
				colorB		= 0.41,
				message		= "(%s) " .. PET .. " -%a",
				scrollArea	= "Incoming",
				isCrit		= true,
			},
			PET_INCOMING_SPELL_MISS = {
				colorR		= 0.57,
				colorG		= 0.58,
				message		= "(%s) " .. PET .. " " .. MISS .. "!",
				scrollArea	= "Incoming",
			},
			PET_INCOMING_SPELL_DODGE = {
				colorR		= 0.57,
				colorG		= 0.58,
				message		= "(%s) " .. PET .. " " .. DODGE .. "!",
				scrollArea	= "Incoming",
			},
			PET_INCOMING_SPELL_PARRY = {
				colorR		= 0.57,
				colorG		= 0.58,
				message		= "(%s) " .. PET .. " " .. PARRY .. "!",
				scrollArea	= "Incoming",
			},
			PET_INCOMING_SPELL_BLOCK = {
				colorR		= 0.57,
				colorG		= 0.58,
				message		= "(%s) " .. PET .. " " .. BLOCK .. "!",
				scrollArea	= "Incoming",
			},
			PET_INCOMING_SPELL_DEFLECT = {
				colorR		= 0.57,
				colorG		= 0.58,
				message		= "(%s) " .. PET .. " " .. DEFLECT .. "!",
				scrollArea	= "Incoming",
			},
			PET_INCOMING_SPELL_RESIST = {
				colorR		= 0.94,
				colorG		= 0,
				colorB		= 0.94,
				message		= "(%s) " .. PET .. " " .. RESIST .. "!",
				scrollArea		= "Incoming",
			},
			PET_INCOMING_SPELL_ABSORB = {
				colorB		= 0.57,
				message		= "(%s) " .. PET .. " " .. ABSORB .. "! <%a>",
				scrollArea	= "Incoming",
			},
			PET_INCOMING_SPELL_IMMUNE = {
				colorB		= 0.57,
				message		= "(%s) " .. PET .. " " .. IMMUNE .. "!",
				scrollArea	= "Incoming",
			},
			PET_INCOMING_HEAL = {
				colorR		= 0.57,
				colorB		= 0.57,
				message		= "(%s - %n) " .. PET .. " +%a",
				scrollArea	= "Incoming",
			},
			PET_INCOMING_HEAL_CRIT = {
				colorR		= 0.57,
				colorB		= 0.57,
				message		= "(%s - %n) " .. PET .. " +%a",
				scrollArea	= "Incoming",
				isCrit		= true,
			},
			PET_INCOMING_HOT = {
				colorR		= 0.57,
				colorB		= 0.57,
				message		= "(%s - %n) " .. PET .. " +%a",
				scrollArea	= "Incoming",
			},
			PET_INCOMING_HOT_CRIT = {
				colorR		= 0.57,
				colorB		= 0.57,
				message		= "(%s - %n) " .. PET .. " +%a",
				scrollArea	= "Incoming",
				isCrit		= true,
			},


			PET_OUTGOING_DAMAGE = {
				colorG		= 0.5,
				colorB		= 0,
				message		= PET .. " %a",
				scrollArea	= "Outgoing",
			},
			PET_OUTGOING_DAMAGE_CRIT = {
				colorG		= 0.5,
				colorB		= 0,
				message		= PET .. " %a",
				scrollArea	= "Outgoing",
				isCrit		= true,
			},
			PET_OUTGOING_MISS = {
				colorG		= 0.5,
				colorB		= 0,
				message		= PET .. " " .. MISS,
				scrollArea	= "Outgoing",
			},
			PET_OUTGOING_DODGE = {
				colorG		= 0.5,
				colorB		= 0,
				message		= PET .. " " .. DODGE,
				scrollArea	= "Outgoing",
			},
			PET_OUTGOING_PARRY = {
				colorG		= 0.5,
				colorB		= 0,
				message		= PET .. " " .. PARRY,
				scrollArea	= "Outgoing",
			},
			PET_OUTGOING_BLOCK = {
				colorG		= 0.5,
				colorB		= 0,
				message		= PET .. " " .. BLOCK,
				scrollArea	= "Outgoing",
			},
			PET_OUTGOING_DEFLECT = {
				colorG		= 0.5,
				colorB		= 0,
				message		= PET .. " " .. DEFLECT,
				scrollArea	= "Outgoing",
			},
			PET_OUTGOING_ABSORB = {
				colorR		= 0.5,
				colorG		= 0.5,
				message		= PET .. " <%a> " .. ABSORB,
				scrollArea	= "Outgoing",
			},
			PET_OUTGOING_IMMUNE = {
				colorR		= 0.5,
				colorG		= 0.5,
				message		= PET .. " " .. IMMUNE,
				scrollArea	= "Outgoing",
			},
			PET_OUTGOING_EVADE = {
				colorG		= 0.77,
				colorB		= 0.57,
				message		= PET .. " " .. EVADE,
				fontSize		= 22,
				scrollArea	= "Outgoing",
			},
			PET_OUTGOING_SPELL_DAMAGE = {
				colorR		= 0.33,
				colorG		= 0.33,
				message		= PET .. " %a (%s)",
				scrollArea	= "Outgoing",
			},
			PET_OUTGOING_SPELL_DAMAGE_CRIT = {
				colorR		= 0.33,
				colorG		= 0.33,
				message		= PET .. " %a (%s)",
				scrollArea	= "Outgoing",
				isCrit		= true,
			},
			PET_OUTGOING_SPELL_DAMAGE_SHIELD = {
				colorR		= 0.33,
				colorG		= 0.33,
				message		= PET .. " %a (%s)",
				scrollArea	= "Outgoing",
			},
			PET_OUTGOING_SPELL_DAMAGE_SHIELD_CRIT = {
				colorR		= 0.33,
				colorG		= 0.33,
				message		= PET .. " %a (%s)",
				scrollArea	= "Outgoing",
				isCrit		= true,
			},
			PET_OUTGOING_SPELL_DOT = {
				colorR		= 0.33,
				colorG		= 0.33,
				message		= PET .. " %a (%s)",
				scrollArea	= "Outgoing",
			},
			PET_OUTGOING_SPELL_DOT_CRIT = {
				colorR		= 0.33,
				colorG		= 0.33,
				message		= PET .. " %a (%s)",
				scrollArea	= "Outgoing",
				isCrit		= true,
			},
			PET_OUTGOING_SPELL_MISS = {
				colorR		= 0.33,
				colorG		= 0.33,
				message		= PET .. " " .. MISS .. "! (%s)",
				scrollArea	= "Outgoing",
			},
			PET_OUTGOING_SPELL_DODGE = {
				colorR		= 0.33,
				colorG		= 0.33,
				message		= PET .. " " .. DODGE .. "! (%s)",
				scrollArea	= "Outgoing",
			},
			PET_OUTGOING_SPELL_PARRY = {
				colorR		= 0.33,
				colorG		= 0.33,
				message		= PET .. " " .. PARRY .. "! (%s)",
				scrollArea	= "Outgoing",
			},
			PET_OUTGOING_SPELL_BLOCK = {
				colorR		= 0.33,
				colorG		= 0.33,
				message		= PET .. " " .. BLOCK .. "! (%s)",
				scrollArea	= "Outgoing",
			},
			PET_OUTGOING_SPELL_DEFLECT = {
				colorR		= 0.33,
				colorG		= 0.33,
				message		= PET .. " " .. DEFLECT .. "! (%s)",
				scrollArea	= "Outgoing",
			},
			PET_OUTGOING_SPELL_RESIST = {
				colorR		= 0.73,
				colorG		= 0.73,
				colorB		= 0.84,
				message		= PET .. " " .. RESIST .. "! (%s)",
				scrollArea	= "Outgoing",
			},
			PET_OUTGOING_SPELL_ABSORB = {
				colorR		= 0.5,
				colorG		= 0.5,
				message		= PET .. " <%a> " .. ABSORB .. "! (%s)",
				scrollArea	= "Outgoing",
			},
			PET_OUTGOING_SPELL_IMMUNE = {
				colorR		= 0.5,
				colorG		= 0.5,
				message		= PET .. " " .. IMMUNE .. "! (%s)",
				scrollArea	= "Outgoing",
			},
			PET_OUTGOING_SPELL_EVADE = {
				colorG		= 0.77,
				colorB		= 0.57,
				message		= PET .. " " .. EVADE .. "! (%s)",
				scrollArea	= "Outgoing",
			},
			PET_OUTGOING_HEAL = {
				colorR		= 0.57,
				colorB		= 0.57,
				message		= PET .. " " .. "+%a (%s - %n)",
				scrollArea	= "Outgoing",
			},
			PET_OUTGOING_HEAL_CRIT = {
				colorR		= 0.57,
				colorB		= 0.57,
				message		= PET .. " " .. "+%a (%s - %n)",
				fontSize		= 22,
				scrollArea	= "Outgoing",
				isCrit		= true,
			},
			PET_OUTGOING_HOT = {
				colorR		= 0.57,
				colorB		= 0.57,
				message		= PET .. " " .. "+%a (%s - %n)",
				scrollArea	= "Outgoing",
			},
			PET_OUTGOING_HOT_CRIT = {
				colorR		= 0.57,
				colorB		= 0.57,
				message		= PET .. " " .. "+%a (%s - %n)",
				scrollArea	= "Outgoing",
				isCrit		= true,
			},
			PET_OUTGOING_DISPEL = {
				colorB		= 0.73,
				message		= PET .. " " .. L.MSG_DISPEL .. "! (%s)",
				scrollArea	= "Outgoing",
			},


			NOTIFICATION_DEBUFF = {
				colorR		= 0,
				colorG		= 0.5,
				colorB		= 0.5,
				message		= "[%sl]",
			},
			NOTIFICATION_DEBUFF_STACK = {
				colorR		= 0,
				colorG		= 0.5,
				colorB		= 0.5,
				message		= "[%sl %a]",
			},
			NOTIFICATION_BUFF = {
				colorR		= 0.698,
				colorG		= 0.698,
				colorB		= 0,
				message		= "[%sl]",
			},
			NOTIFICATION_BUFF_STACK = {
				colorR		= 0.698,
				colorG		= 0.698,
				colorB		= 0,
				message		= "[%sl %a]",
			},
			NOTIFICATION_ITEM_BUFF = {
				colorR		= 0.698,
				colorG		= 0.698,
				colorB		= 0.698,
				message		= "[%sl]",
			},
			NOTIFICATION_DEBUFF_FADE = {
				colorR		= 0,
				colorG		= 0.835,
				colorB		= 0.835,
				message		= "-[%sl]",
			},
			NOTIFICATION_BUFF_FADE = {
				colorR		= 0.918,
				colorG		= 0.918,
				colorB		= 0,
				message		= "-[%sl]",
			},
			NOTIFICATION_ITEM_BUFF_FADE = {
				colorR		= 0.831,
				colorG		= 0.831,
				colorB		= 0.831,
				message		= "-[%sl]",
			},
			NOTIFICATION_COMBAT_ENTER = {
				message		= "+" .. L.MSG_COMBAT,
			},
			NOTIFICATION_COMBAT_LEAVE = {
				message		= "-" .. L.MSG_COMBAT,
			},
			NOTIFICATION_POWER_GAIN = {
				colorR		= 1 ,
				colorG		= 0.85,
				colorB      = 0.72,
				message		= "+%a %p",
			},
			NOTIFICATION_POWER_LOSS = {
				colorR		= 1 ,
				colorG		= 0.85,
				colorB      = 0.72,
				message		= "-%a %p",
			},
			NOTIFICATION_ALT_POWER_GAIN = {
				colorR		= 0,
				colorG		= 0.5,
				colorB		= 0.5,
				message		= "+%a %p",
			},
			NOTIFICATION_ALT_POWER_LOSS = {
				colorR		= 0,
				colorG		= 0.5,
				colorB		= 0.5,
				message		= "-%a %p",
			},
			NOTIFICATION_CHI_CHANGE = {
				colorR		= 0.5,
				colorG		= 0.8,
				colorB		= 0.7,
				message		= "%a " .. CHI,
			},
			NOTIFICATION_CHI_FULL = {
				colorR			= 0.5,
				colorG			= 0.8,
				colorB			= 0.7,
				message			= L.MSG_CHI_FULL .. "!",
				alwaysSticky	= true,
				fontSize		= 26,
			},
			NOTIFICATION_AC_CHANGE = {
				colorR		= 0.3,
				colorG		= 0.7,
				colorB		= 0.9,
				message		= "%a " .. L.MSG_AC,
			},
			NOTIFICATION_AC_FULL = {
				colorR			= 0.3,
				colorG			= 0.7,
				colorB			= 0.9,
				message			= L.MSG_AC_FULL .. "!",
				alwaysSticky	= true,
				fontSize		= 26,
			},
			NOTIFICATION_CP_GAIN = {
				colorG		= 0.5,
				colorB		= 0,
				message		= "%a " .. L.MSG_CP,
			},
			NOTIFICATION_CP_FULL = {
				colorR			= 0.8,
				colorG			= 0,
				colorB			= 0,
				message			= L.MSG_CP_FULL .. "!",
				alwaysSticky	= true,
				fontSize		= 26,
			},
			NOTIFICATION_HOLY_POWER_CHANGE = {
				colorG		= 0.5,
				colorB		= 0,
				message		= "%a " .. HOLY_POWER,
			},
			NOTIFICATION_HOLY_POWER_FULL = {
				colorG			= 0.5,
				colorB			= 0,
				message			= L.MSG_HOLY_POWER_FULL .. "!",
				alwaysSticky	= true,
				fontSize		= 26,
			},
			NOTIFICATION_ESSENCE_CHANGE = {
				colorG		= 0.5,
				colorB		= 0,
				message		= "%a " .. L.MSG_ESSENCE,
			},
			NOTIFICATION_ESSENCE_FULL = {
				colorG			= 0.5,
				colorB			= 0,
				message			= L.MSG_ESSENCE_FULL .. "!",
				alwaysSticky	= true,
				fontSize		= 26,
			},
			NOTIFICATION_HONOR_GAIN = {
				colorR		= 0.5,
				colorG		= 0.5,
				colorB		= 0.698,
				message		= "+%a " .. HONOR,
			},
			NOTIFICATION_REP_GAIN = {
				colorR		= 0.5,
				colorG		= 0.5,
				colorB		= 0.698,
				message		= "+%a " .. REPUTATION .. " (%e)",
			},
			NOTIFICATION_REP_LOSS = {
				colorR		= 0.5,
				colorG		= 0.5,
				colorB		= 0.698,
				message		= "-%a " .. REPUTATION .. " (%e)",
			},
			NOTIFICATION_SKILL_GAIN = {
				colorR		= 0.333,
				colorG		= 0.333,
				message		= "%sl: %a",
			},
			NOTIFICATION_EXPERIENCE_GAIN = {
				disabled		= true,
				colorR			= 0.756,
				colorG			= 0.270,
				colorB			= 0.823,
				message			= "%a " .. XP,
				alwaysSticky	= true,
				fontSize		= 26,
			},
			NOTIFICATION_PC_KILLING_BLOW = {
				colorR			= 0.333,
				colorG			= 0.333,
				message			= L.MSG_KILLING_BLOW .. "! (%n)",
				alwaysSticky	= true,
				fontSize		= 26,
			},
			NOTIFICATION_NPC_KILLING_BLOW = {
				disabled		= true,
				colorR			= 0.333,
				colorG			= 0.333,
				message			= L.MSG_KILLING_BLOW .. "! (%n)",
				alwaysSticky	= true,
				fontSize		= 26,
			},
			NOTIFICATION_EXTRA_ATTACK = {
				colorR		= 1 ,
				colorG		= 0.85,
				colorB      = 0.72,
				message		= "%sl!",
				alwaysSticky	= true,
				fontSize		= 26,
			},
			NOTIFICATION_ENEMY_BUFF = {
				colorB		= 0.5,
				message		= "%n: [%sl]",
				scrollArea	= "Static",
			},
			NOTIFICATION_MONSTER_EMOTE = {
				colorG		= 0.5,
				colorB		= 0,
				message		= "%e",
				scrollArea	= "Static",
			},
			NOTIFICATION_MONEY = {
				message		= "+%e",
				scrollArea	= "Static",
			},
			NOTIFICATION_COOLDOWN = {
				message		= "%e " .. L.MSG_READY_NOW .. "!",
				scrollArea	= "Static",
				fontSize	= 22,
				soundFile	= "MSBT Cooldown",
				skillColorR	= 1,
				skillColorG	= 0,
				skillColorB	= 0,
			},
			NOTIFICATION_PET_COOLDOWN = {
				colorR		= 0.57,
				colorG		= 0.58,
				message		= PET .. " %e " .. L.MSG_READY_NOW .. "!",
				scrollArea	= "Static",
				fontSize	= 22,
				soundFile	= "MSBT Cooldown",
				skillColorR	= 1,
				skillColorG	= 0.41,
				skillColorB	= 0.41,
			},
			NOTIFICATION_ITEM_COOLDOWN = {
				colorR		= 0.784,
				colorG		= 0.784,
				colorB		= 0,
				message		= " %e " .. L.MSG_READY_NOW .. "!",
				scrollArea	= "Static",
				fontSize	= 22,
				soundFile	= "MSBT Cooldown",
				skillColorR	= 1,
				skillColorG	= 0.588,
				skillColorB	= 0.588,
			},
			NOTIFICATION_LOOT = {
				colorR		= 1 ,
				colorG		= 0.85,
				colorB      = 0.72,
				message		= "+%a %e (%t)",
				scrollArea	= "Static",
			},
			NOTIFICATION_CURRENCY = {
				colorR		= 1 ,
				colorG		= 0.85,
				colorB      = 0.72,
				message		= "+%a %e (%t)",
				scrollArea	= "Static",
			},
		}, -- End events


		-- Default trigger settings.
		triggers = {
		}, -- End triggers


		-- Master font settings.
		normalFontName		= L.DEFAULT_FONT_NAME,
		normalOutlineIndex	= 1,
		normalFontSize		= 18,
		normalFontAlpha		= 100,
		critFontName		= L.DEFAULT_FONT_NAME,
		critOutlineIndex	= 1,
		critFontSize		= 26,
		critFontAlpha		= 100,


		-- Animation speed.
		animationSpeed		= 100,


		-- Partial effect settings.
		crushing		= { colorR = 0.5, colorG = 0, colorB = 0, trailer = string_gsub(CRUSHING_TRAILER, "%((.+)%)", "<%1>") },
		glancing		= { colorR = 1, colorG = 0, colorB = 0, trailer = string_gsub(GLANCING_TRAILER, "%((.+)%)", "<%1>") },
		absorb			= { colorR = 1, colorG = 1, colorB = 0, trailer = string_gsub(string_gsub(ABSORB_TRAILER, "%((.+)%)", "<%1>"), "%%d", "%%a") },
		block			= { colorR = 0.5, colorG = 0, colorB = 1, trailer = string_gsub(string_gsub(BLOCK_TRAILER, "%((.+)%)", "<%1>"), "%%d", "%%a") },
		resist			= { colorR = 0.5, colorG = 0, colorB = 0.5, trailer = string_gsub(string_gsub(RESIST_TRAILER, "%((.+)%)", "<%1>"), "%%d", "%%a") },
		overheal		= { colorR = 0, colorG = 0.705, colorB = 0.5, trailer = " <%a>" },
		overkill		= { disabled = true, colorR = 0.83, colorG = 0, colorB = 0.13, trailer = " <%a>" },


		-- Damage color settings.
		physical		= { colorR = 1, colorG = 1, colorB = 1 },
		holy			= { colorR = 1, colorG = 1, colorB = 0.627 },
		fire			= { colorR = 1, colorG = 0.5, colorB = 0.5 },
		nature			= { colorR = 0.5, colorG = 1, colorB = 0.5 },
		frost			= { colorR = 0.5, colorG = 0.5, colorB = 1 },
		arcane			= { colorR = 1, colorG = 0.725, colorB = 1 },
		shadow			= { colorR = 0.628, colorG = 0, colorB = 0.628 },
		--[[
		frostfire		= { colorR = 0.8, colorG = 0.302, colorB = 0.498 },
		froststorm		= { colorR = 0.4, colorG = 1, colorB = 0.651 },
		shadowstrike	= { colorR = 0.75, colorG = 0.75, colorB = 1 },
		stormstrike		= { colorR = 0.65, colorG = 1, colorB = 0.65 },
		frostfire		= { colorR = 0.824, colorG = 0.314, colorB = 0.471 },
		shadowflame		= { colorR = 0.824, colorG = 0.5, colorB = 0.628 },
		twilight		= { colorR = 0.75, colorG = 0.7, colorB = 0.75 },
		Plague			= { colorR = 0.75, colorG = 0.5, colorB = 1 },
		Shadowfrost		= { colorR = 0.5, colorG = 0.75, colorB = 1 },
		Spellstrike		= { colorR = 1, colorG = 0.75, colorB = 0.75 },
		Spellfire		= { colorR = 1, colorG = 0.5, colorB = 0.5 },
		Astral			= { colorR = 0.6, colorG = 0.8, colorB = 0.6 },
		Spellfrost		= { colorR = 0.8, colorG = 0.8, colorB = 1 },
		Spellshadow		= { colorR = 0.8, colorG = 0.4, colorB = 1 },
		Elemental		= { colorR = 1, colorG = 1, colorB = 0 },
		Magic			= { colorR = 1, colorG = 0, colorB = 1 },
		chaos			= { colorR = 0.4, colorG = 0, colorB = 0.6 },
		]]

		-- Class color settings.
		DEATHKNIGHT		= CreateClassSettingsTable("DEATHKNIGHT"),
		DRUID			= CreateClassSettingsTable("DRUID"),
		HUNTER			= CreateClassSettingsTable("HUNTER"),
		MAGE			= CreateClassSettingsTable("MAGE"),
		MONK			= CreateClassSettingsTable("MONK"),
		PALADIN			= CreateClassSettingsTable("PALADIN"),
		PRIEST			= CreateClassSettingsTable("PRIEST"),
		ROGUE			= CreateClassSettingsTable("ROGUE"),
		SHAMAN			= CreateClassSettingsTable("SHAMAN"),
		WARLOCK			= CreateClassSettingsTable("WARLOCK"),
		WARRIOR			= CreateClassSettingsTable("WARRIOR"),
		DEMONHUNTER		= CreateClassSettingsTable("DEMONHUNTER"),
		EVOKER			= CreateClassSettingsTable("EVOKER"),

		-- Throttle settings.
		dotThrottleDuration	= 3,
		hotThrottleDuration	= 3,
		powerThrottleDuration	= 3,
		throttleList = {
		},


		-- Spam control settings.
		mergeExclusions		= {},
		abilitySubstitutions	= {},
		abilitySuppressions	= {
		},
		damageThreshold		= 0,
		healThreshold			= 0,
		powerThreshold			= 0,
		hideFullHoTOverheals	= true,
		shortenNumbers			= false,
		shortenNumberPrecision	= 0,
		groupNumbers			= false,

		--[[
		-- Cooldown settings.
		cooldownExclusions		= {},
		ignoreCooldownThreshold		= {},
		cooldownThreshold		= 5,


		-- Loot settings.
		qualityExclusions		= {
			[LE_ITEM_QUALITY_POOR or Enum.ItemQuality.Poor] = true,
		},
		alwaysShowQuestItems	= true,
		itemsAllowed			= {},
		itemExclusions			= {},
		]]
	}



-------------------------------------------------------------------------------
-- Utility functions.
-------------------------------------------------------------------------------

-- ****************************************************************************
-- Dynamically loads the and displays the options.
-- ****************************************************************************
local function ShowOptions()
	-- Load the options module if it's not already loaded.
	local optionsName = "MSBTOptions"
	if (not C_AddOns.IsAddOnLoaded(optionsName)) then
		local loaded, failureReason = C_AddOns.LoadAddOn(optionsName)

		-- Display an error message indicating why the module wasn't loaded if it
		-- didn't load properly.
		if (not loaded) then
			local failureMessage = _G["ADDON_" .. failureReason] or failureReason or ""
			Print(string_format(ADDON_LOAD_FAILED, optionsName, failureMessage))
		end
	end

	-- Display the main frame if the options module is loaded.
	if (C_AddOns.IsAddOnLoaded(optionsName)) then MSBTOptions.Main.ShowMainFrame() end
end


-- ****************************************************************************
-- Recursively removes empty tables and their differential map entries.
-- ****************************************************************************
local function RemoveEmptyDifferentials(currentTable)
	-- Find nested tables in the current table.
	for fieldName, fieldValue in pairs(currentTable) do
		if (type(fieldValue) == "table") then
			-- Recursively clear empty tables in the nested table.
			RemoveEmptyDifferentials(fieldValue)

			-- Remove the table from the differential map and current table if it's
			-- empty.
			if (not next(fieldValue)) then
				differentialMap[fieldValue] = nil
				differentialCache[#differentialCache+1] = fieldValue
				currentTable[fieldName] = nil
			end
		end
	end
end


-- ****************************************************************************
-- Recursively associates the tables in the passed saved table to corresponding
-- entries in the passed master table.
-- ****************************************************************************
local function AssociateDifferentialTables(savedTable, masterTable)
	-- Associate the saved table with the corresponding master entry.
	differentialMap[savedTable] = masterTable
	setmetatable(savedTable, differential_mt)

	-- Look for nested tables that have a corresponding master entry.
	for fieldName, fieldValue in pairs(savedTable) do
		if (type(fieldValue) == "table" and type(masterTable[fieldName]) == "table") then
			-- Recursively call the function to associate nested tables.
			AssociateDifferentialTables(fieldValue, masterTable[fieldName])
		end
	end
end


-- ****************************************************************************
-- Set the passed option to the current profile while handling differential
-- profile mechanics.
-- ****************************************************************************
local function SetOption(optionPath, optionName, optionValue, optionDefault)
	-- Clear the path table.
	EraseTable(pathTable)

	-- Split the passed option path into the path table.
	if (optionPath) then SplitString(optionPath, "%.", pathTable) end

	-- Attempt to go to the option path in the master profile.
	local masterOption = masterProfile
	for _, fieldName in ipairs(pathTable) do
		masterOption = masterOption[fieldName]
		if (not masterOption) then break end
	end

	-- Get the option name from the master profile.
	masterOption = masterOption and masterOption[optionName]

	-- Check if the option being set needs to be overridden.
	local needsOverride = false
	if (optionValue ~= masterOption) then needsOverride = true end

	-- Treat a nil master option the same as false.
	if ((optionValue == false or optionValue == optionDefault) and not masterOption) then
		needsOverride = false
	end

	-- Make the option value false if the option being set is nil and the master option set.
	if (optionValue == nil and masterOption) then optionValue = false end

	-- Start at the root of the current profile and master profile.
	local currentTable = currentProfile
	local masterTable = masterProfile

	-- Override needed.
	if (needsOverride and optionValue ~= nil) then
		-- Loop through all of the fields in path table.
		for _, fieldName in ipairs(pathTable) do
			-- Check if the field doesn't exist in the current profile.
			if (not rawget(currentTable, fieldName)) then
				-- Create a table for the field and setup the associated inheritance table.
				currentTable[fieldName] = table.remove(differentialCache) or {}
				if (masterTable and masterTable[fieldName]) then
					differentialMap[currentTable[fieldName]] = masterTable[fieldName]
					setmetatable(currentTable[fieldName], differential_mt)
				end
			end

			-- Move to the next field in the option path.
			currentTable = currentTable[fieldName]
			masterTable = masterTable and masterTable[fieldName]
		end

		-- Set the option's value.
		currentTable[optionName] = optionValue

	-- Override NOT needed.
	else
	-- Attempt to go to the option path in the current profile.
		for _, fieldName in ipairs(pathTable) do
			currentTable = rawget(currentTable, fieldName)
			if (not currentTable) then return end
		end

		-- Clear the option from the path and remove any empty differential tables.
		if (currentTable) then
			currentTable[optionName] = nil
			RemoveEmptyDifferentials(currentProfile)
		end
	end
end


-- ****************************************************************************
-- Sets up a button to access MSBT's options from the Blizzard interface
-- options AddOns tab.
-- ****************************************************************************
local function SetupBlizzardOptions()
	-- Create a container frame for the Blizzard options area.
	local frame = CreateFrame("Frame")
	frame.name = "MikScrollingBattleText"

	-- Create an option button in the center of the frame to launch MSBT's options.
	local button = CreateFrame("Button", nil, frame, "SettingsCheckBoxControlTemplate")
	button:SetPoint("CENTER")
	button:SetText(MikSBT.COMMAND)
	button:SetScript("OnClick",
		function (this)
			InterfaceOptionsFrameCancel_OnClick()
			HideUIPanel(GameMenuFrame)
			ShowOptions()
		end
	)

	-- Add the frame as a new category to Blizzard's interface options.
	-- InterfaceOptions_AddCategory(frame)
end


-- ****************************************************************************
-- Disable Blizzard's combat text.
-- ****************************************************************************
local function DisableBlizzardCombatText()
	-- Turn off Blizzard's default combat text.
	--[[SetCVar("enableFloatingCombatText", 0)
	if not IsClassic then
		SetCVar("floatingCombatTextCombatHealing", 0)
	end
	SetCVar("floatingCombatTextCombatDamage", 0)
	SHOW_COMBAT_TEXT = "0"
	if (CombatText_UpdateDisplayedMessages) then CombatText_UpdateDisplayedMessages() end]]
end


-- ****************************************************************************
-- Set the user disabled option
-- ****************************************************************************
local function SetOptionUserDisabled(isDisabled)
	savedVariables.userDisabled = isDisabled or nil

	-- Check if the mod is being set to disabled.
	if (isDisabled) then
		-- Disable the cooldowns, triggers, event parser, and main modules.
		-- MikSBT.Cooldowns.Disable()
		MikSBT.Triggers.Disable()
		MikSBT.Parser.Disable()
		MikSBT.Main.Disable()

	else
		-- Enable the main, event parser, triggers, and cooldowns modules.
		MikSBT.Main.Enable()
		MikSBT.Parser.Enable()
		MikSBT.Triggers.Enable()
		-- MikSBT.Cooldowns.Enable()
	end
end


-- ****************************************************************************
-- Returns whether or not the mod is disabled.
-- ****************************************************************************
local function IsModDisabled()
	return savedVariables and savedVariables.userDisabled
end


-- ****************************************************************************
-- Updates the class colors in the master profile with the colors defined in
-- the CUSTOM_CLASS_COLORS table.
-- ****************************************************************************
local function UpdateCustomClassColors()
	for class, colors in pairs(CUSTOM_CLASS_COLORS) do
		if (masterProfile[class]) then
			masterProfile[class].colorR = colors.r or masterProfile[class].colorR
			masterProfile[class].colorG = colors.g or masterProfile[class].colorG
			masterProfile[class].colorB = colors.b or masterProfile[class].colorB
		end
	end
end

-- ****************************************************************************
-- Searches through current profile for all used fonts and uses the animation
-- module to preload each font so they're available for use.
-- ****************************************************************************
local function LoadUsedFonts()
		-- Add the normal and crit master font.
		local usedFonts = {}
		if currentProfile.normalFontName then usedFonts[currentProfile.normalFontName] = true end
		if currentProfile.critFontName then usedFonts[currentProfile.critFontName] = true end

		-- Add any unique fonts used in the scroll areas.
		if currentProfile.scrollAreas then
			for saKey, saSettings in pairs(currentProfile.scrollAreas) do
				if saSettings.normalFontName then usedFonts[saSettings.normalFontName] = true end
				if saSettings.critFontName then usedFonts[saSettings.critFontName] = true end
			end
		end

		-- Add any unique fonts used in the events.
		if currentProfile.events then
			for eventName, eventSettings in pairs(currentProfile.events) do
				if eventSettings.fontName then usedFonts[eventSettings.fontName] = true end
			end
		end

		-- Add any unique fonts used in the triggers.
		if currentProfile.triggers then
			for triggerName, triggerSettings in pairs(currentProfile.triggers) do
				if type(triggerSettings) == "table" then
					if triggerSettings.fontName then usedFonts[triggerSettings.fontName] = true end
				end
			end
		end

		-- Let the animation system preload the fonts.
		for fontName in pairs(usedFonts) do MikSBT.Animations.LoadFont(fontName) end
end




-------------------------------------------------------------------------------
-- Profile functions.
-------------------------------------------------------------------------------

-- ****************************************************************************
-- Updates profiles created with older versions.
-- ****************************************************************************
local function UpdateProfiles()
	-- Loop through all the profiles.
	for profileName, profile in pairs(savedVariables.profiles) do
		-- Get numeric creation version.
		local creationVersion = tonumber(select(3, string_find(tostring(profile.creationVersion), "(%d+%.%d+)")))

		-- Delete triggers if upgrading from a version prior to 5.2.
		if (creationVersion < 5.2) then
			profile.triggers = nil
			profile.creationVersion = MikSBT.VERSION .. "." .. MikSBT.SVN_REVISION
		end
	end
end


-- ****************************************************************************
-- Selects the passed profile.
-- ****************************************************************************
local function SelectProfile(profileName)
	-- Make sure the profile exists.
	if (savedVariables.profiles[profileName]) then
		-- Set the current profile name for the character to the one being selected.
		savedVariablesPerChar.currentProfileName = profileName

		-- Set the current profile pointer.
		currentProfile = savedVariables.profiles[profileName]
		module.currentProfile = currentProfile

		-- Clear the differential table map.
		EraseTable(differentialMap)

		-- Associate the current profile tables with the corresponding master profile entries.
		AssociateDifferentialTables(currentProfile, masterProfile)

		-- Load the fonts used by the profile now so they are available by the time
		-- the first text is shown.
		LoadUsedFonts()

		-- Update the scroll areas and triggers with the current profile settings.
		MikSBT.Animations.UpdateScrollAreas()
		MikSBT.Triggers.UpdateTriggers()
	end
end


-- ****************************************************************************
-- Copies the passed profile to a new profile with the passed name.
-- ****************************************************************************
local function CopyProfile(srcProfileName, destProfileName)
	-- Leave the function if the the destination profile name is invalid.
	if (not destProfileName or destProfileName == "") then return end

	-- Make sure the source profile exists and the destination profile doesn't.
	if (savedVariables.profiles[srcProfileName] and not savedVariables.profiles[destProfileName]) then
		-- Copy the profile.
		savedVariables.profiles[destProfileName] = CopyTable(savedVariables.profiles[srcProfileName])
	end
end


-- ****************************************************************************
-- Deletes the passed profile.
-- ****************************************************************************
local function DeleteProfile(profileName)
	-- Ignore the delete if the passed profile is the default one.
	if (profileName == DEFAULT_PROFILE_NAME) then return end

	-- Make sure the profile exists.
	if (savedVariables.profiles[profileName]) then
		-- Check if the profile being deleted is the current one.
		if (profileName == savedVariablesPerChar.currentProfileName) then
			-- Select the default profile.
			SelectProfile(DEFAULT_PROFILE_NAME)
		end

		-- Delete the profile.
		savedVariables.profiles[profileName] = nil
	end
end


-- ****************************************************************************
-- Resets the passed profile to its defaults.
-- ****************************************************************************
local function ResetProfile(profileName, showOutput)
	-- Set the profile name to the current profile is one wasn't passed.
	if (not profileName) then profileName = savedVariablesPerChar.currentProfileName end

	-- Make sure the profile exists.
	if (savedVariables.profiles[profileName]) then
		-- Reset the profile.
		EraseTable(savedVariables.profiles[profileName])

		-- Reset the profile's creation version.
		savedVariables.profiles[profileName].creationVersion = MikSBT.VERSION .. "." .. MikSBT.SVN_REVISION


		-- Check if it's the current profile being reset.
		if (profileName == savedVariablesPerChar.currentProfileName) then
			-- Reselect the profile to update everything.
			SelectProfile(profileName)
		end

		-- Check if the output text is to be shown.
		if (showOutput) then
			-- Print the profile reset string.
			Print(profileName .. " " .. L.MSG_PROFILE_RESET, 0, 1, 0)
		end
	end
end


-- ****************************************************************************
-- This function initializes the saved variables.
-- ****************************************************************************
local function InitSavedVariables()
	-- Set the saved variables per character to the value specified in the .toc file.
	savedVariablesPerChar = _G[SAVED_VARS_PER_CHAR_NAME]

	-- Check if there are no saved variables per character.
	if (not savedVariablesPerChar) then
		-- Create a new table to hold the saved variables per character, and set the .toc entry to it.
		savedVariablesPerChar = {}
		_G[SAVED_VARS_PER_CHAR_NAME] = savedVariablesPerChar

		-- Set the current profile for the character to the default profile.
		savedVariablesPerChar.currentProfileName = DEFAULT_PROFILE_NAME
	end


	-- Set the saved variables to the value specified in the .toc file.
	savedVariables = _G[SAVED_VARS_NAME]

	-- Check if there are no saved variables.
	if (not savedVariables) then
		-- Create a new table to hold the saved variables, and set the .toc entry to it.
		savedVariables = {}
		_G[SAVED_VARS_NAME] = savedVariables

		-- Create the profiles table and default profile.
		savedVariablesPerChar.currentProfileName = DEFAULT_PROFILE_NAME
		savedVariables.profiles = {}
		savedVariables.profiles[DEFAULT_PROFILE_NAME] = {}

		savedVariables.profiles[DEFAULT_PROFILE_NAME].creationVersion = MikSBT.VERSION .. "." .. MikSBT.SVN_REVISION

		-- Set the first time loaded flag.
		isFirstLoad = true

	-- There are saved variables.
	else
		-- Updates profiles created by older versions.
		UpdateProfiles()
	end

	-- Select the current profile for the character if it exists, otherwise select the default profile.
	if (savedVariables.profiles[savedVariablesPerChar.currentProfileName]) then
		SelectProfile(savedVariablesPerChar.currentProfileName)
	else
		SelectProfile(DEFAULT_PROFILE_NAME)
	end


	-- Set the saved media to the value specified in the .toc file.
	savedMedia = _G[SAVED_MEDIA_NAME]

	-- Check if there is no saved media.
	if (not savedMedia) then
		-- Create a new table to hold the saved media, and set the .toc entry to it.
		savedMedia = {}
		_G[SAVED_MEDIA_NAME] = savedMedia

		-- Create custom font and sounds tables.
		savedMedia.fonts = {}
		savedMedia.sounds = {}
	end

	-- Allow public access to saved variables.
	module.savedVariables = savedVariables
	module.savedMedia = savedMedia
end


-------------------------------------------------------------------------------
-- Command handler functions.
-------------------------------------------------------------------------------

-- ****************************************************************************
-- Returns the current and remaining parameters from the passed string.
-- ****************************************************************************
local function GetNextParameter(paramString)
	local remainingParams
	local currentParam = paramString

	-- Look for a space.
	local index = string_find(paramString, " ", 1, true)
	if (index) then
		-- Get the current and remaing parameters.
		currentParam = string.sub(paramString, 1, index-1)
		remainingParams = string.sub(paramString, index+1)
	end

	-- Return the current parameter and the remaining ones.
	return currentParam, remainingParams
end


-- ****************************************************************************
-- Called to handle commands.
-- ****************************************************************************
local function CommandHandler(params)
	-- Get the parameter.
	local currentParam, remainingParams
	currentParam, remainingParams = GetNextParameter(params)

	-- Flag for whether or not to show usage info.
	local showUsage = true

	-- Make sure there is a current parameter and lower case it.
	if (currentParam) then currentParam = string.lower(currentParam) end

	-- Look for the recognized parameters.
	if (currentParam == "") then
		-- Load the on demand options.
		ShowOptions()

		-- Don't show the usage info.
		showUsage = false

		-- Reset.
		elseif (currentParam == L.COMMAND_RESET) then
		-- Reset the current profile.
		ResetProfile(nil, true)

		-- Don't show the usage info.
		showUsage = false

	-- Disable.
	elseif (currentParam == L.COMMAND_DISABLE) then
		-- Set the user disabled option.
		SetOptionUserDisabled(true)

		-- Output an informative message.
		Print(L.MSG_DISABLE, 1, 1, 1)

		-- Don't show the usage info.
		showUsage = false

	-- Enable.
	elseif (currentParam == L.COMMAND_ENABLE) then
		-- Unset the user disabled option.
		SetOptionUserDisabled(false)

		-- Output an informative message.
		Print(L.MSG_ENABLE, 1, 1, 1)

		-- Don't show the usage info.
		showUsage = false

	-- Version.
	elseif (currentParam == L.COMMAND_SHOWVER) then
		-- Output the current version number.
		Print(MikSBT.VERSION_STRING, 1, 1, 1)

		-- Don't show the usage info.
		showUsage = false

	end

	-- Check if the usage information should be shown.
	if (showUsage) then
		-- Loop through all of the entries in the command usage list.
		for _, msg in ipairs(L.COMMAND_USAGE) do
			Print(msg, 1, 1, 1)
		end
	end -- Show usage.
end


-------------------------------------------------------------------------------
-- Event handlers.
-------------------------------------------------------------------------------

-- ****************************************************************************
-- Called when the registered events occur.
-- ****************************************************************************
local function OnEvent(this, event, arg1)
	-- When an addon is loaded.
	if (event == "ADDON_LOADED") then
		-- Ignore the event if it isn't this addon.
		if (arg1 ~= "MikScrollingBattleText") then return end

		-- Don't get notification for other addons being loaded.
		this:UnregisterEvent("ADDON_LOADED")

		-- Register slash commands
		SLASH_MSBT1 = MikSBT.COMMAND
		SlashCmdList["MSBT"] = CommandHandler

		-- Initialize the saved variables to make sure there is a profile to work with.
		InitSavedVariables()

		-- Add a button to launch MSBT's options from the Blizzard interface options.
		SetupBlizzardOptions()

		-- Let the media module know the variables are initialized.
		MikSBT.Media.OnVariablesInitialized()

	-- Variables for all addons loaded.
	elseif (event == "VARIABLES_LOADED") then
		-- Disable or enable the mod depending on the saved setting.
		SetOptionUserDisabled(IsModDisabled())

		-- Disable Blizzard's combat text if it's the first load.
		if (isFirstLoad) then DisableBlizzardCombatText() end

		-- Support CUSTOM_CLASS_COLORS.
		if (CUSTOM_CLASS_COLORS) then
			UpdateCustomClassColors()
			if (CUSTOM_CLASS_COLORS.RegisterCallback) then CUSTOM_CLASS_COLORS:RegisterCallback(UpdateCustomClassColors) end
		end
		collectgarbage("collect")
	end
end


-------------------------------------------------------------------------------
-- Initialization.
-------------------------------------------------------------------------------

-- Create a frame to receive events.
eventFrame = CreateFrame("Frame", "MSBTProfileFrame", UIParent)
eventFrame:SetPoint("BOTTOM")
eventFrame:SetWidth(0.0001)
eventFrame:SetHeight(0.0001)
eventFrame:Hide()
eventFrame:SetScript("OnEvent", OnEvent)

-- Register events for when the mod is loaded and variables are loaded.
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("VARIABLES_LOADED")




-------------------------------------------------------------------------------
-- Module interface.
-------------------------------------------------------------------------------

-- Protected Variables.
module.masterProfile = masterProfile

-- Protected Functions.
module.CopyProfile					= CopyProfile
module.DeleteProfile				= DeleteProfile
module.ResetProfile					= ResetProfile
module.SelectProfile				= SelectProfile
module.SetOption					= SetOption
module.SetOptionUserDisabled		= SetOptionUserDisabled
module.IsModDisabled				= IsModDisabled
