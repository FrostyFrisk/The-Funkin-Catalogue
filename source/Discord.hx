package;

import Sys.sleep;
import discord_rpc.DiscordRpc;
import ClientPrefs;

#if LUA_ALLOWED
import llua.Lua;
import llua.State;
#end

using StringTools;

class DiscordClient
{
	public static var isInitialized:Bool = false;
	public function new()
	{
		trace("Discord Client starting...");
		DiscordRpc.start({
			clientID: "1387429130609627156",
			onReady: onReady,
			onError: onError,
			onDisconnected: onDisconnected
		});
		trace("Discord Client started.");

		while (true)
		{
			DiscordRpc.process();
			sleep(2);
			//trace("Discord Client Update");
		}

		DiscordRpc.shutdown();
	}
	
	public static function shutdown()
	{
		DiscordRpc.shutdown();
	}
	
	static function onReady()
	{
		DiscordRpc.presence({
			details: "Navigating the Menus.",
			state: null,
			largeImageKey: 'icon',
			largeImageText: "The Funkin Catalogue"
		});
	}

	static function onError(_code:Int, _message:String)
	{
		trace('Error! $_code : $_message');
	}

	static function onDisconnected(_code:Int, _message:String)
	{
		trace('Disconnected! $_code : $_message');
	}

	public static function initialize()
	{
		if (!ClientPrefs.discordRPCEnabled) {
			trace('Discord RPC is disabled by ClientPrefs.');
			return;
		}
		var DiscordDaemon = sys.thread.Thread.create(() ->
		{
			new DiscordClient();
		});
		trace("Discord Client initialized");
		isInitialized = true;
	}

	public static function changePresence(details:String, state:Null<String>, ?smallImageKey : String, ?hasStartTimestamp : Bool, ?endTimestamp: Float)
	{
		if (!ClientPrefs.discordRPCEnabled) {
			trace('Discord RPC presence update skipped (disabled by ClientPrefs).');
			return;
		}
		var startTimestamp:Float = if(hasStartTimestamp) Date.now().getTime() else 0;

		if (PlayState.devMode) {
			// Hide all song/game info in dev mode
			DiscordClient.changePresence("Developer Mode", "", null, null);
			return;
		}

		if (endTimestamp > 0)
		{
			endTimestamp = startTimestamp + endTimestamp;
		}

		// Custom icon logic for songs
		var largeImageKey = 'icon';
		try {
			var songName = null;
			if (Reflect.hasField(PlayState, 'SONG') && PlayState.SONG != null && Reflect.hasField(PlayState.SONG, 'song')) {
				songName = PlayState.SONG.song;
			} else if (Reflect.hasField(PlayState, 'curSong')) {
				songName = PlayState.curSong;
			}
			if (songName != null) {
				var songKey = songName.toLowerCase();
				var iconMap = [
					'favor' => 'favor_icon',
					'newsflash' => 'favor_icon',
					'seraph' => 'seraph_icon',
					'soliloquy' => 'soliloquy_icon'
				];
				if (iconMap.exists(songKey)) {
					largeImageKey = iconMap.get(songKey);
				}
			}
		} catch(e:Dynamic) {}

		DiscordRpc.presence({
			details: details,
			state: state,
			largeImageKey: largeImageKey,
			largeImageText: "Engine Version: " + MainMenuState.psychEngineVersion,
			smallImageKey : smallImageKey,
			// Obtained times are in milliseconds so they are divided so Discord can use it
			startTimestamp : Std.int(startTimestamp / 1000),
            endTimestamp : Std.int(endTimestamp / 1000)
		});

		//trace('Discord RPC Updated. Arguments: $details, $state, $smallImageKey, $hasStartTimestamp, $endTimestamp');
	}

	#if LUA_ALLOWED
	public static function addLuaCallbacks(lua:State) {
		Lua_helper.add_callback(lua, "changePresence", function(details:String, state:Null<String>, ?smallImageKey:String, ?hasStartTimestamp:Bool, ?endTimestamp:Float) {
			changePresence(details, state, smallImageKey, hasStartTimestamp, endTimestamp);
		});
	}
	#end
}
