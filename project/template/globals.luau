--!nocheck
--!nolint UnknownGlobal
--# selene: allow(global_usage)

-- put globals in here (with types) so we don't have to deal with UnknownGlobal warning on other scripts !
-- this is a mess...

local T = require("types/TypeDefs")
local ActorDefs = require("types/ActorDefs")

local configuration
pcall(function() configuration = require("../src/configuration") end)
configuration = configuration or {}

local globals = {
	foreground = foreground :: T.ActorFrame,
	ROOT = ROOT :: string,
	outputFolder = outputFolder :: string,
	resolveLuaPath = resolveLuaPath :: (path: string, sourcePoint: (number | string)?) -> string,
	normalizePath = normalizePath :: (string) -> string,
	clearRequireCache = clearRequireCache :: () -> (),

	synn = synn :: { [any]: any },
	_G = _G,

	--> Shared Template Variables
	Players = {} :: { T.Player },
	Actors = {} :: ActorDefs.actorTable,
	templateReady = false,
	isLoadingUserMods = false,

	--> Configuration
	PLAYER_COUNT = configuration.MAX_PLAYERS or 8,
	affectedPlayers = configuration.affectedPlayers or { 1, 2 } :: (number | { number })?,

	--> GLOBAL Functions
	DayOfYear = DayOfYear :: T.DayOfYear,
	SecondsToMSSMsMs = SecondsToMSSMsMs :: T.SecondsToMSSMsMs,
	IsExtraStage2 = IsExtraStage2 :: T.IsExtraStage2,
	GetInputType = GetInputType :: T.GetInputType,
	GetDiskSpaceFree = GetDiskSpaceFree :: T.GetDiskSpaceFree,
	IsUsingMemoryCard = IsUsingMemoryCard :: T.IsUsingMemoryCard,
	CourseDifficultyToThemedString = CourseDifficultyToThemedString :: T.CourseDifficultyToThemedString,
	NumStagesLeft = NumStagesLeft :: T.NumStagesLeft,
	GetStageText = GetStageText :: T.GetStageText,
	GetNumCrashLogs = GetNumCrashLogs :: T.GetNumCrashLogs,
	Year = Year :: T.Year,
	Weekday = Weekday :: T.Weekday,
	GetBestFinalGrade = GetBestFinalGrade :: T.GetBestFinalGrade,
	Trace = Trace :: T.Trace,
	ConnectToServer = ConnectToServer :: T.ConnectToServer,
	Hour = Hour :: T.Hour,
	DifficultyToThemedString = DifficultyToThemedString :: T.DifficultyToThemedString,
	GetNumIOErrors = GetNumIOErrors :: T.GetNumIOErrors,
	PlayModeName = PlayModeName :: T.PlayModeName,
	GetNumMachineScores = GetNumMachineScores :: T.GetNumMachineScores,
	AllFailed = AllFailed :: T.AllFailed,
	GradeToString = GradeToString :: T.GradeToString,
	SecondsToMMSS = SecondsToMMSS :: T.SecondsToMMSS,
	SecondsToMMSSMsMsMs = SecondsToMMSSMsMsMs :: T.SecondsToMMSSMsMsMs,
	GetProductVer = GetProductVer :: T.GetProductVer,
	GetIP = GetIP :: T.GetIP,
	SecondsToMMSSMsMs = SecondsToMMSSMsMs :: T.SecondsToMMSSMsMs,
	GetProductName = GetProductName :: T.GetProductName,
	CurStyleName = CurStyleName :: T.CurStyleName,
	OnePassed = OnePassed :: T.OnePassed,
	MonthToString = MonthToString :: T.MonthToString,
	GetGradeFromPercent = GetGradeFromPercent :: T.GetGradeFromPercent,
	GetEasiestNotesDifficulty = GetEasiestNotesDifficulty :: T.GetEasiestNotesDifficulty,
	GetDiskSpaceTotal = GetDiskSpaceTotal :: T.GetDiskSpaceTotal,
	Minute = Minute :: T.Minute,
	CourseSongIndex = CourseSongIndex :: T.CourseSongIndex,
	GetNumMachineEdits = GetNumMachineEdits :: T.GetNumMachineEdits,
	IsNetSMOnline = IsNetSMOnline :: T.IsNetSMOnline,
	IsNetConnected = IsNetConnected :: T.IsNetConnected,
	IsFinalStage = IsFinalStage :: T.IsFinalStage,
	Debug = Debug :: T.Debug,
	IsExtraStage = IsExtraStage :: T.IsExtraStage,
	IsAnyPlayerUsingMemoryCard = IsAnyPlayerUsingMemoryCard :: T.IsAnyPlayerUsingMemoryCard,
	HubIsConnected = HubIsConnected :: T.HubIsConnected,
	Grade = Grade :: T.Grade,
	Second = Second :: T.Second,
	GetUptime = GetUptime :: T.GetUptime,
	GetRevision = GetRevision :: T.GetRevision,
	GetSerialNumber = GetSerialNumber :: T.GetSerialNumber,
	ReportStyle = ReportStyle :: T.ReportStyle,
	FormatPercentScore = FormatPercentScore :: T.FormatPercentScore,
	IsSMOnlineLoggedIn = IsSMOnlineLoggedIn :: T.IsSMOnlineLoggedIn,
	MonthOfMonth = MonthOfMonth :: T.MonthOfMonth,
	DayOfMonth = DayOfMonth :: T.DayOfMonth,

	--> GLOBAL Vars
	SCREEN_HEIGHT = SCREEN_HEIGHT :: number,
	DISPLAY = DISPLAY :: T.RageDisplay,
	MEMCARDMAN = MEMCARDMAN :: T.MemoryCardManager,
	SCREEN_CENTER_Y = SCREEN_CENTER_Y :: number,
	SCREENMAN = SCREENMAN :: T.ScreenManager,
	DISPLAY_LEFT = DISPLAY_LEFT :: number,
	DISPLAY_CENTER_X = DISPLAY_CENTER_X :: number,
	DISPLAYTOP = DISPLAYTOP :: number,
	FUCK_VERSION_3_1 = FUCK_VERSION_3_1 :: number,
	DISPLAY_RIGHT = DISPLAY_RIGHT :: number,
	SOUND = SOUND :: T.GameSoundManager,
	FUCK_VERSION_3 = FUCK_VERSION_3 :: number,
	INPUTMAN = INPUTMAN :: T.RageInput,
	FUCK_VERSION_1 = FUCK_VERSION_1 :: number,
	PROFILEMAN = PROFILEMAN :: T.ProfileManager,
	NOTESKIN = NOTESKIN :: T.NoteSkinManager,
	FUCK_EXE = FUCK_EXE :: boolean,
	SCREENTOP = SCREENTOP :: number,
	PLAYER_2 = PLAYER_2 :: number,
	SCREEN_RIGHT = SCREEN_RIGHT :: number,
	SCREEN_CENTER_X = SCREEN_CENTER_X :: number,
	MESSAGEMAN = MESSAGEMAN :: T.MessageManager,
	THEME = THEME :: T.ThemeManager,
	DISPLAY_CENTER_Y = DISPLAY_CENTER_Y :: number,
	DISPLAY_WIDTH = DISPLAY_WIDTH :: number,
	PLAYER_1 = PLAYER_1 :: number,
	DISPLAY_BOTTOM = DISPLAY_BOTTOM :: number,
	STATSMAN = STATSMAN :: T.StatsManager,
	OPENITG_VERSION = OPENITG_VERSION :: number,
	SONGMAN = SONGMAN :: T.SongManager,
	GAMESTATE = GAMESTATE :: T.GameState,
	SCREEN_LEFT = SCREEN_LEFT :: number,
	SCREEN_BOTTOM = SCREEN_BOTTOM :: number,
	OPENITG = OPENITG :: boolean,
	PREFSMAN = PREFSMAN :: T.PrefsManager,
	DISPLAY_HEIGHT = DISPLAY_HEIGHT :: number,
	UNLOCKMAN = UNLOCKMAN :: T.UnlockManager,
	FUCK_VERSION_2 = FUCK_VERSION_2 :: number,
	SCREEN_WIDTH = SCREEN_WIDTH :: number,
	FILEMAN = FILEMAN :: T.RageFileManager,

	--> Enums
	COIN_MODE_HOME = COIN_MODE_HOME :: number,
	COIN_MODE_PAY = COIN_MODE_PAY :: number,
	COIN_MODE_FREE = COIN_MODE_FREE :: number,

	COURSE_DIFFICULTY_BEGINNER = COURSE_DIFFICULTY_BEGINNER :: number,
	COURSE_DIFFICULTY_EASY = COURSE_DIFFICULTY_EASY :: number,
	COURSE_DIFFICULTY_REGULAR = COURSE_DIFFICULTY_REGULAR :: number,
	COURSE_DIFFICULTY_DIFFICULT = COURSE_DIFFICULTY_DIFFICULT :: number,
	COURSE_DIFFICULTY_CHALLENGE = COURSE_DIFFICULTY_CHALLENGE :: number,
	COURSE_DIFFICULTY_EDIT = COURSE_DIFFICULTY_EDIT :: number,

	DIFFICULTY_BEGINNER = DIFFICULTY_BEGINNER :: number,
	DIFFICULTY_EASY = DIFFICULTY_EASY :: number,
	DIFFICULTY_MEDIUM = DIFFICULTY_MEDIUM :: number,
	DIFFICULTY_HARD = DIFFICULTY_HARD :: number,
	DIFFICULTY_CHALLENGE = DIFFICULTY_CHALLENGE :: number,
	DIFFICULTY_EDIT = DIFFICULTY_EDIT :: number,

	EC_BGANIMATIONS = EC_BGANIMATIONS :: number,
	EC_FONTS = EC_FONTS :: number,
	EC_GRAPHICS = EC_GRAPHICS :: number,
	EC_NUMBERS = EC_NUMBERS :: number,
	EC_SOUNDS = EC_SOUNDS :: number,
	EC_OTHER = EC_OTHER :: number,

	GRADE_TIER01 = GRADE_TIER01 :: number,
	GRADE_TIER02 = GRADE_TIER02 :: number,
	GRADE_TIER03 = GRADE_TIER03 :: number,
	GRADE_TIER04 = GRADE_TIER04 :: number,
	GRADE_TIER05 = GRADE_TIER05 :: number,
	GRADE_TIER06 = GRADE_TIER06 :: number,
	GRADE_TIER07 = GRADE_TIER07 :: number,
	GRADE_TIER08 = GRADE_TIER08 :: number,
	GRADE_TIER09 = GRADE_TIER09 :: number,
	GRADE_TIER10 = GRADE_TIER10 :: number,
	GRADE_TIER11 = GRADE_TIER11 :: number,
	GRADE_TIER12 = GRADE_TIER12 :: number,
	GRADE_TIER13 = GRADE_TIER13 :: number,
	GRADE_TIER14 = GRADE_TIER14 :: number,
	GRADE_TIER15 = GRADE_TIER15 :: number,
	GRADE_TIER16 = GRADE_TIER16 :: number,
	GRADE_TIER17 = GRADE_TIER17 :: number,
	GRADE_TIER18 = GRADE_TIER18 :: number,
	GRADE_TIER19 = GRADE_TIER19 :: number,
	GRADE_TIER20 = GRADE_TIER20 :: number,
	GRADE_FAILED = GRADE_FAILED :: number,

	GOAL_CALORIES = GOAL_CALORIES :: number,
	GOAL_TIME = GOAL_TIME :: number,
	GOAL_NONE = GOAL_NONE :: number,

	HNS_NONE = HNS_NONE :: number,
	HNS_NG = HNS_NG :: number,
	HNS_OK = HNS_OK :: number,

	PREMIUM_NONE = PREMIUM_NONE :: number,
	PREMIUM_DOUBLE = PREMIUM_DOUBLE :: number,
	PREMIUM_JOINT = PREMIUM_JOINT :: number,

	RADAR_CATEGORY_STREAM = RADAR_CATEGORY_STREAM :: number,
	RADAR_CATEGORY_VOLTAGE = RADAR_CATEGORY_VOLTAGE :: number,
	RADAR_CATEGORY_AIR = RADAR_CATEGORY_AIR :: number,
	RADAR_CATEGORY_FREEZE = RADAR_CATEGORY_FREEZE :: number,
	RADAR_CATEGORY_CHAOS = RADAR_CATEGORY_CHAOS :: number,
	RADAR_CATEGORY_TAPS = RADAR_CATEGORY_TAPS :: number,
	RADAR_CATEGORY_JUMPS = RADAR_CATEGORY_JUMPS :: number,
	RADAR_CATEGORY_HOLDS = RADAR_CATEGORY_HOLDS :: number,
	RADAR_CATEGORY_MINES = RADAR_CATEGORY_MINES :: number,
	RADAR_CATEGORY_HANDS = RADAR_CATEGORY_HANDS :: number,
	RADAR_CATEGORY_ROLLS = RADAR_CATEGORY_ROLLS :: number,

	SORT_PREFERRED = SORT_PREFERRED :: number,
	SORT_GROUP = SORT_GROUP :: number,
	SORT_TITLE = SORT_TITLE :: number,
	SORT_BPM = SORT_BPM :: number,
	SORT_POPULARITY = SORT_POPULARITY :: number,
	SORT_TOP_GRADES = SORT_TOP_GRADES :: number,
	SORT_ARTIST = SORT_ARTIST :: number,
	SORT_GENRE = SORT_GENRE :: number,
	SORT_SONG_LENGTH = SORT_SONG_LENGTH :: number,
	SORT_EASY_METER = SORT_EASY_METER :: number,
	SORT_MEDIUM_METER = SORT_MEDIUM_METER :: number,
	SORT_HARD_METER = SORT_HARD_METER :: number,
	SORT_CHALLENGE_METER = SORT_CHALLENGE_METER :: number,
	SORT_MODE_MENU = SORT_MODE_MENU :: number,
	SORT_ALL_COURSES = SORT_ALL_COURSES :: number,
	SORT_NONSTOP = SORT_NONSTOP :: number,
	SORT_ONI = SORT_ONI :: number,
	SORT_ENDLESS = SORT_ENDLESS :: number,
	SORT_ROULETTE = SORT_ROULETTE :: number,

	STEPS_TYPE_DANCE_SINGLE = STEPS_TYPE_DANCE_SINGLE :: number,
	STEPS_TYPE_DANCE_DOUBLE = STEPS_TYPE_DANCE_DOUBLE :: number,
	STEPS_TYPE_DANCE_COUPLE = STEPS_TYPE_DANCE_COUPLE :: number,
	STEPS_TYPE_DANCE_SOLO = STEPS_TYPE_DANCE_SOLO :: number,
	STEPS_TYPE_PUMP_SINGLE = STEPS_TYPE_PUMP_SINGLE :: number,
	STEPS_TYPE_PUMP_HALFDOUBLE = STEPS_TYPE_PUMP_HALFDOUBLE :: number,
	STEPS_TYPE_PUMP_DOUBLE = STEPS_TYPE_PUMP_DOUBLE :: number,
	STEPS_TYPE_PUMP_COUPLE = STEPS_TYPE_PUMP_COUPLE :: number,
	STEPS_TYPE_EZ2_SINGLE = STEPS_TYPE_EZ2_SINGLE :: number,
	STEPS_TYPE_EZ2_DOUBLE = STEPS_TYPE_EZ2_DOUBLE :: number,
	STEPS_TYPE_EZ2_REAL = STEPS_TYPE_EZ2_REAL :: number,
	STEPS_TYPE_PARA_SINGLE = STEPS_TYPE_PARA_SINGLE :: number,
	STEPS_TYPE_PARA_VERSUS = STEPS_TYPE_PARA_VERSUS :: number,
	STEPS_TYPE_DS3DDX_SINGLE = STEPS_TYPE_DS3DDX_SINGLE :: number,
	STEPS_TYPE_BM_SINGLE5 = STEPS_TYPE_BM_SINGLE5 :: number,
	STEPS_TYPE_BM_DOUBLE5 = STEPS_TYPE_BM_DOUBLE5 :: number,
	STEPS_TYPE_BM_SINGLE7 = STEPS_TYPE_BM_SINGLE7 :: number,
	STEPS_TYPE_BM_DOUBLE7 = STEPS_TYPE_BM_DOUBLE7 :: number,
	STEPS_TYPE_MANIAX_SINGLE = STEPS_TYPE_MANIAX_SINGLE :: number,
	STEPS_TYPE_MANIAX_DOUBLE = STEPS_TYPE_MANIAX_DOUBLE :: number,
	STEPS_TYPE_TECHNO_SINGLE4 = STEPS_TYPE_TECHNO_SINGLE4 :: number,
	STEPS_TYPE_TECHNO_SINGLE5 = STEPS_TYPE_TECHNO_SINGLE5 :: number,
	STEPS_TYPE_TECHNO_SINGLE8 = STEPS_TYPE_TECHNO_SINGLE8 :: number,
	STEPS_TYPE_TECHNO_DOUBLE4 = STEPS_TYPE_TECHNO_DOUBLE4 :: number,
	STEPS_TYPE_TECHNO_DOUBLE5 = STEPS_TYPE_TECHNO_DOUBLE5 :: number,
	STEPS_TYPE_PNM_FIVE = STEPS_TYPE_PNM_FIVE :: number,
	STEPS_TYPE_PNM_NINE = STEPS_TYPE_PNM_NINE :: number,
	STEPS_TYPE_LIGHTS_CABINET = STEPS_TYPE_LIGHTS_CABINET :: number,

	TNS_NONE = TNS_NONE :: number,
	TNS_HITMINE = TNS_HITMINE :: number,
	TNS_AVOIDMINE = TNS_AVOIDMINE :: number,
	TNS_MISS = TNS_MISS :: number,
	TNS_BOO = TNS_BOO :: number,
	TNS_GOOD = TNS_GOOD :: number,
	TNS_GREAT = TNS_GREAT :: number,
	TNS_PERFECT = TNS_PERFECT :: number,
}

setmetatable(globals, { __index = synn or {} })
if synn then
	globals.SCX = SCREEN_CENTER_X :: number
	globals.SCY = SCREEN_CENTER_Y :: number
	globals.SW = SCREEN_WIDTH :: number
	globals.SH = SCREEN_HEIGHT :: number
	globals.DW = globals.DISPLAY:GetDisplayWidth()
	globals.DH = globals.DISPLAY:GetDisplayHeight()
end

function globals.assureCaller(
	name: string,
	templateReadyCheckDisabled: boolean?,
	isLoadingUserModsCheckDisabled: boolean?
)
	if (not templateReadyCheckDisabled) and globals.templateReady then
		error(`cannot call {name} after the song has loaded`)
	end
	if (not isLoadingUserModsCheckDisabled) and not globals.isLoadingUserMods then
		error(`cannot call {name} because the template hasn't fully initialized yet`)
	end
end

return globals
