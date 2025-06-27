package;

#if desktop
import Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

class CreditsState extends MusicBeatState
{
    // Manually editable credits lines
    var creditsLines:Array<String> = [
        '',
        'The Funkin\' Catalogue',
        '',
        'A Demo for the Funkin\' Catalogue',
        '',
        'FrostyFrisk',
        'Director, Programmer \'& Musician',
        '',
        'Cryoptera',
        'Co-Director',
        '',
        'Alucardseibie',
        'Artist / Animator',
        '',
        'IsipCoffee',
        'Artist / Animator',
        '',
        'Dylandt',
        'Artist',
        '',
        'Joomples',
        'Artist',
        '',
        'Adamcosmicblooms',
        'Artist',
        '',
        'Salt N Piper',
        'Concept Artist',
        '',
        'KyanTPM',
        'Musician',
        '',
        'stawii',
        'Musician',
        '',
        'Hris',
        'Musician',
        '',
		'CiphieVA',
        'Voice Actor',
        '',		
        'JustyTCCD',
        'Coder',
        '',
        'Special Thanks',
        '',
        'Alex Kister',
        'Creator of The Mandela\' Catalogue',
        '',
        '',
        '---',
        '',
        'Press ESC, ENTER, or SPACE to go back to the main menu.'
    ];

    var bg:FlxSprite;
    var creditsTexts:Array<FlxText> = [];
    var scrollSpeed:Float = 60; // pixels per second
    var startY:Float;
    var finished:Bool = false;

    override function create()
    {
        #if desktop
        DiscordClient.changePresence("Viewing Credits", null);
        #end
        persistentUpdate = true;
        bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
        add(bg);
        bg.screenCenter();
        
        // Calculate starting Y so credits start off-screen at the bottom
        startY = FlxG.height;
        var y:Float = startY;
        for (line in creditsLines) {
            var txt = new FlxText(0, y, FlxG.width, line, 36);
            txt.setFormat(Paths.font("vcr.ttf"), 36, FlxColor.WHITE, "center");
            txt.scrollFactor.set();
            add(txt);
            creditsTexts.push(txt);
            y += 48; // line spacing
        }
        super.create();
    }

    override function update(elapsed:Float)
    {
        if (finished) return;
        // Scroll all text upward
        for (txt in creditsTexts) {
            txt.y -= scrollSpeed * elapsed;
        }
        // If the last line has fully scrolled off the top, finish
        var last = creditsTexts[creditsTexts.length - 1];
        if (last.y + last.height < 0) {
            endCredits();
        }
        // Allow skipping
        if (FlxG.keys.justPressed.ESCAPE || FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.SPACE) {
            endCredits();
        }
        super.update(elapsed);
    }

    function endCredits() {
        if (finished) return;
        finished = true;
        FlxG.sound.play(Paths.sound('cancelMenu'));
        FlxTween.tween(bg, {alpha: 0}, 0.5, {onComplete: function(_) {
            MusicBeatState.switchState(new MainMenuState());
        }});
    }
}