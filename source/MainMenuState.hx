package;

#if desktop
import Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import lime.app.Application;
import Achievements;
import editors.MasterEditorMenu;
import flixel.input.keyboard.FlxKey;
import openfl.media.Video;
import openfl.net.NetConnection;
import openfl.net.NetStream;
import openfl.events.NetStatusEvent;
import BGParticleEffect;
#if VIDEOS_ALLOWED
import hxcodec.FlxVideo;
#end

using StringTools;

class MainMenuState extends MusicBeatState
{
    public static var psychEngineVersion:String = '0.6.2';
    public static var curSelected:Int = 0;
    private static var introPlayed:Bool = false;

    var menuItems:FlxTypedGroup<FlxText>;
    private var camGame:FlxCamera;
    private var camAchievement:FlxCamera;
    private var netConn:NetConnection;
    private var netStream:NetStream;
    private var video:Video;
    private var introVideo:FlxVideo;
    
    var optionShit:Array<String> = [
        'story mode',
        'freeplay',
        'credits',
        'options'
    ];

    var magenta:FlxSprite;
    var camFollow:FlxObject;
    var camFollowPos:FlxObject;
    var debugKeys:Array<FlxKey>;
    var selectedSomethin:Bool = false;
    var underline:FlxSprite;

    override function create()
    {
        trace('MainMenuState.create() called, introPlayed=' + introPlayed);
        if (!introPlayed)
        {
            trace('Playing intro video (hxCodec)...');
            playIntroVideo();
            return;
        }
        // --- New menu visuals and logic ---
        #if MODS_ALLOWED
        Paths.pushGlobalMods();
        #end
        WeekData.loadTheFirstEnabledMod();

        #if desktop
        DiscordClient.changePresence("In the Menus", null);
        #end
        debugKeys = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));

        camGame = new FlxCamera();
        camAchievement = new FlxCamera();
        camAchievement.bgColor.alpha = 0;

        FlxG.cameras.reset(camGame);
        FlxG.cameras.add(camAchievement, false);
        FlxG.cameras.setDefaultDrawTarget(camGame, true);

        transIn = FlxTransitionableState.defaultTransIn;
        transOut = FlxTransitionableState.defaultTransOut;

        persistentUpdate = persistentDraw = true;

        var yScroll:Float = Math.max(0.25 - (0.05 * (optionShit.length - 4)), 0.1);
        // Use custom background art
        var bg:FlxSprite = new FlxSprite(0, 0).loadGraphic(Paths.image('newmainmenuart/background'));
        bg.scrollFactor.set(0, yScroll);
        add(bg);

        add(new BGParticleEffect());

        camFollow = new FlxObject(0, 0, 1, 1);
        camFollowPos = new FlxObject(0, 0, 1, 1);
        add(camFollow);
        add(camFollowPos);

        magenta = new FlxSprite(-80).loadGraphic(Paths.image('menuDesat'));
        magenta.scrollFactor.set(0, yScroll);
        magenta.setGraphicSize(Std.int(magenta.width * 1.175));
        magenta.updateHitbox();
        magenta.screenCenter();
        magenta.visible = false;
        magenta.antialiasing = ClientPrefs.globalAntialiasing;
        magenta.color = 0xFFfd719b;
        //add(magenta);

        // Title text (top left)
        var titleText:FlxText = new FlxText(32, 32, 0, "the funkin' catalogue", 32);
        titleText.setFormat("VCR OSD Mono", 32, 0xFFC0C0C0, LEFT, FlxColor.BLACK); // light gray
        titleText.alpha = 0.7;
        add(titleText);
        // DEMO tag (top right of title)
        var demoText:FlxText = new FlxText(titleText.x + titleText.width + 16, 40, 0, "DEMO", 28);
        demoText.setFormat("VCR OSD Mono", 28, 0xFF444444, LEFT, FlxColor.BLACK); // dark gray
        demoText.alpha = 0.5;
        add(demoText);

        // Menu items (styled as in screenshot)
        menuItems = new FlxTypedGroup<FlxText>();
        add(menuItems);
        var menuStartY = 180;
        var menuGap = 70;
        var menuX = 180;
        for (i in 0...optionShit.length)
        {
            var label = new FlxText(menuX, menuStartY + i*menuGap, 0, optionShit[i].toUpperCase(), 48);
            label.setFormat("VCR OSD Mono", 48, FlxColor.WHITE, LEFT, FlxColor.BLACK);
            label.alpha = (i == 0) ? 1 : 0.4;
            label.color = FlxColor.WHITE;
            add(label);
            menuItems.add(label);
        }
        // White rectangle selector
        var selector:FlxSprite = new FlxSprite(menuX - 50, menuStartY, null);
        selector.makeGraphic(18, 48, FlxColor.WHITE);
        selector.alpha = 1;
        add(selector);
        curSelected = 0;
        updateSelectionVisuals();
        FlxG.camera.follow(camFollowPos, null, 1);

        changeItem();

        var versionShit:FlxText = new FlxText(12, FlxG.height - 44, 0, "Psych Engine v" + psychEngineVersion, 12);
        versionShit.scrollFactor.set();
        versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxColor.BLACK);
        //add(versionShit);
        versionShit = new FlxText(12, FlxG.height - 24, 0, "Friday Night Funkin' v" + Application.current.meta.get('version'), 12);
        versionShit.scrollFactor.set();
        versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxColor.BLACK);
        //add(versionShit);

        #if ACHIEVEMENTS_ALLOWED
        Achievements.loadAchievements();
        var leDate = Date.now();
        if (leDate.getDay() == 5 && leDate.getHours() >= 18) {
            var achieveID:Int = Achievements.getAchievementIndex('friday_night_play');
            if(!Achievements.isAchievementUnlocked(Achievements.achievementsStuff[achieveID][2])) {
                Achievements.achievementsMap.set(Achievements.achievementsStuff[achieveID][2], true);
                giveAchievement();
                ClientPrefs.saveSettings();
            }
        }
        #end

        super.create();
    }

    private function playIntroVideo():Void
    {
        #if VIDEOS_ALLOWED
        introVideo = new FlxVideo();
        add(introVideo);
        introVideo.onEndReached = function() {
            trace('Intro video finished (hxCodec)');
            remove(introVideo);
            introPlayed = true;
            FlxG.sound.playMusic("assets/preload/music/TFCMenu.ogg", 1.0, true);
            create();
        };
        introVideo.play("assets/videos/FunkinCatalogueIntro.mp4");
        #else
        trace('Video playback not allowed on this platform. Skipping intro.');
        introPlayed = true;
        FlxG.sound.playMusic("assets/preload/music/TFCMenu.ogg", 1.0, true);
        create();
        #end
    }

    #if ACHIEVEMENTS_ALLOWED
    // Unlocks "Freaky on a Friday Night" achievement
    function giveAchievement() {
        add(new AchievementObject('friday_night_play', camAchievement));
        FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
        trace('Giving achievement "friday_night_play"');
    }
    #end

    override function update(elapsed:Float)
    {
        if (!introPlayed) return;
        if (FlxG.sound.music.volume < 0.8)
        {
            FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
            if(FreeplayState.vocals != null) FreeplayState.vocals.volume += 0.5 * elapsed;
        }
        var lerpVal:Float = CoolUtil.boundTo(elapsed * 7.5, 0, 1);
        camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));
        if (!selectedSomethin)
        {
            if (FlxG.keys.justPressed.UP)    changeItem(-1);
            if (FlxG.keys.justPressed.DOWN)  changeItem( 1);
            if (FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.SPACE)
                onSelect();
            if (controls.BACK)
            {
                selectedSomethin = true;
                FlxG.sound.play(Paths.sound('cancelMenu'));
                MusicBeatState.switchState(new TitleState());
            }
            if (controls.ACCEPT)
            {
                if (optionShit[curSelected] == 'donate')
                {
                    CoolUtil.browserLoad('https://ninja-muffin24.itch.io/funkin');
                }
                else
                {
                    selectedSomethin = true;
                    FlxG.sound.play(Paths.sound('confirmMenu'));
                    if(ClientPrefs.flashing) FlxFlicker.flicker(magenta, 1.1, 0.15, false);
                    menuItems.forEach(function(spr:FlxSprite)
                    {
                        if (curSelected != spr.ID)
                        {
                            FlxTween.tween(spr, {alpha: 0}, 0.4, {
                                ease: FlxEase.quadOut,
                                onComplete: function(twn:FlxTween)
                                {
                                    spr.kill();
                                }
                            });
                        }
                        else
                        {
                            FlxFlicker.flicker(spr, 1, 0.06, false, false, function(flick:FlxFlicker)
                            {
                                var daChoice:String = optionShit[curSelected];
                                switch (daChoice)
                                {
                                    case 'story_mode':
                                        MusicBeatState.switchState(new StoryMenuState());
                                    case 'freeplay':
                                        MusicBeatState.switchState(new FreeplayState());
                                    case 'credits':
                                        MusicBeatState.switchState(new CreditsState());
                                    case 'options':
                                        LoadingState.loadAndSwitchState(new options.OptionsState());
                                }
                            });
                        }
                    });
                }
            }
            #if desktop
            else if (FlxG.keys.anyJustPressed(debugKeys))
            {
                selectedSomethin = true;
                MusicBeatState.switchState(new MasterEditorMenu());
            }
            #end
        }
        super.update(elapsed);
        menuItems.forEach(function(spr:FlxSprite)
        {
            spr.screenCenter(X);
        });
    }

    function updateSelectionVisuals():Void
    {
        for (i in 0...menuItems.length)
        {
            var label = menuItems.members[i];
            label.alpha = (i == curSelected) ? 1 : 0.4;
        }
        var selectedLabel = menuItems.members[curSelected];
        underline.x = selectedLabel.x;
        underline.y = selectedLabel.y + selectedLabel.height + 4;
        underline.visible = true;
    }

    function changeItem(delta:Int = 0):Void
    {
        curSelected = (curSelected + delta + menuItems.length) % menuItems.length;
        updateSelectionVisuals();
    }

    function onSelect():Void
    {
        switch (optionShit[curSelected])
        {
            case 'story mode':
                MusicBeatState.switchState(new StoryMenuState());
            case 'freeplay':
                MusicBeatState.switchState(new FreeplayState());
            case 'credits':
                MusicBeatState.switchState(new CreditsState());
            case 'options':
                LoadingState.loadAndSwitchState(new options.OptionsState());
        }
    }
}