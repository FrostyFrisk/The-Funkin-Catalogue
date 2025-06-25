package;

import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.text.FlxTextAlign;
import flixel.text.FlxTextBorderStyle;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import openfl.media.Video;
import openfl.net.NetConnection;
import openfl.net.NetStream;
import openfl.events.NetStatusEvent;
import BGParticleEffect;
import openfl.Lib;

class MainMenuState extends FlxState
{
    // remember if we've already seen the intro
    private static var introPlayed:Bool = false;

    // video playback objects
    private var netConn:NetConnection;
    private var netStream:NetStream;
    private var video:Video;

    // our menu items and cursor
    private var menuItems:Array<FlxText>;
    private var curSelected:Int;

    // the actual menu options
    private var optionShit:Array<String> = [
        "story mode",
        "freeplay",
        "options",
        "credits",
        "quit"
    ];

    override public function create():Void
    {
        super.create();

        if (!introPlayed)
        {
            playIntroVideo();
        }
        else
        {
            // if returning to menu, start music and particles immediately
            startMusicAndEffects();
            buildMenu();
        }
    }

    /**
     *  Stream and display the intro.mp4 full‐screen.
     *  When it finishes, we tear it down and call buildMenu().
     */
    private function playIntroVideo():Void
    {
        // set up a "null" NetConnection (for local file)
        netConn   = new NetConnection();
        netConn.connect(null);

        netStream = new NetStream(netConn);
        netStream.client = {};

        video = new Video(FlxG.width, FlxG.height);
        video.attachNetStream(netStream);
        FlxG.stage.addChild(video);

        netStream.addEventListener(NetStatusEvent.NET_STATUS, function(e:NetStatusEvent) {
            if (e.info.code == "NetStream.Play.Stop")
                cleanupVideo();
        });

        netStream.play("assets/videos/intro.mp4");
    }

    private function cleanupVideo():Void
    {
        // remove video, close stream
        FlxG.stage.removeChild(video);
        netStream.close();

        introPlayed = true;

        // start menu music & background effect
        startMusicAndEffects();
        buildMenu();
    }

    /**
     *  Play menu music and spawn background particles.
     */
    private function startMusicAndEffects():Void
    {
        // play menu music (looping)
        FlxG.sound.playMusic("assets/preload/music/TFCMenu.ogg", 1.0, true);

        // add background particle effect
        add(new BGParticleEffect());
    }

    /**
     *  Build the classic TJOC‐style, black‐bg menu
     *  with each entry tweening up into place.
     */
    private function buildMenu():Void
    {
        // full‐screen black background
        var bg = new FlxSprite(0,0)
            .makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        add(bg);

        // create text entries off‐screen (below)
        menuItems = [];
        var startX = (FlxG.width - 300) / 2;
        var startY = FlxG.height + 50;
        var gapY   = 60;

        for (i in 0...optionShit.length)
        {
            var label = new FlxText(startX, startY + i*gapY, 300,
                                    optionShit[i].toUpperCase())
                .setFormat(
                    null,                // default font
                    24,                  // size
                    FlxColor.WHITE,      // color
                    FlxTextAlign.CENTER,
                    FlxTextBorderStyle.OUTLINE,
                    FlxColor.BLACK
                );
            label.alpha = 0;
            add(label);
            menuItems.push(label);

            // tween each entry into its final Y position, staggered by index
            var finalY = (FlxG.height/2 - (optionShit.length*gapY)/2) + i*gapY;
            FlxTween.tween(label, { y: finalY, alpha: 1 }, 0.5, {
                startDelay: i * 0.1,
                ease: FlxEase.quadOut
            });
        }

        // start with first item selected
        curSelected = 0;
        updateSelectionVisuals();
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);

        // if we're still in the video, block inputs
        if (!introPlayed) return;

        // navigate
        if (FlxG.keys.justPressed.UP)    changeItem(-1);
        if (FlxG.keys.justPressed.DOWN)  changeItem( 1);

        // confirm or back/quit
        if (FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.SPACE)
            onSelect();
        else if (FlxG.keys.justPressed.ESCAPE)
            Lib.exit();
    }

    private function changeItem(delta:Int):Void
    {
        curSelected = (curSelected + delta + menuItems.length) % menuItems.length;
        updateSelectionVisuals();
    }

    /** dim non‐selected entries */
    private function updateSelectionVisuals():Void
    {
        for (i in 0...menuItems.length)
            menuItems[i].alpha = (i == curSelected) ? 1 : 0.6;
    }

    private function onSelect():Void
    {
        switch (optionShit[curSelected])
        {
            case "story mode":
                FlxG.switchState(new StoryMenuState());
            case "freeplay":
                FlxG.switchState(new FreeplayState());
            // case "options":
            //     FlxG.switchState(new OptionsState()); // Disabled: OptionsState not found
            case "credits":
                FlxG.switchState(new CreditsState());
            case "quit":
                Lib.exit();
        }
    }
}