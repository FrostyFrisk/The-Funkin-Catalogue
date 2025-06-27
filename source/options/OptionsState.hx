package options;

#if desktop
import Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import Controls;

using StringTools;

class OptionsState extends MusicBeatState
{
	var options:Array<String> = [
		'Note Colors',
		'Controls',
		'Adjust Delay and Combo',
		'Graphics',
		'Visuals and UI',
		'Gameplay'
	];
	private var grpOptions:FlxTypedGroup<Alphabet>;
	private static var curSelected:Int = 0;
	private var bg:FlxSprite;
	private var highlight:FlxSprite;

	override function create()
	{
		#if desktop
		DiscordClient.changePresence("Options Menu", null);
		#end

		// Black background
		bg = new FlxSprite();
		bg.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.scrollFactor.set();
		add(bg);

		// Highlight bar (behind selected option)
		highlight = new FlxSprite();
		highlight.makeGraphic(400, 60, FlxColor.WHITE);
		highlight.alpha = 0.3;
		highlight.color = 0xfffff700;
		add(highlight);

		// Options group
		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		var startY = FlxG.height / 2 - (options.length * 60) / 2;
		for (i in 0...options.length)
		{
			var optionText = new Alphabet(0, 0, options[i], true); // removed the last 'false' argument
			optionText.x = FlxG.width / 2 - optionText.width / 2;
			optionText.y = startY + i * 60;
			grpOptions.add(optionText);
		}

		changeSelection();

		super.create();
	}

	override function closeSubState()
	{
		super.closeSubState();
		ClientPrefs.saveSettings();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (controls.UI_UP_P)
			changeSelection(-1);
		if (controls.UI_DOWN_P)
			changeSelection(1);

		if (controls.BACK)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			MusicBeatState.switchState(new MainMenuState());
		}

		if (controls.ACCEPT)
			openSelectedSubstate(options[curSelected]);
	}

	function changeSelection(change:Int = 0)
	{
		curSelected += change;
		if (curSelected < 0)
			curSelected = options.length - 1;
		if (curSelected >= options.length)
			curSelected = 0;

		var i = 0;
		for (item in grpOptions.members)
		{
			item.alpha = (i == curSelected) ? 1 : 0.6;
			i++;
		}

		// Move highlight bar to selected option
		var selected = grpOptions.members[curSelected];
		FlxTween.tween(highlight, {x: selected.x - 30, y: selected.y - 10}, 0.15, {ease: FlxEase.quadOut});
		highlight.width = selected.width + 60;
		highlight.height = 60;

		FlxG.sound.play(Paths.sound('menu_move'));
	}

	function openSelectedSubstate(label:String)
	{
		switch(label)
		{
			case 'Note Colors':
				openSubState(new options.NotesSubState());
			case 'Controls':
				openSubState(new options.ControlsSubState());
			case 'Graphics':
				openSubState(new options.GraphicsSettingsSubState());
			case 'Visuals and UI':
				openSubState(new options.VisualsUISubState());
			case 'Gameplay':
				openSubState(new options.GameplaySettingsSubState());
			case 'Adjust Delay and Combo':
				LoadingState.loadAndSwitchState(new options.NoteOffsetState());
		}
	}
}